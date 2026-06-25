---
name: pz-b42-mod-loading
description: >
  Hilft, einen Project-Zomboid-Build-42-Mod zum Laden UND korrekt funktionieren
  zu bringen (Singleplayer und Multiplayer). Nutze diesen Skill, wenn ein B42-Mod
  ein rotes X im Mod-Menü zeigt, beim Start crasht ("Script load errors",
  "item not found"), wenn craftRecipes/Items nicht laden, wenn Crafting läuft
  aber NICHTS erzeugt (Material wird zurückgelegt), wenn etwas nur im Singleplayer
  aber nicht im Multiplayer geht, wenn ein 3D-Modell unsichtbar/zu groß ist, oder
  wenn ein zieh-/schiebbarer Wagen/Karren gebaut werden soll (in die Hand nehmen,
  schieben, Tempo, Ladefläche). Deckt Ordnerstruktur, mod.info, craftRecipe-Syntax
  (B42 base:-Tags!), Item-/FluidContainer-Defs, client/shared/server-Trennung,
  Modell-/Textur-Einbindung und die Schiebe-Wagen-Mechanik ab.
  NICHT für Build 41 und nicht für Engine-Fahrzeuge.
---

# Project Zomboid – Build 42 Mod zum Laden & Funktionieren bringen

> Verifiziert gegen **B42 42.19 (unstable)**, Juni 2026, anhand echter Vanilla-
> Scripts (ProfLiebstrumpf/B42.16), dem dekompilierten Quellcode (PAVE44/b42.15-src)
> und funktionierender Community-Mods (SaucedCarts, ZuperCarts/TMC). B42 ist
> instabil – im Zweifel gegen den aktuellen Build testen und **console.txt** lesen
> (`%userprofile%\Zomboid\console.txt`). Bei Multiplayer ZUSÄTZLICH das **Server-Log**.

## Diagnose-Reihenfolge (außen → innen)

1. **Rotes X, lässt sich nicht aktivieren** → mod.info / Struktur. Mod-Name taucht
   im Log gar nicht auf.
2. **Crash beim Start, "Script load errors" / "item not found"** → Skript-Syntax.
3. **Crafting läuft, erzeugt aber NICHTS (Material kommt zurück)** → siehe eigenen
   Abschnitt unten. Häufigste echte Bug-Quelle in B42!
4. **Geht im Singleplayer, aber NICHT im Multiplayer** → client/shared/server-
   Trennung oder Server hat alte/keine Mod-Version. Eigener Abschnitt unten.
5. **Lua-Fehler mit Zeilennummer** → Lua-Syntax.
6. **Lädt durch, aber Modell unsichtbar/falsch groß** → Textur-Alpha / mesh-Pfad / scale.

Immer zuerst console.txt nach dem **eigenen Mod-Namen** und nach `ERROR`/`STACK TRACE`/
`removing script` durchsuchen. Vanilla-Warnungen ignorieren.

## Ordnerstruktur
```
ModName/
  42/
    mod.info
    poster.png
    media/
      scripts/      *.txt
      lua/shared/   (läuft Client UND Server – siehe MP!)
      lua/client/   (NUR Client)
      lua/server/   (NUR Server)
      models_X/     *.fbx / *.glb / *.x   (Ordner heißt models_X)
      textures/     *.png
      AnimSets/player/...   (nur bei eigenen Animationen)
      anims_X/...           (nur bei eigenen Animationsclips)
```

## mod.info
- Gültiges `poster=poster.png` UND die Datei im 42-Ordner, sonst rotes X.
- **Keine leeren Felder** (`require=` ohne Wert weglassen).
- `id=` ist die ID für die Server-Modliste (NICHT der Anzeigename `name=`).
- Minimal: `name=`, `id=`, `description=`, `poster=poster.png`, `author=`.

## craftRecipe-Syntax (B42 – wich­tigste Fallen)

Vorlage = Vanilla `recipes_carpentry.txt` (z. B. MakeWoodenToolbox). Vollständig
ladefähig und **erzeugt auch wirklich etwas**:
```
module Base
{
    craftRecipe Mein_Rezept
    {
        timedAction = Making,                 /* PFLICHT bei Hand-Craft */
        time = 120,
        Tags = AnySurfaceCraft;Carpentry,     /* macht es ueberall craftbar/sichtbar */
        category = Carpentry,
        SkillRequired = Woodwork:1,           /* B42: Perk-Name:Stufe (Woodwork, nicht Carpentry) */
        xpAward = Woodwork:10,
        inputs
        {
            item 1 tags[base:hammer] mode:keep flags[MayDegradeVeryLight],
            item 1 tags[base:saw;base:smallsaw;base:crudesaw] mode:keep flags[MayDegradeLight],
            item 15 [Base.Plank] flags[Prop2],   /* INPUTS: eckige Klammern */
        }
        outputs
        {
            item 1 Base.MeinItem,                 /* OUTPUTS: OHNE Klammern */
        }
    }
}
```

