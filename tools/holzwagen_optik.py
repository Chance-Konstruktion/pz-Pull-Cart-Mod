"""
OPTIK-PAKET fuer den Holzwagen (headless, braucht bpy + numpy).
Erzeugt:
  1) holzwagen_tex.png      - 4-Zonen-Atlas (T1/Fass alt) mit ECHTER Holz-
                              Maserung, Brettfugen, Metall & Reifen-Struktur.
  2) holzwagen_t2_blur.png  - T2-Atlas: gleiche Maserung + Motion-Blur-Rad.
  3) Inventar-Icons         - Item_Holzwagen*.png (64x64, transparent),
                              gezeichnet als Seitenansicht-Piktogramme.
Aufruf:  python3 tools/holzwagen_optik.py
"""
import bpy, math, os
import numpy as np

REPO = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media"
TEXDIR = os.path.join(REPO, "textures")
os.makedirs(TEXDIR, exist_ok=True)
rng = np.random.default_rng(42)

def save_png(img_f, path):
    """img_f: HxWx4 float 0..1 -> PNG via bpy."""
    h, w = img_f.shape[:2]
    im = bpy.data.images.new(os.path.basename(path), w, h, alpha=True)
    im.pixels = np.flipud(img_f).astype(np.float32).ravel()
    im.filepath_raw = path
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)
    print("PNG:", path)

# ---------------- Holz-Maserung ----------------
def value_noise(w, h, cells, seed):
    r = np.random.default_rng(seed)
    g = r.random((cells + 1, cells + 1))
    ys = np.linspace(0, cells, h, endpoint=False)
    xs = np.linspace(0, cells, w, endpoint=False)
    yi, xi = np.floor(ys).astype(int), np.floor(xs).astype(int)
    yf, xf = (ys - yi)[:, None], (xs - xi)[None, :]
    yf = yf * yf * (3 - 2 * yf); xf = xf * xf * (3 - 2 * xf)
    a = g[np.ix_(yi, xi)]; b = g[np.ix_(yi, xi + 1)]
    c = g[np.ix_(yi + 1, xi)]; d = g[np.ix_(yi + 1, xi + 1)]
    return a + (b - a) * xf + (c - a) * yf + (a - b - c + d) * xf * yf

def wood_tile(w, h, base, dark, planks, seed, vertical=True):
    """Holzflaeche mit Maserung + Brettfugen. base/dark = RGB-Arrays."""
    n1 = value_noise(w, h, 6, seed)
    n2 = value_noise(w, h, 24, seed + 1)
    yy, xx = np.mgrid[0:h, 0:w]
    along = (yy / h) if vertical else (xx / w)      # Faserrichtung
    across = (xx / w) if vertical else (yy / h)     # quer (Ringe)
    grain = np.sin(across * planks * 2 * math.pi * 3.5 + n1 * 6 + n2 * 2)
    grain = 0.5 + 0.5 * grain
    col = np.zeros((h, w, 3))
    for c in range(3):
        col[:, :, c] = base[c] * (0.72 + 0.28 * grain) + dark[c] * 0.12 * n2
    # Brettfugen
    plank_pos = (across * planks) % 1.0
    fuge = (plank_pos < 0.035) | (plank_pos > 0.965)
    col[fuge] *= 0.55
    # leichte Laengs-Streifen
    streak = 0.9 + 0.1 * value_noise(w, h, 48, seed + 2)
    col *= streak[:, :, None]
    # ein paar dunkle Astloecher
    r2 = np.random.default_rng(seed + 3)
    for _ in range(3):
        cx, cy, rad = r2.random() * w, r2.random() * h, 3 + r2.random() * 4
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        col[d < rad] *= 0.6
    return np.clip(col, 0, 1)

def metal_tile(w, h, seed):
    n = value_noise(w, h, 16, seed)
    base = np.array([0.44, 0.45, 0.50])
    col = np.zeros((h, w, 3))
    for c in range(3):
        col[:, :, c] = base[c] * (0.8 + 0.25 * n)
    # Kratzer
    yy, xx = np.mgrid[0:h, 0:w]
    scr = np.sin(xx * 0.7 + n * 20) > 0.995
    col[scr] = np.minimum(col[scr] * 1.5, 1.0)
    return np.clip(col, 0, 1)

def tire_tile(w, h, seed):
    n = value_noise(w, h, 20, seed)
    base = np.array([0.07, 0.065, 0.06])
    col = np.zeros((h, w, 3))
    for c in range(3):
        col[:, :, c] = base[c] * (0.7 + 0.5 * n)
    return np.clip(col, 0, 1)

WOOD  = np.array([0.55, 0.34, 0.16])
WOODD = np.array([0.36, 0.22, 0.10])

