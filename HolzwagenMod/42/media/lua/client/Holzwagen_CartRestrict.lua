-- media/lua/client/Holzwagen_CartRestrict.lua
-- Solange ein Wagen geschoben wird (beide Hände belegt), sind bestimmte
-- Aktionen gesperrt: über Zäune/Mauern klettern, durch Fenster steigen und
-- Türen öffnen/schließen. Umgesetzt über die isValid()-Prüfung der jeweiligen
-- Timed Actions – MP-sicher, weil die Validierung clientseitig vor dem Start
-- greift. Schalter in Holzwagen_Config.lua (handling.blockClimb / blockDoors).

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW  = Holzwagen
local CFG = HolzwagenConfig

-- Aktionen, die beim Schieben gesperrt werden. Pro Eintrag: Klassenname +
-- zu welcher Gruppe er gehört (climb / doors). Nicht vorhandene Klassen werden
-- übersprungen (Versions-Robustheit).
local BLOCKED = {
    { class = "ISClimbOverFenceAction", group = "climb" },
    { class = "ISClimbThroughWindow",   group = "climb" },
    { class = "ISClimbOverWallAction",  group = "climb" },
    { class = "ISClimbOverWall",        group = "climb" },
    { class = "ISOpenCloseDoor",        group = "doors" },
    { class = "ISOpenCloseCurtain",     group = "doors" },
}

local function groupEnabled(group)
    if not CFG.handling then return true end
    if group == "climb" then return CFG.handling.blockClimb ~= false end
    if group == "doors" then return CFG.handling.blockDoors ~= false end
    return true
end

local function patchIsValid(className, group)
    local cls = _G[className]
    if not cls or type(cls) ~= "table" or not cls.isValid then return end
    if cls.__holzwagenRestricted then return end
    local orig = cls.isValid
    cls.isValid = function(self, ...)
        if groupEnabled(group) and self and self.character
           and HW.hasCartEquipped(self.character) then
            return false
        end
        return orig(self, ...)
    end
    cls.__holzwagenRestricted = true
end

local function applyPatches()
    for _, entry in ipairs(BLOCKED) do
        patchIsValid(entry.class, entry.group)
    end
end

Events.OnGameStart.Add(applyPatches)
-- Auch direkt versuchen (falls die Klassen schon geladen sind).
applyPatches()
