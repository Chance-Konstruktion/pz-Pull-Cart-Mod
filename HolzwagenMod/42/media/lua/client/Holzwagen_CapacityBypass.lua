-- media/lua/client/Holzwagen_CapacityBypass.lua
-- B42 deckelt Item-Container hart bei 50 - setCapacity() allein reicht NICHT,
-- weil die Transfer-Pruefung das Reinlegen weiter blockt. Loesung (Methode aus
-- dem Hydrocraft-Wheelbarrow-Mod): ISInventoryTransferAction:isValid und
-- ISInventoryPane:canPutIn fuer unsere Wagen ueberschreiben und GEWICHTSBASIERT
-- zulassen (Kapazitaet = max. Inhaltsgewicht). Werte aus HW.cartCapacity.

require "Holzwagen_Core"
local HW = Holzwagen

-- Kapazitaet (als Gewichts-Budget) fuer den Container EINES Wagens, sonst nil.
local function cartCapFor(container)
    if not container or not container.getContainingItem then return nil end
    local item = container:getContainingItem()
    if item and HW.isCart(item) then
        return HW.cartCapacity[item:getType()] or 100
    end
    return nil
end

-- 1) Transfer-Action: erlaubt das Einlegen bis zum Gewichts-Budget.
local orig_transfer_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    local cap = self.destContainer and cartCapFor(self.destContainer)
    if cap then
        self.destContainer:setCapacity(cap)
        local w = (self.item and self.item:getWeight()) or 0
        return cap > (self.destContainer:getContentsWeight() + w)
    end
    return orig_transfer_isValid(self)
end

-- 2) Drag&Drop-Pruefung im Inventarfenster.
local orig_canPutIn = ISInventoryPane.canPutIn
function ISInventoryPane:canPutIn()
    local cap = self.inventory and cartCapFor(self.inventory)
    if cap then
        local items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if items and items[1] then
            self.inventory:setCapacity(cap)
            return cap > (self.inventory:getContentsWeight() + items[1]:getWeight())
        end
    end
    return orig_canPutIn(self)
end
