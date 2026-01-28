--[[
    ============================================================================
    FPS & MS Monitor
    Copyright (c) 2021-2026 Pytilix
    All rights reserved.

    This Add-on and its source code are proprietary. 
    Unauthorized copying, modification, or distribution of this file, 
    via any medium, is strictly prohibited.
    
    The source code is provided for personal use and educational purposes 
    only, as per Blizzard's UI Add-On Development Policy.
    ============================================================================
--]]

local AddonName = "Stat_Info_Bar"
local f = CreateFrame("Frame", "FPSMSTrackerFrame", UIParent)
local categoryID

-- 1. FONT SAMMLUNG
local addonPath = "Interface\\AddOns\\" .. AddonName .. "\\"
local fontPathPrefix = addonPath .. "fonts\\"
local mediaPath = addonPath .. "media\\"

local fonts = {
    {name = "Adventure", path = fontPathPrefix .. "Adventure.ttf"},
    {name = "Bazooka", path = fontPathPrefix .. "Bazooka.ttf"},
    {name = "BlackChancery", path = fontPathPrefix .. "BlackChancery.ttf"},
    {name = "Celestia", path = fontPathPrefix .. "CelestiaMediumRedux1.55.ttf"},
    {name = "DejaVu Sans", path = fontPathPrefix .. "DejaVuLGCSans.ttf"},
    {name = "DejaVu Serif", path = fontPathPrefix .. "DejaVuLGCSerif.ttf"},
    {name = "DorisPP", path = fontPathPrefix .. "DorisPP.ttf"},
    {name = "EnigmaU", path = fontPathPrefix .. "EnigmaU_2.ttf"},
    {name = "Fitzgerald", path = fontPathPrefix .. "Fitzgerald.ttf"},
    {name = "GentiumPlus", path = fontPathPrefix .. "GentiumPlus-Regular.ttf"},
    {name = "Hack", path = fontPathPrefix .. "Hack-Regular.ttf"},
    {name = "HookedUp", path = fontPathPrefix .. "HookedUp.ttf"},
    {name = "SFAtarian", path = fontPathPrefix .. "SFAtarianSystem.ttf"},
    {name = "SFCovington", path = fontPathPrefix .. "SFCovington.ttf"},
    {name = "SFMoviePoster", path = fontPathPrefix .. "SFMoviePoster-Bold.ttf"},
    {name = "SFWonderComic", path = fontPathPrefix .. "SFWonderComic.ttf"},
    {name = "SWF!T", path = fontPathPrefix .. "SWF!T___.ttf"},
    {name = "texgyre Bold", path = fontPathPrefix .. "texgyreadventor-bold.ttf"},
    {name = "texgyre Regular", path = fontPathPrefix .. "texgyreadventor-regular.ttf"},
    {name = "wqy-zenhei", path = fontPathPrefix .. "wqy-zenhei.ttf"},
    {name = "Yellow", path = fontPathPrefix .. "yellow.ttf"},
    {name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF"},
}

local defaults = {
    point = "TOPLEFT", xOfs = 20, yOfs = -20,
    fontSize = 14, fontIndex = 1,
    fontOutline = "OUTLINE",
    showBackground = true, bgAlpha = 0.5,
    colorBG = {r = 0, g = 0, b = 0},
    lockFrame = false, hideInCombat = false,
    showMemory = true, showFPS = true, showMS = true, showCPU = false, showRAM = false, showTime = false,
    showDurability = false, showSpec = false, showLootSpec = false,
    showCoords = false, showBags = false, showFriends = false, showGuild = false, 
    -- Mythic+ Defaults
    showMPlus = false, showSAL = false, showKeyShare = false,
    useMouseover = false, mouseoverAlpha = 0,
    colorFPS = {r = 0, g = 1, b = 0},
    colorMS = {r = 1, g = 0.8, b = 0},
    colorCPU = {r = 0.4, g = 0.7, b = 1},
    colorRAM = {r = 1, g = 0.4, b = 1},
    colorTime = {r = 1, g = 1, b = 1},
    colorDur = {r = 1, g = 0.5, b = 0},
    colorSpec = {r = 0.6, g = 0.4, b = 1},
    colorLoot = {r = 1, g = 0.8, b = 0},
    colorCoords = {r = 1, g = 1, b = 0.5},
    colorBags = {r = 0.5, g = 1, b = 0.5},
    colorFriends = {r = 0.3, g = 0.7, b = 1},
    colorGuild = {r = 0.2, g = 1, b = 0.2},
    colorMPlus = {r = 0.9, g = 0.8, b = 0.5}
}

-- 2. HELPERS
local function GetHex(r, g, b) return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255) end

