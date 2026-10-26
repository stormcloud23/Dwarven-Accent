-- Emulate a client with the Classic/Forever callback & modern Settings absent.
-- This tests graceful failure, not alternate hooks (Simple 1.0's hook is preserved).
local logs, events = {}, {}
UIParent = {}
SlashCmdList = {}
Settings = nil
EventRegistry = nil
UISpecialFrames = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, s) logs[#logs + 1] = s end }

local function Stub(kind)
    local t = { scripts = {}, kind = kind }
    for _, method in ipairs({ "SetPoint", "SetSize", "SetFrameStrata", "SetClampedToScreen",
        "SetMovable", "EnableMouse", "RegisterForDrag", "SetWordWrap", "SetJustifyH",
        "SetWidth", "SetHeight", "SetMaxLetters", "SetAutoFocus", "ClearFocus",
        "SetChecked", "SetEnabled", "SetAlpha", "StartMoving", "StopMovingOrSizing",
        "Raise" }) do t[method] = function() end end
    function t:Hide() end
    function t:Show() end
    function t:CreateFontString() return Stub("FontString") end
    function t:SetScript(k, fn) self.scripts[k] = fn end
    function t:RegisterEvent(k) events[k] = self end
    function t:SetText(s) self.text = s end
    function t:GetText() return self.text or "" end
    function t:GetChecked() return true end
    return t
end
CreateFrame = function(kind) return Stub(kind) end

local DA = {}
for _, file in ipairs({ "Vocabulary.lua", "Core.lua", "Options.lua", "DwarvenAccent.lua" }) do
    assert(loadfile(file))("DwarvenAccent", DA)
end
local handler = events.ADDON_LOADED.scripts.OnEvent
handler(events.ADDON_LOADED, "ADDON_LOADED", "DwarvenAccent")
assert(DA.DB and DA.DB.preset == "Balanced")
assert(logs[#logs]:find("unavailable", 1, true), "missing hook reported gracefully")
SlashCmdList.DWARVENACCENT("test I don't know")
assert(logs[#logs]:find("Ah dinnae ken", 1, true), "manual transform works even without event")
SlashCmdList.DWARVENACCENT("config")
assert(#UISpecialFrames == 1, "standalone settings work when Settings API absent")
print("PASS: no-EventRegistry/no-Settings graceful compatibility fallback")
