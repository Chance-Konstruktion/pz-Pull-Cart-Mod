"""
Fasswagen-Modell fuer Blender (Scripting-Tab -> Run).
Baut den Holzwagen + Fass + Schlauch + Trichter und legt die UVs in die
4 Zonen des vorhandenen Atlas (holzwagen_tex.png), damit dieselbe Textur passt.
Exportiert holzwagen_fass.fbx nach C:\\Users\\<user>\\HolzwagenExport\\
"""
import bpy, math, os, numpy as np
from mathutils import Vector

# ---------- 4 Materialien (Reihenfolge passend zum Atlas) ----------
def mat(name, rgb):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if b: b.inputs["Base Color"].default_value = (*rgb, 1.0)
    m.diffuse_color = (*rgb, 1.0)
    return m
WOOD   = mat("Wood",     (0.50, 0.30, 0.14))
WOOD_D = mat("Wood_Dark",(0.34, 0.20, 0.10))
METAL  = mat("Metal",    (0.45, 0.45, 0.50))
TIRE   = mat("Tire",     (0.06, 0.055,0.05))
NAME2Q = {"Wood":0, "Wood_Dark":1, "Metal":2, "Tire":3}  # Atlas-Zone je Material

col = bpy.data.collections.new("Fasswagen")
bpy.context.scene.collection.children.link(col)
lc = bpy.context.view_layer.layer_collection.children[col.name]
bpy.context.view_layer.active_layer_collection = lc

def add(o, name, material):
    o.name = name
    for c in o.users_collection: c.objects.unlink(o)
    col.objects.link(o)
    if o.data.materials: o.data.materials[0] = material
    else: o.data.materials.append(material)
    return o
def box(sx, sy, sz, loc, name, m):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object; o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    return add(o, name, m)
def cyl(r, h, loc, name, m, axis="z", verts=20):
    rot = {"x": (0, math.pi/2, 0), "y": (math.pi/2, 0, 0), "z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    return add(o, name, m)
def cone(r1, r2, h, loc, name, m, verts=16):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=h, location=loc, vertices=verts)
    return add(bpy.context.active_object, name, m)

# ---------- Wagen (wie gehabt) ----------
BED_L,BED_W,BED_T=1.40,0.86,0.06; WALL_H=0.30
WHEEL_R,WHEEL_W=0.34,0.09; HANDLE_L=0.85
Z_AXLE=WHEEL_R; Z_BED=Z_AXLE+0.10
box(BED_W,BED_L,BED_T,(0,0,Z_BED),"Boden",WOOD)
st,gap=0.05,0.045
for i in range(3):
    z=Z_BED+BED_T/2+st/2+i*(st+gap)
    box(st,BED_L,st,(-BED_W/2+st/2,0,z),f"LatteL{i}",WOOD_D)
    box(st,BED_L,st,( BED_W/2-st/2,0,z),f"LatteR{i}",WOOD_D)
    box(BED_W,st,st,(0,-BED_L/2+st/2,z),f"LatteV{i}",WOOD_D)
    box(BED_W,st,st,(0, BED_L/2-st/2,z),f"LatteH{i}",WOOD_D)
for sx in (-1,1):
    for sy in (-1,1):
        box(0.06,0.06,WALL_H,(sx*(BED_W/2-0.03),sy*(BED_L/2-0.03),Z_BED+BED_T/2+WALL_H/2),"Pfosten",WOOD)
cyl(0.035,BED_W+0.12,(0,0,Z_AXLE),"Achse",METAL,axis="x",verts=12)
for sgn,side in ((-1,"L"),(1,"R")):
    x=sgn*(BED_W/2+WHEEL_W/2+0.02)
    cyl(WHEEL_R,WHEEL_W,(x,0,Z_AXLE),f"Rad{side}",TIRE,axis="x")
    cyl(WHEEL_R*0.32,WHEEL_W*1.05,(x,0,Z_AXLE),f"Nabe{side}",WOOD,axis="x",verts=14)
    for k in range(6):
        o=box(WHEEL_W*0.4,0.03,WHEEL_R*1.45,(x,0,Z_AXLE),f"Speiche{side}{k}",WOOD_D)
        o.rotation_euler[0]=k*math.pi/3; bpy.ops.object.transform_apply(rotation=True)
for sx in (-1,1):
    box(0.05,HANDLE_L,0.05,(sx*0.22,BED_L/2+HANDLE_L/2-0.05,Z_BED),"Holm",WOOD)
