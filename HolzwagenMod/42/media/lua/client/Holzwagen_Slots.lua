-- media/lua/client/Holzwagen_Slots.lua
-- Taschen-Slots an den Seiten. T1 = 2, T2 = 4.
-- Taschen liegen physisch im Wagen-Container; modData merkt sich die Zuordnung.

require "Holzwagen_Config"
require "Holzwagen_Main"
local CFG = HolzwagenConfig
local HW = Holzwagen

local function slotCount(cart)
    local tier = HW.cartTier(cart)
    return (CFG.tiers[tier] and CFG.tiers[tier].bagSlots) or 2
end

-- ist das Item eine Tasche/Rucksack?
local function isBag(item)
    return item and (instanceof(item, "InventoryContainer")
        or (item.getItemCapacity and item:getItemCapacity() and item:getItemCapacity() > 0))
end

-- Tasche aus dem Spieler-Inventar in einen Wagen-Slot legen
function HW.attachBag(player, cart, slotIndex, bag)
    if slotIndex > slotCount(cart) then return end
    local dst = cart:getInventory()
    if not dst then return end
    local from = bag:getContainer() or player:getInventory()
    -- sauber als TimedAction transferieren (greifbare Aktion im Spiel)
    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, bag, from, dst))
    local md = cart:getModData()
    md.bags = md.bags or {}
    md.bags[slotIndex] = bag:getFullType()
end

-- Tasche aus einem Slot zurueck ins Spieler-Inventar
function HW.detachBag(player, cart, slotIndex)
    local md = cart:getModData()
    if not (md.bags and md.bags[slotIndex]) then return end
    local src = cart:getInventory()
    local bag = src and src:getFirstTypeRecurse(md.bags[slotIndex]) or nil
    if bag then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, bag, src, player:getInventory()))
    end
    md.bags[slotIndex] = nil
end

-- Inhalt der Slot-Tasche mit dem getragenen Rucksack tauschen (effizientes Umladen)
function HW.swapContents(player, cart, slotIndex)
    local md = cart:getModData()
    if not (md.bags and md.bags[slotIndex]) then return end
    local cartInv = cart:getInventory()
    local slotBag = cartInv and cartInv:getFirstTypeRecurse(md.bags[slotIndex]) or nil
    local worn = player.getClothingItem_Back and player:getClothingItem_Back() or nil
    if not (slotBag and worn) then return end
    local a = slotBag:getInventory()
    local b = worn:getInventory()
    if not (a and b) then return end
    -- Slot-Tasche -> Rucksack
    for i = a:getItems():size()-1, 0, -1 do
        local it = a:getItems():get(i)
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, it, a, b))
    end
end

-- ---------- Kontextmenue: Slot-Verwaltung ----------
local function onContext(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    for _, v in ipairs(items) do
        local item = (type(v) == "table" and v.items) and v.items[1] or v
        if HW.isCart(item) then
            local n = slotCount(item)
            local parent = context:addOption("Taschen-Slots (" .. n .. ")")
            local sub = ISContextMenu:getNew(context)
            context:addSubMenu(parent, sub)
            local md = item:getModData(); md.bags = md.bags or {}
            for i = 1, n do
                if md.bags[i] then
                    sub:addOption("Slot " .. i .. ": entnehmen", player,
                        function() HW.detachBag(player, item, i) end)
                    sub:addOption("Slot " .. i .. ": Inhalt -> Rucksack", player,
                        function() HW.swapContents(player, item, i) end)
                else
                    -- erste passende Tasche aus dem Inventar anbieten
                    local bag = player:getInventory():getFirstEvalRecurse(function(it) return isBag(it) end)
                    if bag then
                        sub:addOption("Slot " .. i .. ": '" .. bag:getName() .. "' einhaengen", player,
                            function() HW.attachBag(player, item, i, bag) end)
                    else
                        sub:addOption("Slot " .. i .. ": (leer - keine Tasche im Inventar)", nil, nil)
                    end
                end
            end
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onContext)

return HW
