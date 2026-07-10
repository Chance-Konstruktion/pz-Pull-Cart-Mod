-- media/lua/client/Holzwagen_CartSound.lua
-- Achs-Quietschen + Zombie-Aufmerksamkeit beim Schieben des Holzwagens.
-- Solange ein Wagen ausgeruestet ist UND sich der Spieler bewegt:
--  * regelmaessig ein World-Sound (das "Ohr" der Zombies, unhoerbar),
--  * GELEGENTLICH ein hoerbarer Quietscher (zufaelliger Abstand, zufaellige
--    Variante) - kein Dauer-Loop mehr. T1 quietscht oefter als T2 (Config).

require "Holzwagen_Core"
require "Holzwagen_Config"

local HW  = Holzwagen
local CFG = HolzwagenConfig

-- Letzter Geraeusch-Zeitpunkt + letzte Position je Spieler (Bewegungs-Check).
local lastNoiseMs  = {}
local lastPos      = {}
local nextSqueakMs = {}   -- Zeitpunkt des naechsten Quietschers je Spieler

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

-- World-Sound: das "Ohr" der Zombies (selbst nicht hoerbar).
local function emitCartNoise(playerObj, tier)
    local s = CFG.sound
    local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    local radius = (s.noiseRadius and s.noiseRadius[tier]) or 10
    local volume = (s.noiseVolume and s.noiseVolume[tier]) or 30
    local wsm = getWorldSoundManager and getWorldSoundManager()
    if wsm and wsm.addSound then
        -- addSound(source, x, y, z, radius, volume)
        wsm:addSound(playerObj, x, y, z, radius, volume)
    end
end

-- Gelegentlicher Quietscher: naechsten Zeitpunkt zufaellig neu wuerfeln.
local function rollNextSqueak(pn, tier, t)
    local sq = CFG.sound and CFG.sound.squeak
    if not sq then return end
    local lo = (sq.minMs and sq.minMs[tier]) or 4000
    local hi = (sq.maxMs and sq.maxMs[tier]) or 10000
    nextSqueakMs[pn] = t + lo + ZombRand(math.max(1, hi - lo))
end

local function maybeSqueak(playerObj, pn, tier, t)
    local sq = CFG.sound and CFG.sound.squeak
    if not (sq and sq.sounds and #sq.sounds > 0) then return end
    if not nextSqueakMs[pn] then
        rollNextSqueak(pn, tier, t)   -- erster Quietscher erst nach Wartezeit
        return
    end
    if t < nextSqueakMs[pn] then return end
    local name = sq.sounds[ZombRand(#sq.sounds) + 1]
    local emitter = playerObj.getEmitter and playerObj:getEmitter()
    if emitter and emitter.playSound and name then
        emitter:playSound(name)
    end
    rollNextSqueak(pn, tier, t)
end

local function onCartSoundUpdate(playerObj)
    if not playerObj then return end
    if playerObj.isLocalPlayer and not playerObj:isLocalPlayer() then return end

    if not (CFG.sound and CFG.sound.enabled) then return end

    local tier = equippedCartTier(playerObj)
    local pn = playerObj:getPlayerNum()
    if not tier then
        lastPos[pn] = nil
        nextSqueakMs[pn] = nil
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

    local t = nowMs()

    -- 1) Gelegentlicher hoerbarer Quietscher (eigener Zufalls-Timer).
    maybeSqueak(playerObj, pn, tier, t)

    -- 2) World-Sound fuer Zombies: gedrosselt im festen Abstand.
    local interval = (CFG.sound and CFG.sound.intervalMs) or 1300
    if lastNoiseMs[pn] and (t - lastNoiseMs[pn]) < interval then return end
    lastNoiseMs[pn] = t

    emitCartNoise(playerObj, tier)
end

Events.OnPlayerUpdate.Add(onCartSoundUpdate)
