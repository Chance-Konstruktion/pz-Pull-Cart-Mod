-- media/lua/shared/Holzwagen_Config.lua
-- Zentrale Stellschrauben. Hier Balance aendern, nicht in der Logik.

HolzwagenConfig = HolzwagenConfig or {}

-- Tempo-Multiplikator beim Ziehen (1.0 = normale Geschwindigkeit).
HolzwagenConfig.speed = {
    T1 = 0.80,   -- schlechte Raeder -> 80 %
    T2 = 1.00,   -- Speichenraeder  -> 100 %
}

-- Eigene Kapazitaet des Wagens + Anzahl Taschen-Slots an den Seiten.
HolzwagenConfig.tiers = {
    T1   = { capacity = 150, bagSlots = 2 },
    T2   = { capacity = 300, bagSlots = 4 },
    FASS = { capacity = 300, bagSlots = 3, fluid = 450 },  -- Fasswagen: Fass + nur 3 Taschen
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
