-- media/lua/client/Holzwagen_CartEquip.lua
-- In-die-Hand-nehmen + Schieben fuer den Holzwagen.
-- Mechanik adaptiert von ZuperCarts (TMC, "Carts & Trolleys") - bewaehrter
-- B42-Mod. Nutzt die Schiebe-Animationsmasken (holdingtrolleyright/left) und
-- setzt sie beim Ausruesten. MP-sicher (lokaler Spieler).

require "Holzwagen_Core"
require "Holzwagen_Config"
require "TimedActions/ISTakeHolzwagen"

local HW  = Holzwagen
local CFG = HolzwagenConfig

-- Volltypen unserer Wagen (Base.Holzwagen_T1 etc.)
local CART_FULLTYPES = {}
for typ, _ in pairs(HW.cartTypes) do
    CART_FULLTYPES["Base." .. typ] = true
end

local function cartCanEquip(itemFullType)
    return CART_FULLTYPES[itemFullType] == true
end

-- Wagen am Spieler ablegen (aus Hand/Inventar in die Welt).
-- DIREKTER Drop fuer SP UND MP: IsoGridSquare:AddWorldInventoryItem uebertraegt
-- das Welt-Item im Multiplayer selbst an den Server (derselbe Weg, den auch die
-- Vanilla-Drop-Aktion am Ende nimmt). Der fruehere Umweg ueber
-- ISInventoryPaneContextMenu.onDropItems hat im MP eine Timed Action erzeugt,
-- die nie fertig wurde -> Endlos-Ladebalken, Wagen blieb im Inventar, und der
-- Kletter-Notabwurf (CartRestrict) griff nicht mehr (Wagen "durch die Wand").
local function dropCartAtPlayerPosition(playerObj, cartItem)
    if not playerObj or not cartItem then return end
    local square = playerObj:getCurrentSquare()
    if not square then return end

    HW.applyCapacity(cartItem)
    HW.updateWorldModel(cartItem)   -- Fuellstands-Modell (leer/halb/voll)
    playerObj:removeFromHands(cartItem)
    playerObj:setVariable("RightHandMask", "")
    playerObj:setVariable("LeftHandMask", "")

    -- aus JEDEM Container loesen (Hauptinventar oder Rucksack), dann auf die Kachel
    local cont = cartItem.getContainer and cartItem:getContainer()
    if cont then cont:Remove(cartItem) end
    playerObj:getInventory():Remove(cartItem)
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

-- Schiebe-Pose anhand des aktuell gehaltenen Items aktualisieren.
-- Mechanik wie in der Community-AnimAPI: ueber die Equip-Events gesetzt (sofort,
-- MP-sicher), statt nur per OnTick-Polling. Gibt true zurueck, wenn ein Wagen
-- in der Hand ist.
local function refreshCartPose(playerObj)
    if not playerObj then return false end
    local trol = playerObj:getPrimaryHandItem()
    local hasCart = trol and cartCanEquip(trol:getFullType())
    local maskSet = playerObj:getVariableString("righthandmask") == "holdingtrolleyright"
    if hasCart and not maskSet then
        setCartMask(playerObj)
    elseif maskSet and not hasCart then
        playerObj:setPrimaryHandItem(nil)
        playerObj:setSecondaryHandItem(nil)
        playerObj:setVariable("RightHandMask", "")
        playerObj:setVariable("LeftHandMask", "")
    end
    return hasCart == true
end
HW.refreshCartPose = refreshCartPose

-- Sofort auf Equip reagieren (AnimAPI-Prinzip): kein Warten auf den naechsten Tick.
-- Kapazitaet wird HIER (einmal pro Equip) gesetzt statt jeden Frame.
local function onCartEquip(character, item)
    if not character then return end
    refreshCartPose(character)
    if item and HW.isCart(item) then HW.applyCapacity(item) end
end
Events.OnEquipPrimary.Add(onCartEquip)
Events.OnEquipSecondary.Add(onCartEquip)

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

-- Wagen vom Boden anschirren MIT Ladezeit (Anschirr-Animation), statt sofort.
-- Legt zuerst einen evtl. gehaltenen Wagen ab, läuft hin und reiht die
-- Timed Action ISTakeHolzwagen ein (Maske wird in deren perform() gesetzt).
HW.takeCartFromWorld = function(playerObj, WItem)
    if not (playerObj and WItem and WItem:getSquare()) then return end

    -- gehaltenen Wagen vorher ablegen
    local primaryItem = playerObj:getPrimaryHandItem()
    if primaryItem and cartCanEquip(primaryItem:getFullType()) then
        dropCartAtPlayerPosition(playerObj, primaryItem)
    end

    if not luautils.walkAdj(playerObj, WItem:getSquare()) then return end

    local t = (CFG.handling and CFG.handling.equipTime) or 60
    if t and t > 0 then
        ISTimedActionQueue.add(ISTakeHolzwagen:new(playerObj, WItem, t))
    else
        HW.equipCartFromWorld(playerObj, WItem)
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

-- Hinweis: Der fruehere OnTick-Backstop fuer die Pose laeuft jetzt gedrosselt
-- im zentralen Handler (Holzwagen_Update.lua) statt jeden Frame.