Die harten Regeln (jede einzeln verursacht „lädt nicht" ODER „erzeugt nichts"):

- **Werkzeug-Tags brauchen das `base:`-Präfix, kleingeschrieben.** `tags[base:hammer]`,
  `tags[base:saw;base:smallsaw;base:crudesaw]`, `tags[base:drillwood;...]`.
  ⚠️ **`tags[Hammer]`/`tags[Saw]` (B41-Stil) matchen in B42 KEIN Werkzeug** → die
  Anforderung ist unerfüllbar, der Balken läuft durch, committet aber nicht, und
  Material + Werkzeug landen zurück im Inventar – **ohne Fehlermeldung**. Das ist
  DER stille Crafting-Killer.
- **`timedAction` ist Pflicht** für Hand-Craft (`Making` ist die generische Aktion).
- **`Tags = AnySurfaceCraft;Carpentry`** – ohne `AnySurfaceCraft` erscheint das
  Rezept in keinem Menü.
- **Werkzeug erhalten:** `mode:keep flags[MayDegradeLight]` (sonst wird der Hammer
  verbraucht). Verifiziert.
- **`SkillRequired = Woodwork:1`** + **`xpAward = Woodwork:10`** ist gültige B42-
  Syntax (Perk heißt **Woodwork**, nicht Carpentry). Rezepte sind per Default
  „bekannt" (kein `NeedToBeLearn` nötig), solange kein Skill fehlt.
- **Outputs OHNE eckige Klammern, Inputs MIT.** `item not found: [Base.X]` =
  Klammern im Output-Namen.
- Ein referenziertes Item, das **nicht existiert, reißt den ganzen Load ab**.
  ⚠️ **`Base.Stone` existiert in 42.19 NICHT** (typische Falle).
- `Time` vs `time`: Vanilla schreibt `time` (klein) – im Zweifel klein.

## ⚠️ Crafting läuft, erzeugt aber NICHTS (Material kommt zurück)

Reihenfolge der Verdächtigen:
1. **Werkzeug-Tags** `tags[base:hammer]` statt `tags[Hammer]` (s. o.) – Top-Ursache.
2. **`timedAction` fehlt.**
3. **Output-Item existiert serverseitig nicht** (Multiplayer – s. u.).
4. Output mit eckigen Klammern / Tippfehler im Item-Namen.

## ⚠️ Multiplayer: geht im SP, nicht im MP

In B42-MP **validiert und erzeugt der SERVER** das Craft-Item. Daraus folgen die
zwei häufigsten MP-Bugs:

1. **Vom Item-Script referenzierte Lua liegt in `lua/client/`.** Beispiel:
   `AcceptItemFunction = MeineFunktion` im Item. Der **Server führt `client/`-Lua
   nicht aus** → die Funktion fehlt serverseitig → Item-Erzeugung/Validierung
   scheitert → Material kommt zurück. **Fix:** alles, was Scripts referenzieren
   (AcceptItemFunction, OnCreate, OnTest …) und alle gemeinsamen Helfer nach
   **`lua/shared/`** legen. `client/` nur für reine UI/Input-Logik.
2. **Server hat eine alte/keine Mod-Version.** Mod muss auf dem Server liegen,
   in der Server-INI als `Mods=<id>` stehen, und der Server muss **neu gestartet**
   werden (Reconnect reicht nicht). Beim **In-Game-Host** hat der Host eine
   **eigene Mod-Liste** im Host-Menü – dort separat aktivieren.
   Schnelltest: Server-Kopie des Rezepts auf `tags[base:hammer]` prüfen.

Weitere MP-Regeln: Spieler-spezifische Effekte (Tempo etc.) immer mit
`if player.isLocalPlayer and not player:isLocalPlayer() then return end` schützen.
Item-`modData` reist mit dem Item mit (MP-sicher).

## Items
- `Type = Container` funktioniert; alternativ B42-Form `ItemType = base:container`.
- **Container-Capacity ist im Script faktisch bei ~50 gedeckelt.** Für „großes
  Volumen": `WeightReduction = 100` (Inhalt wiegt nichts) und die Capacity zur
  **Laufzeit** setzen: in `OnPlayerUpdate` `item:getItemContainer():setCapacity(N)`.
