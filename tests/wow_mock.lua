-- Headless smoke test of WoW frame methods, in-game options and outgoing chat hook.
-- Does NOT assert real Forever client compatibility; that requires in-game testing.
local all, byName, chat, callbacks, registered = {}, {}, {}, {}, {}
UIParent = {}
UISpecialFrames = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, s) chat[#chat + 1] = s end }
SlashCmdList = {}

local function widget(kind, name)
    local obj = { kind = kind, name = name, scripts = {}, visible = true }
    function obj:CreateFontString(_, _, font)
        local t = widget("FontString")
        t.font = font
        return t
    end
    for _, method in ipairs({ "SetSize", "SetPoint", "SetFrameStrata", "SetClampedToScreen",
        "SetMovable", "EnableMouse", "RegisterForDrag", "SetWidth", "SetHeight",
        "SetAutoFocus", "SetMaxLetters", "SetJustifyH", "SetWordWrap", "ClearFocus",
        "StartMoving", "StopMovingOrSizing" }) do
        obj[method] = function() end
    end
    function obj:SetText(value)
        self.text = value
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
    end
    function obj:GetText() return self.text end
    function obj:SetChecked(value) self.checked = value end
    function obj:GetChecked() return self.checked end
    function obj:SetAlpha(value) self.alpha = value end
    function obj:SetEnabled(value) self.enabled = value end
    function obj:Show() self.visible = true end
    function obj:Hide() self.visible = false end
    function obj:Raise() self.raised = true end
    function obj:RegisterEvent(name) registered[name] = self end
    function obj:SetScript(name, cb) self.scripts[name] = cb end
    all[#all + 1] = obj
    if name then byName[name] = obj end
    return obj
end
CreateFrame = widget
EventRegistry = { RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
Settings = {
    RegisterCanvasLayoutCategory = function(_, name) return { name = name } end,
    RegisterAddOnCategory = function(category) registered.addonCategory = category.name end,
}

local DA = {}
assert(loadfile("Vocabulary.lua"))("DwarvenAccent", DA)
assert(loadfile("Core.lua"))("DwarvenAccent", DA)
assert(loadfile("Options.lua"))("DwarvenAccent", DA)
assert(loadfile("DwarvenAccent.lua"))("DwarvenAccent", DA)

local assertions = 0
local function eq(a, b, description)
    assertions = assertions + 1
    assert(a == b, (description or "test") .. " expected=" .. tostring(b) .. " got=" .. tostring(a))
end

-- Settings only become available during ADDON_LOADED.
eq(DA.DB, nil, "not initialized before addon load")
local eventFrame = registered.ADDON_LOADED
assert(eventFrame and eventFrame.scripts.OnEvent)
eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "OtherAddon")
eq(DA.DB, nil, "ignores other addons")
eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "DwarvenAccent")
eq(DA.DB.preset, "Balanced", "default preset")
eq(registered.addonCategory, "Dwarven Accent", "modern settings registration")
local preSend = callbacks["ChatFrame.OnEditBoxPreSendText"]
assert(type(preSend) == "function", "pre-send callback registered")

local sent = { original = "I don't know what you're doing.", writes = 0 }
function sent:GetText() return self.original end
function sent:SetText(t) self.original = t; self.writes = self.writes + 1 end
preSend("unused callback arg", sent)
eq(sent.original, "Ah dinnae ken what ye're doing.", "same working callback as Simple")
eq(sent.writes, 1, "changes only when necessary")
preSend(sent)
eq(sent.writes, 1, "no duplicate SetText when no further changes")
sent.original = "[Friend] https://example.com/you"
preSend(sent)
eq(sent.writes, 1, "no writes on protected-only text")
sent.original = "/say I don't know"
preSend(sent)
eq(sent.writes, 1, "do not alter slash commands")

-- Slash commands drive configuration and preview without sending text.
local slash = SlashCmdList.DWARVENACCENT
assert(slash)
slash("heavy")
eq(DA.DB.preset, "Heavy", "slash preset")
slash("off")
eq(DA.DB.enabled, false, "slash disabled persisted")
slash("on")
eq(DA.DB.enabled, true, "slash enabled persisted")
slash("config")
local config = byName.DwarvenAccentConfigFrame
assert(config and config.visible and config.raised, "settings window opens")
eq(UISpecialFrames[1], "DwarvenAccentConfigFrame", "escape frame")
local checks = 0
for _, f in ipairs(all) do if f.kind == "CheckButton" then checks = checks + 1 end end
assert(checks <= 20, "UI must reuse checkboxes, got " .. checks)

-- The search box is the 432px EditBox, the preview box is 690px.
-- Distinguish via the SetSize hook below: here find by expected creation order.
local editboxes = {}
for _, f in ipairs(all) do if f.kind == "EditBox" then editboxes[#editboxes + 1] = f end end
eq(#editboxes, 2, "two inputs (filter and preview)")
local filter, preview = editboxes[1], editboxes[2]
preview:SetText("I don't know")
local function findFont(predicate)
    for _, f in ipairs(all) do
        if f.kind == "FontString" and f.text and predicate(f.text) then return f end
    end
end
assert(findFont(function(t) return t:find("After %(1 changes%)") end), "live preview reports substitutions")
filter:SetText("bonnie")
assert(findFont(function(t) return t:find("matching rules;") end), "search result count")
filter:SetText("")

-- Repeat open does not allocate additional UI controls.
local before = #all
DA.ShowConfig()
eq(#all, before, "opening existing config creates no new frames")

-- One per-rule checkbox toggles the underlying setting and refreshes the preview.
-- The first visible vocabulary rule on page one is the first rule in DA.Rules.
local selected = DA.Rules[1].source
local ruleCheck
for _, f in ipairs(all) do
    if f.kind == "CheckButton" and f.scripts.OnClick then
        -- The first 8 checkboxes are the enabled toggle and categories;
        -- the first rule checkbox comes after them.
        if f == all[1] then end
    end
end
local checkFrames = {}
for _, f in ipairs(all) do if f.kind == "CheckButton" then checkFrames[#checkFrames + 1] = f end end
ruleCheck = checkFrames[9]
assert(ruleCheck, "first vocabulary control")
ruleCheck:SetChecked(false)
ruleCheck.scripts.OnClick(ruleCheck)
eq(DA.DB.disabledRules[selected], true, "individual vocabulary toggle")

-- Input changes do not create any new UI controls.
local stable = #all
for _ = 1, 20 do filter:SetText("freend"); filter:SetText("") end
eq(#all, stable, "filter reuses controls")

-- Paging and filtering should reuse existing controls (including across page turns).
local function buttonNamed(label)
    for _, frame in ipairs(all) do
        if frame.kind == "Button" and frame.text == label then return frame end
    end
end
local function labelStarting(prefix)
    return findFont(function(t) return t:sub(1, #prefix) == prefix end)
end
local pageLabel = labelStarting("Page ")
assert(pageLabel, "vocabulary page indicator")
buttonNamed("Next").scripts.OnClick(buttonNamed("Next"))
eq(pageLabel.text, "Page 2 / 10", "paginated vocabulary")
buttonNamed("Previous").scripts.OnClick(buttonNamed("Previous"))
eq(pageLabel.text, "Page 1 / 10", "previous vocabulary page")
filter:SetText("no-such-word-possibly")
eq(pageLabel.text, "Page 1 / 1", "empty filter has one safe page")
filter:SetText("")
buttonNamed("Subtle").scripts.OnClick(buttonNamed("Subtle"))
eq(DA.DB.preset, "Subtle", "preset selection in UI")
buttonNamed("Reset all settings").scripts.OnClick(buttonNamed("Reset all settings"))
eq(DA.DB.preset, "Balanced", "reset restores balanced")
eq(DA.DB.disabledRules[selected], nil, "reset clears individual overrides")
local restoredDB = DA.DB
DA.LoadSettings()
eq(DA.DB, restoredDB, "save table survives reload")

-- No Settings APIs? A standalone window and the chat callback still work.
local oldSettings = Settings
Settings = nil
DA.InitOptions()
DA.ShowConfig()
Settings = oldSettings

print("PASS: " .. assertions .. " mocked WoW behavior assertions; " .. checks .. " checkboxes total")
