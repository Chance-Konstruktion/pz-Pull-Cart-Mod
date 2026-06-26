-- media/lua/shared/Holzwagen_Fluid.lua
-- Flüssigkeits-Logik des Fasswagens (shared: Client + Server).
-- Kapselt die B42-FluidContainer-API hinter robusten Helfern. Falls ein
-- API-Name in deiner B42-Version abweicht, schlägt nicht der ganze Mod fehl,
-- sondern es wird eine Meldung in die Konsole geschrieben (suche nach
-- "[Holzwagen][Fluid]") und die Aktion bricht sauber ab.

require "Holzwagen_Core"

local HW = Holzwagen
HW.Fluid = HW.Fluid or {}
local F = HW.Fluid

local function log(msg)
    print("[Holzwagen][Fluid] " .. tostring(msg))
end

-- Den FluidContainer eines Items holen (nur der Fasswagen hat einen).
function F.getContainer(item)
    if not item or not item.getFluidContainer then return nil end
    return item:getFluidContainer()
end

-- Hat dieses Item einen Fluid-Tank (= ist es ein befüllbarer Fasswagen)?
function F.hasTank(item)
    return F.getContainer(item) ~= nil
end

-- Aktuelle Menge im Tank.
function F.getAmount(fc)
    if not fc then return 0 end
    if fc.getAmount then return fc:getAmount() or 0 end
    return 0
end

-- Fassungsvermögen des Tanks.
function F.getCapacity(fc)
    if not fc then return 0 end
    if fc.getCapacity then return fc:getCapacity() or 0 end
    return 0
end

-- Freier Platz im Tank.
function F.getFree(fc)
    if not fc then return 0 end
    if fc.getFreeCapacity then return fc:getFreeCapacity() or 0 end
    local cap, amt = F.getCapacity(fc), F.getAmount(fc)
    return math.max(0, cap - amt)
end

function F.isEmpty(fc)
    if not fc then return true end
    if fc.isEmpty then return fc:isEmpty() end
    return F.getAmount(fc) <= 0
end

function F.isFull(fc)
    return F.getFree(fc) <= 0.0001
end

-- Füllgrad 0..1 (für Anzeige).
function F.fillFactor(fc)
    local cap = F.getCapacity(fc)
    if cap <= 0 then return 0 end
    return F.getAmount(fc) / cap
end

-- Den Standard-Wasser-Fluidtyp ermitteln (B42: Fluid.Water).
function F.waterType()
    if Fluid and Fluid.Water then return Fluid.Water end
    return nil
end

-- Wasser in den Tank geben (Menge in Fluid-Einheiten). Gibt die tatsächlich
-- eingefüllte Menge zurück.
function F.addWater(fc, amount)
    if not fc then return 0 end
    local free = F.getFree(fc)
    local add = math.min(amount or free, free)
    if add <= 0 then return 0 end
    local water = F.waterType()
    if fc.addFluid and water then
        fc:addFluid(water, add)
        return add
    elseif fc.adjustAmount then
        fc:adjustAmount(add)   -- Fallback: nur Menge erhöhen
        return add
    end
    log("addWater: keine passende API (addFluid/adjustAmount) gefunden")
    return 0
end

-- Tank komplett leeren. Gibt die abgelassene Menge zurück.
function F.empty(fc)
    if not fc then return 0 end
    local amt = F.getAmount(fc)
    if amt <= 0 then return 0 end
    if fc.empty then
        fc:empty()
        return amt
    elseif fc.adjustAmount then
        fc:adjustAmount(-amt)
        return amt
    elseif fc.removeFluid then
        fc:removeFluid(amt)
        return amt
    end
    log("empty: keine passende API (empty/adjustAmount/removeFluid) gefunden")
    return 0
end

-- Menge aus dem Tank abziehen (z. B. beim Umfüllen in einen Behälter).
function F.remove(fc, amount)
    if not fc then return 0 end
    local take = math.min(amount or 0, F.getAmount(fc))
    if take <= 0 then return 0 end
    if fc.adjustAmount then
        fc:adjustAmount(-take)
        return take
    elseif fc.removeFluid then
        fc:removeFluid(take)
        return take
    end
    log("remove: keine passende API gefunden")
    return 0
end

-- Von einem Behälter (Quelle) in einen anderen (Ziel) umfüllen, so viel wie
-- möglich (begrenzt durch Quelle-Inhalt und Ziel-Freiraum). Bevorzugt die
-- B42-Transfer-Funktion, sonst manueller Fallback (überträgt den Hauptfluid).
function F.transfer(srcFC, dstFC, amount)
    if not srcFC or not dstFC then return 0 end
    local move = math.min(amount or math.huge, F.getAmount(srcFC), F.getFree(dstFC))
    if move <= 0 then return 0 end

    -- Bevorzugt: native Transfer-API, falls vorhanden.
    if FluidContainer and FluidContainer.Transfer then
        FluidContainer.Transfer(srcFC, dstFC, move)
        return move
    end

    -- Fallback: Hauptfluid der Quelle bestimmen und manuell umbuchen.
    local fluid = srcFC.getPrimaryFluid and srcFC:getPrimaryFluid() or nil
    if not fluid then fluid = F.waterType() end
    if dstFC.addFluid and fluid then
        dstFC:addFluid(fluid, move)
        F.remove(srcFC, move)
        return move
    end
    log("transfer: keine passende API gefunden")
    return 0
end

return F
