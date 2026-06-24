# VOR DEM TESTEN – Was noch zu tun ist

## Schon erledigt (musst du nicht mehr machen)
- Komplette B42-Struktur, mod.info
- Items: Wagen T1/T2, Räder, Fasswagen + Fluid-Container + Komponenten
- Rezepte: Wagenkasten T1/T2, T1→T2-Upgrade, Räder (Holz/Stein), Speichenrad
  über Schmiede, Fasswagen-Umbau, Rückbau
- Lua: Ziehen + Tempo, Taschen-Slots, Konfig
- Textur (`holzwagen_tex.png`) – wird von BEIDEN Modellen genutzt
- BEIDE Modelle als Geometrie: `models_X/holzwagen.glb/.obj` und
  `models_X/holzwagen_fass.glb/.obj`
- model-Blöcke verdrahtet (Fasswagen zeigt auf `holzwagen_fass`)

## Nur DU kannst das (braucht deinen PC / PZ)

### 1. Modelldateien final ins Format bringen
PZ will am sichersten **FBX**. Du hast bereits `holzwagen.fbx` (aus unserer
Blender-Session). Für den Fasswagen EINE der beiden Optionen:
- (A) `holzwagen_fass_blender.py` in Blender ausführen → `holzwagen_fass.fbx`, ODER
- (B) die beiliegende `models_X/holzwagen_fass.glb` in Blender importieren und
  über Datei → Exportieren → FBX speichern.
Dann `holzwagen.fbx` und `holzwagen_fass.fbx` nach `42/media/models_X/` legen.
(Die `.glb`/`.obj` sind Alternativen/Backup – falls PZ glTF direkt akzeptiert,
kannst du sie sogar direkt probieren. FBX ist der sichere Weg.)

### 2. Mod installieren
- Den Ordner `HolzwagenMod` nach `C:\Users\Chris\Zomboid\mods\` kopieren.
- PZ starten (Build 42 / Unstable), unter **Mods** „Holzwagen (Pull Cart)"
  aktivieren, neues Sandbox-Spiel starten.

### 3. Beim ersten Laden prüfen (die VERIFY-Punkte)
1. **Konsole** auf rote Fehler prüfen (Debug-Modus oder `console.txt`).
   Tippfehler im Rezept-Format sind die häufigste Ursache.
2. **Rezepte da?** Erscheinen Wagen/Räder beim richtigen Skill? (Debug: Items geben)
3. **Ziehen + Tempo:** Kontextmenü „Wagen ziehen" → rüstet es aus und ändert das
   Tempo? Wenn KEIN Tempo-Effekt → `HW.applySpeed` in `Holzwagen_Main.lua`
   nach Vorbild der Bicycle-Mod anpassen (zwei Zeilen). Mod läuft auch so weiter.
4. **Modell sichtbar?** Grau/unsichtbar → mesh-Pfad/Format im model-Block prüfen
   (mit/ohne Endung; falls FBX abgelehnt → das ist die Format-Frage).
5. **Fasswagen:** Lässt er sich bauen? Funktioniert Flüssigkeit? Fehler „Item kann
   nicht Container UND Fluid sein" → in `Holzwagen_Config.lua`
   `fassUsesSeparateBagContainer = true` setzen.
6. **Fluid-Namen** (Milk etc.) gegen die B42-Fluid-Liste prüfen, falls Befüllen hakt.

## Wenn was hakt
Konsolen-Fehlermeldung oder Screenshot hierher kopieren – dann fixen wir gezielt.
Bei einem Unstable-Build sind ein, zwei Nachjustierungen normal.
