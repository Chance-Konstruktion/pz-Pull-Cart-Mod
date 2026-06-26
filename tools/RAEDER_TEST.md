# 🛞 Test: Drehen sich animierte Räder am Hand-Wagen?

Ziel: empirisch klären, ob Project Zomboid B42 die **Animation eines
angehefteten Hand-Modells** abspielt. Wenn ja, bauen wir drehende Räder für
alle Wagen. Wenn nein, verwerfen wir den Ansatz (dann geht es technisch nicht).

## Schon erledigt (von mir, headless mit `bpy`)
- FBX **mit Animation** liegt bereits im Repo:
  `HolzwagenMod/42/media/models_X/holzwagen_t2_anim.fbx`
  (verifiziert: Action `WheelSpin`, Bones `Root`+`Wheel`, Bereich 1–25).
- **T2 ist bereits auf das animierte Modell verdrahtet** (`wagenT2anim` im
  `item Holzwagen_T2`). Du musst also **nichts** mehr im Script ändern.

> Selber neu bauen (optional): Blender → Scripting → `tools/holzwagen_wheels_rig.py`
> → Run; erzeugt `~/HolzwagenExport/holzwagen_t2_anim.fbx`.

## Im Spiel anschauen
1. Spiel **komplett neu starten** (Scripts laden nur beim Start).
2. T2-Wagen in die Hand nehmen und **schieben/laufen**.
3. Beobachten: **Drehen sich die Räder?**

## Ergebnis melden
- **Räder drehen** → 🎉 sag Bescheid, dann ziehe ich es auf T1 + Fasswagen und
  koppele die Dreh-Geschwindigkeit an die Laufgeschwindigkeit.
- **Räder stehen still** → Engine spielt Hand-Prop-Animationen nicht ab; dann
  ist der Ansatz erledigt. Zum Zurückstellen im `item Holzwagen_T2` überall
  `wagenT2anim` → `wagenT2` ändern.

## Falls PZ das animierte Modell gar nicht lädt
Häufige Ursachen:
- Mesh-Name im `model`-Block ≠ FBX-Dateiname (ohne `.fbx`).
- FBX ohne Animation exportiert (im Skript ist `bake_anim=True` gesetzt).
- Modell unsichtbar/zu groß/klein → `scale` im `model`-Block anpassen.
