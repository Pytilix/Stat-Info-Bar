local AddonName = "FPS-MS-Tracker"
local frame = CreateFrame("Frame")

-- Events für den Chat
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")

-- Hilfsfunktion: Prüft die showKeyShare Einstellung
local function IsKeyShareEnabled()
    if StatsFrameDB and StatsFrameDB.charToProfile then
        local charKey = UnitName("player") .. "-" .. GetRealmName()
        local profileName = StatsFrameDB.charToProfile[charKey] or "Default"
        local db = StatsFrameDB.profiles[profileName]
        return db and db.showKeyShare
    end
    return false
end

-- Funktion zum Finden des Keys
local function GetKeystoneLink()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID == 180653 then -- Mythic Keystone ID
                return C_Container.GetContainerItemLink(bag, slot)
            end
        end
    end
    return nil
end

-- Event-Handler
frame:SetScript("OnEvent", function(self, event, text)
    -- Nur ausführen, wenn die Funktion im Menü AN ist
    if IsKeyShareEnabled() and text:lower() == "!key" then
        local keyLink = GetKeystoneLink()
        
        if keyLink then
            local channel = "PARTY"
            if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                channel = "INSTANCE_CHAT"
            elseif IsInRaid() then
                channel = "RAID"
            end
            
            -- Kurze Verzögerung gegen Spam-Schutz
            C_Timer.After(math.random(0.1, 0.4), function()
                SendChatMessage("My Key: " .. keyLink, channel)
            end)
        end
    end
end)