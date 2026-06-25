-- media/lua/client/Holzwagen_CartEquip.lua
-- In-die-Hand-nehmen + Schieben fuer den Holzwagen.
-- Mechanik adaptiert von ZuperCarts (TMC, "Carts & Trolleys") - bewaehrter
-- B42-Mod. Nutzt die Schiebe-Animationsmasken (holdingtrolleyright/left) und
-- setzt sie beim Ausruesten. MP-sicher (lokaler Spieler).

require "Holzwagen_Core"
require "TimedActions/ISTakeHolzwagen"

local HW = Holzwagen

-- Volltypen unserer Wagen (Base.Holzwagen_T1 etc.)
local CART_FULLTYPES = {}
for typ, _ in pairs(HW.cartTypes) do
    CART_FULLTYPES["Base." .. typ] = true
end

local function cartCanEquip(itemFullType)
    return CART_FULLTYPES[itemFullType] == true
end

-- Wagen am Spieler ablegen (aus Hand/Inventar in die Welt)
local function dropCartAtPlayerPosition(playerObj, cartItem)
    if not playerObj or not cartItem then return end
    local square = playerObj:getCurrentSquare()
    if not square then return end

    playerObj:getInventory():Remove(cartItem)
    playerObj:removeFromHands(cartItem)
    playerObj:setVariable("RightHandMask", "")
    playerObj:setVariable("LeftHandMask", "")

    square:AddWorldInventoryItem(cartItem, 0, 0, 0)

    local pdata = getPlayerData(playerObj:getPlayerNum())
    if pdata and pdata.playerInventory then
        pdata.playerInventory:refreshBackpacks()
        if pdata.lootInventory then pdata.lootInventory:refreshBackpacks() end
    end
end
HW.dropCart = dropCartAtPlayerPosition

-- ISTakeHolzwagen immer als gueltig behandeln (wie im Original)
local original_isValid = ISTimedActionQueue.isValid
if original_isValid then
    ISTimedActionQueue.isValid = function(actionClass, character, args)
        if actionClass == ISTakeHolzwagen then return true end
        return original_isValid(actionClass, character, args)
    end
end

-- Hand-Maske beim Anlegen setzen (Schiebe-Pose)
local function setCartMask(playerObj)
    playerObj:setVariable("RightHandMask", "holdingtrolleyright")
    playerObj:setVariable("LeftHandMask", "holdingtrolleyleft")
end

-- Wagen aus der Welt aufnehmen + anschirren
HW.equipCartFromWorld = function(playerObj, WItem)
    if not (WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare())) then return end

    -- aktuell Gehaltenes ablegen
    local primaryItem = playerObj:getPrimaryHandItem()
    if primaryItem then
        if cartCanEquip(primaryItem:getFullType()) then
            dropCartAtPlayerPosition(playerObj, primaryItem)
        else
            playerObj:getInventory():Remove(primaryItem)
            playerObj:removeFromHands(primaryItem)
            playerObj:getInventory():AddItem(primaryItem)
        end
    end

    local item = WItem:getItem()
    if item then
        WItem:getSquare():transmitRemoveItemFromSquare(WItem)
        playerObj:getInventory():AddItem(item)
        playerObj:setPrimaryHandItem(item)
        playerObj:setSecondaryHandItem(item)
        setCartMask(playerObj)

        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata then
            pdata.playerInventory:refreshBackpacks()
            if pdata.lootInventory then pdata.lootInventory:refreshBackpacks() end
        end
    end
end

-- Wagen aus dem Inventar anschirren
local function equipCartFromInventory(playerObj, item)
    local primaryItem = playerObj:getPrimaryHandItem()
    if primaryItem and cartCanEquip(primaryItem:getFullType()) then
        dropCartAtPlayerPosition(playerObj, primaryItem)
    elseif primaryItem then
        playerObj:removeFromHands(primaryItem)
    end
    if item:getContainer() then item:getContainer():Remove(item) end
    playerObj:getInventory():AddItem(item)
    playerObj:setPrimaryHandItem(item)
    playerObj:setSecondaryHandItem(item)
    setCartMask(playerObj)
    local pdata = getPlayerData(playerObj:getPlayerNum())
    if pdata then
        pdata.playerInventory:refreshBackpacks()
        if pdata.lootInventory then pdata.lootInventory:refreshBackpacks() end
    end
