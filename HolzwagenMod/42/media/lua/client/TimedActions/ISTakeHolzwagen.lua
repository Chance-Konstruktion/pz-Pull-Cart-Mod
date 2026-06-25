-- media/lua/client/TimedActions/ISTakeHolzwagen.lua
-- Wagen vom Boden in die Hand nehmen (Schiebe-Pose). Adaptiert von der
-- ISTakeTrolley-Aktion aus ZuperCarts (TMC) - bewaehrte B42-Mechanik.

require "TimedActions/ISBaseTimedAction"
require "Holzwagen_Core"

local HW = Holzwagen

ISTakeHolzwagen = ISBaseTimedAction:derive("ISTakeHolzwagen")

-- destContainer enthaelt noch keinen Wagen?
local function destHasNoCart(container)
    for typ, _ in pairs(HW.cartTypes) do
        if container:getItemCount("Base." .. typ) > 0 then return false end
    end
    return true
end

function ISTakeHolzwagen:isValid()
    if self.item:getSquare() and self.character:getSquare() then
        if self.item:getSquare():isBlockedTo(self.character:getSquare()) then
            return false
        end
    end
    if self.item == nil or self.item:getSquare() == nil then return false end
    if not self.item:getSquare():getWorldObjects():contains(self.item) then return false end
    return destHasNoCart(self.destContainer)
end

function ISTakeHolzwagen:update()
    self.item:getItem():setJobDelta(self:getJobDelta())
end

function ISTakeHolzwagen:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Medium")
    self:setOverrideHandModels(self.item, nil)
    self.item:getItem():setJobType(getText("ContextMenu_Grab"))
    self.item:getItem():setJobDelta(0.0)
    self.transactionID = createItemTransaction(self.character, self.item:getItem(), self.item:getItem():getContainer(), self.destContainer)
end

function ISTakeHolzwagen:stop()
    ISBaseTimedAction.stop(self)
    self.item:getItem():setJobDelta(0.0)
end

function ISTakeHolzwagen:perform()
    local inventoryItem = self.item:getItem()
    if not inventoryItem then
        ISBaseTimedAction.perform(self)
        return
    end

    local destContainer = self.destContainer
    local transID = self.transactionID
    local square = self.item:getSquare()

    if square then
        square:transmitRemoveItemFromSquare(self.item)
    end
    self.item:removeFromWorld()
    self.item:removeFromSquare()
    self.item:setSquare(nil)
    inventoryItem:setWorldItem(nil)
    inventoryItem:setJobDelta(0.0)
    destContainer:setDrawDirty(true)
    destContainer:AddItem(inventoryItem)

    local pdata = getPlayerData(self.character:getPlayerNum())
    if pdata ~= nil then
        ISInventoryPage.renderDirty = true
        pdata.playerInventory:refreshBackpacks()
        if pdata.lootInventory then
            pdata.lootInventory:refreshBackpacks()
        end
    end

    self.character:setPrimaryHandItem(inventoryItem)
    self.character:setSecondaryHandItem(inventoryItem)
    self.character:setVariable("RightHandMask", "holdingtrolleyright")
    self.character:setVariable("LeftHandMask", "holdingtrolleyleft")

    if transID and transID ~= 0 then
        pcall(function()
            if isItemTransactionConsistent(inventoryItem, inventoryItem:getContainer(), destContainer, nil) then
                removeItemTransaction(transID, true)
            end
        end)
    end

    ISBaseTimedAction.perform(self)
end

function ISTakeHolzwagen:new(character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.stopOnRun = true
    o.destContainer = o.character:getInventory()
    o.maxTime = time
    o.loopedAction = true
    o.transactionID = 0
    return o
end
