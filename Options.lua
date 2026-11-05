-- Dwarven Accent Advanced 1.3: compact in-game settings; no UI libraries.
-- Only 11 vocabulary controls are constructed, however large the dictionary grows.
local _, DA = ...
local window, filterBox, previewBox, previewOutput, countLabel, pageLabel, matchLabel
local categoryControls, ruleRows, presetButtons = {}, {}, {}
local enabledCheck, previousButton, nextButton, minimapButton
local page = 1
local PAGE_SIZE = 11
local Refresh

local function Label(parent, text, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
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
    check:SetScript("OnClick", function(self)
        click(self:GetChecked() and true or false)
    end)
    return check
end

local function AddSettingsShortcut()
    if not (Settings and Settings.RegisterCanvasLayoutCategory
        and Settings.RegisterAddOnCategory) then return end
    local panel = CreateFrame("Frame")
    panel:SetSize(600, 170)
    Label(panel, "Dwarven Accent - Advanced", 16, -20, "GameFontNormalLarge")
    Label(panel, "Customize accent intensity, vocabulary, and RP protections.", 16, -54,
        "GameFontHighlight")
    Button(panel, "Open Dwarven Accent Settings", 240, 16, -87, function()
        DA.ShowConfig()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Dwarven Accent")
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
    if window.TitleText then window.TitleText:SetText("Dwarven Accent - Advanced 1.4") end
    -- Some Forever builds draw the inherited X but do not attach a working
    -- close handler. Bind the actual template button explicitly; otherwise
    -- construct one. Raise it above the draggable config window.
    local close = window.CloseButton
        or (_G and _G["DwarvenAccentConfigFrameCloseButton"])
    if not close then
        close = CreateFrame("Button", "DwarvenAccentCloseButton", window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -3, -3)
    end
    close:SetScript("OnClick", function() window:Hide() end)
    close:EnableMouse(true)
    if close.SetFrameLevel and window.GetFrameLevel then
        close:SetFrameLevel(window:GetFrameLevel() + 8)
    end
    if UISpecialFrames then table.insert(UISpecialFrames, "DwarvenAccentConfigFrame") end

    enabledCheck = Check(window, 19, -40, "Enable outgoing accent", function(value)
        DA.DB.enabled = value
        Refresh()
    end)
    Label(window, "Accent strength", 24, -79)
    for i, preset in ipairs({ "Subtle", "Balanced", "Heavy" }) do
        presetButtons[preset] = Button(window, preset, 74, 24 + (i - 1) * 81, -100, function()
            DA.DB.preset = preset
            Refresh()
        end)
    end
    Label(window, "Optional substitution limit", 24, -143)
    Button(window, "-", 25, 24, -164, function()
        DA.DB.maxChanges = math.max(0, DA.DB.maxChanges - 1)
        Refresh()
    end)
    countLabel = Label(window, "Unlimited", 59, -170, "GameFontHighlight")
    Button(window, "+", 25, 150, -164, function()
        local value = DA.DB.maxChanges
        -- Start at a useful optional cap, rather than forcing twenty clicks.
        DA.DB.maxChanges = math.min(20, value == 0 and 10 or value + 1)
        Refresh()
    end)
    Button(window, "No limit", 74, 184, -164, function()
        DA.DB.maxChanges = 0
        Refresh()
    end)

    Label(window, "Vocabulary categories", 24, -207)
    for i, category in ipairs(DA.Categories) do
        categoryControls[category.id] = Check(window, 19, -224 - (i - 1) * 28,
            category.label, function(value)
                DA.DB.categories[category.id] = value
                Refresh()
            end)
    end
    Label(window, "Individual vocabulary", 288, -43, "GameFontNormalLarge")
    Label(window, "Search vocabulary; * marks context-sensitive rules.", 290, -69,
        "GameFontHighlightSmall")
    filterBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    filterBox:SetSize(432, 24)
    filterBox:SetPoint("TOPLEFT", window, "TOPLEFT", 295, -94)
    filterBox:SetAutoFocus(false)
    filterBox:SetMaxLetters(60)
    filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    filterBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    matchLabel = Label(window, "", 295, -128, "GameFontHighlightSmall")

    for i = 1, PAGE_SIZE do
        local row = {}
        row.check = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
        row.check:SetSize(24, 24)
        row.check:SetPoint("TOPLEFT", window, "TOPLEFT", 290, -151 - (i - 1) * 24)
        row.text = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
        row.text:SetWidth(402)
        row.text:SetJustifyH("LEFT")
        row.check:SetScript("OnClick", function(self)
            if row.rule then
                DA.DB.disabledRules[row.rule.source] = not self:GetChecked()
                Refresh()
            end
        end)
        ruleRows[i] = row
    end
    previousButton = Button(window, "Previous", 85, 290, -424, function()
        page = math.max(1, page - 1)
        Refresh()
    end)
    pageLabel = Label(window, "", 394, -429, "GameFontHighlightSmall")
    nextButton = Button(window, "Next", 75, 638, -424, function()
        page = page + 1
        Refresh()
    end)

    Label(window, "Translation preview", 24, -459, "GameFontNormalLarge")
    Label(window, "Preview text (not sent to chat):", 24, -480, "GameFontHighlightSmall")
    previewBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    previewBox:SetSize(690, 24)
    previewBox:SetPoint("TOPLEFT", window, "TOPLEFT", 30, -501)
    previewBox:SetAutoFocus(false)
    previewBox:SetMaxLetters(250)
    previewBox:SetText("I don't know where you're going, my friend.")
    previewBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    previewBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    previewOutput = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    previewOutput:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -535)
    previewOutput:SetWidth(705)
    previewOutput:SetJustifyH("LEFT")
    previewOutput:SetWordWrap(true)

    Button(window, "Reset all settings", 147, 24, -576, function()
        DwarvenAccentDB = DA.NewSettings()
        DA.DB = DwarvenAccentDB
        page = 1
        Refresh()
    end)
    Button(window, "Close", 80, 650, -576, function() window:Hide() end)
    filterBox:SetScript("OnTextChanged", function()
        page = 1
        if Refresh then Refresh() end
    end)
    previewBox:SetScript("OnTextChanged", function()
        if Refresh then Refresh(true) end
    end)
end

-- 'previewOnly' deliberately skips filtering, paging and row updates while typing.
Refresh = function(previewOnly)
    if not window or not DA.DB then return end
    local db = DA.DB
    local after, changes = DA.Transform(previewBox:GetText() or "", db)
    previewOutput:SetText("After (" .. changes .. " changes): " .. after)
    if previewOnly then return end
    enabledCheck:SetChecked(db.enabled)
    for preset, button in pairs(presetButtons) do
        button:SetEnabled(db.preset ~= preset)
    end
    countLabel:SetText(db.maxChanges == 0 and "Unlimited" or tostring(db.maxChanges))
    for _, category in ipairs(DA.Categories) do
        categoryControls[category.id]:SetChecked(db.categories[category.id] ~= false)
    end

    local query = (filterBox:GetText() or ""):lower()
    local visible = {}
    for _, rule in ipairs(DA.Rules) do
        if query == "" or rule.source:find(query, 1, true)
            or rule.replacement:lower():find(query, 1, true)
            or rule.category:find(query, 1, true) then
            visible[#visible + 1] = rule
        end
    end
    local pages = math.max(1, math.ceil(#visible / PAGE_SIZE))
    page = math.min(page, pages)
    pageLabel:SetText("Page " .. page .. " / " .. pages)
    matchLabel:SetText(#visible .. " matching rules; faded rules are inactive for this preset/category")
    previousButton:SetEnabled(page > 1)
    nextButton:SetEnabled(page < pages)
    for i, row in ipairs(ruleRows) do
        local rule = visible[(page - 1) * PAGE_SIZE + i]
        row.rule = rule
        if rule then
            row.check:Show()
            row.text:Show()
            row.check:SetChecked(db.disabledRules[rule.source] ~= true)
            row.text:SetText(rule.source .. "  ->  " .. rule.replacement .. "  [" .. rule.tier .. "]"
                .. (rule.context and " *" or ""))
            local active = rule.tier <= DA.Presets[db.preset].tier
                and db.categories[rule.category] ~= false
            row.text:SetAlpha(active and 1 or 0.45)
        else
            row.check:Hide()
            row.text:Hide()
        end
    end
end

function DA.ShowConfig()
    if not window then MakeWindow() end
    if not DA.DB then DA.LoadSettings() end
    Refresh()
    window:Show()
    window:Raise()
end

-- Compact, dependency-free minimap shortcut. Left-click toggles settings;
-- left-drag moves the icon around the minimap and saves its position.
local function PlaceMinimapButton(angle)
    if not minimapButton or not Minimap then return end
    -- Use the same positioning (including custom radius/map shape) as other
    -- LibDBIcon buttons when that optional library is already loaded.
    local dbIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if dbIcon and dbIcon.SetButtonToPosition then
        dbIcon:SetButtonToPosition(minimapButton, angle)
        return
    end
    local radians = math.rad(angle)
    -- Match LibDBIcon's default orbit: button centers sit on the outer rim.
    local width = Minimap.GetWidth and Minimap:GetWidth() or 140
    local height = Minimap.GetHeight and Minimap:GetHeight() or 140
    local radiusX = math.max(0, width) / 2 + 5
    local radiusY = math.max(0, height) / 2 + 5
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(radians) * radiusX, math.sin(radians) * radiusY)
end

function DA.ToggleConfig()
    if window and window.IsShown and window:IsShown() then
        window:Hide()
    else
        DA.ShowConfig()
    end
end

local function MakeMinimapButton()
    if minimapButton or not Minimap then return end
    minimapButton = CreateFrame("Button", "DwarvenAccentMinimapButton", Minimap)
    minimapButton:SetSize(31, 31)
    minimapButton:SetFrameStrata("MEDIUM")
    if Minimap.GetFrameLevel and minimapButton.SetFrameLevel then
        minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    end
    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Trade_Mining")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    if AddonCompartmentFrame then
        icon:SetSize(18, 18)
        icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
    else
        icon:SetSize(17, 17)
        icon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -6)
    end
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local borderSize = AddonCompartmentFrame and 50 or 53
    border:SetSize(borderSize, borderSize)
    border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
    local background = minimapButton:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    if AddonCompartmentFrame then
        background:SetSize(24, 24)
        background:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
    else
        background:SetSize(20, 20)
        background:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
    end

    minimapButton:RegisterForClicks("LeftButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnClick", function() DA.ToggleConfig() end)
    minimapButton:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Dwarven Accent")
            GameTooltip:AddLine("Click: settings  |  Drag: move", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    minimapButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    minimapButton:SetScript("OnDragStart", function(self)
        if not GetCursorPosition or not Minimap.GetCenter then return end
        self:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not scale or scale == 0 then return end
            local cx, cy = Minimap:GetCenter()
            if not cx or not cy then return end
            local dx, dy = mx / scale - cx, my / scale - cy
            local angle
            if dx == 0 then
                angle = dy >= 0 and 90 or 270
            else
                angle = math.deg(math.atan(dy / dx))
                if dx < 0 then angle = angle + 180
                elseif dy < 0 then angle = angle + 360 end
            end
            DA.DB.minimapAngle = angle % 360
            PlaceMinimapButton(DA.DB.minimapAngle)
        end)
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    local angle = DA.DB and DA.DB.minimapAngle
    if type(angle) ~= "number" or angle ~= angle
        or angle < 0 or angle >= 360 then angle = 225 end
    if DA.DB then DA.DB.minimapAngle = angle end
    PlaceMinimapButton(angle)
    -- Other addons may finish configuring the minimap after ADDON_LOADED.
    minimapButton:RegisterEvent("PLAYER_LOGIN")
    minimapButton:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            PlaceMinimapButton(DA.DB and DA.DB.minimapAngle or 225)
        end
    end)
    if Minimap.HookScript then
        Minimap:HookScript("OnSizeChanged", function()
            PlaceMinimapButton(DA.DB and DA.DB.minimapAngle or 225)
        end)
    end
end

function DA.InitOptions()
    MakeMinimapButton()
    -- The standalone /da config window works even on clients without Settings.
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local ok = pcall(AddSettingsShortcut)
        DA.OptionsShortcutRegistered = ok
    end
end
