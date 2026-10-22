-- Dwarven Accent 1.0
-- A small, editable chat-rewriting addon for WoW: Forever.
--
-- Commands:
--   /da          Show status and help
--   /da on       Enable rewriting
--   /da off      Disable rewriting
--   /da test ... Preview a transformation without sending it
--
-- Add or edit entries in REPLACEMENTS below. Longer phrases are applied first.
-- This addon uses the modern pre-send callback used by WoW's 12.x UI.
-- Because Forever is evolving, verify the callback in your current client.

local ADDON_NAME = ...
local enabled = true

-- Edit this list to customize your dwarf's voice.
-- Use lowercase source phrases. Matching is case-insensitive and whole-word.
local REPLACEMENTS = {
    -- Longer phrases first is handled automatically below.
    { "i don't know", "ah dinnae ken" },
    { "i dont know", "ah dinnae ken" },
    { "i do not know", "ah dinnae ken" },
    { "don't worry", "dinnae fash" },
    { "dont worry", "dinnae fash" },
    { "do not worry", "dinnae fash" },
    { "how are you", "how are ye" },
    { "what are you", "whit are ye" },
    { "come here", "come o'er here" },
    { "this sucks", "tha's a fine mess" },
    { "thank you", "thank ye" },
    { "thanks", "cheers" },
    { "my friend", "ma freend" },
    { "yourself", "yersel" },
    { "you're", "ye're" },
    { "youre", "ye're" },
    { "you've", "ye've" },
    { "youve", "ye've" },
    { "you'll", "ye'll" },
    { "youll", "ye'll" },
    { "little", "wee" },
    { "do you", "d'ye" },
    { "you", "ye" },
    { "your", "yer" },
    { "them", "thae" },
    { "that", "tha'" },
    { "with", "wi'" },
    { "stupid", "daft" },
    { "nothing", "naething" },
    { "dumb", "daft" },
    { "silly", "daft" },
    { "idiot", "numpty" },
    { "moron", "numpty" },
    { "shit", "shite" },
    { "ass", "arse" },
    { "before", "afore" },
    { "don't", "dinnae" },
    { "doesn't", "disnae" },
    { "didn't", "didnae" },
    { "didnt", "didnae" },
    { "did not", "didnae" },
    { "isn't", "isnae" },
    { "can't", "cannae" },
    { "cant", "cannae" },
    { "won't", "winnae" },
    { "wont", "winnae" },
    { "haven't", "haenae" },
    { "havent", "haenae" },
    { "have not", "haenae" },
    { "hasn't", "hasnae" },
    { "hasnt", "hasnae" },
    { "has not", "hasnae" },
    { "hadn't", "hadnae" },
    { "hadnt", "hadnae" },
    { "had not", "hadnae" },
    { "wasn't", "wisnae" },
    { "wasnt", "wisnae" },
    { "aren't", "arenae" },
    { "arent", "arenae" },
    { "isnt", "isnae" },
    { "are not", "arenae" },
    { "was not", "wisnae" },
    { "weren't", "werenae" },
    { "werent", "werenae" },
    { "were not", "werenae" },
    { "wouldn't", "wouldnae" },
    { "wouldnt", "wouldnae" },
    { "would not", "wouldnae" },
    { "couldn't", "couldnae" },
    { "couldnt", "couldnae" },
    { "could not", "couldnae" },
    { "shouldn't", "shouldnae" },
    { "shouldnt", "shouldnae" },
    { "should not", "shouldnae" },
    { "will not", "winnae" },
    { "cannot", "cannae" },
    { "can not", "cannae" },
    { "gonna", "gonnae" },
    { "crazy", "barmy" },
    { "tired", "knackered" },
    { "very", "bloody" },
    { "gotta", "hae tae" },
    { "wanna", "fancy tae" },
    { "kinda", "sortae" },
    { "out of", "oot o'" },
    { "about", "aboot" },
    { "without", "wi'oot" },
    { "because", "cause" },
    { "though", "tho" },
    { "worry", "fash" },
    { "trouble", "fash" },
    { "bother", "fash" },
    { "know", "ken" },
    { "yes", "aye" },
    { "yeah", "aye" },
    { "over", "ower" },
    { "pretty", "bonnie" },
    { "beautiful", "bonnie" },
    { "no", "naw" },
    { "that", "tha'" },
    { "man", "lad" },
    { "boy", "laddy" },
    { "woman", "lass" },
    { "girl", "lassy" },
    { "friend", "freend" },
    { "of", "o'" },
    { "oh", "ah" },
}

