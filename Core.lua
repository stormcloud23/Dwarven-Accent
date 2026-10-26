-- Dwarven Accent Advanced 1.2: deterministic single-pass rewrite engine.
-- The original Simple branch is intentionally separate and unchanged.
local _, DA = ...

local DEFAULT_PRESET = "Balanced"
local PRESETS = {
    Subtle   = { tier = 1, limit = 2 },
    Balanced = { tier = 2, limit = 3 },
    Heavy    = { tier = 3, limit = 7 },
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

-- "Pretty" is frequently an adverb (pretty fast/pretty sure). Translate only
-- where a visual compliment is clear, and leave ambiguous usages untouched.
local PRETTY_NOUNS = {
    lass = true, girl = true, woman = true, lady = true,
    face = true, dress = true, flower = true, flowers = true,
    view = true, sight = true, picture = true, place = true,
    village = true, sunset = true, sunrise = true,
}
local function ContextAllows(rule, lower, endPos)
    if rule.source == "pretty" then
        local nextWord = lower:sub(endPos + 1):match("^%s+([%a]+)")
        return nextWord ~= nil and PRETTY_NOUNS[nextWord] == true
    end
    return true
end

local function TransformPlain(text, db, preset, remaining)
    if remaining <= 0 or text == "" then return text, 0 end
    local out, lower, pos, changes = {}, text:lower(), 1, 0
    while pos <= #text do
        local selected
        local current = lower:sub(pos, pos)
        local bucket = indexed[current]
        if bucket and changes < remaining
            and (pos == 1 or not IsWordChar(text:sub(pos - 1, pos - 1))) then
            for _, rule in ipairs(bucket) do
                local last = pos + rule.length - 1
                if last <= #text and lower:sub(pos, last) == rule.source
                    and (last == #text or not IsWordChar(text:sub(last + 1, last + 1)))
                    and RuleAllowed(rule, db, preset)
                    and ContextAllows(rule, lower, last) then
                    selected = rule
                    break
                end
            end
        end
        if selected then
            out[#out + 1] = MatchCase(text:sub(pos, pos + selected.length - 1), selected.replacement)
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
    local limit = db.maxChanges > 0 and db.maxChanges or preset.limit
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
