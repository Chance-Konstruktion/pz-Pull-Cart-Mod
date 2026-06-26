# 🛞 Test: Drehen sich animierte Räder am Hand-Wagen?

Ziel: empirisch klären, ob Project Zomboid B42 die **Animation eines
angehefteten Hand-Modells** abspielt. Wenn ja, bauen wir drehende Räder für
alle Wagen. Wenn nein, verwerfen wir den Ansatz (dann geht es technisch nicht).

## Schritt 1 – Modell erzeugen (Blender, bei dir)
1. Blender öffnen → **Scripting**-Tab.
2. `tools/holzwagen_wheels_rig.py` öffnen → **Run Script**.
3. Es entsteht `~/HolzwagenExport/holzwagen_t2_anim.fbx` (mit Armature + Dreh-Animation).
4. Diese Datei nach `HolzwagenMod/42/media/models_X/` kopieren.

## Schritt 2 – Modell ins Spiel einhängen (nur zum Test)
In `HolzwagenMod/42/media/scripts/holzwagen_items.txt` **direkt unter** den
anderen `model`-Blöcken diesen Block einfügen:

```
model wagenT2anim
{
    mesh = holzwagen_t2_anim, texture = holzwagen_tex, scale = 0.007,
    attachment Bip01_Prop1 { offset = -1.4 0.0 0.0, rotate = 0.0 90.0 0.0, }
}
```

Dann im `item Holzwagen_T2` testweise die Modellnamen tauschen:

```
WorldStaticModel = wagenT2anim,
StaticModel      = wagenT2anim,
ReplaceInPrimaryHand = wagenT2anim holdingtrolleyright,
ReplaceInSecondHand  = wagenT2anim holdingtrolleyleft,
```

> ⚠️ Erst einbauen, **wenn die FBX existiert** – sonst meckert PZ über ein
> fehlendes Modell. Den Block/die Namen nach dem Test wieder zurückstellen,
> falls die Animation nicht läuft.

## Schritt 3 – Im Spiel anschauen
1. Spiel **komplett neu starten** (Scripts laden nur beim Start).
2. T2-Wagen in die Hand nehmen und **schieben/laufen**.
3. Beobachten: **Drehen sich die Räder?**

## Ergebnis melden
- **Räder drehen** → 🎉 sag Bescheid, dann ziehe ich es auf T1 + Fasswagen und
  koppele die Dreh-Geschwindigkeit an die Laufgeschwindigkeit.
- **Räder stehen still** → Engine spielt Hand-Prop-Animationen nicht ab; dann
  ist der Ansatz erledigt und wir lassen die Räder statisch.

## Falls PZ das animierte Modell gar nicht lädt
Häufige Ursachen:
- Mesh-Name im `model`-Block ≠ FBX-Dateiname (ohne `.fbx`).
- FBX ohne Animation exportiert (im Skript ist `bake_anim=True` gesetzt).
- Modell unsichtbar/zu groß/klein → `scale` im `model`-Block anpassen.
