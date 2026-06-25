# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added
- **Welt-Interaktion am abgestellten Wagen.** Rechtsklick auf das stehende
  3D-Modell bietet jetzt „Wagen öffnen" (hinlaufen + Loot-Fenster), „Wagen
  aufnehmen" und „Wagen aufnehmen + ziehen". Ein abgelegter `Type=Container`
  zeigt sein Inventar ohnehin im Boden-/Loot-Fenster – das Modell bleibt das
  3D-Mesh (kein Tile-Sprite-Umbau). Defensiv ge-guarded (`ISGrabItemAction`,
  `getPlayerLoot`), bricht sauber ab statt zu crashen, falls eine API fehlt.
- **Multiplayer-Absicherung:** Tempo-Logik wirkt jetzt ausschließlich auf den
  eigenen Spieler (`isLocalPlayer`-Guard), nie auf Remote-Spieler. Rezepte laufen
  serverseitig, Taschen-Transfers über synchronisierte Timed Actions, und die
  Wagen-Zustände (`pulling`/`wheelTier`/`bags`) liegen in der Item-modData, die
  mit dem Item mitwandert – damit ist der Mod MP-tauglich ausgelegt.
- **Stauraum-Design überarbeitet:** alle Wagen haben jetzt **4 seitliche
  Taschen-Slots**. Normaler Wagen: offene Loot-Ladefläche zusätzlich. Fasswagen:
  Bett vom Fass belegt – **keine lose Ladung** (`bedLocked`), nur die 4 Taschen.
  Durchgesetzt über `AcceptItemFunction` (nur Container-Items auf gesperrtem Bett).
- **Gewichtsabhängiges Tempo** (vorbereitet, standardmäßig AUS): voll beladener
  Wagen zieht langsamer. Aktivierbar über `HolzwagenConfig.weightSpeed.enabled`,
  Stärke über `fullPenalty`. Nutzt die verifizierte API
  `ItemContainer:getContentsWeight()` / `getCapacity()`.
- Skill-Gating für alle Rezepte (`SkillRequired` + `AutoLearnAny`, Woodwork 2–5).
- Werkzeuge (Säge/Hammer) bleiben beim Bauen erhalten
  (`mode:keep flags[MayDegradeLight]`) statt verbraucht zu werden.
- 3D-Modelle (GLB) für T1, T2 und Fasswagen aktiviert und an die Items verdrahtet
  (`WorldStaticModel`).
- Projekt-Dokumentation: `CHANGELOG.md`, `ROADMAP.md`, strukturierte `docs/`.

### Changed
- **Test-Modus für Rezepte:** alle Bau-Rezepte vorübergehend auf **1 Baumstamm
  + Werkzeug** und **Woodwork 1** reduziert, damit das Craften schnell
  durchgetestet werden kann. Das echte Material-/Skill-Balancing folgt danach –
  das sind reine Zahlen im Rezeptbaum ohne Code-Einfluss.
- `scale`-Startwert der Modelle von `0.32` auf `1.0` korrigiert
  (Modelle sind in echten Metern gebaut, Wagen ≈ 2,2 m).
- Modell-Namen B42-konform ohne das Wort „model" (`wagenT1`/`wagenT2`/`wagenFass`),
  Mesh-Pfade relativ zu `media/models_X/` (ohne `WorldItems/`-Unterordner).
- Dev-Doku nach `docs/` verschoben, Blender-Skript nach `tools/`.

### Changed
- **Schieben/Tempo auf Engine-Felder umgestellt** (Vorbild: funktionierender
  B42-Mod *SaucedCarts*). Statt das Ziehen per Lua nachzubauen, nutzen die
  Wagen-Items jetzt `RequiresEquippedBothHands = TRUE` (beide Hände = schieben,
  von der Engine, automatisch MP-sicher) und `RunSpeedModifier` (Tempo-Bremse:
  T1 0.80, T2 0.90, Fasswagen 0.75). `TwoHandWeapon` entfernt. Die Lua-Tempo-
  Logik (`setSpeedMod` pro Tick) ist damit überflüssig und als No-Op stillgelegt.
  `WeightReduction` auf 95 erhöht (viel Ladung tragbar, wie bei SaucedCarts).
  Ausrüsten geschieht jetzt über das normale „Anlegen (beide Hände)".

### Fixed
- **Crafting im Multiplayer behoben (DER MP-Bug).** Die Wagen-Items referenzieren
  im Script `AcceptItemFunction = HolzwagenAccept`. Diese Lua-Funktion lag nur in
  `media/lua/client/` – der **Server** führt `client/`-Lua aber nicht aus. Im MP
  erzeugt/prüft der Server das Item beim Craften, fand `HolzwagenAccept` nicht und
  brach ab (Material verbraucht und zurückgelegt, nichts erstellt); im Singleplayer
  lief alles auf dem Client, daher funktionierte es dort. `HolzwagenAccept` samt
  Helfern (`isCart`/`cartTier`/`wheelTier`/`loadFactor`/`isBagItem`/`bedLocked`)
  nach **`media/lua/shared/Holzwagen_Core.lua`** verschoben → lädt auf Client UND
  Server.
- **Modell ~1000x zu groß korrigiert.** `scale` der Weltmodelle von `1.0` auf
  `0.001` gesetzt. PZ interpretiert die FBX-Einheiten des in echten Metern
  gebauten Wagens (~2,2 m) nicht als Meter; bei `1.0` erschien er riesig.
  Feintuning über den `scale`-Wert in `holzwagen_items.txt`/`_fasswagen.txt`.
