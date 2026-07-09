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
require "Holzwagen_Config"
require "Holzwagen_Fluid"

local HW  = Holzwagen
local CFG = HolzwagenConfig

local UPDATE_MS = 300
local lastRun = {}
local lastPos = {}

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return (getTimestamp and getTimestamp() * 1000) or 0
end

-- Anzeigename mit Ladung/Zustand/Fuellstand aktualisieren (Tooltip + Inventar).
local function updateCartName(cart)
    if not (cart and cart.getScriptItem and cart.setName) then return end
    local base = cart:getScriptItem() and cart:getScriptItem():getDisplayName()
    if not base then return end
    local parts = { base }
    local inv = cart.getInventory and cart:getInventory()
    if inv and inv.getContentsWeight and inv.getCapacity then
        parts[#parts + 1] = string.format("%d/%d", math.floor(inv:getContentsWeight() + 0.5), inv:getCapacity())
    end
    local fc = HW.Fluid and HW.Fluid.getContainer and HW.Fluid.getContainer(cart)
    if fc then
        parts[#parts + 1] = string.format("%dL", math.floor(HW.Fluid.getAmount(fc) + 0.5))
    end
    if CFG.wear and CFG.wear.enabled then
        parts[#parts + 1] = string.format("%d%%", HW.getCondition(cart))
    end
    cart:setName(parts[1] .. " (" .. table.concat(parts, " | ", 2) .. ")")
end

-- Beladungs-Tempo: voller Wagen zieht langsamer. Wirkt ueber den Slow-Faktor
-- des Charakters; fehlt die API in der Spielversion, passiert nichts.
local function applyWeightSpeed(playerObj, cart)
    local ws = CFG.weightSpeed
    if not (ws and ws.enabled) then return end
    if not (playerObj.setSlowFactor and playerObj.setSlowTimer) then return end
    local penalty = (ws.fullPenalty or 0.30) * HW.loadFactor(cart)
    -- schlechter Zustand macht zusaetzlich langsamer (max. +20 % Abzug bei 0 %)
    if CFG.wear and CFG.wear.enabled then
        penalty = penalty + 0.20 * (1 - HW.getCondition(cart) / 100)
    end
    if penalty > 0.01 then
        playerObj:setSlowFactor(penalty)
        playerObj:setSlowTimer(0.5)
    end
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

    if hasCart then
        local cart = playerObj:getPrimaryHandItem()
        -- 2) Capacity-Backstop
        HW.applyCapacity(cart)

        -- 4) Verschleiss: gefahrene Strecke aufaddieren
        local x, y = playerObj:getX(), playerObj:getY()
        local prev = lastPos[pn]
        if prev then
            local dx, dy = x - prev.x, y - prev.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d > 0.01 and d < 3 then HW.addWearDistance(cart, d) end
        end
        lastPos[pn] = { x = x, y = y }

        -- 5) Beladungs-/Zustands-Tempo
        applyWeightSpeed(playerObj, cart)

        -- 6) Tooltip/Name: Ladung | Liter | Zustand
        updateCartName(cart)

        -- 7) Fuellstands-Modell vormerken (greift beim naechsten Abstellen)
        HW.updateWorldModel(cart)
    else
        lastPos[pn] = nil
    end

    -- Abgestellte Wagen in der Naehe: Fuellstands-Modell nachziehen (z. B.
    -- wenn am Boden be-/entladen wurde). Kleiner Radius, gedrosselt genug.
    local psq = playerObj:getCurrentSquare()
    if psq and HW.updateWorldModel then
        local cell = psq:getCell()
        local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
        for dx = -4, 4 do
            for dy = -4, 4 do
                local s = cell and cell:getGridSquare(px + dx, py + dy, pz)
                local objs = s and s:getWorldObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local wo = objs:get(i)
                        local it = wo and wo.getItem and wo:getItem()
                        if it and HW.isCart(it) then HW.updateWorldModel(it) end
                    end
                end
            end
        end
    end

    -- 3) Lose Wagen im Inventar auf den Boden stellen
    if HW.autoDropLooseCarts then HW.autoDropLooseCarts(playerObj) end
end

Events.OnPlayerUpdate.Add(onHolzwagenUpdate)
