-- Dwarven Accent Advanced 1.1: optional in-game editor. No external UI libraries.
local _, DA = ...
local window, filterBox, previewBox, previewOutput, countLabel
local categoryControls, ruleRows, presetButtons = {}, {}, {}
local scroll, scrollChild, enabledCheck
local Refresh

local function Label(parent, text, anchor, relativeTo, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetPoint(anchor, relativeTo or parent, anchor, x or 0, y or 0)
    label:SetText(text)
    return label
end

local function Button(parent, text, width, x, y, click)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", click)
    return b
end

local function Check(parent, x, y, text, click)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetSize(24, 24)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetText(text)
    check:SetScript("OnClick", function(self) click(self:GetChecked() and true or false) end)
    return check
end

local function AddSettingsShortcut()
    if not (Settings and Settings.RegisterCanvasLayoutCategory
        and Settings.RegisterAddOnCategory) then return end
    local page = CreateFrame("Frame")
    page:SetSize(600, 170)
    Label(page, "Dwarven Accent - Advanced", "TOPLEFT", page, 16, -20, "GameFontNormalLarge")
    Label(page, "Configure the accent preset, vocabulary categories, and individual words.",
        "TOPLEFT", page, 16, -54, "GameFontHighlight")
    Button(page, "Open Dwarven Accent Settings", 238, 16, -87, function()
        DA.ShowConfig()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(page, "Dwarven Accent")
    Settings.RegisterAddOnCategory(category)
end

local function MakeWindow()
    window = CreateFrame("Frame", "DwarvenAccentConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(760, 615)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:Hide()
    if window.TitleText then window.TitleText:SetText("Dwarven Accent - Advanced 1.1") end
    if UISpecialFrames then table.insert(UISpecialFrames, "DwarvenAccentConfigFrame") end

    enabledCheck = Check(window, 19, -40, "Enable accent in outgoing chat", function(value)
        DA.DB.enabled = value
        Refresh()
    end)
    Label(window, "Accent strength", "TOPLEFT", window, 24, -79)
    for i, preset in ipairs({ "Subtle", "Balanced", "Heavy" }) do
        presetButtons[preset] = Button(window, preset, 74, 24 + (i - 1) * 81, -100, function()
            DA.DB.preset = preset
            Refresh()
        end)
    end
    Label(window, "Maximum substitutions per message", "TOPLEFT", window, 24, -143)
    Button(window, "-", 25, 24, -164, function()
        local value = DA.DB.maxChanges
        DA.DB.maxChanges = value == 0 and 0 or math.max(0, value - 1)
        Refresh()
    end)
    countLabel = Label(window, "Auto", "TOPLEFT", window, 59, -170, "GameFontHighlight")
    Button(window, "+", 25, 150, -164, function()
        local value = DA.DB.maxChanges
        DA.DB.maxChanges = math.min(20, value == 0 and DA.Presets[DA.DB.preset].limit + 1 or value + 1)
        Refresh()
    end)
    Button(window, "Auto", 49, 184, -164, function()
        DA.DB.maxChanges = 0
        Refresh()
    end)

    Label(window, "Vocabulary categories", "TOPLEFT", window, 24, -207)
    for i, category in ipairs(DA.Categories) do
        categoryControls[category.id] = Check(window, 19, -224 - (i - 1) * 28,
            category.label, function(value)
                DA.DB.categories[category.id] = value
                Refresh()
            end)
    end

    Label(window, "Individual vocabulary", "TOPLEFT", window, 288, -43, "GameFontNormalLarge")
    Label(window, "Search to toggle specific substitutions.", "TOPLEFT", window, 290, -69, "GameFontHighlightSmall")
    filterBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    filterBox:SetSize(432, 24)
    filterBox:SetPoint("TOPLEFT", window, "TOPLEFT", 295, -94)
    filterBox:SetAutoFocus(false)
    filterBox:SetMaxLetters(60)
    filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    filterBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 290, -130)
    scroll:SetSize(415, 301)
    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(408, 301)
    scroll:SetScrollChild(scrollChild)

    Label(window, "Translation preview", "TOPLEFT", window, 24, -443, "GameFontNormalLarge")
    Label(window, "Preview text (not sent to chat):", "TOPLEFT", window, 24, -467, "GameFontHighlightSmall")
    previewBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    previewBox:SetSize(690, 24)
    previewBox:SetPoint("TOPLEFT", window, "TOPLEFT", 30, -489)
    previewBox:SetMaxLetters(250)
    previewBox:SetAutoFocus(false)
    previewBox:SetText("I don't know where you're going, my friend.")
    previewBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    previewBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    previewOutput = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    previewOutput:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -530)
    previewOutput:SetWidth(700)
    previewOutput:SetJustifyH("LEFT")
    previewOutput:SetWordWrap(true)

    Button(window, "Reset all settings", 147, 24, -573, function()
        DwarvenAccentDB = DA.NewSettings()
        DA.DB = DwarvenAccentDB
        Refresh()
    end)
    Button(window, "Close", 80, 650, -573, function() window:Hide() end)
    filterBox:SetScript("OnTextChanged", function() if Refresh then Refresh(true) end end)
    previewBox:SetScript("OnTextChanged", function() if Refresh then Refresh(false) end end)
end

Refresh = function(rebuildRules)
    if not window then return end
    local db = DA.DB
    enabledCheck:SetChecked(db.enabled)
    for preset, button in pairs(presetButtons) do
        button:SetEnabled(db.preset ~= preset)
    end
    local limit = DA.Presets[db.preset].limit
    countLabel:SetText(db.maxChanges == 0 and ("Auto (" .. limit .. ")") or tostring(db.maxChanges))
    for _, category in ipairs(DA.Categories) do
        categoryControls[category.id]:SetChecked(db.categories[category.id] ~= false)
    end
    previewOutput:SetText("After:  " .. DA.Transform(previewBox:GetText() or "", db))
    -- Preview changes don't need to recreate the vocabulary list.
    if rebuildRules == false then return end

    local query = (filterBox:GetText() or ""):lower()
    local visible = {}
    for _, rule in ipairs(DA.Rules) do
        if query == "" or rule.source:find(query, 1, true)
            or rule.replacement:lower():find(query, 1, true) then
            visible[#visible + 1] = rule
        end
    end
    for i, rule in ipairs(visible) do
        local row = ruleRows[i]
        if not row then
            row = {}
            row.check = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
            row.check:SetSize(24, 24)
            row.check:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * 25)
            row.text = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
            row.text:SetWidth(378)
            row.text:SetJustifyH("LEFT")
            ruleRows[i] = row
        end
        row.check:Show()
        row.text:Show()
        row.text:SetText(rule.source .. "  ->  " .. rule.replacement)
        row.check:SetChecked(db.disabledRules[rule.source] ~= true)
        row.check:SetScript("OnClick", function(self)
            db.disabledRules[rule.source] = not self:GetChecked()
            Refresh(false)
        end)
    end
    for i = #visible + 1, #ruleRows do
        ruleRows[i].check:Hide()
        ruleRows[i].text:Hide()
    end
    scrollChild:SetHeight(math.max(301, #visible * 25))
    if rebuildRules == true then scroll:SetVerticalScroll(0) end
end

function DA.ShowConfig()
    if not window then MakeWindow() end
    Refresh()
    window:Show()
    window:Raise()
end

function DA.InitOptions()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local ok = pcall(AddSettingsShortcut)
        if not ok then
            -- /da config remains available if the client API differs.
        end
    end
end
