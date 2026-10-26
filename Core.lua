-- Dwarven Accent Advanced 1.3: deterministic single-pass rewrite engine.
-- The original Simple branch is intentionally separate and unchanged.
local _, DA = ...

local DEFAULT_PRESET = "Balanced"
local PRESETS = {
    Subtle   = { tier = 1, limit = 2 },
    Balanced = { tier = 2, limit = 3 },
    Heavy    = { tier = 3, limit = 0 }, -- 0 = unlimited when no manual limit is set
}
DA.Presets = PRESETS

local function NewSettings()
    return { enabled = true, preset = DEFAULT_PRESET, maxChanges = 0,
        categories = {}, disabledRules = {} }
end
DA.NewSettings = NewSettings

local function ValidateSettings(db)
    if type(db) ~= "table" then db = NewSettings() end
    if type(db.enabled) ~= "boolean" then db.enabled = true end
    if not PRESETS[db.preset] then db.preset = DEFAULT_PRESET end
    if type(db.maxChanges) ~= "number" or db.maxChanges ~= math.floor(db.maxChanges)
        or db.maxChanges < 0 or db.maxChanges > 20 then db.maxChanges = 0 end
    if type(db.categories) ~= "table" then db.categories = {} end
    if type(db.disabledRules) ~= "table" then db.disabledRules = {} end
    return db
end
DA.ValidateSettings = ValidateSettings

function DA.LoadSettings()
    DwarvenAccentDB = ValidateSettings(DwarvenAccentDB)
    DA.DB = DwarvenAccentDB
    return DA.DB
end

local function IsWordChar(ch)
    return ch ~= "" and ch:match("[%w_]") ~= nil
end

local function MatchCase(original, replacement)
    -- Standalone 'I' is grammatically capitalized, NOT shouted.
    if #original > 1 and original:match("%a") and original == original:upper() then
        return replacement:upper()
    end
    local first = original:sub(1, 1)
    if first:match("%a") and first == first:upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

