# Roadmap

Der Plan für den Holzwagen, grob nach Priorität. Reihenfolge und Umfang sind
nicht in Stein gemeißelt – Feedback per Issue ist willkommen.

## 🎯 Als Nächstes (Kernfunktion absichern)

- [ ] **Tempo-API robust machen.** `HW.applySpeed` nutzt aktuell geratene
      Methodennamen in einem `pcall`. Gegen die echte B42-42.19-API (bzw. die
      Bicycle-Mod) verifizieren, `pcall` durch sauberes Feature-Detect ersetzen
      und die Tick-Logik entschlacken. Ohne das ist der Tempo-Effekt evtl. wirkungslos.
- [ ] **In-Game-Verifikation der Modelle.** `scale = 1.0` gegen eine Spielfigur
      prüfen, danach Rotation/Offset feinjustieren.

## 🧱 Substanz (Tiefgang & Balancing)

- [ ] **Gewichtsabhängiges Tempo** – voll beladener Wagen zieht langsamer.
- [ ] **Radverschleiß** über `modData` – Räder nutzen sich ab und müssen ersetzt werden.
- [ ] **Annahme-Filter** in `HolzwagenAccept` (aktuell `return true`), damit nur
      sinnvolle Güter in den Wagen passen.
- [ ] **Balancing-Pass** für Skill-Stufen, Materialkosten und Bauzeiten.

## ✨ Politur (spürbarer Feinschliff)

- [ ] **Sound-Effekte** beim Ziehen (Rollen/Knarzen).
- [ ] **Zieh-Animation** statt nur belegter Hände.
- [ ] **Eigene Item-Icons** statt der Platzhalter (`Crate`/`Wheel`).
- [ ] **Bessere Texturen** / Material-Varianten.

## 🚀 Ideen / später

- [ ] Weitere Varianten: Schubkarre, Planwagen (Segeltuch), tiergezogene Version.
- [ ] Multiplayer-Test und ggf. Sync-Anpassungen.
- [ ] Steam-Workshop-Release mit Preview-Bildern.

---

Erledigte Punkte wandern ins [CHANGELOG](CHANGELOG.md).
