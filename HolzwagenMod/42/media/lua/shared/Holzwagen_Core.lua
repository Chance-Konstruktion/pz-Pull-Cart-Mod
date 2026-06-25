-- media/lua/shared/Holzwagen_Core.lua
-- SHARED: laeuft auf Client UND Server. Hier liegt alles, was die Item-Scripts
-- oder der Server braucht - vor allem HolzwagenAccept (von AcceptItemFunction
-- im Script referenziert). Im MP erzeugt/prueft der Server das Item beim
-- Craften; liegt diese Funktion nur in client/, kennt der Server sie nicht und
-- der Craft scheitert (Material zurueck, nichts erstellt).

require "Holzwagen_Config"
local CFG = HolzwagenConfig

Holzwagen = Holzwagen or {}
local HW = Holzwagen

-- ---------- Wagen-Erkennung ----------
-- Ueber den Item-Typ (robust). hasTag() wirft bei manchen Item-Klassen
-- (z. B. ComboItem) einen Fehler, darum NICHT verwenden.
HW.cartTypes = { Holzwagen_T1 = "T1", Holzwagen_T2 = "T2", Holzwagen_Fasswagen = "FASS" }

function HW.isCart(item)
    return item ~= nil and item.getType ~= nil and HW.cartTypes[item:getType()] ~= nil
end

function HW.cartTier(cart)
    return HW.cartTypes[cart:getType()] or "T1"
end

function HW.isFasswagen(cart)
    return HW.isCart(cart) and HW.cartTier(cart) == "FASS"
end

-- Welche Raeder sind verbaut? In modData gespeichert (Default aus Config).
function HW.wheelTier(cart)
    local md = cart:getModData()
    return md.wheelTier or CFG.defaultWheels
end

-- Fuellgrad des Wagens: 0.0 (leer) .. 1.0 (voll), anhand Container-Gewicht.
function HW.loadFactor(cart)
    local inv = cart and cart:getInventory()
    if not inv or not inv.getContentsWeight or not inv.getCapacity then return 0 end
    local cap = inv:getCapacity()
    if not cap or cap <= 0 then return 0 end
    local f = inv:getContentsWeight() / cap
    if f < 0 then return 0 elseif f > 1 then return 1 end
    return f
end

-- ---------- Taschen / Bett ----------
-- Ist das Item eine Tasche/ein Rucksack (eigener Container)?
function HW.isBagItem(item)
    if not item then return false end
    if instanceof(item, "InventoryContainer") then return true end
    return item.getItemCapacity ~= nil and (item:getItemCapacity() or 0) > 0
end

-- Hat dieser Wagen ein gesperrtes Bett (keine lose Ladung, nur Taschen)?
function HW.bedLocked(cart)
    local t = CFG.tiers[HW.cartTier(cart)]
    return t and t.bedLocked == true
end

-- ---------- AcceptItemFunction (im Item-Script referenziert) ----------
-- MUSS shared sein (Server ruft sie bei MP auf). Offene Ladeflaeche: alles
-- erlaubt. Gesperrtes Bett (Fasswagen): nur Taschen.
function HolzwagenAccept(container, item)
    local cart = container and container.getContainingItem and container:getContainingItem()
    if cart and HW.bedLocked(cart) then
        return HW.isBagItem(item)
    end
    return true
end

return HW
