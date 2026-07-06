-- media/lua/client/Holzwagen_Update.lua
-- ZENTRALER, GEDROSSELTER Update-Handler (Performance-Konsolidierung).
-- Ersetzt drei fruehere Pro-Frame-Handler:
--   * Pose-Backstop (frueher OnTick, jeden Frame)
--   * autoDropLooseCarts (frueher OnPlayerUpdate, jeden Frame)
--   * Capacity-Refresh (frueher OnPlayerUpdate, jeden Frame; wird jetzt primaer
--     einmalig beim Equip gesetzt - hier nur als seltener Backstop)
-- Laeuft nur alle UPDATE_MS Millisekunden pro Spieler. Die eigentliche Arbeit
-- passiert sofort ueber die Equip-Events in Holzwagen_CartEquip.lua; dieser
-- Handler faengt nur Sonderfaelle ab (Pose via Lua gesetzt, Wagen per Debug
-- ins Inventar gelegt usw.).

require "Holzwagen_Core"

local HW = Holzwagen

local UPDATE_MS = 300
local lastRun = {}

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return (getTimestamp and getTimestamp() * 1000) or 0
end

local function onHolzwagenUpdate(playerObj)
    if not playerObj then return end
    if playerObj.isLocalPlayer and not playerObj:isLocalPlayer() then return end

    local pn = playerObj:getPlayerNum()
    local t = nowMs()
    if lastRun[pn] and (t - lastRun[pn]) < UPDATE_MS then return end
    lastRun[pn] = t

    -- 1) Pose-Backstop (setzt/entfernt Schiebe-Maske, falls Events verpasst wurden)
    local hasCart = HW.refreshCartPose and HW.refreshCartPose(playerObj)

    -- 2) Capacity-Backstop nur, wenn tatsaechlich ein Wagen in der Hand ist
    if hasCart then
        HW.applyCapacity(playerObj:getPrimaryHandItem())
    end

    -- 3) Lose Wagen im Inventar auf den Boden stellen
    if HW.autoDropLooseCarts then HW.autoDropLooseCarts(playerObj) end
end

Events.OnPlayerUpdate.Add(onHolzwagenUpdate)