local function GetCurrentProfile()
    if not StatsFrameDB then return defaults, "Default" end
    local charKey = UnitName("player") .. "-" .. GetRealmName()
    local profileName = StatsFrameDB.charToProfile[charKey] or "Default"
    if not StatsFrameDB.profiles[profileName] then profileName = "Default" end
    local db = StatsFrameDB.profiles[profileName]
    for k, v in pairs(defaults) do if db[k] == nil then db[k] = v end end
    return db, profileName
end

local function GetOnlineFriends()
    local onlineFriends = C_FriendList.GetNumOnlineFriends() or 0
    local bnetTotal = BNGetNumFriends() or 0
    local onlineBnetWow = 0
    for i = 1, bnetTotal do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline and accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
            onlineBnetWow = onlineBnetWow + 1
        end
    end
    return onlineFriends + onlineBnetWow
end

local function GetOnlineGuild()
    if not IsInGuild() then return 0 end
    local _, _, numOnline = GetNumGuildMembers()
    return numOnline or 0
end

local function GetMPlusScore()
    local score = C_ChallengeMode.GetOverallDungeonScore()
    return score or 0
end

local function ApplySettings()
    local db = GetCurrentProfile()
    local fInfo = fonts[db.fontIndex] or fonts[1]
    f:ClearAllPoints()
    f:SetPoint(db.point, UIParent, db.point, db.xOfs, db.yOfs)
    local flags = db.fontOutline ~= "NONE" and db.fontOutline or ""
    f.text:SetFont(fInfo.path, db.fontSize, flags)
    if db.showBackground then 
        f.bg:Show() 
        f.bg:SetColorTexture(db.colorBG.r, db.colorBG.g, db.colorBG.b, db.bgAlpha or 0.5)
    else 
        f.bg:Hide() 
    end
    f:SetMovable(not db.lockFrame)
    f:EnableMouse(true)
    if db.hideInCombat and InCombatLockdown() then f:Hide() else f:Show()
        if db.useMouseover then f:SetAlpha(db.mouseoverAlpha or 0) else f:SetAlpha(1) end
    end
end