- **Modell unsichtbar / durchsichtiger Platzhalter behoben.** Der Textur-Atlas
  `holzwagen_tex.png` war zu 99 % vollständig transparent (Alpha-Kanal komplett
  auf 0, RGB-Farben aber vorhanden). PZ rendert Weltmodelle mit Alpha 0
  unsichtbar – das Mesh lud korrekt (kein Lade-Fehler im Log), war aber durchweg
  durchsichtig. Alpha-Kanal des Atlas auf voll undurchsichtig (255) gesetzt,
  RGB unverändert.
- **Crash beim Taschen-Einhängen behoben** (`attachBag`/`detachBag`/`swapContents`,
  `Object tried to call nil`). Container-Zugriff (`cart:getInventory()`) läuft jetzt
  über einen abgesicherten Helfer mit Methoden-Check; fehlt der Container, bricht die
  Aktion sauber ab und schreibt eine klare Log-Meldung statt zu crashen.
- **Crafting erzeugte nichts – falsche Werkzeug-Tags (DER Bug).** Rezepte
  referenzierten Werkzeuge als `tags[Hammer]` / `tags[Saw]`. In B42 heißen die
  Tags `base:hammer` bzw. `base:saw;base:smallsaw;base:crudesaw` (kleingeschrieben,
  mit `base:`-Präfix). Das alte Format matchte kein Werkzeug → die Anforderung war
  unerfüllbar, der Craft committete nicht (Balken lief, Material+Werkzeug zurück,
  kein Fehler). Alle Rezepte exakt an die Vanilla-Carpentry-Rezepte
  (MakeWoodenToolbox/-Bucket aus den entpackten B42.16-Dateien) angeglichen:
  `timedAction = Making`, `Tags = AnySurfaceCraft;Carpentry`, korrekte Werkzeug-Tags.
- **Crafting erzeugte nichts – Pflichtfeld `timedAction` ergänzt.** Hand-Craft-
  Rezepte in B42 brauchen ein `timedAction`; ohne das lief der Balken durch, die
  Aktion committete aber nicht (Material zurück, kein Ergebnis, kein Fehler).
  Allen Rezepten `timedAction = Making` (generische Vanilla-Crafting-Aktion)
  hinzugefügt.
- **Crafting erzeugte nichts** (Balken lief durch, Material kam zurück, kein
  Fehler). Skill-/Lern-Gate als Ursache isoliert: für diese Testrunde das
  Skill-Gating (`SkillRequired`/`AutoLearnAny`) entfernt → Rezepte sind von jedem
  craftbar. Außerdem Feldname `Time` → `time` (Vanilla-Schreibweise) korrigiert.
  Sinnvolle Woodwork-Stufung kommt nach bestätigtem Craften zurück.
- **Rezepte erschienen nicht im Crafting-Menü.** Allen craftRecipes fehlte der
  Tag `tags = AnySurfaceCraft` – dadurch waren sie nirgends sichtbar (weder unter
  Carpentry noch per Suche). Jetzt überall craftbar.
- **Crash bei Kontextmenü/Item-Interaktion behoben.** `HW.isCart` rief `hasTag()`
  auf jedem Item auf; bei manchen Klassen (z. B. `ComboItem`) wirft das einen
  Fehler. Wagen-Erkennung läuft jetzt über den Item-Typ statt über Tags.
- **Tempo-Steuerung repariert.** `HW.applySpeed` rief zuvor geratene, nicht
  existierende Methoden (`setWalkSpeedModifier`/`setRunSpeedModifier`) in einem
  `pcall` auf – der Tempo-Effekt lief dadurch wirkungslos durch. Jetzt über die
  echte B42-API `IsoGameCharacter:setSpeedMod(mult)`, mit einmaligem
  Capability-Check, der eine fehlende API sichtbar ins Log schreibt statt sie
  zu verschlucken.
- Kaputtes Stein-Rad-Rezept entfernt: referenzierte `Base.Stone`, das es in
  B42 42.19 nicht gibt und beim Laden einen `WorldDictionary`-Fehler warf.

### Verified
- `getClothingItem_Back()` als gültige B42-API bestätigt (Slots-Logik,
  bereits feature-guarded).
- B42-Rezept-Syntax (`SkillRequired`, `mode:keep`) gegen Vanilla-Rezepte
  abgeglichen.

## [0.1.0] – Erststand

### Added
- Ziehbarer einachsiger Holzwagen nach dem Fahrrad-Mod-Prinzip
  (ausrüstbares Item, beide Hände = ziehen) für Project Zomboid Build 42.
- Zwei Stufen: T1 (Vollholzrad, 80 % Tempo), T2 (Speichenrad, 100 % Tempo).
- Fasswagen-Variante mit fest verbautem Flüssigkeits-Container (450 Einheiten).
- Seitliche Taschen-Slots (T1: 2, T2: 4, Fasswagen: 3).
- Rezepte für Bau, Upgrade T1→T2 und Fasswagen-Umbau/-Rückbau.
- Zentrale Balance-Konfiguration (`Holzwagen_Config.lua`).

[Unreleased]: https://github.com/Chance-Konstruktion/pz-Holzwagen-mod-/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Chance-Konstruktion/pz-Holzwagen-mod-/releases/tag/v0.1.0