-- ---------- Lose Wagen automatisch auf den Boden stellen ----------
-- Gewuenscht: ein gecrafteter Wagen liegt auf der Map (wie der Fasswagen) und
-- ist dort wie eine Kiste oeffenbar (Boden-Loot). Ein Wagen gehoert nie lose
-- ins Rucksack-Inventar: entweder in der Hand (schieben) oder auf dem Boden.
-- Daher: jeder NICHT ausgeruestete Wagen im Spieler-Inventar wird abgestellt.
-- MP-WICHTIG: Ein frisch GECRAFTETER Wagen haengt serverseitig noch in der
-- Craft-Transaktion. Wird er in dem Moment schon aus dem Inventar gerissen,
-- bricht der Server den Craft ab und legt das Material zurueck ("nicht
-- baubar"). Darum eine Schonfrist: erst abstellen, wenn der Wagen ein paar
-- Sekunden ununterbrochen im Inventar gesehen wurde.
local GRACE_MS = 2000
local firstSeen = {}
setmetatable(firstSeen, { __mode = "k" })   -- weak keys: keine Item-Leichen halten

local function autoDropLooseCarts(playerObj)
    if not playerObj or (playerObj.isLocalPlayer and not playerObj:isLocalPlayer()) then return end
    -- Solange noch eine Aktion laeuft (z. B. der Craft selbst), nichts anfassen.
    if ISTimedActionQueue and ISTimedActionQueue.isPlayerDoingAction
       and ISTimedActionQueue.isPlayerDoingAction(playerObj) then return end
    local inv = playerObj:getInventory()
    if not inv then return end
    local t = (getTimestampMs and getTimestampMs()) or 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and cartCanEquip(it:getFullType()) and not it:isEquipped() then
            if not firstSeen[it] then firstSeen[it] = t end
            if (t - firstSeen[it]) >= GRACE_MS then
                firstSeen[it] = nil
                dropCartAtPlayerPosition(playerObj, it)
                return -- pro Durchlauf nur einen, Liste hat sich geaendert
            end
        end
    end
end
HW.autoDropLooseCarts = autoDropLooseCarts
-- (Aufruf erfolgt gedrosselt aus Holzwagen_Update.lua, nicht mehr pro Frame.)

-- ---------- "E"-Taste: Wagen schnell schnappen / loslassen ----------
-- E mit Wagen in der Hand -> abstellen. E neben einem Wagen am Boden -> schieben.
-- Vergleicht gegen die echte Interact-Belegung (getCore) UND fest E als Fallback.
local function isInteractKey(key)
    if Keyboard and (key == Keyboard.KEY_E or key == Keyboard.KEY_V) then return true end
    local core = getCore and getCore()
    if core and core.getKey then
        if key == core:getKey("Interact") then return true end
    end
    return false
end

local function onCartKey(key)
    if not isInteractKey(key) then return end
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    local primaryItem = playerObj:getPrimaryHandItem()
    if primaryItem and cartCanEquip(primaryItem:getFullType()) then
        dropCartAtPlayerPosition(playerObj, primaryItem)
        return
    end

    -- naheliegenden Wagen am Boden suchen
    local sq = playerObj:getCurrentSquare()
    if not sq then return end
    local cell = sq:getCell()
    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local s = cell and cell:getGridSquare(px + dx, py + dy, pz)
            local objList = s and s:getWorldObjects()
            if objList then
                for i = 0, objList:size() - 1 do
                    local wo = objList:get(i)
                    if wo and wo:getItem() and cartCanEquip(wo:getItem():getFullType()) then
                        HW.takeCartFromWorld(playerObj, wo)
                        return
                    end
                end
            end
        end
    end
end
-- OnKeyStartPressed feuert zuverlaessig beim Druck (OnKeyPressed kann beim
-- Loslassen feuern / verschluckt werden).
if Events.OnKeyStartPressed then
    Events.OnKeyStartPressed.Add(onCartKey)
else
    Events.OnKeyPressed.Add(onCartKey)
end

-- ---------- Inventar-Kontextmenue ----------
local function cartInventoryContext(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local item = items and items[1]
    if item and not instanceof(item, "InventoryItem") then
        item = (type(item) == "table" and item.items and item.items[1]) or nil
    end
    if not item or not cartCanEquip(item:getFullType()) then return end

    local primaryItem = playerObj:getPrimaryHandItem()
    local hasCartEquipped = primaryItem and cartCanEquip(primaryItem:getFullType())

    -- am Boden liegend: "Wagen schieben" (aufnehmen)
    if not item:isEquipped() and item:getWorldItem() and not item:isInPlayerInventory() then
        context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
        context:removeOptionByName(getText("ContextMenu_Grab"))
        if not hasCartEquipped then
            context:addOptionOnTop("Wagen schieben", playerObj, HW.takeCartFromWorld, item:getWorldItem())
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
                    if not added then
                        if not hasCartEquipped then
                            context:addOptionOnTop("Wagen schieben", playerObj, HW.takeCartFromWorld, wo)
                        end
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
