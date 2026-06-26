-- media/lua/client/Holzwagen_FassActions.lua
-- Kontextmenü-Aktionen für den Fasswagen-Tank: füllen (Wasser), leeren,
-- umfüllen in/aus einem gehaltenen Flüssigkeits-Behälter, Füllstand anzeigen.
-- Nutzt die Helfer aus shared/Holzwagen_Fluid.lua.

require "Holzwagen_Core"
require "Holzwagen_Fluid"

local HW = Holzwagen
local F  = HW.Fluid

-- ---------- Hilfen ----------

-- Steht der Spieler an/neben einer natürlichen Wasserquelle (See/Fluss)?
local function nearWater(playerObj)
    local sq = playerObj:getCurrentSquare()
    if not sq then return false end
    local cell = sq:getCell()
    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local s = (dx == 0 and dy == 0) and sq
                      or (cell and cell:getGridSquare(px + dx, py + dy, pz))
            if s and s.Is and IsoFlagType and s:Is(IsoFlagType.water) then
                return true
            end
        end
    end
    return false
end

-- Ein gehaltener Flüssigkeits-Behälter (Flasche/Kanister), NICHT der Fasswagen.
local function heldFluidItem(playerObj, fasswagen)
    for _, getter in ipairs({ "getPrimaryHandItem", "getSecondaryHandItem" }) do
        local it = playerObj[getter] and playerObj[getter](playerObj)
        if it and it ~= fasswagen and F.hasTank(it) then
            return it
        end
    end
    return nil
end

local function fmt(n) return string.format("%.0f", n or 0) end

-- ---------- Aktionen ----------

local function doFill(playerObj, fasswagen)
    local fc = F.getContainer(fasswagen)
    local added = F.addWater(fc, F.getFree(fc))
    if added > 0 then
        playerObj:Say("Fass gefüllt (+" .. fmt(added) .. ")")
    end
end

local function doEmpty(playerObj, fasswagen)
    local fc = F.getContainer(fasswagen)
    local removed = F.empty(fc)
    if removed > 0 then
        playerObj:Say("Fass geleert (-" .. fmt(removed) .. ")")
    end
end

-- Aus dem gehaltenen Behälter IN das Fass.
local function doPourIn(playerObj, fasswagen, heldItem)
    local moved = F.transfer(F.getContainer(heldItem), F.getContainer(fasswagen))
    if moved > 0 then playerObj:Say("In Fass umgefüllt (+" .. fmt(moved) .. ")") end
end

-- AUS dem Fass in den gehaltenen Behälter.
local function doPourOut(playerObj, fasswagen, heldItem)
    local moved = F.transfer(F.getContainer(fasswagen), F.getContainer(heldItem))
    if moved > 0 then playerObj:Say("Aus Fass abgefüllt (-" .. fmt(moved) .. ")") end
end

-- ---------- Menü-Aufbau (für ein konkretes Fasswagen-Item) ----------
local function buildFassMenu(playerObj, context, fasswagen)
    local fc = F.getContainer(fasswagen)
    if not fc then return end

    local amt, cap = F.getAmount(fc), F.getCapacity(fc)
    local sub = context:getNew(context)
    context:addSubMenu(
        context:addOption("Fass (" .. fmt(amt) .. "/" .. fmt(cap) .. ")", playerObj, nil),
        sub
    )

    -- Füllen (nur an Wasserquelle und wenn Platz)
    local fillOpt = sub:addOption("Mit Wasser füllen", playerObj, doFill, fasswagen)
    if F.isFull(fc) or not nearWater(playerObj) then
        fillOpt.notAvailable = true
        local tip = ISToolTip:new()
        tip:initialise(); tip:setVisible(false)
        tip.description = F.isFull(fc) and "Tank ist voll."
                          or "Keine Wasserquelle (See/Fluss) in der Nähe."
        fillOpt.toolTip = tip
    end

    -- Leeren
    local emptyOpt = sub:addOption("Fass leeren", playerObj, doEmpty, fasswagen)
    if F.isEmpty(fc) then emptyOpt.notAvailable = true end

    -- Umfüllen mit gehaltenem Behälter
    local held = heldFluidItem(playerObj, fasswagen)
    if held then
        local hfc = F.getContainer(held)
        local inOpt = sub:addOption("Behälter ins Fass leeren", playerObj, doPourIn, fasswagen, held)
        if F.isEmpty(hfc) or F.isFull(fc) then inOpt.notAvailable = true end
        local outOpt = sub:addOption("Aus Fass in Behälter", playerObj, doPourOut, fasswagen, held)
        if F.isEmpty(fc) or F.isFull(hfc) then outOpt.notAvailable = true end
    end
end

-- ---------- Inventar-Kontextmenü ----------
local function fassInventoryContext(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local item = items[1]
    if not instanceof(item, "InventoryItem") then item = items[1].items[1] end
    if not item or not HW.isFasswagen(item) then return end
    buildFassMenu(playerObj, context, item)
end

-- ---------- Welt-Kontextmenü (abgestellter Fasswagen) ----------
local function fassWorldContext(player, context, worldobjects)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not worldobjects then return end
    for i = 1, #worldobjects do
        local wo = worldobjects[i]
        if wo and instanceof(wo, "IsoObject") and wo.getItem and wo:getItem()
           and HW.isFasswagen(wo:getItem()) then
            buildFassMenu(playerObj, context, wo:getItem())
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(fassInventoryContext)
Events.OnFillWorldObjectContextMenu.Add(fassWorldContext)
