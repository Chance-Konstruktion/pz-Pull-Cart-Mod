"""
Prozedurale Roll-/Knarz-Sounds fuer den Holzwagen (kein Sample-Download noetig).

Drei Loops (~1,4 s, nahtlos, 44,1 kHz mono OGG):
  HolzwagenRollT1  - Vollholzraeder: schweres Poltern, deutliche Schlaege
  HolzwagenRollT2  - Speichenraeder: leichteres Rollen, leises Klackern
  HolzwagenRollFass- wie T2 plus tiefes Fass-Wummern (Resonanz)

Bausteine: tiefpass-gefiltertes Rauschen (Rollen auf Erde), gedaempfte
Sinus-Impulse (Radschlaege/Stossfugen), Stick-Slip-Knarzen (frequenz-
moduliertes Saegezahn-Kreischen mit Zufallsjitter).

Aufruf: python3 tools/holzwagen_sounds.py
"""
import numpy as np
import soundfile as sf
import os

SR = 44100
DUR = 1.4                      # Loop-Laenge (intervalMs 650 -> 2 Schlaege/Loop)
N = int(SR * DUR)
OUT = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media/sound"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(42)
t = np.arange(N) / SR


def lowpass(x, alpha):
    """1-Pol-Tiefpass; alpha klein = dunkler."""
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def rumble(cutoff_alpha, gain):
    """Roll-Grundrauschen: braunes Rauschen, tiefpassgefiltert, mit
    langsamer Amplituden-Wobbelung (unebener Boden)."""
    noise = rng.normal(0, 1, N)
    x = lowpass(noise, cutoff_alpha)
    wob = 1.0 + 0.35 * np.sin(2 * np.pi * 1.7 * t) + 0.2 * np.sin(2 * np.pi * 3.1 * t + 1.3)
    return gain * x * wob


def thump(at, freq, decay, gain):
    """Gedaempfter Schlag (Radstoss)."""
    i0 = int(at * SR)
    n = min(N - i0, int(0.25 * SR))
    tt = np.arange(n) / SR
    burst = np.sin(2 * np.pi * freq * tt * (1 - 0.3 * tt)) * np.exp(-tt / decay)
    out = np.zeros(N)
    out[i0:i0 + n] = burst * gain
    return out


def creak(at, f0, f1, dur, gain):
    """Stick-Slip-Knarzen: Saegezahn mit Frequenz-Gleiten + Jitter."""
    i0 = int(at * SR)
    n = min(N - i0, int(dur * SR))
    tt = np.arange(n) / SR
    f = f0 + (f1 - f0) * (tt / dur)
    f = f * (1 + 0.06 * rng.normal(0, 1, n).cumsum() / SR * 30)
    phase = np.cumsum(f) / SR
    saw = 2 * (phase % 1.0) - 1
    env = np.sin(np.pi * tt / dur) ** 2 * np.exp(-tt * 2)
    out = np.zeros(N)
    out[i0:i0 + n] = lowpass(saw, 0.25) * env * gain
    return out


def finish(x, name, peak=0.55):
    """Loop-Naht glaetten, normalisieren, als OGG speichern."""
    fade = int(0.02 * SR)                       # 20 ms Crossfade Ende->Anfang
    w = np.linspace(0, 1, fade)
    x[:fade] = x[:fade] * w + x[-fade:] * (1 - w)
    x[-fade:] *= np.linspace(1, 0, fade)
    x = x / (np.abs(x).max() + 1e-9) * peak
    sf.write(os.path.join(OUT, name + ".ogg"), x.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print("SOUND:", name + ".ogg", f"{DUR}s")


# ---- T1: Vollholz, schwer, polternd, knarzt oefter ----
x = rumble(0.045, 1.0)
for at, f in ((0.10, 70), (0.42, 62), (0.75, 74), (1.08, 66)):
    x += thump(at, f, 0.055, 2.6)
x += creak(0.28, 320, 560, 0.30, 0.9)
x += creak(0.95, 260, 420, 0.24, 0.7)
finish(x, "HolzwagenRollT1", peak=0.62)

# ---- T2: Speichenrad, leichter/heller, dezentes Klackern ----
x = rumble(0.09, 0.7)
for at, f in ((0.15, 110), (0.48, 118), (0.82, 105), (1.15, 112)):
    x += thump(at, f, 0.03, 1.2)
x += creak(0.60, 480, 700, 0.16, 0.35)
finish(x, "HolzwagenRollT2", peak=0.45)

# ---- Fass: T2-Basis + tiefes Fass-Wummern (Hohlraum-Resonanz) ----
x = rumble(0.08, 0.75)
for at, f in ((0.15, 108), (0.48, 115), (0.82, 104), (1.15, 110)):
    x += thump(at, f, 0.03, 1.1)
for at in (0.22, 0.88):
    x += thump(at, 48, 0.12, 1.8)               # Fass-Resonanz
x += creak(0.55, 300, 480, 0.22, 0.5)
finish(x, "HolzwagenRollFass", peak=0.55)

print("FERTIG:", OUT)
