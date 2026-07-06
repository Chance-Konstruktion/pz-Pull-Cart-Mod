"""
Fasswagen mit MOTION-BLUR-Raedern. Nutzt denselben 4-Zonen-Atlas wie T2
(holzwagen_t2_blur.png: Rad / Wood / WoodDark / Metal) -> keine neue Textur.
Erzeugt media/models_X/holzwagen_fass_blur.fbx.
Aufruf: python3 tools/holzwagen_fass_blur.py
"""
import bpy, math, os

REPO = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media"
FBXOUT = os.path.join(REPO, "models_X", "holzwagen_fass_blur.fbx")

bpy.ops.wm.read_factory_settings(use_empty=True)
col = bpy.data.collections.new("FassBlur")
bpy.context.scene.collection.children.link(col)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[col.name]

def newobj(o, name, tag):
    o.name = name; o["zone"] = tag
    for c in o.users_collection: c.objects.unlink(o)
    col.objects.link(o); return o
def box(sx, sy, sz, loc, name, tag):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object; o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True); return newobj(o, name, tag)
def cyl(r, h, loc, name, tag, axis="z", verts=24):
    rot = {"x": (0, math.pi/2, 0), "y": (math.pi/2, 0, 0), "z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    return newobj(o, name, tag)

BED_L, BED_W, BED_T = 1.40, 0.86, 0.06
WHEEL_R, WHEEL_W = 0.34, 0.10; HANDLE_L = 0.85
Z_AXLE = WHEEL_R; Z_BED = Z_AXLE + 0.10
AXLE_HALF = BED_W / 2 + WHEEL_W / 2 + 0.02

objs = []
objs.append(box(BED_W, BED_L, BED_T, (0, 0, Z_BED), "Boden", "wood"))
st, gap = 0.05, 0.045
for i in range(2):
    z = Z_BED + BED_T / 2 + st / 2 + i * (st + gap)
    objs += [box(st, BED_L, st, (-BED_W/2 + st/2, 0, z), f"LL{i}", "wooddark"),
             box(st, BED_L, st, ( BED_W/2 - st/2, 0, z), f"LR{i}", "wooddark")]
objs.append(cyl(0.035, BED_W + 0.12, (0, 0, Z_AXLE), "Achse", "metal", axis="x", verts=12))
for sx in (-1, 1):
    objs.append(box(0.05, HANDLE_L, 0.05, (sx * 0.22, BED_L/2 + HANDLE_L/2 - 0.05, Z_BED), "Holm", "wood"))
objs.append(box(0.49, 0.05, 0.05, (0, BED_L/2 + HANDLE_L - 0.05, Z_BED), "Griff", "wood"))

# ---- FASS (liegend auf Wiege) ----
bed_top = Z_BED + BED_T / 2
BR, BL = 0.30, 0.95; hc = 0.08; bz = bed_top + hc + BR
for yy in (-(BL/2 - 0.12), (BL/2 - 0.12)):
    objs.append(box(0.64, 0.12, hc, (0, yy, bed_top + hc/2), "Bock", "wooddark"))
objs.append(cyl(BR, BL, (0, 0, bz), "Fass", "wood", axis="y", verts=24))
for yy in (-BL/2 + 0.14, 0.0, BL/2 - 0.14):
    objs.append(cyl(BR + 0.015, 0.05, (0, yy, bz), "Band", "metal", axis="y", verts=24))
objs.append(cyl(0.05, 0.07, (0, 0, bz + BR), "Spund", "metal", axis="z", verts=10))

# ---- Raeder: flache Scheiben mit Blur-Bild auf den Kappen ----
wheels = []
for sgn, side in ((-1, "L"), (1, "R")):
    x = sgn * AXLE_HALF
    wheels.append(cyl(WHEEL_R, WHEEL_W, (x, 0, Z_AXLE), f"Rad{side}", "wheel", axis="x", verts=32))

# ---- UVs (Zonen wie in holzwagen_t2_blur.py) ----
Q = {"wheel": (0.25, 0.75), "wood": (0.75, 0.75), "wooddark": (0.25, 0.25), "metal": (0.75, 0.25)}
HALF, M = 0.25, 0.02

def uv_solid(o):
    me = o.data
    if not me.uv_layers: me.uv_layers.new()
    uvl = me.uv_layers.active.data
    cu, cv = Q[o["zone"]]
    # kleine Streuung im Quadranten, damit die Maserung sichtbar wird
    verts, loops = me.vertices, me.loops
    for poly in me.polygons:
        for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
            co = verts[loops[li].vertex_index].co
            u = cu + max(-HALF + M, min(HALF - M, co.y * 0.15))
            v = cv + max(-HALF + M, min(HALF - M, co.z * 0.25 - 0.05))
            uvl[li].uv = (u, v)

def uv_wheel(o):
    me = o.data
    if not me.uv_layers: me.uv_layers.new()
    uvl = me.uv_layers.active.data
    verts, loops = me.vertices, me.loops
    cu, cv = Q["wheel"]
    for poly in me.polygons:
        iscap = abs(poly.normal.x) > 0.7
        for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
            co = verts[loops[li].vertex_index].co
            if iscap:
                u = cu + (co.y / WHEEL_R) * (HALF - M)
                v = cv + ((co.z - Z_AXLE) / WHEEL_R) * (HALF - M)
            else:
                u, v = cu - (HALF - M) * 0.95, cv + (HALF - M) * 0.95
            uvl[li].uv = (u, v)

for o in objs: uv_solid(o)
for o in wheels: uv_wheel(o)

# ---- Material (Atlas) + join + export ----
mat = bpy.data.materials.new("fassblur"); mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
timg = nt.nodes.new("ShaderNodeTexImage")
texpath = os.path.join(REPO, "textures", "holzwagen_t2_blur.png")
if os.path.exists(texpath): timg.image = bpy.data.images.load(texpath)
nt.links.new(bsdf.inputs["Base Color"], timg.outputs["Color"])
nt.links.new(out.inputs["Surface"], bsdf.outputs["BSDF"])
allobjs = objs + wheels
for o in allobjs:
    o.data.materials.clear(); o.data.materials.append(mat)

bpy.ops.object.select_all(action='DESELECT')
for o in allobjs: o.select_set(True)
bpy.context.view_layer.objects.active = allobjs[0]
bpy.ops.object.join()
cart = bpy.context.view_layer.objects.active; cart.name = "Holzwagen_Fass_blur"
bpy.ops.object.select_all(action='DESELECT'); cart.select_set(True)
bpy.context.view_layer.objects.active = cart
bpy.ops.export_scene.fbx(filepath=FBXOUT, use_selection=True, apply_unit_scale=True, object_types={'MESH'})
print("EXPORT:", FBXOUT, "| Polys:", len(cart.data.polygons))
