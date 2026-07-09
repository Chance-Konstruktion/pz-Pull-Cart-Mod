"""

!!! AUSSER BETRIEB: Die fest gebackenen Satteltaschen sahen nicht gut aus
und sind wieder entfernt (Basis fuer world_tilt sind die nackten Modelle).
Datei bleibt nur als Referenz liegen.
SICHTBARE TASCHEN an den Wagen-Modellen.

PZ kann Hand-Prop-Modelle nicht dynamisch umbauen (gleiche Engine-Grenze wie
bei animierten Raedern) -> die Taschen sind FEST ins Modell gebacken und
immer sichtbar. Design: Leder-Satteltaschen haengen aussen an den Seiten-
holmen (2 je Seite = die 4 Slots); der Fasswagen bekommt 3 Taschen + einen
aufgerollten SCHLAUCH am vierten Platz (sein Schlauch-Slot).

Pipeline: Basis-FBX importieren -> Taschen-Meshes anbauen -> als *_bags.fbx
exportieren. Danach tools/holzwagen_world_tilt.py laufen lassen, das aus den
*_bags.fbx die _hand/_world-Varianten erzeugt.

Aufruf: python3 tools/holzwagen_taschen.py && python3 tools/holzwagen_world_tilt.py
"""
import bpy, math, os

MODELS = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media/models_X"

# Zonen-Zentren je Atlas (UV-Quadranten, siehe tools/holzwagen_optik.py):
#   holzwagen_tex.png  : metal TL, tire TR, wood BL, wooddark BR
#   holzwagen_t2_blur  : wheel TL, wood TR, wooddark BL, metal BR
ZONES_T1   = {"wood": (0.25, 0.25), "wooddark": (0.75, 0.25), "metal": (0.25, 0.75)}
ZONES_BLUR = {"wood": (0.75, 0.75), "wooddark": (0.25, 0.25), "metal": (0.75, 0.25)}

# (basis, ausgabe, zonen, mit_schlauch)
JOBS = [
    ("holzwagen_t1.fbx",        "holzwagen_t1_bags.fbx",        ZONES_T1,   False),
    ("holzwagen_t2_blur.fbx",   "holzwagen_t2_blur_bags.fbx",   ZONES_BLUR, False),
    ("holzwagen_fass_blur.fbx", "holzwagen_fass_blur_bags.fbx", ZONES_BLUR, True),
]

# Taschen-Mass (Meter). Haengt aussen am Holm, Oberkante ~ Bett-Hoehe.
BAG_W, BAG_D, BAG_H = 0.10, 0.26, 0.30   # dick(x), breit(y), hoch(z)
# Abstand der Taschen-MITTE von der Radachse (y=0). Muss so gross sein, dass
# die Innenkante (BAG_Y - BAG_D/2) AUSSERHALB des Rads (Radius 0.34) liegt!
BAG_Y = 0.56                              # Innenkante 0.43 > Rad 0.34
Z_BED_TOP = 0.50                          # Bett-Oberkante (Z_AXLE .34 + .10 + .06)


def uv_solid(o, zones, zone):
    me = o.data
    if not me.uv_layers: me.uv_layers.new()
    uvl = me.uv_layers.active.data
    cu, cv = zones[zone]
    HALF, M = 0.25, 0.03
    for poly in me.polygons:
        for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
            co = me.vertices[me.loops[li].vertex_index].co
            u = cu + max(-HALF + M, min(HALF - M, co.y * 0.2))
            v = cv + max(-HALF + M, min(HALF - M, co.z * 0.3 - 0.1))
            uvl[li].uv = (u, v)


def box(col, sx, sy, sz, loc):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    for c in o.users_collection: c.objects.unlink(o)
    col.objects.link(o)
    return o


def torus(col, R, r, loc, rot):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r,
                                     location=loc, rotation=rot,
                                     major_segments=16, minor_segments=6)
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(rotation=True)
    for c in o.users_collection: c.objects.unlink(o)
    col.objects.link(o)
    return o


def satchel(col, zones, x_out, y, sgn):
    """Eine Satteltasche: Korpus (dunkles Leder) + Deckel-Klappe + Riemen."""
    parts = []
    zc = Z_BED_TOP - BAG_H / 2 + 0.02
    body = box(col, BAG_W, BAG_D, BAG_H, (x_out + sgn * BAG_W / 2, y, zc))
    uv_solid(body, zones, "wooddark"); parts.append(body)
    flap = box(col, BAG_W + 0.03, BAG_D + 0.03, 0.05,
               (x_out + sgn * BAG_W / 2, y, zc + BAG_H / 2))
    uv_solid(flap, zones, "wooddark"); parts.append(flap)
    strap = box(col, BAG_W + 0.045, 0.04, BAG_H * 0.8,
                (x_out + sgn * BAG_W / 2, y, zc + 0.02))
    uv_solid(strap, zones, "metal"); parts.append(strap)
    return parts


def process(src, dst, zones, with_hose):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MODELS, src))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    base = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    x_out = base.dimensions.x / 2 - 0.02      # Aussenkante (Radaussenseite)
    # Taschen haengen INNERHALB der Raeder am Wagenkasten: Kastenkante suchen
    #  -> breitester Punkt OHNE Raeder ~ Bettbreite; nehmen konservativ 0.45.
    x_bed = 0.45

    col = base.users_collection[0]
    new = []
    # 4 Plaetze: links/rechts je vorn+hinten. Fasswagen: hinten-rechts = Schlauch.
    spots = [(-1, -BAG_Y), (-1, BAG_Y), (1, -BAG_Y), (1, BAG_Y)]
    for i, (sgn, y) in enumerate(spots):
        if with_hose and i == 3:
            new.append(torus(col, 0.13, 0.035,
                             (sgn * (x_bed + 0.05), y, Z_BED_TOP - 0.12),
                             (0, math.pi / 2, 0)))
            uv_solid(new[-1], zones, "wooddark")
        else:
            new += satchel(col, zones, sgn * x_bed, y, sgn)

    # Material vom Basis-Mesh uebernehmen (gleicher Atlas)
    mat = base.data.materials[0] if base.data.materials else None
    for o in new:
        o.data.materials.clear()
        if mat: o.data.materials.append(mat)

    bpy.ops.object.select_all(action='DESELECT')
    base.select_set(True)
    for o in new: o.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    out = bpy.context.view_layer.objects.active
    bpy.ops.object.select_all(action='DESELECT'); out.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(MODELS, dst),
                             use_selection=True, apply_unit_scale=True,
                             object_types={'MESH'})
    print("EXPORT:", dst, "| Polys:", len(out.data.polygons))


for src, dst, zones, hose in JOBS:
    process(src, dst, zones, hose)
print("FERTIG.")
