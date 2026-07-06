-- media/lua/client/Holzwagen_Rain.lua
-- Regen-Sammlung: ein Fasswagen, der DRAUSSEN steht oder geschoben wird,
-- sammelt bei Regen langsam Wasser (skaliert mit Regen-Intensitaet).
-- Laeuft auf Events.EveryTenMinutes (praktisch kostenlos). Abgestellte
-- Fasswagen werden nur im Umkreis um Spieler gesucht (Config searchRadius).

require "Holzwagen_Core"
require "Holzwagen_Config"
require "Holzwagen_Fluid"

local HW  = Holzwagen
local CFG = HolzwagenConfig
local F   = HW.Fluid

local function rainIntensity()
    local cm = getClimateManager and getClimateManager()
    if cm and cm.getRainIntensity then return cm:getRainIntensity() or 0 end
    if RainManager and RainManager.isRaining then return RainManager.isRaining() and 1 or 0 end
    return 0
end

local function collectInto(cartItem, liters)
    if not HW.isFasswagen(cartItem) then return end
    local fc = F.getContainer(cartItem)
    if fc and not F.isFull(fc) then
        F.addWater(fc, liters)
    end
end

local function onEveryTenMinutes()
    local rain = CFG.rain
    if not (rain and rain.enabled) then return end
    local intensity = rainIntensity()
    if intensity <= 0 then return end
    local liters = (rain.ratePer10Min or 8) * intensity

    for pn = 0, getNumActivePlayers() - 1 do
        local playerObj = getSpecificPlayer(pn)
        if playerObj then
            -- 1) geschobener Fasswagen (nur wenn Spieler draussen steht)
            local held = playerObj:getPrimaryHandItem()
            local psq = playerObj:getCurrentSquare()
            if held and psq and psq:isOutside() then
                collectInto(held, liters)
            end
            -- 2) abgestellte Fasswagen im Umkreis
            if psq then
                local cell = psq:getCell()
                local r = rain.searchRadius or 12
                local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
                for dx = -r, r do
                    for dy = -r, r do
                        local s = cell and cell:getGridSquare(px + dx, py + dy, pz)
                        if s and s:isOutside() then
                            local objs = s:getWorldObjects()
                            if objs then
                                for i = 0, objs:size() - 1 do
                                    local wo = objs:get(i)
                                    local it = wo and wo.getItem and wo:getItem()
                                    if it then collectInto(it, liters) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.EveryTenMinutes.Add(onEveryTenMinutes)
