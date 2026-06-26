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
    -- Fasswagen: nur 3 Taschen, der 4. Slot ist fuer den Schlauch reserviert.
    FASS = { capacity = 0, bagSlots = 3, hoseSlot = true, fluid = 450, bedLocked = true },
}

-- Fasswagen-Flüssigkeitsregeln.
HolzwagenConfig.fass = {
    -- true = Befüllen/Umfüllen geht nur mit einem Schlauch (im Schlauch-Slot
    -- des Fasses oder im Spieler-Inventar). Leeren (Ablassen) geht immer.
    requiresHose = true,
}

-- Fallback-Schalter (siehe VERIFY im Fasswagen-Skript):
-- Falls ein Item nicht gleichzeitig Item- und Fluid-Container sein darf,
-- werden die Fasswagen-Taschen an einem separaten versteckten Container gehalten.
HolzwagenConfig.fassUsesSeparateBagContainer = false

-- ---------- Geraeusche / Zombie-Aufmerksamkeit ----------
-- Beim Schieben rollt der Wagen hoerbar UND erzeugt einen "World-Sound", den
-- Zombies wahrnehmen. T1 (Vollholzraeder) ist deutlich lauter als T2
-- (Speichenraeder) -> T1 lockt Zombies frueher an.
HolzwagenConfig.sound = {
    enabled    = true,
    -- Radius in Kacheln, in dem Zombies das Rollen hoeren (groesser = frueher).
    noiseRadius = { T1 = 20, T2 = 8,  FASS = 15 },
    -- Lautstaerke 0..100 des World-Sounds (beeinflusst, wie stark es zieht).
    noiseVolume = { T1 = 70, T2 = 25, FASS = 50 },
    -- Hoerbares Roll-Geraeusch (Sound-Name aus den Spiel-Banks). "" = stumm.
    -- Falls der Name nicht existiert, passiert nichts (kein Crash) -> hier
    -- einfach einen anderen Bank-Namen eintragen.
    rollSound  = "FootstepWoodWalk",
    -- Mindestabstand zwischen zwei Geraeusch-Ausstoessen in Millisekunden.
    intervalMs = 650,
}

-- Tag, an dem die Logik den Wagen erkennt.
HolzwagenConfig.cartTag = "Holzwagen"

-- Standard-Radstufe, wenn am Wagen nichts gespeichert ist.
HolzwagenConfig.defaultWheels = "T1"

return HolzwagenConfig