# ---------------- 1) Alter 4-Zonen-Atlas (T1 / Fass) ----------------
# Zonen-Layout (aus fass/t1-Skripten, NAME2Q): q0=Wood, q1=Wood_Dark,
# q2=Metal, q3=Tire; Quadrant q -> Spalte c=q%2, Zeile r=q//2 (V von unten).
S = 512; T = 1024
atlas = np.zeros((T, T, 3))
# Bildzeilen: oben = V hoch. V-Zeile r=1 (q2,q3) liegt im Bild OBEN.
atlas[0:S,   0:S]   = metal_tile(S, S, 20)                      # q2 Metal (oben links)
atlas[0:S,   S:T]   = tire_tile(S, S, 30)                       # q3 Tire  (oben rechts)
atlas[S:T,   0:S]   = wood_tile(S, S, WOOD,  WOODD, 4, 10)      # q0 Wood  (unten links)
atlas[S:T,   S:T]   = wood_tile(S, S, WOODD, WOODD * 0.6, 6, 11)# q1 WoodDark (unten rechts)
save_png(np.dstack([atlas, np.ones((T, T))]), os.path.join(TEXDIR, "holzwagen_tex.png"))

# ---------------- 2) T2-Blur-Atlas mit Maserung ----------------
# Layout aus holzwagen_t2_blur.py: top-left=Rad, top-right=Wood,
# bottom-left=WoodDark, bottom-right=Metal (top = Bild oben).
t2 = np.zeros((T, T, 3))
t2[0:S, S:T] = wood_tile(S, S, WOOD, WOODD, 4, 12)
t2[S:T, 0:S] = wood_tile(S, S, WOODD, WOODD * 0.6, 6, 13)
t2[S:T, S:T] = metal_tile(S, S, 21)
# Motion-Blur-Rad (top-left) - Holzton mit Maserungs-Unterlage
yy, xx = np.mgrid[0:S, 0:S]
dx = (xx - S / 2) / (S / 2); dy = (yy - S / 2) / (S / 2)
r = np.sqrt(dx * dx + dy * dy); theta = np.arctan2(dy, dx)
wheel = tire_tile(S, S, 31)
inner, outer = 0.20, 0.86
zone = (r >= inner) & (r <= outer)
sp = np.zeros((S, S))
for k in range(8):
    a0 = k * 2 * math.pi / 8
    d = (theta - a0); d = (d + math.pi) % (2 * math.pi) - math.pi
    core = np.exp(-(d / 0.10) ** 2)
    tail = np.exp(-(d / 0.55)) * (d > 0) * 0.6
    sp = np.maximum(sp, np.maximum(core, tail))
sp *= zone
spoke_wood = wood_tile(S, S, WOOD, WOODD, 1, 14)
for c in range(3):
    wheel[:, :, c] = wheel[:, :, c] * (1 - sp) + spoke_wood[:, :, c] * sp
rim = (r >= 0.80) & (r <= 0.88)
wheel[rim] = wood_tile(S, S, WOODD, WOODD * 0.6, 1, 15)[rim]
hub = r <= inner
wheel[hub] = spoke_wood[hub]
hubm = r <= 0.07
wheel[hubm] = metal_tile(S, S, 22)[hubm]
t2[0:S, 0:S] = np.clip(wheel, 0, 1)
save_png(np.dstack([t2, np.ones((T, T))]), os.path.join(TEXDIR, "holzwagen_t2_blur.png"))

# ---------------- 3) Inventar-Icons (64x64, transparent) ----------------
IS = 256   # supersampled, wird auf 64 verkleinert

def canvas():
    return np.zeros((IS, IS, 4))

def blit_rect(img, x0, y0, x1, y1, rgb, a=1.0):
    x0, x1 = int(x0 * IS), int(x1 * IS)
    y0, y1 = int(y0 * IS), int(y1 * IS)
    img[y0:y1, x0:x1, :3] = rgb
    img[y0:y1, x0:x1, 3] = a

def blit_circle(img, cx, cy, rad, rgb, a=1.0, ring=None):
    yy, xx = np.mgrid[0:IS, 0:IS]
    d = np.sqrt((xx - cx * IS) ** 2 + (yy - cy * IS) ** 2) / IS
    m = d <= rad if ring is None else (d <= rad) & (d >= ring)
    img[m, :3] = rgb
    img[m, 3] = a

def blit_line(img, x0, y0, x1, y1, width, rgb, a=1.0):
    n = 400
    ts = np.linspace(0, 1, n)
    for t in ts:
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        blit_circle(img, x, y, width / 2, rgb, a)

def downsave(img, name):
    small = img.reshape(64, 4, 64, 4, 4).mean(axis=(1, 3))
    save_png(small, os.path.join(TEXDIR, name))

