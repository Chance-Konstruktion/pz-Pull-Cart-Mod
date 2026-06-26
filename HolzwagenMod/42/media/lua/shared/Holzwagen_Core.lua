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

-- Ist das Item der Schlauch (Werkzeug fuer den Fasswagen)?
function HW.isSchlauch(item)
    return item ~= nil and item.getType ~= nil and item:getType() == "Holzwagen_Schlauch"
end

-- Ist irgendwo ein Schlauch greifbar? Erst im Fass-Bett (Schlauch-Slot),
-- sonst im Spieler-Inventar. Gibt das Schlauch-Item oder nil zurueck.
function HW.findSchlauch(playerObj, fasswagen)
    local inv = fasswagen and fasswagen.getInventory and fasswagen:getInventory()
    if inv and inv.getItems then
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if HW.isSchlauch(it) then return it end
        end
    end
    local pinv = playerObj and playerObj:getInventory()
    if pinv and pinv.getFirstTypeRecurse then
        local s = pinv:getFirstTypeRecurse("Holzwagen_Schlauch")
        if s then return s end
    end
    return nil
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

-- ---------- Ladeflaechen-Volumen ----------
-- B42 deckelt die Script-Capacity hart; darum zur Laufzeit setzen.
HW.cartCapacity = {
    Holzwagen_T1        = 200,
    Holzwagen_T2        = 200,
    Holzwagen_Fasswagen = 30,
}

-- Capacity einmal auf dem Item-Container setzen (bleibt danach erhalten).
function HW.applyCapacity(item)
    if not item or not item.getType then return end
    local cap = HW.cartCapacity[item:getType()]
    if not cap then return end
    local container = item.getItemContainer and item:getItemContainer() or nil
    if not container and item.getInventory then container = item:getInventory() end
    if container and container.getCapacity and container:getCapacity() ~= cap then
        container:setCapacity(cap)
    end
end

-- ---------- AcceptItemFunction (im Item-Script referenziert) ----------
-- MUSS shared sein (Server ruft sie bei MP auf). Offene Ladeflaeche: alles
-- erlaubt. Gesperrtes Bett (Fasswagen): nur Taschen.
function HolzwagenAccept(container, item)
    local cart = container and container.getContainingItem and container:getContainingItem()
    if cart and HW.bedLocked(cart) then
        -- Fass-Bett: nur Taschen ODER der Schlauch (haengt im Schlauch-Slot).
        return HW.isBagItem(item) or HW.isSchlauch(item)
    end
    return true
end

return HW
