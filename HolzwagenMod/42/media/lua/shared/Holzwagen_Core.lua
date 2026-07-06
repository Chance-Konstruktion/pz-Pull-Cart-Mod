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

-- Hat der Charakter gerade einen Wagen in der Hand (= schiebt)?
function HW.hasCartEquipped(character)
    if not character or not character.getPrimaryHandItem then return false end
    local it = character:getPrimaryHandItem()
    return it ~= nil and HW.isCart(it)
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

-- ---------- Zustand / Abnutzung (modData, wandert mit dem Item) ----------
-- Zustand 0..100 (%). Neue Wagen starten bei 100.
function HW.getCondition(cart)
    local md = cart and cart.getModData and cart:getModData()
    if not md then return 100 end
    if md.hwCondition == nil then md.hwCondition = 100 end
    return md.hwCondition
end

function HW.setCondition(cart, value)
    local md = cart and cart.getModData and cart:getModData()
    if not md then return end
    if value < 0 then value = 0 elseif value > 100 then value = 100 end
    md.hwCondition = value
end

-- Strecke aufaddieren; senkt den Zustand gemaess Config (tilesPerPoint).
function HW.addWearDistance(cart, tiles)
    if not (CFG.wear and CFG.wear.enabled) then return end
    local md = cart and cart.getModData and cart:getModData()
    if not md then return end
    md.hwDist = (md.hwDist or 0) + tiles
    local per = CFG.wear.tilesPerPoint or 60
    while md.hwDist >= per do
        md.hwDist = md.hwDist - per
        HW.setCondition(cart, HW.getCondition(cart) - 1)
    end
end

-- Wie viele Taschen-Slots hat dieser Wagen? (Config je Stufe)
function HW.bagSlots(cart)
    local t = CFG.tiers[HW.cartTier(cart)]
    return (t and t.bagSlots) or 4
end

-- Aktuelle Anzahl Taschen im Container (zaehlt nur echte Taschen, nicht den
-- Schlauch oder losen Loot).
local function countBags(container)
    local n = 0
    if not container or not container.getItems then return 0 end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        if HW.isBagItem(items:get(i)) then n = n + 1 end
    end
    return n
end

-- ---------- AcceptItemFunction (im Item-Script referenziert) ----------
-- MUSS shared sein (Server ruft sie bei MP auf). Regeln:
--  * Schlauch: immer erlaubt (eigener Schlauch-Slot am Fasswagen).
--  * Taschen/Rucksaecke: erlaubt bis zur Slot-Zahl (T1/T2 = 4, Fass = 3).
--    Eine Tasche, die schon drin ist, darf bleiben (Umsortieren).
--  * Loser Loot (keine Tasche): nur auf OFFENEM Bett (T1/T2), nicht am Fass.
function HolzwagenAccept(container, item)
    local cart = container and container.getContainingItem and container:getContainingItem()
    if not cart or not HW.isCart(cart) then return true end

    if HW.isSchlauch(item) then return true end

    if HW.isBagItem(item) then
        -- bereits in genau diesem Container -> erlauben (kein Neu-Zaehlen)
        if item.getContainer and item:getContainer() == container then return true end
        return countBags(container) < HW.bagSlots(cart)
    end

    -- Nicht-Tasche: am gesperrten Fass-Bett verboten, sonst (offenes Bett) ok
    if HW.bedLocked(cart) then return false end
    return true
end

return HW
