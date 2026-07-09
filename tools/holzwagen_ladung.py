"""
FUELLSTANDS-MODELLE: Ladeflaeche halbvoll / voll.

PZ kann Modelle nicht dynamisch umbauen -> je Fuellstand ein eigenes,
fest gebackenes Modell. Dieses Skript nimmt die Basis-FBX (OHNE Taschen)
und baut Fracht aufs Bett: Kisten + Saecke, bei "halb" wenige, bei "voll"
gestapelt. Danach erzeugt tools/holzwagen_world_tilt.py daraus die
_world-Varianten (abgestellt, Griff am Boden). Der Modell-Tausch zur
Laufzeit passiert in Lua (Holzwagen_Core: HW.updateWorldModel) ueber
InventoryItem:setWorldStaticModel - nur das WELT-Modell wechselt, das
Hand-Modell ist enginebedingt fest.

Fasswagen hat kein offenes Bett (bedLocked) -> keine Varianten.

Aufruf: python3 tools/holzwagen_ladung.py && python3 tools/holzwagen_world_tilt.py
"""
import bpy, math, os, random

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = os.path.join(HERE, "..", "HolzwagenMod", "42", "media", "models_X")

# UV-Zonen-Zentren je Atlas (Quadranten, siehe tools/holzwagen_optik.py):
ZONES_T1   = {"wood": (0.25, 0.25), "wooddark": (0.75, 0.25), "metal": (0.25, 0.75)}
ZONES_BLUR = {"wood": (0.75, 0.75), "wooddark": (0.25, 0.25), "metal": (0.75, 0.25)}

# Bett-Geometrie (Meter, wie in tools/holzwagen_taschen.py hergeleitet):
X_BED = 0.40        # halbe Bettbreite (Fracht bleibt innerhalb der Holme)
Y_BED = 0.55        # halbe Bettlaenge (Radachse y=0, Griff bei +y)
Z_BED = 0.50        # Bett-Oberkante

# (basis, ausgabe, zonen, fuellgrad)
JOBS = [
    ("holzwagen_t1.fbx",      "holzwagen_t1_halb.fbx",      ZONES_T1,   "halb"),
    ("holzwagen_t1.fbx",      "holzwagen_t1_voll.fbx",      ZONES_T1,   "voll"),
    ("holzwagen_t2_blur.fbx", "holzwagen_t2_blur_halb.fbx", ZONES_BLUR, "halb"),
    ("holzwagen_t2_blur.fbx", "holzwagen_t2_blur_voll.fbx", ZONES_BLUR, "voll"),
]


def uv_solid(o, zones, zone):
    """Alle Faces in die einfarbige Atlas-Zone mappen (mit etwas Verlauf)."""
    me = o.data
    if not me.uv_layers:
        me.uv_layers.new()
    uvl = me.uv_layers.active.data
    cu, cv = zones[zone]
    HALF, M = 0.25, 0.03
    for poly in me.polygons:
        for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
            co = me.vertices[me.loops[li].vertex_index].co
            u = cu + max(-HALF + M, min(HALF - M, co.y * 0.2))
            v = cv + max(-HALF + M, min(HALF - M, co.z * 0.3 - 0.1))
            uvl[li].uv = (u, v)


def box(sx, sy, sz, loc, rot_z=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=(0, 0, rot_z))
    o = bpy.context.active_object
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    return o


def cargo(zones, level, seed):
    """Kisten + Saecke aufs Bett. Gibt Liste neuer Objekte zurueck."""
    rnd = random.Random(seed)
    out = []

    def crate(x, y, z, s=0.22, h=0.20, zone="wooddark"):
        o = box(s, s, h, (x, y, z + h / 2), rot_z=rnd.uniform(-0.15, 0.15))
        uv_solid(o, zones, zone)
        out.append(o)

    def sack(x, y, z, zone="wood"):
        # Sack = flachgedrueckter Wuerfel (liest sich auf Distanz als Sack)
        o = box(0.26, 0.18, 0.13, (x, y, z + 0.065), rot_z=rnd.uniform(-0.4, 0.4))
        uv_solid(o, zones, zone)
        out.append(o)

    if level == "halb":
        crate(-0.16, -0.25, Z_BED)
        crate(0.15, 0.05, Z_BED, s=0.20, h=0.18)
        sack(-0.10, 0.30, Z_BED)
        sack(0.14, -0.38, Z_BED)
    else:  # voll
        # Untere Lage: Kisten fast bettfuellend
        for ix in (-0.18, 0.18):
            for iy in (-0.34, 0.0, 0.34):
                crate(ix + rnd.uniform(-0.02, 0.02), iy, Z_BED,
                      s=0.24, h=0.22, zone=rnd.choice(("wood", "wooddark")))
        # Obere Lage: versetzt gestapelt + Saecke obendrauf
        crate(-0.05, -0.18, Z_BED + 0.22, s=0.24, h=0.20)
        crate(0.10, 0.22, Z_BED + 0.22, s=0.20, h=0.18, zone="wood")
        sack(-0.12, 0.35, Z_BED + 0.22)
        sack(0.05, -0.42, Z_BED + 0.22, zone="wooddark")
    return out


for src, dst, zones, level in JOBS:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MODELS, src))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert meshes, "kein Mesh importiert: " + src
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    # Import-Transform in die Vertices backen -> gleicher Raum wie Bau-Skripte
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    parts = cargo(zones, level, seed=hash(dst) & 0xffff)

    bpy.ops.object.select_all(action='DESELECT')
    base.select_set(True)
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()

    bpy.ops.object.select_all(action='DESELECT')
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    # EXAKT dieselben Export-Flags wie tools/holzwagen_world_tilt.py
    bpy.ops.export_scene.fbx(filepath=os.path.join(MODELS, dst),
                             use_selection=True, apply_unit_scale=True,
                             object_types={'MESH'})
    print("EXPORT:", dst, f"({level})")

print("FERTIG.")
