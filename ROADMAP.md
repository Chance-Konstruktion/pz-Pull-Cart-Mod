# Roadmap

Der Plan für den Holzwagen, grob nach Priorität. Reihenfolge und Umfang sind
nicht in Stein gemeißelt – Feedback per Issue ist willkommen.

## 🎯 Als Nächstes (In-Game-Test & Feinschliff)

- [ ] **In-Game-Feedback zum aktuellen Stand einholen** – Kippung (Griff hoch
      in der Hand / am Boden abgestellt), neue Texturen/Icons, Fasswagen-Fluss
      (Schlauch, Regen, 140 L), Ladefläche >50, Gewicht-Tempo, Zaun-/Tür-Sperre.
- [ ] **Multiplayer-Test** mit einer zweiten Person (Drop-Sync, Anschirren,
      Aktions-Sperren) – Code ist dafür vorbereitet, aber noch nicht live getestet.
- [ ] **Balancing-Pass** für Skill-Stufen, Materialkosten, Bauzeiten und
      Reparaturkosten – bewusst zurückgestellt bis der Rest steht.

## ✅ Erledigt (Kernfunktion & Substanz)

- [x] Tempo-API über echte B42-Funktion (`RunSpeedModifier`), gewichtsabhängige
      Verlangsamung (`HolzwagenConfig.weightSpeed`, standardmäßig AN).
- [x] Kapazitäts-Bypass über das B42-Container-Limit (~50) hinaus
      (`ISInventoryTransferAction`/`ISInventoryPane`-Overrides).
- [x] Taschen-Slots pro Tier konfigurierbar (T1/T2: 4, Fasswagen: 3 + Schlauch-Slot).
- [x] Annahme-Filter in `HolzwagenAccept` (Bett-Sperre beim Fasswagen, Taschen-Limit).
- [x] Fasswagen-Fluidmechanik: alle Flüssigkeiten, Schlauch-Pflicht,
      Regenwasser-Sammlung, 140-L-Kappe (B42-Engine-Limit empirisch ermittelt).
- [x] Schnell-Ausrüsten mit `V`/`E` inkl. kurzer Anschirr-Zeit; blockiert
      Zaun-Klettern/Fenster/Türen solange der Wagen ausgerüstet ist.
- [x] Leichen-Transport, Radverschleiß + Reparatur (Bretter+Nägel+Hammer),
      Füllstand/Zustand direkt im Item-Namen.
- [x] MP-sichere Drop-/Pickup-Pfade (vanilla synchronisierte Aktionen).
- [x] Performance: ein zentraler, throttled Update-Handler statt mehrerer
      Tick-Listener.

## ✨ Politur (spürbarer Feinschliff)

- [x] **Handgriff-Kippung.** Zwei gebackene Modell-Varianten pro Wagen: in der
      Hand 10° Griff hoch, abgestellt 15,8° Griff auf dem Boden
      (`tools/holzwagen_world_tilt.py`).
- [x] **Motion-Blur-Speichenräder** (T2 + Fasswagen) – echte Rad-Animation ist
      in PZ B42 technisch nicht möglich (bestätigt), Blur-Textur als Ersatz.
- [x] **Echte Holz-Texturen** (Maserung, Brettfugen, Astlöcher) für alle Wagen.
- [x] **Eigene Item-Icons** für alle 9 Items statt Platzhalter (`Crate`/`Wheel`).
- [ ] **Poster-Bild** (`poster.png`) für den Workshop – zeigt aktuell einen
      Wagen mit zwei Achsen, unser Wagen ist einachsig. Noch nicht erstellt.
- [ ] **Sound-Effekte** beim Ziehen (Rollen/Knarzen) – Grundgerüst
      (`HolzwagenConfig.sound`) steht, echte Sound-Dateien fehlen noch.
- [ ] **Sichtbare Taschen am Modell.** Die Taschen-Slots sind aktuell rein
      logisch (Rechtsklick-Menü). Sie sichtbar am Wagen zu rendern (vor/hinter
      den Rädern) erfordert eigene Modell-Attachments.
- [ ] **Zieh-Animation** statt nur belegter Hände (siehe Motion-Blur-Punkt:
      eigene Animationen für Hand-Props sind in PZ B42 nicht möglich – höchstens
      über eine eigene Push-Pose, kein aktiver Plan).

## 🚀 Ideen / später

- [ ] Weitere Varianten: Schubkarre, Planwagen (Segeltuch), tiergezogene Version.
- [ ] Steam-Workshop-Release mit Preview-Bildern (inkl. korrigiertem Poster).

---

Erledigte Punkte wandern ins [CHANGELOG](CHANGELOG.md).