end

-- ---------- Tick: Hand-Maske aufraeumen, wenn kein Wagen mehr in der Hand ----------
local function onCartTick()
    local playersSum = getNumActivePlayers()
    for playerNum = 0, playersSum - 1 do
        local playerObj = getSpecificPlayer(playerNum)
        if playerObj and playerObj:getVariableString("righthandmask") == "holdingtrolleyright" then
            local trol = playerObj:getPrimaryHandItem()
            if not (trol and cartCanEquip(trol:getFullType())) then
                playerObj:setPrimaryHandItem(nil)
                playerObj:setSecondaryHandItem(nil)
                playerObj:setVariable("RightHandMask", "")
                playerObj:setVariable("LeftHandMask", "")
            end
        end
    end
end
Events.OnTick.Add(onCartTick)

-- ---------- Inventar-Kontextmenue ----------
local function cartInventoryContext(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local item = items[1]
    if not instanceof(item, "InventoryItem") then item = items[1].items[1] end
    if not item or not cartCanEquip(item:getFullType()) then return end

    local primaryItem = playerObj:getPrimaryHandItem()
    local hasCartEquipped = primaryItem and cartCanEquip(primaryItem:getFullType())

    -- am Boden liegend: "Wagen schieben" (aufnehmen)
    if not item:isEquipped() and item:getWorldItem() and not item:isInPlayerInventory() then
        context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
        context:removeOptionByName(getText("ContextMenu_Grab"))
        if not hasCartEquipped then
            context:addOptionOnTop("Wagen schieben", playerObj, HW.equipCartFromWorld, item:getWorldItem())
        end
    end

    -- im Inventar: "Wagen schieben" (anschirren)
    if not item:isEquipped() and not item:getWorldItem() then
        context:removeOptionByName(getText("ContextMenu_Equip_Primary"))
        context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
        if not hasCartEquipped or item == primaryItem then
            context:addOptionOnTop("Wagen schieben", playerObj, function(p, it) equipCartFromInventory(p, it) end, item)
        end
    end

    -- ausgeruestet: "Wagen abstellen"
    if item:isEquipped() then
        context:removeOptionByName(getText("ContextMenu_Drop"))
        context:addOptionOnTop("Wagen abstellen", playerObj, function(p)
            local cart = p:getPrimaryHandItem()
            if cart then dropCartAtPlayerPosition(p, cart) end
        end)
    end

    context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
    context:removeOptionByName(getText("ContextMenu_Unequip"))
    context:removeOptionByName(getText("ContextMenu_Grab"))
end

-- ---------- Welt-Kontextmenue ----------
local function cartWorldContext(player, context, worldobjects)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not worldobjects then return end

    local primaryItem = playerObj:getPrimaryHandItem()
    local hasCartEquipped = primaryItem and cartCanEquip(primaryItem:getFullType())

    local squares = {}
    for i = 1, #worldobjects do
        local wo = worldobjects[i]
        if wo and instanceof(wo, "IsoObject") and wo:getSquare() then
            squares[wo:getSquare():getID()] = wo:getSquare()
        end
    end

    local added = false
    for _, square in pairs(squares) do
        local objList = square:getWorldObjects()
        if objList then
            for i = 0, objList:size() - 1 do
                local wo = objList:get(i)
                if wo and wo:getItem() and cartCanEquip(wo:getItem():getFullType()) then
                    if not added and not hasCartEquipped then
                        context:addOptionOnTop("Wagen schieben", playerObj, HW.equipCartFromWorld, wo)
                        added = true
                    end
                end
            end
        end
    end

    if added then
        context:removeOptionByName(getText("ContextMenu_Grab"))
        context:removeOptionByName(getText("ContextMenu_Take"))
    end
end

-- canEquipItem erlauben (sonst blockt PZ schwere Items)
if not HW._canEquipPatched then
    local original_canEquipItem = ISInventoryPaneContextMenu.canEquipItem
    ISInventoryPaneContextMenu.canEquipItem = function(item, player)
        if item and cartCanEquip(item:getFullType()) then return true end
        return original_canEquipItem(item, player)
    end
    HW._canEquipPatched = true
end

Events.OnFillInventoryObjectContextMenu.Add(cartInventoryContext)
Events.OnFillWorldObjectContextMenu.Add(cartWorldContext)