-- 3. SETTINGS UI
local function CreateSettingsUI()
    local opt = CreateFrame("Frame", "FPSMS_OptionsPanel", UIParent)
    opt.name = "Stat & Info Bar"
    
    local logo = opt:CreateTexture(nil, "ARTWORK")
    logo:SetSize(125, 125)
    logo:SetPoint("TOPRIGHT", opt, "TOPRIGHT", -20, -10)
    logo:SetTexture(mediaPath .. "logo.tga")
    
    local title = opt:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Stat & Info Bar |cffffd100Settings|r")

    local scrollContainer = CreateFrame("ScrollFrame", "FPSMS_MainScroll", opt, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", 10, -50)
    scrollContainer:SetPoint("BOTTOMRIGHT", -30, 10)
    local scrollChild = CreateFrame("Frame", "FPSMS_MainScrollChild", scrollContainer)
    scrollChild:SetSize(580, 1400) 
    scrollContainer:SetScrollChild(scrollChild)

    local function CreateLine(relativeTo, yOffset)
        local line = scrollChild:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, yOffset)
        line:SetPoint("RIGHT", opt, "RIGHT", -50, 0)
        line:SetColorTexture(1, 1, 1, 0.1)
        return line
    end

    -- SECTION: PROFILES
    local profHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profHeader:SetPoint("TOPLEFT", 5, -5)
    profHeader:SetText("Profiles")
    local line1 = CreateLine(profHeader, -5)

    local pScroll = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    pScroll:SetSize(230, 100)
    pScroll:SetPoint("TOPLEFT", line1, "BOTTOMLEFT", 0, -10)
    pScroll:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = {2,2,2,2}})
    pScroll:SetBackdropColor(0, 0, 0, 0.4)

    local function RefreshProfiles()
        if pScroll.btns then for _, b in ipairs(pScroll.btns) do b:Hide() if b.del then b.del:Hide() end end end
        pScroll.btns = pScroll.btns or {}
        local names = {}
        for k in pairs(StatsFrameDB.profiles) do table.insert(names, k) end
        table.sort(names)
        for i, name in ipairs(names) do
            local b = pScroll.btns[i] or CreateFrame("Button", nil, pScroll, "UIPanelButtonTemplate")
            b:SetSize(190, 18) b:SetPoint("TOPLEFT", 5, -5 - ((i-1) * 19))
            b:SetText(name)
            b:SetScript("OnClick", function() StatsFrameDB.charToProfile[UnitName("player").."-"..GetRealmName()] = name ApplySettings() end)
            b:Show()
            if not b.del then b.del = CreateFrame("Button", nil, pScroll, "UIPanelButtonTemplate") b.del:SetSize(20, 18) b.del:SetText("|cffff0000X|r") end
            b.del:SetPoint("LEFT", b, "RIGHT", 2, 0)
            b.del:SetScript("OnClick", function()
                if name ~= "Default" then StatsFrameDB.profiles[name] = nil RefreshProfiles() ApplySettings() end
            end)
            if name == "Default" then b.del:Hide() else b.del:Show() end
            pScroll.btns[i] = b
        end
    end
    RefreshProfiles()

    local createHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    createHeader:SetPoint("TOPLEFT", pScroll, "TOPRIGHT", 20, 0)
    createHeader:SetText("Create New Profile:")
    local eb = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    eb:SetSize(140, 20) eb:SetPoint("TOPLEFT", createHeader, "BOTTOMLEFT", 0, -10) eb:SetAutoFocus(false)
    local ebBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    ebBtn:SetSize(60, 22) ebBtn:SetPoint("LEFT", eb, "RIGHT", 10, 0) ebBtn:SetText("New")
    ebBtn:SetScript("OnClick", function()
        local name = eb:GetText()
        if name ~= "" and not StatsFrameDB.profiles[name] then StatsFrameDB.profiles[name] = CopyTable(defaults) eb:SetText("") RefreshProfiles() end
    end)

    -- SECTION: DISPLAY & LAYOUT
    local dispHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dispHeader:SetPoint("TOPLEFT", pScroll, "BOTTOMLEFT", 0, -25)
    dispHeader:SetText("Display & Layout")
    local line2 = CreateLine(dispHeader, -5)

    local function CreateSlider(label, minV, maxV, step, x, y, key)
        local s = CreateFrame("Slider", "FPSMS_Slider_"..key, scrollChild, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", line2, "BOTTOMLEFT", x, y)
        s:SetMinMaxValues(minV, maxV) s:SetValueStep(step) s:SetObeyStepOnDrag(true)
        s:SetSize(160, 17) _G[s:GetName().."Text"]:SetText(label)
        s:SetScript("OnValueChanged", function(self, val) GetCurrentProfile()[key] = val ApplySettings() end)
        s:SetScript("OnShow", function(self) self:SetValue(GetCurrentProfile()[key]) end)
        return s
    end
    CreateSlider("Font Size", 8, 40, 1, 0, -35, "fontSize")
    CreateSlider("BG Alpha", 0, 1, 0.05, 0, -85, "bgAlpha")
    CreateSlider("Mouseover Alpha", 0, 1, 0.05, 0, -135, "mouseoverAlpha")

    local bgColBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    bgColBtn:SetSize(130, 22)
    bgColBtn:SetPoint("TOPLEFT", line2, "BOTTOMLEFT", 0, -170)
    bgColBtn:SetText("BG Color")
    local bgSwatch = bgColBtn:CreateTexture(nil, "OVERLAY")
    bgSwatch:SetSize(18, 18)
    bgSwatch:SetPoint("LEFT", bgColBtn, "RIGHT", 5, 0)
    bgSwatch:SetColorTexture(1, 1, 1, 1)

    local bgCheck = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
    bgCheck:SetPoint("LEFT", bgSwatch, "RIGHT", 10, 0)
    bgCheck.Text:SetText("Enable BG")
    bgCheck:SetScript("OnShow", function(self) self:SetChecked(GetCurrentProfile().showBackground) end)
    bgCheck:SetScript("OnClick", function(self) GetCurrentProfile().showBackground = self:GetChecked() ApplySettings() end)

    bgColBtn:SetScript("OnShow", function() local c = GetCurrentProfile().colorBG bgSwatch:SetColorTexture(c.r, c.g, c.b, 1) end)
    bgColBtn:SetScript("OnClick", function()
        local db = GetCurrentProfile()
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function() 
                local r, g, b = ColorPickerFrame:GetColorRGB()
                db.colorBG = {r=r, g=g, b=b} bgSwatch:SetColorTexture(r, g, b, 1) ApplySettings() 
            end,
            r = db.colorBG.r, g = db.colorBG.g, b = db.colorBG.b
        })
    end)

    local outHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    outHeader:SetPoint("TOPLEFT", bgColBtn, "BOTTOMLEFT", 0, -15)
    outHeader:SetText("Outline Style:")
    local outlines = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"}
    local outLabels = {"None", "Thin", "Thick", "Shadow"}
    for i, mode in ipairs(outlines) do
        local b = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        b:SetSize(50, 18) b:SetPoint("TOPLEFT", outHeader, "BOTTOMLEFT", (i-1)*52, -5) b:SetText(outLabels[i])
        b:SetScript("OnClick", function() GetCurrentProfile().fontOutline = mode ApplySettings() end)
    end

    local fBack = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    fBack:SetSize(220, 220) fBack:SetPoint("TOPRIGHT", line2, "BOTTOMRIGHT", 0, -20)
    fBack:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = {2,2,2,2}})
    fBack:SetBackdropColor(0, 0, 0, 0.4)
    local sf = CreateFrame("ScrollFrame", nil, fBack, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 5, -5) sf:SetPoint("BOTTOMRIGHT", -25, 5)
    local c = CreateFrame("Frame") c:SetSize(180, #fonts * 22) sf:SetScrollChild(c)
    for i, info in ipairs(fonts) do
        local b = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        b:SetSize(175, 20) b:SetPoint("TOPLEFT", 0, -((i-1) * 22)) b:SetText(info.name)
        b:GetFontString():SetFont(info.path, 10, "OUTLINE")
        b:SetScript("OnClick", function() GetCurrentProfile().fontIndex = i ApplySettings() end)
    end

    -- SECTION: MODULES
    local modHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modHeader:SetPoint("TOPLEFT", line2, "BOTTOMLEFT", 0, -280)
    modHeader:SetText("General Modules")
    local line3 = CreateLine(modHeader, -5)
    
    local function CreateCB(label, x, y, key, relativeLine)
        local cb = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", relativeLine or line3, "BOTTOMLEFT", x, y)
        cb.Text:SetText(label)
        cb:SetScript("OnShow", function(self) self:SetChecked(GetCurrentProfile()[key]) end)
        cb:SetScript("OnClick", function(self) GetCurrentProfile()[key] = self:GetChecked() ApplySettings() end)
        return cb
    end

    CreateCB("Show FPS", 0, -10, "showFPS") CreateCB("Show MS", 160, -10, "showMS") CreateCB("Show CPU", 320, -10, "showCPU")
    CreateCB("Show RAM", 0, -35, "showRAM") CreateCB("Show Time", 160, -35, "showTime") CreateCB("Show Durability", 320, -35, "showDurability")
    CreateCB("Show Spec", 0, -60, "showSpec") CreateCB("Show Loot", 160, -60, "showLootSpec") CreateCB("Show Coords", 320, -60, "showCoords")
    CreateCB("Show Bags", 0, -85, "showBags") CreateCB("Show Friends", 160, -85, "showFriends") CreateCB("Show Guild", 320, -85, "showGuild")
    CreateCB("Lock Frame", 0, -110, "lockFrame") CreateCB("Tooltip", 160, -110, "showMemory")
    CreateCB("Mouseover", 0, -135, "useMouseover") CreateCB("Hide In Combat", 160, -135, "hideInCombat")

    -- SECTION: MYTHIC+ (NEW)
    local mplusHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mplusHeader:SetPoint("TOPLEFT", line3, "BOTTOMLEFT", 0, -180)
    mplusHeader:SetText("Mythic+ Modules")
    local lineMPlus = CreateLine(mplusHeader, -5)
    
    CreateCB("Show Score", 0, -10, "showMPlus", lineMPlus)
    CreateCB("Score & Level", 160, -10, "showSAL", lineMPlus)
    CreateCB("Key Share", 320, -10, "showKeyShare", lineMPlus)

    -- SECTION: COLORS
    local colHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colHeader:SetPoint("TOPLEFT", lineMPlus, "BOTTOMLEFT", 0, -60)
    colHeader:SetText("Module Colors")
    local line4 = CreateLine(colHeader, -5)
    
    local function CreateColorBtn(label, x, y, key)
        local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        btn:SetSize(90, 22) btn:SetPoint("TOPLEFT", line4, "BOTTOMLEFT", x, y) btn:SetText(label)
        local swatch = btn:CreateTexture(nil, "OVERLAY")
        swatch:SetSize(16, 16) swatch:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        btn:SetScript("OnShow", function() local c = GetCurrentProfile()[key] swatch:SetColorTexture(c.r, c.g, c.b, 1) end)
        btn:SetScript("OnClick", function()
            local db = GetCurrentProfile()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function() 
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    db[key] = {r=r, g=g, b=b} swatch:SetColorTexture(r, g, b, 1) ApplySettings() 
                end,
                r = db[key].r, g = db[key].g, b = db[key].b
            })
        end)
    end
    CreateColorBtn("FPS", 0, -10, "colorFPS") CreateColorBtn("MS", 115, -10, "colorMS") CreateColorBtn("CPU", 230, -10, "colorCPU")
    CreateColorBtn("RAM", 345, -10, "colorRAM") CreateColorBtn("Time", 460, -10, "colorTime")
    CreateColorBtn("Dur", 0, -40, "colorDur") CreateColorBtn("Spec", 115, -40, "colorSpec") CreateColorBtn("Loot", 230, -40, "colorLoot")
    CreateColorBtn("Coord", 345, -40, "colorCoords") CreateColorBtn("Bag", 460, -40, "colorBags")
    CreateColorBtn("Friends", 0, -70, "colorFriends") CreateColorBtn("Guild", 115, -70, "colorGuild") CreateColorBtn("M+", 230, -70, "colorMPlus")

    local resBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resBtn:SetSize(140, 25) resBtn:SetPoint("TOPLEFT", line4, "BOTTOMLEFT", 0, -120) resBtn:SetText("Reset Position")
    resBtn:SetScript("OnClick", function() local db = GetCurrentProfile() db.point, db.xOfs, db.yOfs = "TOPLEFT", 20, -20 ApplySettings() end)

    local category = Settings.RegisterCanvasLayoutCategory(opt, "Stat & Info Bar")
    categoryID = category:GetID()
    Settings.RegisterAddOnCategory(category)
