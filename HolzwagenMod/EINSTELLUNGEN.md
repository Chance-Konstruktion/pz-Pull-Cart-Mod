# 🔧 Holzwagen – Einstellungen zum Selbst-Tunen

Diese Datei sammelt **alle Kleinigkeiten, die du ohne Code-Kenntnisse selbst
ändern kannst**. Immer gilt: **Wert ändern → Datei speichern → Spiel komplett
neu starten** (PZ liest Scripts & Lua nur beim Start) → testen.

Alle Pfade beginnen ab dem Mod-Ordner `HolzwagenMod/`.

---

## 1. 🛒 Position / Drehung / Größe des Wagens IN DER HAND

**Datei:**
- `42/media/scripts/holzwagen_items.txt` → Blöcke `model wagenT1` und `model wagenT2`
- `42/media/scripts/holzwagen_fasswagen.txt` → Block `model wagenFass`

**In der Hand** stellst du über `attachment Bip01_Prop1` ein:

```
attachment Bip01_Prop1 { offset = -1.4 0.1 0.0, rotate = 0.0 90.0 0.0, }  # IN DER HAND
```

| Wert | Bedeutung |
|------|-----------|
| `rotate = a b c` | **a** = auf der Radachse kippen · **b** = Yaw · **c** = seitlich kippen. Die Griff-Hoch-Kippung (10°) steckt fest im `_hand`-Modell → Winkel ändern über `HAND_UP_DEG` in `tools/holzwagen_world_tilt.py` + Skript neu laufen lassen, NICHT über `a`. |
| `offset = x y z` | **x** = rechts/links · **y** = oben/unten · **z** = vorne/hinten (Meter). |
| `scale` (Zeile drüber) | Gesamtgröße. Kleiner z. B. `0.004`, größer `0.008`. |

**Abgestellt (Handgriff liegt auf dem Boden):** Das ist KEIN rotate-Wert mehr,
sondern ein **eigenes Welt-Modell** mit fest eingebauter 15,8°-Kippung
(`wagenT1world` / `wagenT2world` / `wagenFassWorld`, jeweils als
`WorldStaticModel` am Item). Wenn du den Kipp-Winkel ändern willst:
`WHEEL_R` bzw. die Toleranz in `tools/holzwagen_world_tilt.py` anpassen und
das Skript neu laufen lassen (`python3 tools/holzwagen_world_tilt.py`) —
es findet den Winkel automatisch, bei dem der Griff genau aufliegt.

---

## 2. 📦 Ladevolumen (wie viel reinpasst)

**Datei:** `42/media/lua/shared/Holzwagen_Core.lua` → Tabelle `HW.cartCapacity`

```lua
HW.cartCapacity = {
    Holzwagen_T1        = 200,
    Holzwagen_T2        = 200,
    Holzwagen_Fasswagen = 30,
}
```

Einfach die Zahl ändern (z. B. `300`). Höher = mehr Stauraum.

> Hinweis: Die `Capacity = 50` in den `.txt`-Script-Dateien ist **NICHT** das echte
> Volumen – B42 deckelt Script-Capacity bei 50. Das echte Volumen wird zur Laufzeit
> aus der Tabelle oben gesetzt. Also **immer hier** ändern.

---

## 2b. 🎒 Taschen-Slots (Rucksäcke im Wagen)

**Datei:** `42/media/lua/shared/Holzwagen_Config.lua` → `HolzwagenConfig.tiers`

```lua
T1   = { capacity = 150, bagSlots = 4 },
T2   = { capacity = 300, bagSlots = 4 },
FASS = { capacity = 0, bagSlots = 3, hoseSlot = true, fluid = 450, bedLocked = true },
```

`bagSlots` = wie viele Taschen/Rucksäcke man in den Wagen hängen kann (jede bringt
ihren eigenen Stauraum mit). Beim Fasswagen ist der 4. Slot für den **Schlauch**
reserviert (daher 3 Taschen). Zahl ändern → Spiel neu starten.

## 3. 🏃 Tempo (wie schnell man mit dem Wagen läuft)

**Datei:**
- `42/media/scripts/holzwagen_items.txt` → in `item Holzwagen_T1` / `item Holzwagen_T2`
- `42/media/scripts/holzwagen_fasswagen.txt` → in `item Holzwagen_Fasswagen`

Zeile:

```
RunSpeedModifier = 0.80,
```

| Wert | Wirkung |
|------|---------|
| `1.00` | normale Geschwindigkeit |
| `0.80` | 80 % = etwas langsamer (aktuell T1) |
| `0.90` | 90 % (aktuell T2) |
| `0.75` | 75 % (aktuell Fasswagen) |

Kleiner = langsamer. Das ist die **einzige aktive Tempo-Schraube**.

> ℹ️ In `Holzwagen_Config.lua` stehen noch `HolzwagenConfig.speed` und
> `weightSpeed` – die sind **aktuell NICHT angeschlossen** (Reste/Vorbereitung).
> Tempo also bitte über `RunSpeedModifier` oben ändern, nicht dort.

---

## 4. 🔊 Geräusche & Zombie-Aufmerksamkeit

**Datei:** `42/media/lua/shared/Holzwagen_Config.lua` → `HolzwagenConfig.sound`

```lua
HolzwagenConfig.sound = {
    enabled     = true,
    noiseRadius = { T1 = 20, T2 = 8,  FASS = 15 },
    noiseVolume = { T1 = 70, T2 = 25, FASS = 50 },
    rollSound   = { T1 = "HolzwagenRollT1", T2 = "HolzwagenRollT2", FASS = "HolzwagenRollFass" },
    intervalMs  = 1300,
}
```

