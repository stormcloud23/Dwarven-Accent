-- Dwarven Accent Advanced 1.1: single-pass text rewriting and saved settings.
local _, DA = ...

local DEFAULT_PRESET = "Balanced"
local PRESETS = {
    Subtle = { tier = 1, limit = 2 },
    Balanced = { tier = 2, limit = 3 },
    Heavy = { tier = 3, limit = 7 },
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
    -- Standalone "I" is uppercase by grammar, not shouting; avoid "AH".
    if #original > 1 and original:match("%a") and original == original:upper() then
        return replacement:upper()
    end
    local first = original:sub(1, 1)
    if first:match("%a") and first == first:upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

local ordered = {}
for _, rule in ipairs(DA.Rules) do
    ordered[#ordered + 1] = rule
end
table.sort(ordered, function(a, b)
    if #a.source ~= #b.source then return #a.source > #b.source end
    if a.tier ~= b.tier then return a.tier < b.tier end
    return a.source < b.source
end)
DA.OrderedRules = ordered

local function RuleAllowed(rule, db, preset)
    return rule.tier <= preset.tier
        and db.categories[rule.category] ~= false
        and db.disabledRules[rule.source] ~= true
end

local function ContextAllows(rule, lower, startPos, endPos)
    -- "pretty sure" / "pretty good" means degree, not attractiveness.
    -- Leave these alone even when the "pretty" rule is enabled.
    if rule.source == "pretty" then
        local following = lower:sub(endPos + 1):match("^%s+([%a]+)")
        if following and ({ sure = true, much = true, good = true, bad = true,
            well = true, far = true, close = true, certain = true })[following] then
            return false
        end
    end
    return true
end

local function TransformPlain(text, db, preset, remaining)
    local out, lower, pos, count = {}, text:lower(), 1, 0
    while pos <= #text do
        local selected
        if count < remaining and IsWordChar(text:sub(pos, pos)) then
            for _, rule in ipairs(ordered) do
                local last = pos + #rule.source - 1
                if last <= #text and lower:sub(pos, last) == rule.source
                    and (pos == 1 or not IsWordChar(text:sub(pos - 1, pos - 1)))
                    and (last == #text or not IsWordChar(text:sub(last + 1, last + 1)))
                    and RuleAllowed(rule, db, preset)
                    and ContextAllows(rule, lower, pos, last) then
                    selected = rule
                    break
                end
            end
        end
        if selected then
            out[#out + 1] = MatchCase(text:sub(pos, pos + #selected.source - 1), selected.replacement)
            pos = pos + #selected.source
            count = count + 1
        else
            out[#out + 1] = text:sub(pos, pos)
            pos = pos + 1
        end
    end
    return table.concat(out), count
end

-- Returns the length of a protected span that begins at 'pos', or nil.
local function ProtectedLength(text, pos)
    local rest = text:sub(pos)
    local span
    -- Entire hyperlink, including game color codes and hidden payload.
    span = rest:match("^|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r")
        or rest:match("^|H.-|h.-|h")
        or rest:match("^|T.-|t")
        or rest:match("^|A.-|a")
    if span then return #span end
    if rest:sub(1, 2) == "((" then
        local finish = text:find("))", pos + 2, true)
        return finish and (finish + 1 - pos) or (#text - pos + 1)
    end
    if rest:sub(1, 1) == "[" then
        span = rest:match("^%b[]")
        if span then return #span end
        -- Conservative handling of malformed item names.
        return #text - pos + 1
    end
    span = rest:match("^https?://[^%s]+") or rest:match("^www%.[^%s]+")
    if span then return #span end
    return nil
end

function DA.Transform(text, settings)
    if type(text) ~= "string" or text == "" then return text end
    -- Preserve slash commands and chat command arguments exactly as entered.
    if text:sub(1, 1) == "/" then return text end
    local db = ValidateSettings(settings or DA.DB or NewSettings())
    if not db.enabled then return text end
    local preset = PRESETS[db.preset]
    local limit = db.maxChanges > 0 and db.maxChanges or preset.limit
    local out, buffer, pos, changed = {}, {}, 1, 0
    local function Flush()
        if #buffer == 0 then return end
        local transformed, n = TransformPlain(table.concat(buffer), db, preset, limit - changed)
        out[#out + 1] = transformed
        changed = changed + n
        buffer = {}
    end
    while pos <= #text do
        local protected = ProtectedLength(text, pos)
        if protected then
            Flush()
            out[#out + 1] = text:sub(pos, pos + protected - 1)
            pos = pos + protected
        else
            buffer[#buffer + 1] = text:sub(pos, pos)
            pos = pos + 1
        end
    end
    Flush()
    return table.concat(out)
end
