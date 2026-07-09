-- media/lua/client/Holzwagen_Repair.lua
-- Reparatur: Rechtsklick auf einen abgenutzten Wagen -> "Wagen reparieren
-- (2 Bretter + 4 Naegel)". Verbraucht Material, stellt Zustand her (Config:
-- wear.repairPlanks / repairNails / repairAmount). Hammer als Werkzeug noetig.

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW  = Holzwagen
local CFG = HolzwagenConfig

local function countType(inv, fullType)
    return inv and inv.getItemCountRecurse and inv:getItemCountRecurse(fullType)
        or (inv and inv.getItemCount and inv:getItemCount(fullType)) or 0
end

local function removeSome(inv, fullType, n)
    for _ = 1, n do
        -- Existenzcheck mit PUNKT, Aufruf mit Doppelpunkt (":" ohne Aufruf
        -- ist ein Lua-SYNTAXFEHLER und hat diese ganze Datei am Laden gehindert)
        local it = (inv.getFirstTypeRecurse and inv:getFirstTypeRecurse(fullType))
                   or (inv.getFirstType and inv:getFirstType(fullType))
        if it then
            local c = it:getContainer() or inv
            c:Remove(it)
        end
    end
end

local function hasHammer(inv)
    if not inv then return false end
    if inv.containsTagRecurse and inv:containsTagRecurse("Hammer") then return true end
    return countType(inv, "Base.Hammer") > 0 or countType(inv, "Base.HammerStone") > 0
        or countType(inv, "Base.ClubHammer") > 0 or countType(inv, "Base.BallPeenHammer") > 0
end

local function doRepair(playerObj, cart)
    local w = CFG.wear or {}
    local inv = playerObj:getInventory()
    local planks, nails = (w.repairPlanks or 2), (w.repairNails or 4)
    if countType(inv, "Base.Plank") < planks or countType(inv, "Base.Nails") < nails then
        playerObj:Say("Ich brauche " .. planks .. " Bretter und " .. nails .. " Naegel.")
        return
    end
    if not hasHammer(inv) then
        playerObj:Say("Ich brauche einen Hammer.")
        return
    end
    removeSome(inv, "Base.Plank", planks)
    removeSome(inv, "Base.Nails", nails)
    HW.setCondition(cart, HW.getCondition(cart) + (w.repairAmount or 40))
    playerObj:Say("Wagen repariert (" .. HW.getCondition(cart) .. "%)")
    local pdata = getPlayerData(playerObj:getPlayerNum())
    if pdata and pdata.playerInventory then pdata.playerInventory:refreshBackpacks() end
end

local function addRepairOption(playerObj, context, cart)
    if not (CFG.wear and CFG.wear.enabled) then return end
    if HW.getCondition(cart) >= 100 then return end
    local w = CFG.wear
    context:addOption(
        string.format("Wagen reparieren (%d Bretter + %d Naegel)", w.repairPlanks or 2, w.repairNails or 4),
        playerObj, doRepair, cart)
end

-- Inventar-Kontext (Wagen in der Hand / im Inventarfenster)
local function repairInventoryContext(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local item = items and items[1]
    if item and not instanceof(item, "InventoryItem") then
        item = (type(item) == "table" and item.items and item.items[1]) or nil
    end
    if item and HW.isCart(item) then addRepairOption(playerObj, context, item) end
end

-- Welt-Kontext (abgestellter Wagen)
local function repairWorldContext(player, context, worldobjects)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not worldobjects then return end
    for i = 1, #worldobjects do
        local wo = worldobjects[i]
        local sq = wo and instanceof(wo, "IsoObject") and wo:getSquare()
        local objs = sq and sq:getWorldObjects()
        if objs then
            for j = 0, objs:size() - 1 do
                local o = objs:get(j)
                local it = o and o.getItem and o:getItem()
                if it and HW.isCart(it) then
                    addRepairOption(playerObj, context, it)
                    return
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(repairInventoryContext)
Events.OnFillWorldObjectContextMenu.Add(repairWorldContext)