| Wert | Bedeutung |
|------|-----------|
| `enabled` | `false` schaltet alle Wagen-Geräusche ab. |
| `noiseRadius` | Wie weit (in Kacheln) Zombies das Rollen hören. T1 lauter = lockt früher. |
| `noiseVolume` | Stärke des Geräuschs (0–100), beeinflusst die Anziehung. |
| `rollSound` | Hörbarer Roll-Clip **je Stufe** (unsere eigenen Sounds aus `media/sound/`). `""` = stumm. Auch ein einzelner String für alle Stufen geht (z. B. `"FootstepWoodWalk"`). Existiert der Name nicht, bleibt es still (kein Absturz). |
| `intervalMs` | Abstand zwischen zwei Geräuschen in Millisekunden (kleiner = öfter). Die eigenen Loops sind 1,4 s lang → 1300 schließt fast nahtlos an. |

**Sound-Charakter ändern** (dumpfer, mehr Knarzen, andere Schlag-Frequenz):
`tools/holzwagen_sounds.py` anpassen und neu laufen lassen
(`python3 tools/holzwagen_sounds.py`). Audio-Lautstärke/Hörweite der Clips:
`42/media/scripts/holzwagen_sounds.txt` (`volume`, `distanceMax`).

---

## 4b. 🚪 Handhabung: Ladezeit, Klettern & Türen sperren

**Datei:** `42/media/lua/shared/Holzwagen_Config.lua` → `HolzwagenConfig.handling`

```lua
HolzwagenConfig.handling = {
    equipTime  = 60,    -- Ladezeit (Ticks) beim Anschirren vom Boden. 0 = sofort.
    blockClimb = true,  -- beim Schieben nicht klettern/durch Fenster
    blockDoors = true,  -- beim Schieben keine Türen öffnen/schließen
}
```

- **equipTime** kleiner = schneller anschirren (z. B. `30`), `0` = ganz ohne Ladezeit.
- **blockClimb / blockDoors** auf `false` setzen, um die jeweilige Sperre auszuschalten.

> Bedienung: **E oder V** neben einem Wagen am Boden = anschirren (mit Ladezeit),
> **E oder V** mit Wagen in der Hand = abstellen.

## 4c. ⚖️ Beladungs-Tempo, 🌧️ Regen-Sammlung, 🔨 Abnutzung

**Datei:** `42/media/lua/shared/Holzwagen_Config.lua`

```lua
HolzwagenConfig.weightSpeed = {
    enabled     = true,   -- voller Wagen zieht langsamer
    fullPenalty = 0.30,   -- max. Tempo-Abzug bei vollem Wagen (30 %)
}
HolzwagenConfig.rain = {
    enabled      = true,
    ratePer10Min = 8,     -- Liter pro 10 Min bei vollem Regen (Fasswagen draußen)
    searchRadius = 12,    -- Suchradius für abgestellte Fasswagen (Kacheln)
}
HolzwagenConfig.wear = {
    enabled       = true,
    tilesPerPoint = 60,   -- alle N Kacheln Strecke -1 % Zustand
    repairPlanks  = 2,    -- Reparaturkosten
    repairNails   = 4,
    repairAmount  = 40,   -- % pro Reparatur
}
```

- Der **Zustand** steht im Wagen-Namen (z. B. „Holzwagen (T2) (34/200 | 87%)").
- **Reparieren**: Rechtsklick auf den Wagen → „Wagen reparieren" (braucht Hammer).
- Schlechter Zustand macht zusätzlich langsamer (bis −20 % bei 0 %).
- Alles einzeln per `enabled = false` abschaltbar.

## 5. 🛢️ Fasswagen-Tank (Flüssigkeitsmenge)

**Datei:** `42/media/scripts/holzwagen_fasswagen.txt` → `component FluidContainer`

```
Capacity = 450.0,
```

Größerer Wert = größerer Tank. Der Tank startet **leer** (kein `Fluids{}`-Block).

---

## 6. ⚙️ Crafting-Rezepte (Material & Skill)

**Datei:** `42/media/scripts/holzwagen_recipes.txt` und
`42/media/scripts/holzwagen_fasswagen.txt` (Fass-Rezepte).

Pro `craftRecipe`:
- `inputs { item N [Base.XYZ], }` – Zutaten und Mengen.
- `SkillRequired = Woodwork:1` – nötige Skill-Stufe.
- `time = 120` – Dauer.
- `xpAward = Woodwork:10` – XP beim Bauen.

> Aktuell stehen die Rezepte im **Test-Modus** (billig). Das echte Balancing
> machen wir bewusst ganz am Schluss vor dem Workshop-Release.

---

## Spickzettel: „Was wo?"

| Ich will ändern… | Datei |
|------------------|-------|
| Wagen in der Hand drehen/verschieben/größer | `scripts/holzwagen_items.txt` + `scripts/holzwagen_fasswagen.txt` (`attachment Bip01_Prop1`) |
| Wie viel reinpasst | `lua/shared/Holzwagen_Core.lua` (`HW.cartCapacity`) |
| Laufgeschwindigkeit | `scripts/holzwagen_items.txt` + `..._fasswagen.txt` (`RunSpeedModifier`) |
| Lautstärke / Zombie-Radius / Sound | `lua/shared/Holzwagen_Config.lua` (`HolzwagenConfig.sound`) |
| Tankgröße Fasswagen | `scripts/holzwagen_fasswagen.txt` (`FluidContainer.Capacity`) |
| Rezepte / Material / Skill | `scripts/holzwagen_recipes.txt` (+ Fass-Rezepte) |
