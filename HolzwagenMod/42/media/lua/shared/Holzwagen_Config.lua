-- media/lua/shared/Holzwagen_Config.lua
-- Zentrale Stellschrauben. Hier Balance aendern, nicht in der Logik.

HolzwagenConfig = HolzwagenConfig or {}

-- Tempo-Multiplikator beim Ziehen (1.0 = normale Geschwindigkeit).
HolzwagenConfig.speed = {
    T1 = 0.80,   -- schlechte Raeder -> 80 %
    T2 = 1.00,   -- Speichenraeder  -> 100 %
}

-- Gewichtsabhaengiges Tempo: ein voll beladener Wagen zieht langsamer.
-- Standardmaessig AUS - erst einschalten, wenn das Basis-Tempo (setSpeedMod)
-- im Spiel bestaetigt ist. Dann genuegt enabled = true.
HolzwagenConfig.weightSpeed = {
    enabled     = false,  -- true = Feature aktiv
    fullPenalty = 0.30,   -- max. Tempo-Abzug bei vollem Wagen (0.30 = -30 %)
}

-- Eigene Kapazitaet des Wagens + Anzahl Taschen-Slots an den Seiten.
-- bedLocked = true: keine lose Ladung auf dem Bett (nur Taschen), z. B. Fasswagen.
HolzwagenConfig.tiers = {
    T1   = { capacity = 150, bagSlots = 4 },
    T2   = { capacity = 300, bagSlots = 4 },
    FASS = { capacity = 0,   bagSlots = 4, fluid = 450, bedLocked = true },  -- Fass belegt das Bett
}

-- Fallback-Schalter (siehe VERIFY im Fasswagen-Skript):
-- Falls ein Item nicht gleichzeitig Item- und Fluid-Container sein darf,
-- werden die Fasswagen-Taschen an einem separaten versteckten Container gehalten.
HolzwagenConfig.fassUsesSeparateBagContainer = false

-- Tag, an dem die Logik den Wagen erkennt.
HolzwagenConfig.cartTag = "Holzwagen"

-- Standard-Radstufe, wenn am Wagen nichts gespeichert ist.
HolzwagenConfig.defaultWheels = "T1"

return HolzwagenConfig
