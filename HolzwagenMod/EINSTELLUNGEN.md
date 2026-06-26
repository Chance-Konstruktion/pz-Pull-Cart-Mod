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

In jedem `model { ... }` steht eine Zeile wie:

```
attachment Bip01_Prop1 { offset = 0.0 0.0 -1.7, rotate = 0.0 90.0 0.0, }
```

| Wert | Bedeutung |
|------|-----------|
| `rotate = a b c` | **a** = vor/zurück kippen · **b** = um die Hochachse drehen (Yaw, „Z") · **c** = seitlich kippen. `90` = Vierteldrehung im Uhrzeigersinn, `-90` = gegen, `180` = um. |
| `offset = x y z` | **x** = rechts/links · **y** = oben/unten · **z** = vorne/hinten (Meter). Aktuell `z = -1.7` = 1,7 m nach hinten. |
| `scale` (Zeile drüber) | Gesamtgröße. Kleiner z. B. `0.004`, größer `0.008`. |

> ⚠️ Beide Modelle (`wagenT1` **und** `wagenT2`, plus `wagenFass`) gleich
> einstellen, sonst sieht jede Stufe anders aus.
> Dreht etwas „falsch herum"? → Vorzeichen tauschen (`90` ↔ `-90`) oder die `90`
> in eine andere der drei `rotate`-Stellen setzen.

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
    rollSound   = "FootstepWoodWalk",
    intervalMs  = 650,
}
```

| Wert | Bedeutung |
|------|-----------|
| `enabled` | `false` schaltet alle Wagen-Geräusche ab. |
| `noiseRadius` | Wie weit (in Kacheln) Zombies das Rollen hören. T1 lauter = lockt früher. |
| `noiseVolume` | Stärke des Geräuschs (0–100), beeinflusst die Anziehung. |
| `rollSound` | Name des hörbaren Roll-Clips. `""` = stumm. Existiert der Name nicht, bleibt es still (kein Absturz) – dann einfach anderen Bank-Namen eintragen. |
| `intervalMs` | Abstand zwischen zwei Geräuschen in Millisekunden (kleiner = öfter). |

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
