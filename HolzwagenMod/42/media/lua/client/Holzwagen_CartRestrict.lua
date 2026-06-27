-- media/lua/client/Holzwagen_CartRestrict.lua
-- Solange ein Wagen geschoben wird (beide Hände belegt), sind bestimmte
-- Aktionen gesperrt: über Zäune/Mauern klettern, durch Fenster steigen und
-- Türen öffnen/schließen.
--
-- ROBUSTER Ansatz: Wir hängen uns in ISTimedActionQueue.add ein und prüfen den
-- Action-TYP-NAMEN (self.Type, z. B. "ISClimbOverFenceAction"). So fangen wir
-- ALLE Kletter-/Tür-Varianten per Namensmuster ab, ohne exakte Klassennamen zu
-- raten. Zusätzlich werden die bekannten Klassen via isValid() abgesichert.
-- MP-sicher (clientseitig vor Action-Start). Schalter in Holzwagen_Config.lua.

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW  = Holzwagen
local CFG = HolzwagenConfig

local function climbBlocked() return not (CFG.handling and CFG.handling.blockClimb == false) end
local function doorBlocked()  return not (CFG.handling and CFG.handling.blockDoors == false) end

-- Anhand des Typ-Namens entscheiden, ob die Aktion beim Schieben verboten ist.
local function nameIsBlocked(typeName)
    if not typeName then return false end
    local n = string.lower(typeName)
    if climbBlocked() and (n:find("climb") or n:find("fence") or n:find("vault")
                           or n:find("window") or n:find("wall")) then
        return true
    end
    if doorBlocked() and (n:find("door") or n:find("curtain")) then
        return true
    end
    return false
end

-- Eine konkrete Action-Instanz blockieren?
local function actionBlocked(action)
    if not action or not action.character then return false end
    if not HW.hasCartEquipped(action.character) then return false end
    return nameIsBlocked(action.Type)
end

-- ---- Primär: ISTimedActionQueue.add abfangen ----
if not HW._restrictQueuePatched then
    local origAdd = ISTimedActionQueue.add
    ISTimedActionQueue.add = function(action)
        if actionBlocked(action) then
            -- nicht einreihen; Action trotzdem zurueckgeben, damit Aufrufer
            -- (die das Ergebnis weiterverwenden) nicht auf nil laufen.
            return action
        end
        return origAdd(action)
    end
    HW._restrictQueuePatched = true
end

-- ---- Backup: isValid() der bekannten Klassen ----
local KNOWN = {
    "ISClimbOverFenceAction", "ISClimbThroughWindow", "ISClimbOverWallAction",
    "ISClimbOverWall", "ISClimbSheetRopeAction", "ISClimbDownSheetRopeAction",
    "ISOpenCloseDoor", "ISOpenCloseCurtain",
}
local function patchIsValid(className)
    local cls = _G[className]
    if not cls or type(cls) ~= "table" or not cls.isValid or cls.__holzwagenRestricted then return end
    local orig = cls.isValid
    cls.isValid = function(self, ...)
        if self and self.character and HW.hasCartEquipped(self.character)
           and nameIsBlocked(self.Type or className) then
            return false
        end
        return orig(self, ...)
    end
    cls.__holzwagenRestricted = true
end
local function applyPatches()
    for _, name in ipairs(KNOWN) do patchIsValid(name) end
end
Events.OnGameStart.Add(applyPatches)
applyPatches()