end

-- 4. INITIALIZE
local function Init()
    f:SetSize(100, 25) f:SetClampedToScreen(true) f:RegisterForDrag("LeftButton") f:SetFrameStrata("HIGH")
    f.bg = f:CreateTexture(nil, "BACKGROUND") f.bg:SetAllPoints()
    f.text = f:CreateFontString(nil, "OVERLAY") f.text:SetPoint("CENTER", f)
    
    f:SetScript("OnEnter", function(self)
        local db = GetCurrentProfile()
        if db.showMemory then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("FPS-MS Tracker", 0, 0.8, 1)
            GameTooltip:AddLine(" ")
            UpdateAddOnMemoryUsage()
            GameTooltip:AddDoubleLine("Addon Memory:", string.format("%.2f KB", GetAddOnMemoryUsage(AddonName)), 1, 1, 1, 1, 1, 1)
            GameTooltip:Show()
        end
        if db.useMouseover then self:SetAlpha(1) end
    end)
    
    f:SetScript("OnLeave", function(self) GameTooltip:Hide() if GetCurrentProfile().useMouseover then self:SetAlpha(GetCurrentProfile().mouseoverAlpha or 0) end end)
    f:SetScript("OnMouseDown", function(self) if not GetCurrentProfile().lockFrame then self:StartMoving() end end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() local db = GetCurrentProfile() local p, _, _, x, y = self:GetPoint() db.point, db.xOfs, db.yOfs = p, x, y end)
    
    local timer = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        timer = timer + elapsed
        if timer > 0.4 then
            local db = GetCurrentProfile()
            local parts = {}
            
            -- FPS / MS
            if db.showFPS then table.insert(parts, string.format("%s%d fps|r", GetHex(db.colorFPS.r, db.colorFPS.g, db.colorFPS.b), floor(GetFramerate()))) end
            if db.showMS then table.insert(parts, string.format("%s%d ms|r", GetHex(db.colorMS.r, db.colorMS.g, db.colorMS.b), select(4, GetNetStats()))) end
            
            -- CPU / RAM
            if db.showCPU then
                UpdateAddOnCPUUsage()
                table.insert(parts, string.format("%sCPU: %.1fms|r", GetHex(db.colorCPU.r, db.colorCPU.g, db.colorCPU.b), GetAddOnCPUUsage(AddonName)))
            end
            if db.showRAM then
                UpdateAddOnMemoryUsage()
                table.insert(parts, string.format("%sRAM: %.1fkb|r", GetHex(db.colorRAM.r, db.colorRAM.g, db.colorRAM.b), GetAddOnMemoryUsage(AddonName)))
            end

            -- SPEC / LOOT
            if db.showSpec then
                local specIndex = GetSpecialization()
                if specIndex then
                    local _, specName = GetSpecializationInfo(specIndex)
                    table.insert(parts, string.format("%s%s|r", GetHex(db.colorSpec.r, db.colorSpec.g, db.colorSpec.b), specName or ""))
                end
            end
            if db.showLootSpec then
                local lootSpec = GetLootSpecialization()
                local _, specName = GetSpecializationInfoByID(lootSpec > 0 and lootSpec or GetSpecializationInfo(GetSpecialization() or 1))
                table.insert(parts, string.format("%sL: %s|r", GetHex(db.colorLoot.r, db.colorLoot.g, db.colorLoot.b), specName or ""))
            end

            -- COORDS / BAGS / DURABILITY
            if db.showCoords then
                local mapID = C_Map.GetBestMapForUnit("player")
                if mapID then
                    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
                    if pos then table.insert(parts, string.format("%s%.1f, %.1f|r", GetHex(db.colorCoords.r, db.colorCoords.g, db.colorCoords.b), pos.x*100, pos.y*100)) end
                end
            end
            if db.showBags then
                local free, total = 0, 0
                for i = 0, 4 do total = total + C_Container.GetContainerNumSlots(i) free = free + C_Container.GetContainerNumFreeSlots(i) end
                table.insert(parts, string.format("%sB:%d/%d|r", GetHex(db.colorBags.r, db.colorBags.g, db.colorBags.b), free, total))
            end
            if db.showDurability then
                local low = 100
                for i = 1, 18 do local cur, max = GetInventoryItemDurability(i) if cur and max then low = math.min(low, (cur/max)*100) end end
                table.insert(parts, string.format("%sD:%d%%|r", GetHex(db.colorDur.r, db.colorDur.g, db.colorDur.b), floor(low)))
            end

            -- TIME
            if db.showTime then table.insert(parts, string.format("%s%s|r", GetHex(db.colorTime.r, db.colorTime.g, db.colorTime.b), date("%H:%M"))) end

            -- MYTHIC+ SECTION
            if db.showMPlus then 
                local score = GetMPlusScore()
                local color = C_ChallengeMode.GetDungeonScoreRarityColor(score) or db.colorMPlus
                table.insert(parts, string.format("%sM+:%d|r", GetHex(color.r, color.g, color.b), score)) 
            end
            
            -- EXTERNAL MODULES (sal.lua & key.lua)
            if db.showSAL and GetScoreLevelInfo then
                local data = GetScoreLevelInfo()
                if data then table.insert(parts, string.format("%s%s|r", GetHex(db.colorMPlus.r, db.colorMPlus.g, db.colorMPlus.b), data)) end
            end
            if db.showKeyShare and GetKeyShareInfo then
                local data = GetKeyShareInfo()
                if data then table.insert(parts, string.format("%sKey:%s|r", GetHex(1, 0.8, 0), data)) end
            end

            -- SOCIAL
            if db.showFriends then table.insert(parts, string.format("%sF:%d|r", GetHex(db.colorFriends.r, db.colorFriends.g, db.colorFriends.b), GetOnlineFriends())) end
            if db.showGuild then table.insert(parts, string.format("%sG:%d|r", GetHex(db.colorGuild.r, db.colorGuild.g, db.colorGuild.b), GetOnlineGuild())) end
            
            self.text:SetText(table.concat(parts, "  "))
            self:SetSize(self.text:GetStringWidth() + 15, (db.fontSize or 14) + 8)
            timer = 0
        end
    end)
    ApplySettings()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if name == AddonName then
        -- 1. Datenbank grundlegend sicherstellen
        if not StatsFrameDB then 
            StatsFrameDB = {} 
        end
        
        -- 2. Untertabellen sicherstellen, falls sie fehlen
        if not StatsFrameDB.profiles then 
            StatsFrameDB.profiles = {} 
        end
        if not StatsFrameDB.charToProfile then 
            StatsFrameDB.charToProfile = {} 
        end
        
        -- 3. Default Profil anlegen, falls nicht vorhanden
        if not StatsFrameDB.profiles["Default"] then 
            StatsFrameDB.profiles["Default"] = CopyTable(defaults) 
        end
        
        -- 4. Jetzt erst UI und Logik laden
        CreateSettingsUI() 
        Init()
        
        -- Debug Nachricht (optional)
        print("|cff00ff00Stat & Info Bar loaded!|r")
    end
end)

SLASH_FPSMS1 = "/fpsms"
SlashCmdList["FPSMS"] = function() if categoryID then Settings.OpenToCategory(categoryID) end end