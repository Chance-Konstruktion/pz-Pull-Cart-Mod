# 🛒 Holzwagen – Pull Cart für Project Zomboid

Ein **ziehbarer** einachsiger Holzwagen für **Build 42**.
Schluss damit, 50 kg Beute einzeln nach Hause zu schleppen.

> **Status:** funktionsfähig & lädt sauber in B42 42.19 · in aktiver Entwicklung
> 🇬🇧 English version: [README.en.md](README.en.md)

---

## ✨ Features

- **Ziehen mit beiden Händen** → Tempo abhängig von Rädern **und Beladung**
- **Schnell-Ausrüsten** mit `V`/`E` (kurze Anschirr-Zeit) · beim Schieben sind
  Zäune klettern & Türen öffnen gesperrt — erst abstellen!
- **Gekippte Modelle**: in der Hand Griff leicht hoch, abgestellt liegt der
  Griff auf dem Boden 🛒
- **Motion-Blur-Speichenräder** (T2/Fasswagen) + echte Holzmaserung + eigene Icons
- **Große Ladefläche** (über das B42-50er-Limit hinaus) + **Taschen-Slots** seitlich
- **Fasswagen**: 140-L-Tank für alle Flüssigkeiten, Befüllen/Umfüllen per
  **Schlauch**, sammelt **Regenwasser**
- **Leichen-Transport**, **Abnutzung & Reparatur** (Bretter+Nägel+Hammer),
  Füllstand direkt im Item-Namen
- Vollständige Rezepte inkl. **Rückbau** · zentrale **Balance-Konfiguration**
  (`Holzwagen_Config.lua`) · **Multiplayer-tauglich** (synchronisierte Aktionen)

| Variante       | Tempo | Ladefläche | Taschen-Slots | Flüssigkeit | Woodwork |
|----------------|:-----:|:----------:|:-------------:|:-----------:|:--------:|
| **T1** (Holzrad)     | 80 %  | offener Loot | 4 | – | 3 |
| **T2** (Speichenrad) | 100 % | offener Loot (größer) | 4 | – | 5 |
| **Fasswagen**        | wie Räder | Fass (gesperrt) | 3 + Schlauch-Slot | 140 L (alle Fluids) | 5 |

> Taschen-Slots = Rucksäcke seitlich einhängen (Rechtsklick-Menü). Die offene
> Ladefläche nimmt zusätzlich losen Loot auf; beim Fasswagen belegt das Fass das
> Bett und der vierte Slot gehört dem Schlauch.

## ⚙️ Selber tunen

Fast alles ist ohne Programmierkenntnisse einstellbar — Tempo, Volumen,
Taschen-Slots, Geräusche, Abnutzung, Regen-Sammelrate:
**[HolzwagenMod/EINSTELLUNGEN.md](HolzwagenMod/EINSTELLUNGEN.md)** (mit
Datei- und Zeilenangaben). Die 3D-Modelle/Texturen/Icons werden von den
Python-Skripten in [`tools/`](tools) erzeugt (headless Blender, `pip install bpy`).

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
