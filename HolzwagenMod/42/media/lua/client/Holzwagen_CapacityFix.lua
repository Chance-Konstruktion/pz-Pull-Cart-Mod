-- media/lua/client/Holzwagen_CapacityFix.lua
-- Volumen an die Wagengroesse anpassen. B42 deckelt die Script-Capacity hart;
-- darum setzen wir die Container-Capacity zur Laufzeit (Mechanik aus ZuperCarts).
-- Volumen je Wagen: T1 < T2 (groesseres Bett), Fasswagen klein (Fass belegt Bett).

require "Holzwagen_Core"
local HW = Holzwagen

-- Volumen je Wagentyp (an der Wagengroesse orientiert; Feintuning hier)
local CART_CAPACITY = {
    Holzwagen_T1       = 60,
    Holzwagen_T2       = 80,
    Holzwagen_Fasswagen = 30,
}

local function capacityFor(item)
    if not item then return nil end
    local t = item.getType and item:getType() or nil
    return t and CART_CAPACITY[t] or nil
end

Events.OnPlayerUpdate.Add(function(player)
    if player.isLocalPlayer and not player:isLocalPlayer() then return end
    local primaryItem = player:getPrimaryHandItem()
    if not primaryItem then return end
    local cap = capacityFor(primaryItem)
    if not cap then return end
    local container = primaryItem.getItemContainer and primaryItem:getItemContainer() or nil
    if container and container.getCapacity and container:getCapacity() ~= cap then
        container:setCapacity(cap)
    end
end)
