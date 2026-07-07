-- media/lua/client/Holzwagen_Taschen.lua
-- Rucksaecke bequem an den Wagen haengen / abnehmen (die Taschen-Slots).
-- Workflow: Wagen schieben, Rechtsklick auf einen Rucksack im Inventar ->
-- "Tasche an den Wagen haengen" -> looten gehen. Die sichtbaren Sattel-
-- taschen am Modell sind die Optik dazu; der Stauraum kommt von den echten
-- eingehaengten Taschen. Transfer laeuft ueber ISInventoryTransferAction
-- (vanilla, MP-synchron); die Slot-Grenze prueft HolzwagenAccept serverseitig.

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW = Holzwagen

local function getCart(playerObj)
    local p = playerObj:getPrimaryHandItem()
    if p and HW.isCart(p) then return p end
    local s = playerObj:getSecondaryHandItem()
    if s and HW.isCart(s) then return s end
    return nil
end

local function countBags(container)
    local n = 0
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        if HW.isBagItem and HW.isBagItem(items:get(i)) then n = n + 1 end
    end
    return n
end

-- items aus dem Event normalisieren (kann InventoryItem oder Stapel-Tabelle sein)
local function normalize(items)
    local out = {}
    for _, v in ipairs(items) do
        if instanceof(v, "InventoryItem") then
            table.insert(out, v)
        elseif type(v) == "table" and v.items then
            for i = 1, #v.items do
                local it = v.items[i]
                if instanceof(it, "InventoryItem") then table.insert(out, it) end
            end
        end
    end
    return out
end

local function onFillInventoryMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local cart = getCart(playerObj)

    for _, it in ipairs(normalize(items)) do
        -- nur echte Taschen, nicht der Wagen selbst
        if HW.isBagItem and HW.isBagItem(it) and not HW.isCart(it) then
            local cont = cart and cart:getItemContainer()
            if cont and it:getContainer() == cont then
                -- Tasche haengt am Wagen -> abnehmen
                context:addOption("Tasche vom Wagen nehmen", playerObj, function()
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(
                        playerObj, it, cont, playerObj:getInventory()))
                end)
            elseif cont then
                -- Tasche im Inventar/angezogen -> anhaengen (Slots pruefen)
                local slots = (HW.bagSlots and HW.bagSlots(cart)) or 4
                local used  = countBags(cont)
                local label = string.format("Tasche an den Wagen haengen (%d/%d)", used, slots)
                local opt = context:addOption(label, playerObj, function()
                    if countBags(cont) >= slots then
                        playerObj:Say("Alle Taschen-Slots sind belegt!")
                        return
                    end
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(
                        playerObj, it, it:getContainer(), cont))
                end)
                if used >= slots then
                    opt.notAvailable = true
                    local tip = ISToolTip:new()
                    tip:setName("Alle Taschen-Slots belegt")
                    tip.description = "Erst eine Tasche vom Wagen nehmen."
                    opt.toolTip = tip
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryMenu)