-- Sort longest source phrase first so "I don't know" wins over "know".
table.sort(REPLACEMENTS, function(a, b)
    return #a[1] > #b[1]
end)

local function IsWordChar(char)
    return char ~= "" and char:match("[%w_]") ~= nil
end

local function MatchCase(original, replacement)
    -- Preserve all-caps and initial-capital style; otherwise use replacement as written.
    if original == original:upper() and original:match("%a") then
        return replacement:upper()
    end
    if original:sub(1, 1) == original:sub(1, 1):upper()
       and original:sub(1, 1):match("%a") then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

local function ReplacePhrase(text, source, replacement)
    local lowerText = text:lower()
    local lowerSource = source:lower()
    local result = {}
    local cursor = 1

    while cursor <= #text do
        local startPos, endPos = lowerText:find(lowerSource, cursor, true)
        if not startPos then
            result[#result + 1] = text:sub(cursor)
            break
        end

        local before = startPos > 1 and text:sub(startPos - 1, startPos - 1) or ""
        local after = endPos < #text and text:sub(endPos + 1, endPos + 1) or ""

        -- Don't replace a word inside a larger word (e.g. "no" in "nobody").
        local leftOK = not IsWordChar(before) or not IsWordChar(text:sub(startPos, startPos))
        local lastChar = text:sub(endPos, endPos)
        local rightOK = not IsWordChar(after) or not IsWordChar(lastChar)

        if leftOK and rightOK then
            result[#result + 1] = text:sub(cursor, startPos - 1)
            local original = text:sub(startPos, endPos)
            result[#result + 1] = MatchCase(original, replacement)
            cursor = endPos + 1
        else
            result[#result + 1] = text:sub(cursor, startPos)
            cursor = startPos + 1
        end
    end

    return table.concat(result)
end

local function Transform(text)
    if not text or text == "" then
        return text
    end

    -- Avoid rewriting slash commands. This also keeps addon commands intact.
    if text:sub(1, 1) == "/" then
        return text
    end

    for _, entry in ipairs(REPLACEMENTS) do
        text = ReplacePhrase(text, entry[1], entry[2])
    end
    return text
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc69b6dDwarven Accent:|r " .. message)
end

local function FindEditBox(...)
    -- Be tolerant of small callback signature differences between client builds.
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
    if not enabled then
        return
    end

    local editBox = FindEditBox(...)
    if not editBox then
        return
    end

    local ok, original = pcall(editBox.GetText, editBox)
    if not ok or type(original) ~= "string" or original == "" then
        return
    end

    local transformed = Transform(original)
    if transformed ~= original then
        pcall(editBox.SetText, editBox, transformed)
    end
end

local function HandleSlashCommand(message)
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()

    if command == "on" then
        enabled = true
        Print("accent rewriting enabled.")
    elseif command == "off" then
        enabled = false
        Print("accent rewriting disabled.")
    elseif command == "test" then
        if rest == "" then
            Print("Usage: /da test I'll help you man")
        else
            Print(Transform(rest))
        end
    else
        Print("Status: " .. (enabled and "|cff00ff00ON|r" or "|cffff4444OFF|r"))
        Print("Commands: /da on, /da off, /da test <text>")
        Print("Edit DwarvenAccent.lua to add or change vocabulary.")
    end
end

SLASH_DWARVENACCENT1 = "/da"
SlashCmdList["DWARVENACCENT"] = HandleSlashCommand

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= ADDON_NAME then
        return
    end

    if EventRegistry and EventRegistry.RegisterCallback then
        local ok = pcall(function()
            EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", OnPreSendText)
        end)
        if ok then
            Print("loaded. Try /da test I'll help you man")
        else
            Print("loaded, but couldn't register the pre-send hook on this build.")
        end
    else
        Print("loaded, but this client has no EventRegistry pre-send hook.")
        Print("Check for a newer version or ask me to adapt it to your build.")
    end
end)
