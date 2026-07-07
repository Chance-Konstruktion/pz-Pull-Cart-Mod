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
- [x] **Poster-Bild** (`poster.png`) – neu gerendert aus dem echten T2-Modell
      (einachsig, abgestellte Pose, `tools/holzwagen_poster.py`).
- [x] **Sound-Effekte** beim Ziehen – drei prozedural synthetisierte
      Roll-Loops je Stufe inkl. Knarzen (`tools/holzwagen_sounds.py`).
- [x] **Sichtbare Taschen am Modell.** Leder-Satteltaschen je Seite vor/hinter
      dem Rad, Fasswagen mit Schlauch-Rolle (`tools/holzwagen_taschen.py`).
      Immer sichtbar (PZ kann Hand-Props nicht dynamisch umbauen).
- [ ] **Zieh-Animation** statt nur belegter Hände (siehe Motion-Blur-Punkt:
      eigene Animationen für Hand-Props sind in PZ B42 nicht möglich – höchstens
      über eine eigene Push-Pose, kein aktiver Plan).

## 🚀 Ideen / später

- [ ] Weitere Varianten: **Planwagen** (Segeltuch, drin schlafen?) und
      **tiergezogene Version**. (Schubkarre gestrichen: kein Vorteil gegenüber
      dem Ziehwagen.)
- [ ] Steam-Workshop-Release mit Preview-Bildern (Poster ist fertig).

---

Erledigte Punkte wandern ins [CHANGELOG](CHANGELOG.md).