box(0.49,0.05,0.05,(0,BED_L/2+HANDLE_L-0.05,Z_BED),"Griff",WOOD)

# ---------- FASS (liegend, auf Wiege) ----------
bed_top=Z_BED+BED_T/2
BR,BL=0.30,0.95; hc=0.08; bz=bed_top+hc+BR
for yy in (-(BL/2-0.12), (BL/2-0.12)):                        # zwei Auflageboecke
    box(0.64,0.12,hc,(0,yy,bed_top+hc/2),"Bock",WOOD_D)
cyl(BR,BL,(0,0,bz),"Fass",WOOD,axis="y",verts=24)             # Fasskoerper LIEGEND (entlang Y)
for yy in (-BL/2+0.14, 0.0, BL/2-0.14):                       # Metallbaender
    cyl(BR+0.015,0.05,(0,yy,bz),"Band",METAL,axis="y",verts=24)
cyl(0.05,0.07,(0,0,bz+BR),"Spund",METAL,axis="z",verts=10)    # Spundloch oben
# (Schlauch + Trichter sind NICHT mehr am Modell - traegt man im Rucksack)

# ---------- joinen ----------
bpy.ops.object.select_all(action='DESELECT')
for o in list(col.objects): o.select_set(True)
bpy.context.view_layer.objects.active = col.objects[0]
bpy.ops.object.join()
cart = bpy.context.view_layer.objects.active
cart.name = "Holzwagen_Fass"
me = cart.data

# ---------- UV: Box-Projektion in die 4 Atlas-Zonen ----------
if not me.uv_layers: me.uv_layers.new(name="UVMap")
uvl = me.uv_layers.active.data
loops, verts = me.loops, me.vertices
raw={}; per_q={0:[],1:[],2:[],3:[]}; poly_q=[]
for poly in me.polygons:
    q = NAME2Q.get(me.materials[poly.material_index].name, 0); poly_q.append(q)
    n=poly.normal; ax=int(np.argmax([abs(n.x),abs(n.y),abs(n.z)]))
    for li in range(poly.loop_start,poly.loop_start+poly.loop_total):
        co=verts[loops[li].vertex_index].co
        uv=(co.y,co.z) if ax==0 else ((co.x,co.z) if ax==1 else (co.x,co.y))
        raw[li]=uv; per_q[q].append(uv)
bounds={q:(min(p[0] for p in pts),max(p[0] for p in pts),
           min(p[1] for p in pts),max(p[1] for p in pts)) for q,pts in per_q.items() if pts}
M=0.012
for pi,poly in enumerate(me.polygons):
    q=poly_q[pi]; u0,u1,v0,v1=bounds[q]; c=q%2; r=q//2
    for li in range(poly.loop_start,poly.loop_start+poly.loop_total):
        ru,rv=raw[li]
        nu=(ru-u0)/(u1-u0+1e-9); nv=(rv-v0)/(v1-v0+1e-9)
        uvl[li].uv=((c*0.5)+M+nu*(0.5-2*M),(r*0.5)+M+nv*(0.5-2*M))

# ---------- ein Material mit dem vorhandenen Atlas ----------
home=os.path.expanduser("~"); outdir=os.path.join(home,"HolzwagenExport")
os.makedirs(outdir,exist_ok=True)
tex_path=os.path.join(outdir,"holzwagen_tex.png")
fin=bpy.data.materials.new("Holzwagen_Fass_Mat"); fin.use_nodes=True
nt=fin.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
out=nt.nodes.new("ShaderNodeOutputMaterial"); out.location=(300,0)
bsdf=nt.nodes.new("ShaderNodeBsdfPrincipled"); bsdf.location=(0,0)
tex=nt.nodes.new("ShaderNodeTexImage"); tex.location=(-400,0); tex.interpolation='Linear'
if os.path.exists(tex_path): tex.image=bpy.data.images.load(tex_path, check_existing=True)
nt.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs["BSDF"],out.inputs["Surface"])
while me.materials: me.materials.pop()
me.materials.append(fin)
for p in me.polygons: p.material_index=0

# ---------- export ----------
fbx=os.path.join(outdir,"holzwagen_fass.fbx")
bpy.ops.object.select_all(action='DESELECT'); cart.select_set(True)
bpy.context.view_layer.objects.active=cart
bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, apply_unit_scale=True, object_types={'MESH'})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(outdir,"holzwagen_fass.blend"))
print("Fasswagen exportiert:", fbx, "| Polys:", len(me.polygons))