-- Bucket by first source character rather than scanning every rule at every position.
-- Order longest-first within each bucket so phrases outrank individual words.
local indexed = {}
for _, rule in ipairs(DA.Rules) do
    rule.length = #rule.source
    local initial = rule.source:sub(1, 1)
    indexed[initial] = indexed[initial] or {}
    indexed[initial][#indexed[initial] + 1] = rule
end
for _, bucket in pairs(indexed) do
    table.sort(bucket, function(a, b)
        if a.length ~= b.length then return a.length > b.length end
        if a.tier ~= b.tier then return a.tier < b.tier end
        return a.source < b.source
    end)
end

local function RuleAllowed(rule, db, preset)
    return rule.tier <= preset.tier
        and db.categories[rule.category] ~= false
        and db.disabledRules[rule.source] ~= true
end

-- The vocabulary marks only ambiguous rules with context metadata. Defaults
-- deliberately remain unconditional: no NLP dependencies, random choices, or
-- changes to the proven pre-send hook. All lookups inspect ORIGINAL text.
local APPEARANCE_NOUNS = {
    lass = true, girl = true, woman = true, lady = true, lad = true, boy = true,
    face = true, smile = true, dress = true, flower = true, flowers = true,
    view = true, sight = true, picture = true, painting = true, place = true,
    village = true, sunset = true, sunrise = true, day = true, scene = true,
    landscape = true, mountain = true, mountains = true, river = true,
    waterfall = true, sky = true, house = true, garden = true, gem = true,
}
local APPEARANCE_MODIFIERS = {
    little = true, small = true, wee = true, young = true, old = true,
    lovely = true, quaint = true, charming = true, bright = true,
}
local EMPHASIS_ADJECTIVES = {
    good = true, bad = true, hard = true, tough = true, cold = true,
    hot = true, brave = true, strong = true, tired = true, lucky = true,
    strange = true, odd = true, big = true, small = true, fast = true,
    slow = true, angry = true, happy = true, loud = true, fine = true,
}
local CRAZY_NOUNS = {
    idea = true, plan = true, scheme = true, story = true,
    man = true, woman = true, person = true, lad = true, lass = true,
    dwarf = true, fool = true, thing = true,
}
local FASH_OBJECTS = {
    me = true, you = true, yourself = true, yourselves = true,
    him = true, her = true, them = true, us = true, oneself = true,
}
local MAN_VERB_FOLLOWERS = {
    the = true, a = true, an = true, your = true, our = true, their = true,
    his = true, her = true, my = true, these = true, those = true, up = true,
}
local BODY_PART_PRECEDERS = {
    my = true, your = true, yer = true, his = true, her = true,
    our = true, their = true, its = true, smart = true, dumb = true,
    lazy = true, kick = true, kicked = true, kicking = true,
}
local NO_DETERMINER_NOUNS = {
    idea = true, clue = true, time = true, money = true, gold = true,
    problem = true, chance = true, luck = true, reason = true, way = true,
    doubt = true, doubts = true, food = true, ale = true, beer = true,
    weapons = true, weapon = true, fear = true, need = true, hope = true,
    worries = true, question = true, questions = true,
}
local NO_REPLY_FOLLOWERS = {
    i = true, you = true, he = true, she = true, we = true, they = true,
    it = true, thanks = true, thank = true, please = true, sir = true,
    never = true, ["not"] = true, just = true, really = true,
}

-- Only match an adjacent word; punctuation starts a new phrase, not an
-- accidental modifier. A hyphen is likewise NOT interpreted as whitespace.
local function NextWord(lower, last)
    return lower:sub(last + 1):match("^%s+([%a]+)")
end

local function PreviousWord(lower, first)
    return lower:sub(1, first - 1):match("([%a']+)%s*$")
end

local function HasVisualNoun(lower, last)
    local remainder = lower:sub(last + 1)
    for _ = 1, 3 do
        local word, nextPos = remainder:match("^%s+([%a]+)()")
        if not word then return false end
        if APPEARANCE_NOUNS[word] then return true end
        if not APPEARANCE_MODIFIERS[word] then return false end
        remainder = remainder:sub(nextPos)
    end
    return false
end

-- Returns the actual substitution, or nil to leave the original word intact.
-- This is more flexible than a yes/no check: English 'no' is either the answer
-- 'naw' or the negative determiner 'nae' in Scots, but often ambiguous.
local function ContextReplacement(rule, lower, first, last)
    local context = rule.context
    if not context then return rule.replacement end
    local nextWord = NextWord(lower, last)
    if context == "appearance" then
        return HasVisualNoun(lower, last) and rule.replacement or nil
    elseif context == "intensifier" then
        return nextWord and EMPHASIS_ADJECTIVES[nextWord] and rule.replacement or nil
    elseif context == "crazy_description" then
        -- 'crazy idea' and 'that's crazy' work; 'crazy good' does not.
        return (not nextWord or CRAZY_NOUNS[nextWord]) and rule.replacement or nil
    elseif context == "fash_verb" then
        -- 'fash' is primarily 'bother/trouble (someone)', not a blanket
        -- translation of the noun 'trouble' or 'worry about the future'.
        return nextWord and FASH_OBJECTS[nextWord] and rule.replacement or nil
    elseif context == "man_noun" then
        -- 'Man the cannons!' must never become 'Lad the cannons!'
        return (not nextWord or not MAN_VERB_FOLLOWERS[nextWord])
            and rule.replacement or nil
    elseif context == "bare_only" then
        -- E.g. "that's" must not produce "tha''s".
        local nextCharacter = lower:sub(last + 1, last + 1)
        return nextCharacter ~= "'" and lower:sub(last + 1, last + 3) ~= "’"
            and rule.replacement or nil
    elseif context == "body_part" then
        local preceding = PreviousWord(lower, first)
        return preceding and BODY_PART_PRECEDERS[preceding] and rule.replacement or nil
    elseif context == "no_form" then
        if nextWord and NO_DETERMINER_NOUNS[nextWord] then return "nae" end
        if not nextWord or NO_REPLY_FOLLOWERS[nextWord] then return "naw" end
        -- 'no one', 'no longer', unknown nouns, etc. are left alone.
        return nil
    end
    -- Fail closed: an unknown context label must not silently mistranslate.
    return nil
end

local function TransformPlain(text, db, preset, remaining)
    if remaining <= 0 or text == "" then return text, 0 end
    local out, lower, pos, changes = {}, text:lower(), 1, 0
    while pos <= #text do
        local selected, selectedReplacement
        local current = lower:sub(pos, pos)
        local bucket = indexed[current]
        if bucket and changes < remaining
            and (pos == 1 or not IsWordChar(text:sub(pos - 1, pos - 1))) then
            for _, rule in ipairs(bucket) do
                local last = pos + rule.length - 1
                if last <= #text and lower:sub(pos, last) == rule.source
                    and (last == #text or not IsWordChar(text:sub(last + 1, last + 1)))
                    and RuleAllowed(rule, db, preset) then
                    local replacement = ContextReplacement(rule, lower, pos, last)
                    if replacement then
                        selected, selectedReplacement = rule, replacement
                        break
                    end
                end
            end
        end
        if selected then
            out[#out + 1] = MatchCase(text:sub(pos, pos + selected.length - 1), selectedReplacement)
            pos = pos + selected.length
            changes = changes + 1
        else
            out[#out + 1] = text:sub(pos, pos)
            pos = pos + 1
        end
        -- No need to scan the rest of the string once the budget is exhausted.
        if changes >= remaining then
            out[#out + 1] = text:sub(pos)
            break
        end
    end
    return table.concat(out), changes
end

-- A protected span is copied byte-for-byte, including invisible link payloads.
-- Only check expensive patterns for plausible starting characters.
local function ProtectedLength(text, pos)
    local lead = text:sub(pos, pos)
    local rest, span
    if lead == "|" then
        rest = text:sub(pos)
        span = rest:match("^|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r")
            or rest:match("^|H.-|h.-|h")
            or rest:match("^|T.-|t")
            or rest:match("^|A.-|a")
            or rest:match("^||")
    elseif lead == "(" and text:sub(pos, pos + 1) == "((" then
        local finish = text:find("))", pos + 2, true)
        return finish and (finish + 1 - pos) or (#text - pos + 1)
    elseif lead == "[" then
        rest = text:sub(pos)
        span = rest:match("^%b[]")
        -- For unfinished item links, preserve the rest of the message.
        if not span then return #text - pos + 1 end
    elseif (lead == "h" and text:sub(pos, pos + 3) == "http")
        or (lead == "w" and text:sub(pos, pos + 3) == "www.") then
        rest = text:sub(pos)
        span = rest:match("^https?://[^%s]+") or rest:match("^www%.[^%s]+")
    end
    return span and #span or nil
end

-- Second return value is the actual number of substitutions, useful for preview.
function DA.Transform(text, settings)
    if type(text) ~= "string" or text == "" then return text, 0 end
    -- Keep slash commands untouched, as in the proven Simple 1.0 addon.
    if text:sub(1, 1) == "/" then return text, 0 end
    local db = ValidateSettings(settings or DA.DB or NewSettings())
    if not db.enabled then return text, 0 end
    local preset = PRESETS[db.preset]
    local limit = db.maxChanges > 0 and db.maxChanges
        or (preset.limit == 0 and math.huge or preset.limit)
    local out, changed, cursor, pos = {}, 0, 1, 1
    while pos <= #text do
        local length = ProtectedLength(text, pos)
        if length then
            if pos > cursor then
                local part, n = TransformPlain(text:sub(cursor, pos - 1), db, preset, limit - changed)
                out[#out + 1], changed = part, changed + n
            end
            out[#out + 1] = text:sub(pos, pos + length - 1)
            pos = pos + length
            cursor = pos
        else
            pos = pos + 1
        end
    end
    if cursor <= #text then
        local part, n = TransformPlain(text:sub(cursor), db, preset, limit - changed)
        out[#out + 1], changed = part, changed + n
    end
    return table.concat(out), changed
end
