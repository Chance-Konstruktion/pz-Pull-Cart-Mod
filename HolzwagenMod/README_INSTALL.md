# Holzwagen – Installation (Singleplayer & Multiplayer)

> **WICHTIG bei Multiplayer:** Beim Crafting im MP ist der **Server**
> maßgeblich – er prüft das Rezept und erzeugt das Item. Wenn der Server eine
> **alte** oder **gar keine** Mod-Version hat, wird beim Bauen das Material nur
> verbraucht und wieder zurückgelegt (es entsteht nichts). **Client UND Server
> müssen dieselbe, aktuelle Mod-Version haben.**

---

## 1. Singleplayer

Den Ordner `HolzwagenMod` (den mit `42/` darin) kopieren nach:

```
C:\Users\<DU>\Zomboid\mods\HolzwagenMod
```

Dann im Hauptmenü unter **Mods** aktivieren und ein Spiel starten.

---

## 2. Multiplayer – Server einrichten

### a) Mod auf den Server kopieren
Denselben Ordner `HolzwagenMod` in den **Mods-Ordner des Servers** legen:

- **Selbst gehosteter / Dedicated Server (lokal):**
  `C:\Users\<DU>\Zomboid\mods\HolzwagenMod`
  (gleicher Pfad wie SP – der lokale Dedicated Server liest denselben mods-Ordner)
- **Gemieteter Server (GPORTAL, Nitrado etc.):** über FTP/Dateimanager nach
  `.../Zomboid/mods/HolzwagenMod` hochladen.

### b) Mod in der Server-Konfig aktivieren
In der `servertest.ini` (bzw. `<Servername>.ini`) die Mod-ID eintragen:

```
Mods=HolzwagenMod
```

(mehrere Mods mit `;` trennen, z. B. `Mods=AndereMod;HolzwagenMod`)

> Die ID ist `HolzwagenMod` (siehe `42/mod.info`, Zeile `id=`). **Nicht** der
> Anzeigename „Holzwagen (Pull Cart)".

Wenn die Mod über den **Steam Workshop** läuft, zusätzlich die Workshop-ID unter
`WorkshopItems=` eintragen (lokal kopierte Mods brauchen das nicht).

### c) Server NEU STARTEN
Damit der Server die neuen/aktualisierten Scripts wirklich lädt, **muss der
Server komplett neu gestartet werden** – ein bloßes Reconnect des Clients reicht
nicht.

### d) Jeder Mitspieler aktualisiert seinen Client
Alle Spieler brauchen dieselbe Version im lokalen `Zomboid\mods\`-Ordner.

---

## 3. Bei einem Update (z. B. neuer Crafting-Fix)
Reihenfolge, damit MP nicht „hängen bleibt":

1. Neue Version in **Server**-`mods\HolzwagenMod` **und** in jeden
   **Client**-`mods\HolzwagenMod` kopieren (alte Dateien ersetzen).
2. **Server neu starten.**
3. Alle Clients neu verbinden.

**Schnelltest, ob der Server die richtige Version hat:** In der Server-Datei
`mods\HolzwagenMod\42\media\scripts\holzwagen_recipes.txt` muss bei den
Werkzeugen `tags[base:hammer]` / `tags[base:saw...]` stehen (mit `base:`-Präfix).
Steht dort noch `tags[Hammer]` / `tags[Saw]`, ist es die **alte, kaputte**
Version → Crafting schlägt im MP fehl.

---

## 4. Schnelltest nach dem Laden
1. **Konsole** (`console.txt` oder Optionen → Debug) auf rote `ERROR` prüfen –
   sowohl Client- als auch Server-Log.
2. Woodwork ≥ 1 (Test-Modus), dann ein **Rad (T1)** aus **1 Baumstamm + Säge**
   bauen → es sollte ein Wagenrad entstehen.
3. Wagen abstellen → Rechtsklick auf das Modell: öffnen / aufnehmen / ziehen.

---

## 4b. 🔧 Position/Drehung des Wagens IN DER HAND selbst einstellen

Die Lage des Wagens **in den Händen** wird **nicht** über Lua geregelt, sondern
direkt in den Modell-Definitionen – du kannst das also selbst am PC ändern, ohne
neuen Code. Es gibt **zwei getrennte Lagen**:

| Was | Datei | Block |
|-----|-------|-------|
| **In der Hand** (beim Schieben) | `42/media/scripts/holzwagen_items.txt` (T1/T2) und `42/media/scripts/holzwagen_fasswagen.txt` (Fass) | `attachment Bip01_Prop1` |
| **Auf der Map** (abgestellt) | dieselben Dateien | `attachment world` (aktuell nicht gesetzt = Standard) |

Im jeweiligen `model { ... }`-Block steht z. B.:

```
model wagenT1
{
    mesh = holzwagen_t1, texture = holzwagen_tex, scale = 0.006,
    attachment Bip01_Prop1 { offset = 0.0 0.0 0.0, rotate = 0.0 90.0 0.0, }
}
```

**`rotate = a b c`** (Grad) – drei Drehachsen:
- `a` = vor/zurück kippen (Nase hoch/runter)
- `b` = **um die Hochachse drehen (Yaw)** – das ist die „Z-Drehung". `90` =
  Viertel­drehung im Uhrzeigersinn, `-90` = gegen den Uhrzeigersinn, `180` = um.
- `c` = seitlich kippen (Roll)

**`offset = x y z`** (Meter) – verschieben:
- `x` = nach rechts/links
- `y` = nach oben/unten
- `z` = nach vorne/hinten

**`scale`** – Gesamtgröße (kleiner = z. B. `0.004`, größer = `0.008`).

Vorgehen: Wert ändern → Datei speichern → **Spiel komplett neu starten** (Script-
Dateien werden nur beim Start gelesen) → in die Hand nehmen → schauen → wiederholen.
Beide Modelle (`wagenT1` **und** `wagenT2`, plus `wagenFass`) gleich einstellen,
sonst sieht jede Stufe anders aus.

> Hinweis: Welche Zahl welche Achse bewegt, hängt davon ab, wie das Mesh in
> Blender ausgerichtet wurde. Die Zuordnung oben gilt empirisch für unsere FBX
> (Blender Z-up). Wenn etwas „falsch herum" dreht: Vorzeichen tauschen
> (`90` ↔ `-90`) oder die Zahl in eine andere der drei `rotate`-Stellen setzen.

---

## 5. Bekannte Design-Grenzen
- B42 deckelt Item-Container hart bei 50. Das „Ladevolumen" läuft daher über die
  4 seitlichen Taschen-Slots (Rucksäcke im Wagen), nicht über rohe Capacity.
- Modell-Maßstab im `model`-Block: `scale = 0.001` (PZ liest die FBX-Einheiten
  des in Metern gebauten Wagens nicht als Meter). Bei Bedarf fein justieren.
- Echtes Material-/Skill-Balancing folgt nach dem Test (Rezepte aktuell im
  Test-Modus: 1 Baumstamm + Woodwork 1 pro Rezept).

## 6. Fasswagen (Flüssigkeits-Variante)
Umbau aus dem T2-Wagen (`scripts/holzwagen_fasswagen.txt`). Das Fass ist fest
verbaut (450er Fluid-Tank). Bett vom Fass belegt – **keine lose Ladung**, aber
weiterhin **4 Taschen-Slots** seitlich. Rückbau zu T2 möglich.
