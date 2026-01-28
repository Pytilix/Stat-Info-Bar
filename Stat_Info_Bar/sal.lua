local AddonName = "FPS-MS-Tracker"

-- Hilfsfunktion: Holt die aktuelle Einstellung für showSAL aus der Datenbank
local function IsSalEnabled()
    if StatsFrameDB and StatsFrameDB.charToProfile then
        local charKey = UnitName("player") .. "-" .. GetRealmName()
        local profileName = StatsFrameDB.charToProfile[charKey] or "Default"
        local db = StatsFrameDB.profiles[profileName]
        return db and db.showSAL
    end
    return false
end

local function CreateStatsPanel()
    -- Hauptframe
    local f = CreateFrame("Frame", "MPlusSeasonDashboard", PVEFrame, "BackdropTemplate")
    f:SetSize(360, 310)
    f:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", 2, -10)
    
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    -- Titel
    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.header:SetPoint("TOPLEFT", 15, -15)
    
    f.rows = {}
    for i = 1, 10 do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(330, 24)
        row:SetPoint("TOPLEFT", 12, -40 - (i * 24))

        row.icon = row:CreateTexture(nil, "OVERLAY")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
        row.text:SetJustifyH("LEFT")
        
        f.rows[i] = row
    end

    f.UpdateData = function()
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if not summary or not summary.runs then return end

        f.header:SetText("Saison-Score: |cff00ff00" .. summary.currentSeasonScore .. "|r")

        for i, run in ipairs(summary.runs) do
            if f.rows[i] then
                local mapName, _, _, texture = C_ChallengeMode.GetMapUIInfo(run.challengeModeID)
                f.rows[i].icon:SetTexture(texture or "Interface\\Icons\\Inv_misc_questionmark")
                
                local levelColor = "|cffffffff"
                if run.bestRunLevel >= 7 then levelColor = "|cff0070dd" end
                if run.bestRunLevel >= 10 then levelColor = "|cffa335ee" end
                if run.bestRunLevel >= 15 then levelColor = "|cffff8000" end

                f.rows[i].text:SetText(string.format("|cffffd100%s:|r %s+%d|r (|cffffffff%d|r)", 
                    mapName or "Lade...", levelColor, run.bestRunLevel, run.mapScore))
                f.rows[i]:Show()
            end
        end
    end

    -- Steuerung der Sichtbarkeit basierend auf Menü-Einstellung
    PVEFrame:HookScript("OnShow", function() 
        if IsSalEnabled() then 
            f:Show()
            f.UpdateData()
        else
            f:Hide()
        end 
    end)
    
    return f
end

-- Warten bis das Spiel bereit ist
local l = CreateFrame("Frame")
l:RegisterEvent("PLAYER_LOGIN")
l:SetScript("OnEvent", function() CreateStatsPanel() end)