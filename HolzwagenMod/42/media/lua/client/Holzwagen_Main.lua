-- media/lua/client/Holzwagen_Main.lua
-- Zieh-Logik nach dem Fahrrad-Prinzip: Wagen in beide Haende ("ziehen"),
-- solange ausgeruestet gilt ein Tempo-Multiplikator je nach Raedern.

require "Holzwagen_Config"
require "Holzwagen_Core"   -- shared: isCart/cartTier/isBagItem/HolzwagenAccept ...
local CFG = HolzwagenConfig

Holzwagen = Holzwagen or {}
local HW = Holzwagen

-- ---------- Tempo (nur Client) ----------
function HW.speedMult(cart)
    local base = CFG.speed[HW.wheelTier(cart)] or 1.0
    local ws = CFG.weightSpeed
    if ws and ws.enabled then
        -- voll beladen -> base * (1 - fullPenalty)
        base = base * (1.0 - ws.fullPenalty * HW.loadFactor(cart))
    end
    return base
end

-- ====== Tempo-Steuerung ======
-- Das Tempo macht jetzt die ENGINE ueber RunSpeedModifier im Item-Script
-- (wie bei SaucedCarts) - das ist robuster und automatisch MP-sicher.
-- Die folgenden Funktionen sind daher No-Ops (kein per-Tick setSpeedMod mehr),
-- bleiben aber als Stubs erhalten, damit bestehende Aufrufer nicht brechen.
function HW.applySpeed(player, mult) end
function HW.resetSpeed(player) end

-- ---------- Ziehen / Loslassen ----------
function HW.startPulling(player, cart)
    player:setPrimaryHandItem(cart)
    player:setSecondaryHandItem(cart)
    cart:getModData().pulling = true
    if player.setHaloNote then player:setHaloNote("Wagen angeschirrt") end
end

function HW.stopPulling(player, cart)
    if player:getPrimaryHandItem() == cart then player:setPrimaryHandItem(nil) end
    if player:getSecondaryHandItem() == cart then player:setSecondaryHandItem(nil) end
    cart:getModData().pulling = false
end

-- Aktuell gezogener Wagen (oder nil)
local function pulledCart(player)
    local it = player:getPrimaryHandItem()
    if HW.isCart(it) and it:getModData().pulling then return it end
    return nil
end

-- ---------- Tick: Tempo halten + Sicherheits-Reset ----------
local function onPlayerUpdate(player)
    if not player then return end
    -- MP: nur den eigenen Spieler steuern, nie Remote-Spieler.
    if player.isLocalPlayer and not player:isLocalPlayer() then return end
    local cart = pulledCart(player)
    if cart then
        HW.applySpeed(player, HW.speedMult(cart))
    else
        -- Falls Wagen nicht mehr in der Hand ist (abgelegt/getauscht): Flag + Tempo zuruecksetzen
        local md = player:getModData()
        if md._hwWasPulling then HW.resetSpeed(player) end
    end
    player:getModData()._hwWasPulling = (cart ~= nil)
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- ---------- Kontextmenue (Inventar) ----------
local function onContext(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    for _, v in ipairs(items) do
        local item = (type(v) == "table" and v.items) and v.items[1] or v
        if HW.isCart(item) then
            local tier = HW.cartTier(item)
            local wheels = HW.wheelTier(item)
            local pct = math.floor((CFG.speed[wheels] or 1.0) * 100)
            if item:getModData().pulling then
                context:addOption("Wagen loslassen", player, function() HW.stopPulling(player, item) end)
            else
                local opt = context:addOption("Wagen ziehen (" .. pct .. "% Tempo)", player,
                    function() HW.startPulling(player, item) end)
                if player:getPrimaryHandItem() or player:getSecondaryHandItem() then
                    -- Hinweis, dass Haende frei sein sollten
                    local tt = ISWorldObjectContextMenu and ISToolTip:new() or nil
                    if tt then tt:initialise(); tt.description = "Beide Haende muessen frei sein."; opt.toolTip = tt end
                end
            end
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onContext)

-- ---------- Kontextmenue (abgestellter Wagen in der WELT) ----------
-- Ein abgelegtes Container-Item zeigt PZ automatisch im Boden-/Loot-Fenster als
-- aufklappbaren Container. Hier nur die Bequemlichkeit: direkt am stehenden
-- 3D-Modell "oeffnen" (hinlaufen -> Loot-Fenster) / "aufnehmen" / "ziehen".
local function onWorldContext(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local seen = {}
    for _, obj in ipairs(worldobjects) do
        local item = (obj and obj.getItem) and obj:getItem() or nil
        if item and HW.isCart(item) and not seen[item] then
            seen[item] = true
            if test then return true end
            local sq = (obj.getSquare) and obj:getSquare() or nil

            context:addOption("Wagen oeffnen", player, function()
                if sq and luautils and luautils.walkAdj then luautils.walkAdj(player, sq) end
                local loot = getPlayerLoot and getPlayerLoot(playerNum) or nil
                if loot and loot.setVisible then loot:setVisible(true) end
            end)

            context:addOption("Wagen aufnehmen", player, function()
                if ISGrabItemAction then
                    ISTimedActionQueue.add(ISGrabItemAction:new(player, obj, 40))
                end
            end)

            if not (player:getPrimaryHandItem() or player:getSecondaryHandItem()) then
                context:addOption("Wagen aufnehmen + ziehen", player, function()
                    if ISGrabItemAction then
                        ISTimedActionQueue.add(ISGrabItemAction:new(player, obj, 40))
                    end
                    -- nach dem Aufnehmen anschirren (Wagen liegt dann im Inventar)
                    if item then HW.startPulling(player, item) end
                end)
            end
        end
    end
end
Events.OnFillWorldObjectContextMenu.Add(onWorldContext)

-- isBagItem / bedLocked / HolzwagenAccept liegen jetzt in shared/Holzwagen_Core.lua
-- (Server braucht HolzwagenAccept im MP).

return HW
