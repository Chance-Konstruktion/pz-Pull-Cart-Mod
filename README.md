# 🛒 Holzwagen – Pull Cart für Project Zomboid

Ein **ziehbarer** einachsiger Holzwagen für **Build 42**.
Schluss damit, 50 kg Beute einzeln nach Hause zu schleppen.

> **Status:** funktionsfähig & lädt sauber in B42 42.19 · in aktiver Entwicklung
> 🇬🇧 English version: [README.en.md](README.en.md)

---

## ✨ Features

- **Ziehen mit beiden Händen** → Tempo abhängig von den verbauten Rädern
- **Zwei Stufen** plus Fasswagen-Umbau für Flüssigkeiten
- **Taschen-Slots** an den Seiten (Rucksäcke einhängen)
- Vollständige Rezepte inkl. **Rückbau**
- Zentrale **Balance-Konfiguration** (`Holzwagen_Config.lua`)

| Variante       | Tempo | Ladefläche | Taschen-Slots | Flüssigkeit | Woodwork |
|----------------|:-----:|:----------:|:-------------:|:-----------:|:--------:|
| **T1** (Holzrad)     | 80 %  | offener Loot | 4 | – | 3 |
| **T2** (Speichenrad) | 100 % | offener Loot (größer) | 4 | – | 5 |
| **Fasswagen**        | wie Räder | Fass (gesperrt) | 4 | 450 Einheiten | 5 |

> Taschen-Slots = Rucksäcke seitlich einhängen (Rechtsklick-Menü). Die offene
> Ladefläche nimmt zusätzlich losen Loot auf; beim Fasswagen belegt das Fass das Bett.

## 📦 Installation

1. Den Ordner [`HolzwagenMod`](HolzwagenMod) in deinen Mods-Ordner kopieren:
   `C:\Users\<DU>\Zomboid\mods\HolzwagenMod`
2. Im Spiel **Mods** aktivieren und ein Spiel starten.

Details & Modell-Hinweise: [`HolzwagenMod/README_INSTALL.md`](HolzwagenMod/README_INSTALL.md).

## 🔨 Rezepte (Carpentry)

- Holzwagen **T1** & **T2** + Rad-Upgrade T1 → T2
- Räder (Holz) und Speichenräder
- Fasswagen-**Umbau** + **Rückbau**

Werkzeuge (Säge/Hammer) werden beim Bauen **nicht verbraucht**. Rezepte schalten
sich automatisch beim Erreichen des nötigen Woodwork-Levels frei.

## 📚 Dokumentation

| Dokument | Inhalt |
|----------|--------|
| [CHANGELOG](CHANGELOG.md) | Was sich geändert hat |
| [ROADMAP](ROADMAP.md) | Was als Nächstes kommt |
| [docs/TESTING.md](docs/TESTING.md) | Spawnen, Verify-Checkliste, Modelle |
| [README_INSTALL](HolzwagenMod/README_INSTALL.md) | Ausführliche Installation |

## 🤝 Mitwirken / Feedback

Issues und Pull Requests willkommen – besonders zu **Balance**, **Modellen/Texturen**
und **weiteren Varianten** (Planwagen, Schubkarre, tiergezogen …).
Siehe die [Roadmap](ROADMAP.md) für offene Punkte.

---

**Viel Spaß beim Ziehen!** Made with ❤️ für alle, die genug vom Schleppen haben.