- `FluidContainer`-Komponente: **`ContainerName` ohne Leerzeichen**.
- Container + FluidContainer am selben Item läuft (verifiziert beim Fasswagen-Ansatz).

## Modelle & Texturen
- **FBX, GLB und .X** werden direkt unterstützt; **`.obj` NICHT** (weglassen).
- `mesh = name` ist relativ zu `media/models_X/` (Unterpfade möglich:
  `mesh = weapons/2handed/foo|MeshName`, der Teil hinter `|` ist der interne
  FBX-Mesh-Name).
- `texture = name` relativ zu `media/textures/`.
- **Modellname im `model`-Block darf das Wort „model" NICHT enthalten.**
- **Unsichtbar trotz geladenem Mesh? Zuerst den Textur-Alpha-Kanal prüfen!**
  Ein Atlas mit Alpha = 0 (voll transparent) rendert das Modell unsichtbar,
  obwohl RGB-Farben da sind und KEIN Lade-Fehler im Log steht. (Realer Bug dieser
  Session.) Alpha auf 255 setzen.
- **Skalierung:** Ein in Blender in **echten Metern** gebautes Mesh als FBX wird
  von PZ **~100–1000× zu groß** interpretiert. Praxiswerte für einen ~2 m Wagen:
  `scale` um **0.001–0.006**. Erst sichtbar machen, dann empirisch feinjustieren.

## Schiebe-/Zieh-Wagen (Karren, Trolley, Schubkarre)

**Kein Engine-Fahrzeug** (B42-Vehicle-Physik ungeeignet, kein natives „gezogenes"
Fahrzeug). Bewährter Weg (SaucedCarts / ZuperCarts) = **ausrüstbares Container-Item
+ Engine-Felder + Animations-Masken**:

Im Item-Script:
```
ItemType = base:container,   (oder Type = Container)
WeightReduction = 100,
RunSpeedModifier = 0.85,                          /* Tempo-Bremse, von der Engine */
StaticModel = MeinModell,
WorldStaticModel = MeinModell,
ReplaceInPrimaryHand = MeinModell holdingtrolleyright,
ReplaceInSecondHand  = MeinModell holdingtrolleyleft,
```
Dazu in Lua (client) beim Anschirren:
```lua
playerObj:setPrimaryHandItem(item)
playerObj:setSecondaryHandItem(item)
playerObj:setVariable("RightHandMask", "holdingtrolleyright")
playerObj:setVariable("LeftHandMask",  "holdingtrolleyleft")
```
Und mitliefern: die AnimSet-Masken (`AnimSets/player/.../holdingtrolley*.xml`,
`walktrolley*`, `runtrolley*` …) und die Animationsclips (`anims_X/.../*Trolley*.X`).
Die Masken referenzieren die Clips (`Bob_IdleTrolley`, `Bob_WalkTrolley`).

- **Tempo:** `RunSpeedModifier` im Item ist der saubere, automatisch MP-sichere Weg.
  ⚠️ `setWalkSpeedModifier` / `setRunSpeedModifier` **existieren NICHT**. Falls man
  doch per Lua skaliert: `IsoGameCharacter:setSpeedMod(mult)` existiert, muss aber
  **jeden Tick** neu gesetzt werden (Bewegungssystem resettet ihn) → meist
  unnötig, `RunSpeedModifier` bevorzugen.
- **In-Hand-Position/Größe** ist Feintuning: hängt an `scale` und den Hand-Offsets
  des Modells; das fremde Mesh ist passend gerigt, ein eigenes muss nachjustiert
  werden.

## Lua-Fallen
- Methoden-**Existenzcheck mit Punkt**, **Aufruf mit Doppelpunkt**:
  ```lua
  local x = player.getDing and player:getDing() or nil
  ```
  `player:getDing and ...` ist ein Syntaxfehler.
- **client vs shared vs server** ist in B42-MP entscheidend (s. MP-Abschnitt).
- Verifizierte APIs (42.15-Quelle): `InventoryContainer:getInventory()`,
  `ItemContainer:getContentsWeight()`/`getCapacity()`/`setCapacity()`,
  `getClothingItem_Back()`, `IsoPlayer:isLocalPlayer()`,
  `IsoGameCharacter:setSpeedMod(float)`.

## Schneller In-Game-Test
Hauptmenü → „Mehr…" → **Debug** an → Spiel laden → Käfer-Symbol → Item-Browser →
Item suchen → spawnen → ablegen, um das Weltmodell zu sehen. (Der Item-Browser hat
in manchen 42.x-Builds einen vanilla Crash – dann per Lua-Konsole spawnen.)
