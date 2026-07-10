"""
GELEGENTLICHES QUIETSCHEN statt Dauer-Rollsound.

Die alten Roll-Loops (HolzwagenRollT1/T2/Fass) klangen synthetisch
("Raumschiff") und liefen als Dauerschleife. Neuer Ansatz: kurze, trockene
Achs-Quietscher (Stick-Slip einer Holzachse), die Holzwagen_CartSound.lua
nur GELEGENTLICH abspielt (zufaelliger Abstand, siehe Config.squeak).

Drei Varianten, damit es nicht repetitiv klingt:
  HolzwagenQuietschen1 - kurzer heller Quietscher
  HolzwagenQuietschen2 - laengerer, absinkender Knarz-Quietscher
  HolzwagenQuietschen3 - doppelter kurzer Quietscher ("iek-iek")

Bausteine: frequenzmoduliertes Stick-Slip (Saegezahn mit Jitter und
Pitch-Gleiten), Formant-artige Tiefpass-Faerbung (klingt nach Holz/Metall
statt nach Synthesizer), kurze Attack-/Release-Huellkurve, dezentes
Reibungs-Rauschbett nur waehrend des Quietschers.

Aufruf: python3 tools/holzwagen_quietschen.py
"""
import numpy as np
import soundfile as sf
import os

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "HolzwagenMod", "42", "media", "sound")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def squeak(dur, f0, f1, wobble_hz, gain=1.0):
    """Ein einzelner Stick-Slip-Quietscher.
    f0->f1 = Pitch-Gleiten; wobble = Reibungs-Zittern (macht es organisch)."""
    n = int(dur * SR)
    tt = np.arange(n) / SR
    # Pitch-Verlauf: gleiten + Zittern + langsamer Random-Walk
    f = f0 + (f1 - f0) * (tt / dur)
    f = f * (1 + 0.03 * np.sin(2 * np.pi * wobble_hz * tt))
    f = f * (1 + 0.02 * lowpass(rng.normal(0, 1, n), 0.002) * 8)
    phase = np.cumsum(f) / SR
    # Saegezahn = obertonreich (Reibung), dann dunkel filtern (Holz)
    saw = 2 * (phase % 1.0) - 1
    body = lowpass(saw, 0.18)
    # Huellkurve: schneller Attack, natuerliches Ausklingen
    atk = np.minimum(tt / 0.015, 1.0)
    rel = np.exp(-np.maximum(tt - dur * 0.55, 0) * 14)
    env = atk * rel * np.sin(np.pi * np.minimum(tt / dur, 1.0)) ** 0.4
    # Reibungs-Rauschbett, nur unter der gleichen Huellkurve
    fric = lowpass(rng.normal(0, 1, n), 0.06) * 0.18
    return (body + fric) * env * gain


def save(parts, name, peak=0.5):
    """Teile (offset_sekunden, signal) zu einer Datei mischen, speichern."""
    total = max(off + len(sig) / SR for off, sig in parts) + 0.08
    n = int(total * SR)
    x = np.zeros(n)
    for off, sig in parts:
        i0 = int(off * SR)
        x[i0:i0 + len(sig)] += sig
    x = x / (np.abs(x).max() + 1e-9) * peak
    sf.write(os.path.join(OUT, name + ".ogg"), x.astype(np.float32), SR,
             format="OGG", subtype="VORBIS")
    print("SOUND:", name + ".ogg", f"{total:.2f}s")


# 1: kurz + hell ("iiek")
save([(0.0, squeak(0.28, 950, 1250, 11))], "HolzwagenQuietschen1", peak=0.42)

# 2: laenger, absinkend ("iiieeeuu")
save([(0.0, squeak(0.55, 1100, 720, 7))], "HolzwagenQuietschen2", peak=0.45)

# 3: doppelt ("iek-iek", zweiter etwas tiefer/leiser)
save([(0.0, squeak(0.20, 1000, 1150, 13)),
      (0.30, squeak(0.18, 880, 990, 12, gain=0.8))],
     "HolzwagenQuietschen3", peak=0.42)

print("FERTIG:", OUT)
