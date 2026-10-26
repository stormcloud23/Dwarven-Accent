-- Dwarven Accent Advanced 1.1: outgoing-chat hook and slash commands.
local ADDON_NAME, DA = ...

local function Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffc69b6dDwarven Accent:|r " .. message)
    end
end

local function FindEditBox(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value and type(value) == "table"
            and type(value.GetText) == "function"
            and type(value.SetText) == "function" then
            return value
        end
    end
end

local function OnPreSendText(...)
    if not DA.DB or not DA.DB.enabled then return end
    local editBox = FindEditBox(...)
    if not editBox then return end
    local ok, original = pcall(editBox.GetText, editBox)
    if not ok or type(original) ~= "string" or original == "" then return end
    local success, transformed = pcall(DA.Transform, original, DA.DB)
    if success and transformed ~= original then
        pcall(editBox.SetText, editBox, transformed)
    end
end

local function HandleSlashCommand(message)
    local command, rest = (message or ""):match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()
    local db = DA.DB or DA.LoadSettings()
    if command == "on" or command == "off" then
        db.enabled = command == "on"
        Print("accent rewriting " .. (db.enabled and "enabled." or "disabled."))
    elseif command == "config" or command == "settings" then
        DA.ShowConfig()
    elseif command == "subtle" or command == "balanced" or command == "heavy" then
        db.preset = command:sub(1, 1):upper() .. command:sub(2)
        Print("accent set to " .. db.preset .. ".")
    elseif command == "test" then
        if rest == "" then
            Print("Usage: /da test I'll help you, my friend")
        else
            Print(DA.Transform(rest, db))
        end
    else
        Print("Status: " .. (db.enabled and "|cff00ff00ON|r" or "|cffff4444OFF|r")
            .. " / " .. db.preset)
        Print("Commands: /da on, off, config, subtle, balanced, heavy, test <text>")
    end
end

SLASH_DWARVENACCENT1 = "/da"
SlashCmdList["DWARVENACCENT"] = HandleSlashCommand

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= ADDON_NAME then return end
    DA.LoadSettings()
    DA.InitOptions()
    if EventRegistry and EventRegistry.RegisterCallback then
        local ok = pcall(function()
            EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", OnPreSendText)
        end)
        if ok then
            Print("Advanced 1.1 loaded. Type /da config for settings.")
        else
            Print("loaded, but couldn't register the chat pre-send hook on this build.")
        end
    else
        Print("loaded, but the chat pre-send callback is unavailable on this client.")
    end
end)