W, WD, MT, TR = WOOD, WOODD, np.array([0.5, 0.5, 0.55]), np.array([0.1, 0.09, 0.08])

def draw_cart(img, wheel="solid"):
    blit_rect(img, 0.12, 0.42, 0.78, 0.58, W)              # Bett
    blit_rect(img, 0.12, 0.34, 0.78, 0.42, WD)             # Bordwand
    blit_line(img, 0.78, 0.50, 0.96, 0.38, 0.045, WD)      # Holm
    if wheel == "solid":
        blit_circle(img, 0.40, 0.70, 0.16, TR)
        blit_circle(img, 0.40, 0.70, 0.12, W)
        blit_circle(img, 0.40, 0.70, 0.03, MT)
    else:
        blit_circle(img, 0.40, 0.70, 0.16, TR)
        blit_circle(img, 0.40, 0.70, 0.13, np.array([0, 0, 0]), 0.0)  # Loch
        for k in range(6):
            a = k * math.pi / 3
            blit_line(img, 0.40, 0.70, 0.40 + 0.13 * math.cos(a), 0.70 + 0.13 * math.sin(a), 0.03, WD)
        blit_circle(img, 0.40, 0.70, 0.045, W)
        blit_circle(img, 0.40, 0.70, 0.02, MT)

img = canvas(); draw_cart(img, "solid");  downsave(img, "Item_HolzwagenT1.png")
img = canvas(); draw_cart(img, "spoke");  downsave(img, "Item_HolzwagenT2.png")

img = canvas(); draw_cart(img, "spoke")
blit_rect(img, 0.22, 0.14, 0.68, 0.36, W)                  # Fass (liegend)
for fx in (0.28, 0.45, 0.62):
    blit_rect(img, fx, 0.14, fx + 0.03, 0.36, MT)          # Metallbaender
downsave(img, "Item_HolzwagenFass.png")

img = canvas()
blit_circle(img, 0.5, 0.5, 0.34, TR); blit_circle(img, 0.5, 0.5, 0.27, W)
blit_circle(img, 0.5, 0.5, 0.06, MT)
downsave(img, "Item_HolzwagenRadT1.png")

img = canvas()
blit_circle(img, 0.5, 0.5, 0.34, TR)
blit_circle(img, 0.5, 0.5, 0.28, np.array([0, 0, 0]), 0.0)
for k in range(6):
    a = k * math.pi / 3
    blit_line(img, 0.5, 0.5, 0.5 + 0.28 * math.cos(a), 0.5 + 0.28 * math.sin(a), 0.05, WD)
blit_circle(img, 0.5, 0.5, 0.09, W); blit_circle(img, 0.5, 0.5, 0.04, MT)
downsave(img, "Item_HolzwagenRadT2.png")

img = canvas()   # Speichengestell: nur Ring + Speichen, ohne Beschlag
blit_circle(img, 0.5, 0.5, 0.32, WD, ring=0.27)
for k in range(6):
    a = k * math.pi / 3
    blit_line(img, 0.5, 0.5, 0.5 + 0.28 * math.cos(a), 0.5 + 0.28 * math.sin(a), 0.045, WD)
blit_circle(img, 0.5, 0.5, 0.07, W)
downsave(img, "Item_HolzwagenGestell.png")

img = canvas()   # Fass (Item, stehend)
blit_rect(img, 0.30, 0.18, 0.70, 0.85, W)
blit_circle(img, 0.5, 0.18, 0.20, W)
for fy in (0.28, 0.50, 0.72):
    blit_rect(img, 0.30, fy, 0.70, fy + 0.04, MT)
downsave(img, "Item_HolzwagenFassItem.png")

img = canvas()   # Schlauch: aufgerollte Ringe
for rr in (0.30, 0.22, 0.14):
    blit_circle(img, 0.5, 0.5, rr + 0.035, np.array([0.15, 0.25, 0.15]), ring=rr)
blit_line(img, 0.72, 0.62, 0.92, 0.78, 0.06, np.array([0.15, 0.25, 0.15]))
blit_circle(img, 0.92, 0.78, 0.045, MT)
downsave(img, "Item_HolzwagenSchlauch.png")

img = canvas()   # Trichter
for i in range(60):
    t = i / 59
    hw = 0.30 * (1 - t) + 0.045
    y = 0.15 + t * 0.45
    blit_rect(img, 0.5 - hw, y, 0.5 + hw, y + 0.012, MT)
blit_rect(img, 0.455, 0.60, 0.545, 0.88, MT)
downsave(img, "Item_HolzwagenTrichter.png")

print("OPTIK-PAKET fertig.")
