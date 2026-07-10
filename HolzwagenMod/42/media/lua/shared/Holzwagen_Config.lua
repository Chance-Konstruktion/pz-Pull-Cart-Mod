-- media/lua/shared/Holzwagen_Config.lua
-- Zentrale Stellschrauben. Hier Balance aendern, nicht in der Logik.

HolzwagenConfig = HolzwagenConfig or {}

-- Tempo-Multiplikator beim Ziehen (1.0 = normale Geschwindigkeit).
HolzwagenConfig.speed = {
    T1 = 0.80,   -- schlechte Raeder -> 80 %
    T2 = 1.00,   -- Speichenraeder  -> 100 %
}

-- Gewichtsabhaengiges Tempo: ein voll beladener Wagen zieht langsamer.
-- Wirkt ueber den Slow-Faktor des Charakters (defensiv: fehlt die API in der
-- Spielversion, passiert einfach nichts).
HolzwagenConfig.weightSpeed = {
    enabled     = true,   -- false = Feature aus
    fullPenalty = 0.30,   -- max. Tempo-Abzug bei vollem Wagen (0.30 = -30 %)
}

-- Regen-Sammlung: draussen stehender/geschobener Fasswagen sammelt Regenwasser.
HolzwagenConfig.rain = {
    enabled      = true,
    ratePer10Min = 8,    -- Liter pro 10 Ingame-Minuten bei vollem Regen (skaliert mit Intensitaet)
    searchRadius = 12,   -- Kacheln um jeden Spieler, in denen abgestellte Fasswagen gesucht werden
}

-- Abnutzung + Reparatur: der Wagen verschleisst mit gefahrener Strecke.
HolzwagenConfig.wear = {
    enabled       = false,  -- deaktiviert: kein Verschleiss, keine Reparatur noetig
    tilesPerPoint = 60,   -- alle N Kacheln Strecke sinkt der Zustand um 1 % (60 => ~6000 Kacheln bis 0)
    repairPlanks  = 2,    -- Reparatur-Kosten: Bretter
    repairNails   = 4,    -- Reparatur-Kosten: Naegel
    repairAmount  = 40,   -- wieviel % eine Reparatur wiederherstellt
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

-- ---------- Handhabung (Tasten / Ladezeit / Blockaden) ----------
HolzwagenConfig.handling = {
    -- Ladezeit (in Spiel-Ticks) beim Anschirren des Wagens vom Boden.
    -- ~50–70 ≈ kurze Anschirr-Animation. 0 = sofort.
    equipTime = 60,
    -- Solange ein Wagen geschoben wird:
    blockClimb = true,  -- nicht über Zäune/Mauern klettern, nicht durch Fenster steigen
    blockDoors = true,  -- keine Türen öffnen/schließen
}

-- ---------- Fuellstands-Modelle (Ladeflaeche sichtbar beladen) ----------
-- Je Beladung (Gewicht/Kapazitaet) ein anderes WELT-Modell (abgestellt):
-- leer / halbvoll (Kisten+Saecke) / voll (gestapelt). Das Hand-Modell beim
-- Schieben ist enginebedingt fest. Fasswagen hat kein offenes Bett -> keine
-- Varianten. Modelle: tools/holzwagen_ladung.py + holzwagen_world_tilt.py.
HolzwagenConfig.loadModels = {
    thresholds = { half = 0.25, full = 0.70 },   -- Fuellgrad-Schwellen 0..1
    T1 = { empty = "wagenT1world", half = "wagenT1halbWorld", full = "wagenT1vollWorld" },
    T2 = { empty = "wagenT2world", half = "wagenT2halbWorld", full = "wagenT2vollWorld" },
}

-- Tag, an dem die Logik den Wagen erkennt.
HolzwagenConfig.cartTag = "Holzwagen"

-- Standard-Radstufe, wenn am Wagen nichts gespeichert ist.
HolzwagenConfig.defaultWheels = "T1"

return HolzwagenConfig
