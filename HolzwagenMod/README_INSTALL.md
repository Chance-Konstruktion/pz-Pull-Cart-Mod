# Holzwagen – Installation & Test (morgen)

## 1. Mod installieren
Den Ordner `HolzwagenMod` kopieren nach:
`C:\Users\Chris\Zomboid\mods\HolzwagenMod`
Dann im Spiel unter **Mods** aktivieren und ein neues Sandbox-Spiel starten.

## 2. Das eine fehlende Teil (Modell) – mit PZ
WICHTIG: Den ZomboidAssetConverter brauchst du dafuer NICHT. Der geht in die
andere Richtung (PZ-Assets -> Blender), ist ein Assimp-Wrapper.

PZ importiert Modelle ueber Assimp; FBX ist seit B41 ein unterstuetztes Format.
- `holzwagen.fbx` (aus `C:\Users\Chris\HolzwagenExport\`) nach `42/media/models_X/` legen.
- Textur liegt schon unter `42/media/textures/holzwagen_tex.png`.
- Der `model`-Block in `scripts/holzwagen_items.txt` verweist bereits darauf.

VERIFY mit installiertem PZ (geht erst morgen): ob B42 die FBX direkt laedt oder
eine `.X`-Konvertierung will, und wie der `mesh =`-Pfad exakt heissen muss. Falls
der Wagen unsichtbar bleibt, im `model`-Block den Pfad/das Format anpassen oder
kurz im PZ-Modding-Discord nachfragen. Ohne Modelldatei laeuft der Mod, der Wagen
ist dann nur funktional (Platzhalter/unsichtbar).

## 3. Was alles fertig ist
- Items: Holzwagen T1/T2, Räder T1/T2, Speichenrad-Gestell
- Rezepte: Wagenkasten T1/T2, T1→T2-Upgrade, Räder (Holz/Stein), Schmiede-Pfad fürs T2-Rad
- Logik: Ziehen/Loslassen, Tempo 80%/100% je nach Rädern, Taschen-Slots
  (einhängen, entnehmen, Inhalt mit Rücken-Rucksack tauschen), Kontextmenüs

## 4. Verify-Checkliste (5 Minuten beim ersten Laden)
Weil B42 noch Unstable ist und die offizielle API-Doku gesperrt war, gibt es
genau **drei** Stellen, die du beim ersten Test kurz prüfen solltest:

1. **Lädt der Mod sauber?** Konsole (Optionen → Debug, oder `console.txt`)
   auf rote Fehler prüfen. Tippfehler im Rezept-Format sind die häufigste Ursache.

2. **Tempo-Funktion** – die EINZIGE unsichere API. In
   `42/media/lua/client/Holzwagen_Main.lua`, Funktion `HW.applySpeed`:
   stehen dort `setWalkSpeedModifier` / `setRunSpeedModifier`. Falls das Ziehen
   das Tempo NICHT verändert, schau in die **Bicycle-Mod**, wie sie das macht,
   und ersetze die zwei Zeilen entsprechend. Alles andere bleibt unberührt
   (durch `pcall` lädt der Mod auch bei falschem Namen, nur ohne Tempo-Effekt).

3. **Rezept-Felder** – `timedActionType`, `mode:keep`, `needTobeLearn` gegen
   die laufende 42.x abgleichen, falls ein Rezept nicht auftaucht.

## 5. Bekannte Design-Grenzen
- B42 deckelt Item-Container hart bei 50. Die 150/300 „Ladevolumen" laufen
  daher über die Taschen-Slots (Rucksäcke im Wagen), nicht über rohe Capacity.
  Wenn du echte 150/300 willst, ist der gleiche Bypass nötig wie bei
  Wheelbarrow/Bicycle (eigener Schritt).
- Modell-Maßstab/Rotation im `model`-Block (`scale = 0.32`) nach erstem
  Blick justieren – PZ-Achsen ≠ Blender.

## 6. Fasswagen (Flüssigkeits-Variante)
Umbau aus dem T2-Wagen: **T2 + Fass + Schlauch + Trichter** → Fasswagen
(`scripts/holzwagen_fasswagen.txt`). Das Fass ist fest verbaut (450er Fluid-Tank,
Wasser/Benzin/Milch u. a.), dafür nur noch **3 Taschen-Slots** statt 4. Rückbau
zu T2 ist möglich (Fass bleibt erhalten). Fass/Schlauch/Trichter sind craftbar.

Befüllen/Ablassen läuft über PZs eigene Fluid-Mechanik (Zapfen/See/Umfüllen) –
der Schlauch und Trichter sind Bau-Komponenten.

VERIFY (im `holzwagen_fasswagen.txt` markiert): ob B42 ein Item gleichzeitig als
Taschen-Container UND Fluid-Container erlaubt. Falls nicht, in
`Holzwagen_Config.lua` den Schalter `fassUsesSeparateBagContainer` auf `true`
setzen – dann hängen die 3 Taschen an einem separaten Container. Außerdem die
Fluid-Namen (Milk etc.) gegen die laufende B42-Fluid-Liste prüfen.
