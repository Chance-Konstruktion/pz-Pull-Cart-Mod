-- media/lua/client/Holzwagen_CartSound.lua
-- Rollgeraeusch + Zombie-Aufmerksamkeit beim Schieben des Holzwagens.
-- Solange ein Wagen ausgeruestet ist UND sich der Spieler bewegt, wird in
-- festen Abstaenden ein World-Sound erzeugt (Zombies hoeren ihn) und optional
-- ein hoerbares Roll-Geraeusch abgespielt. T1 ist lauter als T2 (Config).

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW  = Holzwagen
local CFG = HolzwagenConfig

-- Letzter Geraeusch-Zeitpunkt + letzte Position je Spieler (Bewegungs-Check).
local lastNoiseMs = {}
local lastPos     = {}

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return (getTimestamp and getTimestamp() * 1000) or 0
end

-- Welche Wagenstufe steckt im Item? (T1 / T2 / FASS)
local function equippedCartTier(playerObj)
    local item = playerObj:getPrimaryHandItem()
    if item and HW.isCart(item) then return HW.cartTier(item) end
    return nil
end

local function emitCartNoise(playerObj, tier)
    local s = CFG.sound
    if not s or not s.enabled then return end

    local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()

    -- 1) World-Sound: das hoeren die Zombies. Radius/Lautstaerke je Stufe.
    local radius = (s.noiseRadius and s.noiseRadius[tier]) or 10
    local volume = (s.noiseVolume and s.noiseVolume[tier]) or 30
    local wsm = getWorldSoundManager and getWorldSoundManager()
    if wsm and wsm.addSound then
        -- addSound(source, x, y, z, radius, volume)
        wsm:addSound(playerObj, x, y, z, radius, volume)
    end

    -- 2) Hoerbares Roll-Geraeusch (nur lokal, optional).
    if s.rollSound and s.rollSound ~= "" then
        local emitter = playerObj.getEmitter and playerObj:getEmitter()
        if emitter and emitter.playSound then
            emitter:playSound(s.rollSound)
        end
    end
end

local function onCartSoundUpdate(playerObj)
    if not playerObj then return end
    if playerObj.isLocalPlayer and not playerObj:isLocalPlayer() then return end

    local tier = equippedCartTier(playerObj)
    local pn = playerObj:getPlayerNum()
    if not tier then
        lastPos[pn] = nil
        return
    end

    -- Bewegungs-Check: nur Geraeusch, wenn der Wagen tatsaechlich rollt.
    local x, y = playerObj:getX(), playerObj:getY()
    local prev = lastPos[pn]
    lastPos[pn] = { x = x, y = y }
    local moving
    if playerObj.isPlayerMoving then
        moving = playerObj:isPlayerMoving()
    elseif prev then
        local dx, dy = x - prev.x, y - prev.y
        moving = (dx * dx + dy * dy) > 0.0009  -- ~0.03 Kacheln/Tick
    else
        moving = false
    end
    if not moving then return end

    -- Throttle: nicht jeden Frame, sondern im konfigurierten Abstand.
    local t = nowMs()
    local interval = (CFG.sound and CFG.sound.intervalMs) or 650
    if lastNoiseMs[pn] and (t - lastNoiseMs[pn]) < interval then return end
    lastNoiseMs[pn] = t

    emitCartNoise(playerObj, tier)
end

Events.OnPlayerUpdate.Add(onCartSoundUpdate)
