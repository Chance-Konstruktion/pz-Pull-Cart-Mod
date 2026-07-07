"""
Mod-Poster (poster.png) aus dem ECHTEN Wagen-Modell rendern.

Seitenansicht des abgestellten T2 (holzwagen_t2_blur_world.fbx, Griff am
Boden): Flaechen werden per Painter-Algorithmus (nach Tiefe sortiert)
gefuellt, die Zone (Holz/Holz-dunkel/Metall/Rad) wird aus den UV-Koordinaten
des Atlas zurueckgelesen. Das Rad bekommt den echten Blur-Rad-Ausschnitt aus
holzwagen_t2_blur.png. Titel per DejaVu-Font.

Aufruf: python3 tools/holzwagen_poster.py
"""
import bpy, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42"
FBX = os.path.join(REPO, "media/models_X/holzwagen_t2_blur_world.fbx")
ATLAS = os.path.join(REPO, "media/textures/holzwagen_t2_blur.png")
OUT = os.path.join(REPO, "poster.png")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Zonen-Zentren im Atlas (wie holzwagen_t2_blur.py) -> Grundfarbe
ZONES = {
    "wheel":    ((0.25, 0.75), None),            # Rad: Textur-Ausschnitt
    "wood":     ((0.75, 0.75), (168, 116, 60)),
    "wooddark": ((0.25, 0.25), (112, 74, 40)),
    "metal":    ((0.75, 0.25), (96, 96, 104)),
}
WHEEL_R, Z_AXLE = 0.34, 0.34

# ---- Modell laden ----
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FBX)
obj = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
bpy.context.view_layer.objects.active = obj; obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = obj.data
uvl = me.uv_layers.active.data

def zone_of(poly):
    u = sum(uvl[li].uv[0] for li in range(poly.loop_start, poly.loop_start + poly.loop_total)) / poly.loop_total
    v = sum(uvl[li].uv[1] for li in range(poly.loop_start, poly.loop_start + poly.loop_total)) / poly.loop_total
    best, bd = "wood", 9
    for name, ((cu, cv), _) in ZONES.items():
        d = (u - cu) ** 2 + (v - cv) ** 2
        if d < bd: best, bd = name, d
    return best

faces = []   # (tiefe_x, zone, [(y,z)...], normal)
for poly in me.polygons:
    pts = [me.vertices[me.loops[li].vertex_index].co for li in
           range(poly.loop_start, poly.loop_start + poly.loop_total)]
    depth = sum(p.x for p in pts) / len(pts)
    faces.append((depth, zone_of(poly), [(p.y, p.z) for p in pts], poly.normal))
faces.sort(key=lambda f: f[0])   # weit weg (links, -x) zuerst

# ---- Leinwand: Abendhimmel-Verlauf + Boden ----
W = H = 512
yy = np.linspace(0, 1, H)[:, None]
sky_top = np.array([46, 38, 34]); sky_bot = np.array([196, 138, 74])
img = (sky_top + (sky_bot - sky_top) * yy ** 1.6)
img = np.repeat(img[:, None, :] if img.ndim == 2 else img, W, axis=1)
img = np.broadcast_to((sky_top + (sky_bot - sky_top) * yy ** 1.6)[:, None, :], (H, W, 3)).copy()
GROUND_Y = int(H * 0.80)
gy = np.linspace(0, 1, H - GROUND_Y)[:, None, None]
img[GROUND_Y:] = (np.array([72, 58, 40]) * (1 - gy * 0.4) + np.array([40, 32, 24]) * gy * 0.4)
rng = np.random.default_rng(7)
img += rng.normal(0, 3.5, (H, W, 3))          # Filmkorn
pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
draw = ImageDraw.Draw(pil)

# ---- Projektion Modell -> Bild ----
S = 195.0                        # Pixel pro Meter
CX, CY = W * 0.44, GROUND_Y      # Boden = z 0
def px(y, z): return (CX + (y - 0.15) * S, CY - z * S)

SUN = np.array([0.3, -0.5, 0.81])
for depth, zone, pts, n in faces:
    base = ZONES[zone][1]
    if base is None:             # Radflaechen ueberspringen -> eigenes Bild
        continue
    lit = 0.48 + 0.55 * max(0.0, float(n.x * SUN[0] + n.y * SUN[1] + n.z * SUN[2]))
    back = 0.82 if depth < -0.2 else 1.0     # entfernte Seite leicht abdunkeln
    col = tuple(int(min(255, c * lit * back)) for c in base)
    draw.polygon([px(y, z) for (y, z) in pts], fill=col)

# ---- Rad: echter Blur-Ausschnitt aus dem Atlas ----
atlas = Image.open(ATLAS).convert("RGB")
A = atlas.size[0]
crop = atlas.crop((0, 0, A // 2, A // 2)).resize((int(2 * WHEEL_R * S),) * 2)
mask = Image.new("L", crop.size, 0)
ImageDraw.Draw(mask).ellipse((0, 0, crop.size[0] - 1, crop.size[1] - 1), fill=255)
wx, wy = px(0, Z_AXLE)
pil.paste(crop, (int(wx - crop.size[0] / 2), int(wy - crop.size[1] / 2)), mask)
d2 = ImageDraw.Draw(pil)
r = WHEEL_R * S
d2.ellipse((wx - r, wy - r, wx + r, wy + r), outline=(52, 40, 28), width=5)
d2.ellipse((wx - r * 0.16, wy - r * 0.16, wx + r * 0.16, wy + r * 0.16), fill=(88, 88, 96))

# ---- Bodenschatten ----
sh = Image.new("L", (W, H), 0)
ImageDraw.Draw(sh).ellipse((wx - r * 2.6, CY - 10, wx + r * 2.9, CY + 22), fill=90)
sh = sh.filter(ImageFilter.GaussianBlur(9))
pil = Image.composite(Image.new("RGB", (W, H), (18, 14, 10)), pil, sh.point(lambda a: a // 2))
draw = ImageDraw.Draw(pil)

# ---- Titel ----
f1 = ImageFont.truetype(FONT, 64); f2 = ImageFont.truetype(FONT, 26)
def center(t, f, y, fill, shadow=True):
    w = draw.textlength(t, font=f)
    if shadow: draw.text(((W - w) / 2 + 3, y + 3), t, font=f, fill=(20, 14, 8))
    draw.text(((W - w) / 2, y), t, font=f, fill=fill)
center("HOLZWAGEN", f1, 30, (240, 222, 190))
center("Pull Cart · Build 42", f2, 104, (216, 188, 148))

pil.save(OUT)
print("POSTER:", OUT, pil.size)
