-- media/lua/client/Holzwagen_Main.lua
-- Zieh-Logik nach dem Fahrrad-Prinzip: Wagen in beide Haende ("ziehen"),
-- solange ausgeruestet gilt ein Tempo-Multiplikator je nach Raedern.

require "Holzwagen_Config"
local CFG = HolzwagenConfig

Holzwagen = Holzwagen or {}
local HW = Holzwagen

-- ---------- Helfer ----------
function HW.isCart(item)
    return item and instanceof(item, "InventoryItem") and item:hasTag(CFG.cartTag)
end

function HW.cartTier(cart)
    if cart:hasTag("HolzwagenFass") then return "FASS" end
    return cart:hasTag("HolzwagenT2") and "T2" or "T1"
end

function HW.isFasswagen(cart)
    return HW.isCart(cart) and cart:hasTag("HolzwagenFass")
end

-- Welche Raeder sind verbaut? In modData gespeichert (Default aus Config).
function HW.wheelTier(cart)
    local md = cart:getModData()
    return md.wheelTier or CFG.defaultWheels
end

-- Fuellgrad des Wagens: 0.0 (leer) .. 1.0 (voll), anhand Container-Gewicht.
-- Verifizierte B42-API: ItemContainer:getContentsWeight() / getCapacity().
function HW.loadFactor(cart)
    local inv = cart and cart:getInventory()
    if not inv or not inv.getContentsWeight or not inv.getCapacity then return 0 end
    local cap = inv:getCapacity()
    if not cap or cap <= 0 then return 0 end
    local f = inv:getContentsWeight() / cap
    if f < 0 then return 0 elseif f > 1 then return 1 end
    return f
end

function HW.speedMult(cart)
    local base = CFG.speed[HW.wheelTier(cart)] or 1.0
    local ws = CFG.weightSpeed
    if ws and ws.enabled then
        -- voll beladen -> base * (1 - fullPenalty)
        base = base * (1.0 - ws.fullPenalty * HW.loadFactor(cart))
    end
    return base
end

-- ====== Tempo-Steuerung (B42-API: IsoGameCharacter:setSpeedMod) ======
-- setSpeedMod(mult) skaliert die Bewegungsgeschwindigkeit (1.0 = normal,
-- < 1.0 = langsamer). Das Bewegungssystem setzt den Wert JEDEN Frame zurueck,
-- daher wird er pro Tick neu gesetzt, solange gezogen wird (onPlayerUpdate).
--
-- Einmaliger Capability-Check: ein fehlender API-Name landet sichtbar im Log
-- (statt still in einem pcall verschluckt zu werden).
HW.speedApiOk = nil  -- nil = noch nicht geprueft, danach true/false

local function ensureSpeedApi(player)
    if HW.speedApiOk == nil and player then
        HW.speedApiOk = (player.setSpeedMod ~= nil)
        if HW.speedApiOk then
            print("[Holzwagen] Tempo-API ok: IsoGameCharacter:setSpeedMod gefunden.")
        else
            print("[Holzwagen] WARNUNG: setSpeedMod fehlt - Wagen-Tempo ohne Effekt. API pruefen.")
        end
    end
    return HW.speedApiOk
end

function HW.applySpeed(player, mult)
    if ensureSpeedApi(player) then
        player:setSpeedMod(mult)
    end
end

function HW.resetSpeed(player)
    HW.applySpeed(player, 1.0)
end

-- ---------- Ziehen / Loslassen ----------
function HW.startPulling(player, cart)
    player:setPrimaryHandItem(cart)
    player:setSecondaryHandItem(cart)
    cart:getModData().pulling = true
    HW.applySpeed(player, HW.speedMult(cart))
    if player.setHaloNote then player:setHaloNote("Wagen angeschirrt") end
end

function HW.stopPulling(player, cart)
    if player:getPrimaryHandItem() == cart then player:setPrimaryHandItem(nil) end
    if player:getSecondaryHandItem() == cart then player:setSecondaryHandItem(nil) end
    cart:getModData().pulling = false
    HW.resetSpeed(player)
end

-- Aktuell gezogener Wagen (oder nil)
local function pulledCart(player)
    local it = player:getPrimaryHandItem()
    if HW.isCart(it) and it:getModData().pulling then return it end
    return nil
end

-- ---------- Tick: Tempo halten + Sicherheits-Reset ----------
local function onPlayerUpdate(player)
    if not player then return end
    local cart = pulledCart(player)
    if cart then
        HW.applySpeed(player, HW.speedMult(cart))
    else
        -- Falls Wagen nicht mehr in der Hand ist (abgelegt/getauscht): Flag + Tempo zuruecksetzen
        local md = player:getModData()
        if md._hwWasPulling then HW.resetSpeed(player) end
    end
    player:getModData()._hwWasPulling = (cart ~= nil)
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- ---------- Kontextmenue (Inventar) ----------
local function onContext(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    for _, v in ipairs(items) do
        local item = (type(v) == "table" and v.items) and v.items[1] or v
        if HW.isCart(item) then
            local tier = HW.cartTier(item)
            local wheels = HW.wheelTier(item)
            local pct = math.floor((CFG.speed[wheels] or 1.0) * 100)
            if item:getModData().pulling then
                context:addOption("Wagen loslassen", player, function() HW.stopPulling(player, item) end)
            else
                local opt = context:addOption("Wagen ziehen (" .. pct .. "% Tempo)", player,
                    function() HW.startPulling(player, item) end)
                if player:getPrimaryHandItem() or player:getSecondaryHandItem() then
                    -- Hinweis, dass Haende frei sein sollten
                    local tt = ISWorldObjectContextMenu and ISToolTip:new() or nil
                    if tt then tt:initialise(); tt.description = "Beide Haende muessen frei sein."; opt.toolTip = tt end
                end
            end
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onContext)

-- ---------- AcceptItemFunction (im Item-Script referenziert) ----------
-- Verhindert, dass man Unsinn in den Wagen legt; Taschen + lose Gueter ok.
function HolzwagenAccept(container, item)
    return true   -- offen halten; bei Bedarf hier filtern
end

return HW
