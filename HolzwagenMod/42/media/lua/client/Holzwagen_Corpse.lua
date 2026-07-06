-- media/lua/client/Holzwagen_Corpse.lua
-- Leichen-Transport: Rechtsklick auf eine Leiche, waehrend ein Wagen mit
-- OFFENEM Bett (T1/T2, nicht Fasswagen) geschoben wird -> "Leiche auf den
-- Wagen laden". Pragmatischer Vanilla-Weg: erst die Vanilla-Grab-Aktion
-- (synchronisiert, MP-tauglich), danach schiebt eine Mini-Folgeaktion das
-- Leichen-Item vom Inventar in den Wagen-Container. Defensiv gekapselt.

require "Holzwagen_Core"
require "TimedActions/ISBaseTimedAction"

local HW = Holzwagen

-- ---------- Folge-Aktion: Leiche vom Inventar in den Wagen ----------
HolzwagenMoveCorpseToCart = ISBaseTimedAction:derive("HolzwagenMoveCorpseToCart")

function HolzwagenMoveCorpseToCart:isValid() return true end
function HolzwagenMoveCorpseToCart:update() end
function HolzwagenMoveCorpseToCart:start() end
function HolzwagenMoveCorpseToCart:stop() ISBaseTimedAction.stop(self) end

function HolzwagenMoveCorpseToCart:perform()
    local playerObj = self.character
    local cart = playerObj:getPrimaryHandItem()
    if cart and HW.isCart(cart) and not HW.bedLocked(cart) then
        local cartInv = cart.getInventory and cart:getInventory()
        local inv = playerObj:getInventory()
        if cartInv and inv then
            local items = inv:getItems()
            for i = items:size() - 1, 0, -1 do
                local it = items:get(i)
                local ft = it and it.getFullType and it:getFullType() or ""
                if ft:find("Corpse") then
                    inv:Remove(it)
                    cartInv:AddItem(it)
                    playerObj:Say("Leiche verladen")
                    break
                end
            end
            local pdata = getPlayerData(playerObj:getPlayerNum())
            if pdata and pdata.playerInventory then pdata.playerInventory:refreshBackpacks() end
        end
    end
    ISBaseTimedAction.perform(self)
end

function HolzwagenMoveCorpseToCart:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = 1
    o.stopOnWalk = false
    o.stopOnRun = false
    return o
end

-- ---------- Kontextmenue auf Leichen ----------
local function loadCorpse(playerObj, body)
    if not (playerObj and body and body.getSquare and body:getSquare()) then return end
    luautils.walkAdj(playerObj, body:getSquare())
    -- Vanilla-Grab (synchronisiert). Klassenname je Version defensiv prueben.
    local grabbed = false
    if ISGrabCorpseAction and ISGrabCorpseAction.new then
        local ok = pcall(function()
            ISTimedActionQueue.add(ISGrabCorpseAction:new(playerObj, body, 150))
        end)
        grabbed = ok
    end
    if not grabbed and ISGrabItemAction then
        pcall(function()
            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, body, 150))
        end)
    end
    -- danach: Leiche vom Inventar in den Wagen
    ISTimedActionQueue.add(HolzwagenMoveCorpseToCart:new(playerObj))
end

local function corpseContext(player, context, worldobjects)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local cart = playerObj:getPrimaryHandItem()
    if not (cart and HW.isCart(cart)) or HW.bedLocked(cart) then return end

    -- Leiche auf den angeklickten Kacheln suchen
    for i = 1, #worldobjects do
        local wo = worldobjects[i]
        local sq = wo and wo.getSquare and wo:getSquare()
        local bodies = sq and sq.getDeadBodys and sq:getDeadBodys()
        if bodies and bodies:size() > 0 then
            local body = bodies:get(0)
            context:addOptionOnTop("Leiche auf den Wagen laden", playerObj, loadCorpse, body)
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(corpseContext)
