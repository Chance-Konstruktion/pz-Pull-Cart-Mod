markdown---
name: pz-b42-mod-loading
description: >
  Hilft, einen Project-Zomboid-Build-42-Mod überhaupt zum Laden zu bringen und
  die häufigsten Skript-Syntax-Fallen zu vermeiden. Nutze diesen Skill, wenn ein
  B42-Mod ein rotes X im Mod-Menü zeigt, beim Start crasht ("Script load errors",
  "item not found"), Rezepte (craftRecipe) oder Items nicht laden, oder wenn ein
  3D-Modell nicht erscheint. Deckt Ordnerstruktur, mod.info, craftRecipe-Syntax,
  Item-/FluidContainer-Definitionen, Modell-Einbindung (GLB) und typische
  Lua-Syntaxfehler ab. NICHT für Build 41 und nicht für Engine-Fahrzeuge.
---

# Project Zomboid – Build 42 Mod zum Laden bringen

> Verifiziert gegen **B42 42.19 (unstable)**, Juni 2026. B42 ist instabil –
> der laufzeitnahe Teil (APIs, Skill-Syntax) ändert sich. Siehe Abschnitt
> "Vor Gebrauch prüfen". Bei Unklarheit immer gegen den aktuellen Build testen
> und die console.txt lesen (`%userprofile%\Zomboid\console.txt`).

## Diagnose-Reihenfolge

Fehler kommen praktisch immer in dieser Schichtung – von außen nach innen:

1. **Rotes X, Mod wird gelistet, lässt sich nicht aktivieren** → mod.info /
   Struktur. Der Mod wird nie geladen; im Log taucht der Mod-Name gar nicht auf.
2. **Crash beim Start, "Script load errors"** → Skript-Syntax (craftRecipe / item).
3. **"item not found: [Base.X]"** → Output-Klammern oder ein fehlendes Item.
4. **Lua-Fehler mit Zeilennummer** → Lua-Syntax.
5. **Lädt durch, aber Modell unsichtbar** → mesh-Pfad / Name / scale.

Immer zuerst die console.txt nach dem Mod-Namen und nach `ERROR`/`removing script`
durchsuchen. Vanilla-Warnungen (z. B. "Large Bucket", "AnvilStone") ignorieren –
nur Zeilen mit dem eigenen Mod-Namen zählen.

## Verifiziert (42.19)

### Ordnerstruktur
ModName/

42/

mod.info

poster.png

media/

scripts/   *.txt

lua/shared/  lua/client/  lua/server/

models_X/    *.glb (oder .fbx/.X)

textures/    *.png

common/        (leer, aber Pflichtordner)

### mod.info
- Braucht ein **gültiges `poster=poster.png` UND die Datei** im 42-Ordner.
  Leeres `poster=` oder fehlende Datei → rotes X.
- **Keine leeren Felder** (`require=` ohne Wert weglassen).
- Minimal funktionierend:
name=Mein Mod

id=MeinMod

description=...

poster=poster.png

author=...

### craftRecipe-Syntax
Vorlage ist das Vanilla-Format (z. B. MakeCoffeeMug). Minimal & ladefähig:
module Base

{

craftRecipe Mein_Rezept

{

Time = 120,

category = Carpentry,

inputs

{

item 15 [Base.Plank],     /* INPUTS: mit eckigen Klammern /

item 1 tags[Hammer],      / Werkzeug per Tag /

}

outputs

{

item 1 Base.MeinItem,     / OUTPUTS: OHNE Klammern! */

}

}

}
- **Outputs OHNE eckige Klammern, Inputs MIT.** Der Fehler
  `item not found: [Base.X]` (Klammern im Namen) heißt: Klammern aus den Outputs raus.
- **`timedActionType` existiert nicht.** Richtig ist `timedAction` (+ `Time`).
  Im Zweifel weglassen statt einen ungültigen Wert setzen.
- Ein in einem Rezept referenziertes Item, das nicht existiert, **reißt den
  ganzen Load ab**. Nur Items/Tags verwenden, die sicher da sind.
- Recipes müssen in einem `module`-Block stehen.

### Items
- `Type = Container`, `TwoHandWeapon = TRUE` etc. funktionieren.
- `FluidContainer`-Komponente: **`ContainerName` ohne Leerzeichen** (sonst
  "Sanitizing container name ... may not contain whitespaces").

### Modelle
- **GLB wird direkt unterstützt** (mischbar mit FBX/.X) – keine Konvertierung nötig.
- `mesh = name` ist **relativ zu `media/models_X/`** (Datei direkt drin,
  KEIN `WorldItems/`-Unterordner, außer er existiert wirklich).
- `texture = name` ist relativ zu `media/textures/`.
- **Der Modellname im `model`-Block darf das Wort "model" NICHT enthalten** –
  berüchtigte Falle. Z. B. `wagenT1` statt `MeinModel`.
- Modell unsichtbar/zu groß/zu klein = fast immer `scale`. Bei einem in echten
  Metern modellierten Objekt bei `scale = 1.0` anfangen, dann anpassen.
- `.obj` wird von PZ nicht gelesen – weglassen.

### Lua-Falle
- Methoden-**Existenzcheck mit Punkt**, **Aufruf mit Doppelpunkt**:
```lua
  local x = player.getDing and player:getDing() or nil
```
  `player:getDing and ...` ist ein Syntaxfehler ("function arguments expected near `and`").

### Architektur-Hinweis: Zieh-/Schiebe-Objekte
Für gezogene Wagen, Karren o. Ä. **kein Engine-Fahrzeug** bauen (B42-Vehicle-
Physik ist buggy, kein natives "gezogenes" Fahrzeug). Stattdessen das
**Fahrrad-Mod-Prinzip**: ausrüstbares Item (beide Hände belegt = ziehen) +
Lua für Tempo (Walk/Run-Modifier) und Logik.

## Vor Gebrauch prüfen (volatil / nicht verifiziert)

Diese Dinge gegen den **aktuellen** Build testen, nicht als Fakt annehmen:

- **`SkillRequired`-Syntax** in craftRecipe (B41-Format `Skill:Stufe` evtl. anders).
- **`keep`-Flag** für Werkzeuge (sonst wird der Hammer beim Craften verbraucht).
- **Tempo-API**: `setWalkSpeedModifier` / `setRunSpeedModifier` – Existenz und
  Wirkung prüfen (in `pcall` kapseln; ggf. aus aktueller Bicycle-Mod abschauen).
- **Methodennamen** wie `getClothingItem_Back()` – gegen die aktuelle API prüfen.
- **Container + FluidContainer** am selben Item – ob die Kombination sauber läuft.
- **`scale`-Umrechnung** Blender-Meter → PZ – empirisch im Spiel einstellen.
- **`category`-Namen** und ob ungültige Kategorien einen Tab erzeugen oder Fehler werfen.

## Schneller In-Game-Test (auch für Nicht-Spieler)
Hauptmenü → "Mehr…" → **Debug** an → Spiel laden → Käfer-Symbol links →
Item-Browser → Item-Namen suchen → spawnen → auf Boden legen, um das Weltmodell
zu sehen.
