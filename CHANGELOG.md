# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added
- Skill-Gating für alle Rezepte (`SkillRequired` + `AutoLearnAny`, Woodwork 2–5).
- Werkzeuge (Säge/Hammer) bleiben beim Bauen erhalten
  (`mode:keep flags[MayDegradeLight]`) statt verbraucht zu werden.
- 3D-Modelle (GLB) für T1, T2 und Fasswagen aktiviert und an die Items verdrahtet
  (`WorldStaticModel`).
- Projekt-Dokumentation: `CHANGELOG.md`, `ROADMAP.md`, strukturierte `docs/`.

### Changed
- `scale`-Startwert der Modelle von `0.32` auf `1.0` korrigiert
  (Modelle sind in echten Metern gebaut, Wagen ≈ 2,2 m).
- Modell-Namen B42-konform ohne das Wort „model" (`wagenT1`/`wagenT2`/`wagenFass`),
  Mesh-Pfade relativ zu `media/models_X/` (ohne `WorldItems/`-Unterordner).
- Dev-Doku nach `docs/` verschoben, Blender-Skript nach `tools/`.

### Fixed
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
