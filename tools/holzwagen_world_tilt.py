"""
GEKIPPTE WELT-MODELLE (Wagen abgestellt: Handgriff liegt auf dem Boden).

Prinzip: Wir nehmen die FBX-Dateien, die im Spiel NACHWEISLICH richtig
stehen (holzwagen_t1 / holzwagen_t2_blur / holzwagen_fass_blur), drehen NUR
die Vertices um die Radachse (X-Achse, Pivot auf Achshoehe) und exportieren
mit exakt denselben Export-Einstellungen wie die Original-Skripte.
-> Einziger Unterschied zum funktionierenden Modell ist die Kippung selbst.
   (Der fruehere Fehlversuch nutzte einen eigenen Export-Weg und lag deshalb
   auf der Seite = Drehung um die falsche Achse im Export-Raum.)

Der Kippwinkel wird NUMERISCH bestimmt: groesster Winkel, bei dem kein
Vertex unter den Boden (z < 0) sinkt -> Handgriff-Unterseite beruehrt den
Boden exakt, Raeder bleiben auf dem Boden (Pivot = Achse, Rad ist rund).

Aufruf: python3 tools/holzwagen_world_tilt.py
"""
import bpy, math, os

REPO = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media"
MODELS = os.path.join(REPO, "models_X")

# Radgeometrie wie in den Bau-Skripten (alle drei Wagen identisch)
WHEEL_R = 0.34   # Achshoehe = Radradius (Radunterseite liegt bei z=0)

SOURCES = [
    ("holzwagen_t1.fbx",        "holzwagen_t1_world.fbx"),
    ("holzwagen_t2_blur.fbx",   "holzwagen_t2_blur_world.fbx"),
    ("holzwagen_fass_blur.fbx", "holzwagen_fass_blur_world.fbx"),
]


def tilt_one(src_name, dst_name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MODELS, src_name))

    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert meshes, "kein Mesh importiert: " + src_name
    # Objekt-Transform (Import-Achsenkorrektur) fest in die Vertices backen,
    # damit wir im selben Blender-Raum arbeiten wie die Bau-Skripte.
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    me = obj.data
    zmin = min(v.co.z for v in me.vertices)
    dims = obj.dimensions
    # Masseinheiten pruefen: Modell ist in Metern gebaut (~2.2 m lang).
    # Falls der Import in cm skaliert hat, zurueckrechnen.
    unit = 1.0
    if dims.y > 20:  # offensichtlich cm
        unit = 100.0
    pivot_z = WHEEL_R * unit
    print(f"{src_name}: dims=({dims.x:.2f},{dims.y:.2f},{dims.z:.2f}) "
          f"zmin={zmin:.4f} unit={unit}")

    # Groessten Winkel finden, bei dem nichts unter den Boden sinkt.
    # Drehung um X am Pivot (0, *, pivot_z); Handgriff liegt bei +Y und
    # soll RUNTER -> negatives Theta (y-Anteil drueckt z nach unten).
    coords = [(v.co.x, v.co.y, v.co.z) for v in me.vertices]

    def zmin_at(deg):
        t = math.radians(-deg)
        c, s = math.cos(t), math.sin(t)
        lo = 1e9
        for x, y, z in coords:
            zz = y * s + (z - pivot_z) * c + pivot_z
            if zz < lo:
                lo = zz
        return lo

    best = 0.0
    for deg10 in range(1, 400):           # 0.1..40.0 Grad in 0.1er-Schritten
        deg = deg10 / 10.0
        if zmin_at(deg) < -0.005 * unit:  # 5 mm Toleranz
            break
        best = deg
    print(f"  -> Kippwinkel: {best:.1f} Grad (Handgriff beruehrt Boden)")

    t = math.radians(-best)
    c, s = math.cos(t), math.sin(t)
    for v in me.vertices:
        y, z = v.co.y, v.co.z - pivot_z
        v.co.y = y * c - z * s
        v.co.z = y * s + z * c + pivot_z

    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    # EXAKT dieselben Export-Flags wie tools/holzwagen_t2_blur.py & Co.
    bpy.ops.export_scene.fbx(filepath=os.path.join(MODELS, dst_name),
                             use_selection=True, apply_unit_scale=True,
                             object_types={'MESH'})
    print("EXPORT:", dst_name)


for src, dst in SOURCES:
    tilt_one(src, dst)
print("FERTIG.")
