# Testing & Verifikation

Kurzanleitung zum Prüfen des Mods im Spiel. Stand: Build 42.19.

## Installation zum Testen

1. Den Ordner `HolzwagenMod` nach `C:\Users\<DU>\Zomboid\mods\` kopieren.
2. PZ starten (Build 42), unter **Mods** „Holzwagen (Pull Cart)" aktivieren,
   neues Sandbox-Spiel starten.

## Schnellspawn (umgeht den Item-Browser)

Der Vanilla-Debug-Item-Browser stürzt in B42 unabhängig vom Mod ab
(`ISItemsListTable.lua`). Stattdessen über die **Lua-Konsole**:

```lua
getPlayer():getInventory():AddItem("Base.Holzwagen_T1")
-- bzw. Base.Holzwagen_T2 / Base.Holzwagen_Fasswagen
```

Alternativ ganz normal craften (Carpentry-Menü, erfordert das jeweilige
Woodwork-Level – siehe [README](../README.md)).

## Verify-Checkliste

1. **Konsole / `console.txt`** auf rote Fehler prüfen. Tippfehler im
   Rezept-Format sind die häufigste Ursache für Load-Probleme.
2. **Rezepte da?** Erscheinen Wagen/Räder beim passenden Woodwork-Level?
3. **Ziehen + Tempo:** Kontextmenü „Wagen ziehen" → rüstet es aus und ändert das
   Tempo? Falls **kein** Tempo-Effekt → `HW.applySpeed` in
   `Holzwagen_Main.lua` an die echte B42-API anpassen (siehe [ROADMAP](../ROADMAP.md)).
   Der Mod läuft auch ohne den Effekt weiter.
4. **Modell sichtbar & richtig groß?** `scale = 1.0` ist der Startwert (Modelle
   sind in echten Metern gebaut). Zu klein → 1.5/2.0, zu groß → 0.6/0.4.
   Unsichtbar/grau → Mesh-Pfad/Format im `model`-Block prüfen.
5. **Fasswagen:** Lässt er sich bauen? Funktioniert Flüssigkeit? Fehler
   „Item kann nicht Container UND Fluid sein" → in `Holzwagen_Config.lua`
   `fassUsesSeparateBagContainer = true` setzen.
6. **Fluid-Namen** (Milk etc.) gegen die B42-Fluid-Liste prüfen, falls Befüllen hakt.

## Modelle

- Format **GLB** (B42 unterstützt es direkt, mischbar mit FBX/.X).
  `.fbx`/`.obj` liegen als Backup bei.
- `mesh` = Dateiname **ohne** Endung, relativ zu `media/models_X/`
  (kein `WorldItems/`-Unterordner).
- Modellname B42-konform **ohne** das Wort „model" (`wagenT1`/`wagenT2`/`wagenFass`).
- Fass-Modell neu generieren: `tools/holzwagen_fass_blender.py` in Blender
  ausführen, oder die beiliegende `.glb` importieren und als FBX exportieren.

## Wenn etwas hakt

Konsolen-Fehlermeldung oder Screenshot ins Issue/den Chat – dann lässt sich
gezielt fixen. Bei einem Unstable-Build sind ein, zwei Nachjustierungen normal.
