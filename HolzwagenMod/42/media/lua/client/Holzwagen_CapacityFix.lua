-- media/lua/client/Holzwagen_CapacityFix.lua
-- Volumen an die Wagengroesse anpassen. B42 deckelt die Script-Capacity hart;
-- darum setzen wir die Container-Capacity zur Laufzeit (Mechanik aus ZuperCarts).
-- Werte + Logik liegen in Holzwagen_Core.lua (HW.cartCapacity / HW.applyCapacity),
-- damit sie auch beim Ablegen auf den Boden greifen (Feintuning dort).

require "Holzwagen_Core"
local HW = Holzwagen

Events.OnPlayerUpdate.Add(function(player)
    if player.isLocalPlayer and not player:isLocalPlayer() then return end
    local primaryItem = player:getPrimaryHandItem()
    if primaryItem then HW.applyCapacity(primaryItem) end
end)
