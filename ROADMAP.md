# Roadmap

Der Plan für den Holzwagen, grob nach Priorität. Reihenfolge und Umfang sind
nicht in Stein gemeißelt – Feedback per Issue ist willkommen.

## 🎯 Als Nächstes (Kernfunktion absichern)

- [x] **Tempo-API robust machen.** Erledigt: `HW.applySpeed` nutzt jetzt die
      echte B42-API `IsoGameCharacter:setSpeedMod(mult)` statt geratener Namen im
      `pcall`, mit Capability-Check der eine fehlende API sichtbar loggt.
      → [CHANGELOG](CHANGELOG.md). _In-Game-Wirkung noch zu bestätigen._
- [ ] **In-Game-Verifikation der Modelle.** `scale = 1.0` gegen eine Spielfigur
      prüfen, danach Rotation/Offset feinjustieren.

## 🧱 Substanz (Tiefgang & Balancing)

- [~] **Gewichtsabhängiges Tempo** – implementiert, aber **standardmäßig AUS**
      (`HolzwagenConfig.weightSpeed.enabled`). Nach bestätigtem Basis-Tempo
      einschalten. → [CHANGELOG](CHANGELOG.md)
- [ ] **Radverschleiß** über `modData` – Räder nutzen sich ab und müssen ersetzt werden.
- [ ] **Annahme-Filter** in `HolzwagenAccept` (aktuell `return true`), damit nur
      sinnvolle Güter in den Wagen passen.
- [ ] **Balancing-Pass** für Skill-Stufen, Materialkosten und Bauzeiten.

## ✨ Politur (spürbarer Feinschliff)

- [ ] **Sound-Effekte** beim Ziehen (Rollen/Knarzen).
- [ ] **Zieh-Animation** statt nur belegter Hände.
- [ ] **Poster-Bild korrigieren** – `poster.png` zeigt aktuell einen Wagen mit
      **zwei Achsen**, der Wagen ist aber einachsig. Das 3D-Modell selbst ist korrekt
      einachsig; nur das Menü-Vorschaubild muss ersetzt werden.
- [ ] **Sichtbare Taschen am Modell.** Die seitlichen Taschen-Slots sind aktuell
      rein logisch (Rechtsklick-Menü). Sie an festen Positionen (vor/hinter den
      Rädern) sichtbar am Wagen zu rendern, erfordert eigene Modell-Attachments.
- [ ] **Eigene Item-Icons** statt der Platzhalter (`Crate`/`Wheel`).
- [ ] **Bessere Texturen** / Material-Varianten.

## 🚀 Ideen / später

- [ ] Weitere Varianten: Schubkarre, Planwagen (Segeltuch), tiergezogene Version.
- [ ] Multiplayer-Test und ggf. Sync-Anpassungen.
- [ ] Steam-Workshop-Release mit Preview-Bildern.

---

Erledigte Punkte wandern ins [CHANGELOG](CHANGELOG.md).
