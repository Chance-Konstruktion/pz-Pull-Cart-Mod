"""
T2-Wagen mit MOTION-BLUR-Raedern (statisch, sieht aber aus wie in Drehung).
Animierte Hand-Modelle gehen in PZ nicht (ModelInstance teilt den AnimPlayer
des Spielers) -> stattdessen ein Rad-Look, der statisch nicht "eingefroren"
wirkt: die Speichen sind radial verwischt in eine eigene Textur gebacken und
auf flache Rad-Scheiben gelegt.

Erzeugt:
  - media/textures/holzwagen_t2_blur.png   (Korpus-Zonen + Blur-Rad in 1 Atlas)
  - media/models_X/holzwagen_t2_blur.fbx
Headless: python3 tools/holzwagen_t2_blur.py   (bpy noetig)
"""
import bpy, math, os, numpy as np

REPO = "/home/user/pz-Holzwagen-mod-/HolzwagenMod/42/media"
TEXOUT = os.path.join(REPO, "textures", "holzwagen_t2_blur.png")
FBXOUT = os.path.join(REPO, "models_X", "holzwagen_t2_blur.fbx")

# ---------------- Szene leeren ----------------
bpy.ops.wm.read_factory_settings(use_empty=True)
col = bpy.data.collections.new("T2blur")
bpy.context.scene.collection.children.link(col)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[col.name]

WOOD=np.array([0.55,0.34,0.16]); WOODD=np.array([0.36,0.22,0.10])
METAL=np.array([0.5,0.5,0.55]);  TIRE=np.array([0.05,0.045,0.04])

# ================= 1) Kombi-Textur (1024, 2x2 Quadranten) =================
S=512; T=2*S
tex=np.zeros((T,T,3),dtype=np.float32)
# Quadranten (in Bild-Koordinaten, y nach unten): wir fuellen einfach Bloecke
# Layout (u,v) bottom-left origin -> wir bauen top-down und flippen am Ende.
# top-left = Rad, top-right = Wood, bottom-left = WoodDark, bottom-right = Metal
tex[0:S,0:S]=0          # wird Rad
tex[0:S,S:2*S]=WOOD
tex[S:2*S,0:S]=WOODD
tex[S:2*S,S:2*S]=METAL

# --- Blur-Rad in top-left zeichnen ---
yy,xx=np.mgrid[0:S,0:S]
cx=cy=S/2.0
dx=(xx-cx)/(S/2.0); dy=(yy-cy)/(S/2.0)
r=np.sqrt(dx*dx+dy*dy); theta=np.arctan2(dy,dx)
w=np.zeros((S,S,3)); w[:]=TIRE
inner,outer=0.20,0.86; zone=(r>=inner)&(r<=outer)
N=8; sigma=0.10; tail=0.55
sp=np.zeros((S,S))
for k in range(N):
    a0=k*2*math.pi/N
    d=(theta-a0); d=(d+math.pi)%(2*math.pi)-math.pi
    core=np.exp(-(d/sigma)**2); tv=np.exp(-(d/tail))*(d>0)*0.6
    sp=np.maximum(sp,np.maximum(core,tv))
sp*=zone
for c in range(3): w[:,:,c]=w[:,:,c]*(1-sp)+WOOD[c]*sp
rim=(r>=0.80)&(r<=0.88)
for c in range(3): w[rim,c]=WOODD[c]
hub=(r<=inner)
for c in range(3): w[hub,c]=WOOD[c]
hm=(r<=0.07)
for c in range(3): w[hm,c]=METAL[c]
tex[0:S,0:S]=np.clip(w,0,1)

rgba=np.dstack([tex,np.ones((T,T))]).astype(np.float32)
rgba=np.flipud(rgba)
os.makedirs(os.path.dirname(TEXOUT),exist_ok=True)
im=bpy.data.images.new("t2blur",T,T,alpha=True); im.pixels=rgba.ravel()
im.filepath_raw=TEXOUT; im.file_format='PNG'; im.save()

# UV-Quadranten-Mitten (u,v) bottom-left origin:
Q={"wheel":(0.25,0.75),"wood":(0.75,0.75),"wooddark":(0.25,0.25),"metal":(0.75,0.25)}
HALF=0.25; M=0.02

# ================= 2) Geometrie =================
def newobj(o,name,tag):
    o.name=name; o["zone"]=tag
    for c in o.users_collection: c.objects.unlink(o)
    col.objects.link(o); return o
def box(sx,sy,sz,loc,name,tag):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.active_object; o.scale=(sx,sy,sz)
    bpy.ops.object.transform_apply(scale=True); return newobj(o,name,tag)
def cyl(r,h,loc,name,tag,axis="z",verts=24):
    rot={"x":(0,math.pi/2,0),"y":(math.pi/2,0,0),"z":(0,0,0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(radius=r,depth=h,location=loc,rotation=rot,vertices=verts)
    o=bpy.context.active_object; bpy.ops.object.transform_apply(rotation=True,scale=True)
    return newobj(o,name,tag)

BED_L,BED_W,BED_T=1.40,0.86,0.06; WALL_H=0.30
WHEEL_R,WHEEL_W=0.34,0.10; HANDLE_L=0.85
Z_AXLE=WHEEL_R; Z_BED=Z_AXLE+0.10
AXLE_HALF=BED_W/2+WHEEL_W/2+0.02

objs=[]
objs.append(box(BED_W,BED_L,BED_T,(0,0,Z_BED),"Boden","wood"))
st,gap=0.05,0.045
for i in range(3):
    z=Z_BED+BED_T/2+st/2+i*(st+gap)
    objs+=[box(st,BED_L,st,(-BED_W/2+st/2,0,z),f"LL{i}","wooddark"),
           box(st,BED_L,st,( BED_W/2-st/2,0,z),f"LR{i}","wooddark"),
           box(BED_W,st,st,(0,-BED_L/2+st/2,z),f"LV{i}","wooddark"),
           box(BED_W,st,st,(0, BED_L/2-st/2,z),f"LH{i}","wooddark")]
for sx in (-1,1):
    for sy in (-1,1):
        objs.append(box(0.06,0.06,WALL_H,(sx*(BED_W/2-0.03),sy*(BED_L/2-0.03),Z_BED+BED_T/2+WALL_H/2),"Pf","wood"))
objs.append(cyl(0.035,BED_W+0.12,(0,0,Z_AXLE),"Achse","metal",axis="x",verts=12))
for sx in (-1,1):
    objs.append(box(0.05,HANDLE_L,0.05,(sx*0.22,BED_L/2+HANDLE_L/2-0.05,Z_BED),"Holm","wood"))
objs.append(box(0.49,0.05,0.05,(0,BED_L/2+HANDLE_L-0.05,Z_BED),"Griff","wood"))
# Raeder = flache Scheiben (Zylinder entlang X), Caps tragen das Blur-Rad
wheels=[]
for sgn,side in ((-1,"L"),(1,"R")):
    x=sgn*AXLE_HALF
    wheels.append(cyl(WHEEL_R,WHEEL_W,(x,0,Z_AXLE),f"Rad{side}","wheel",axis="x",verts=32))

# ================= 3) UVs setzen =================
def uv_solid(o):
    me=o.data
    if not me.uv_layers: me.uv_layers.new()
    uvl=me.uv_layers.active.data
    cu,cv=Q[o["zone"]]
    for poly in me.polygons:
        for li in range(poly.loop_start,poly.loop_start+poly.loop_total):
            uvl[li].uv=(cu,cv)   # einfarbige Zone -> ein Punkt reicht
def uv_wheel(o):
    me=o.data
    if not me.uv_layers: me.uv_layers.new()
    uvl=me.uv_layers.active.data; verts=me.vertices; loops=me.loops
    cu,cv=Q["wheel"]
    for poly in me.polygons:
        n=poly.normal; iscap=abs(n.x)>0.7
        for li in range(poly.loop_start,poly.loop_start+poly.loop_total):
            co=verts[loops[li].vertex_index].co
            if iscap:
                # Radmitte sitzt bei z=Z_AXLE -> z zentrieren
                u=cu+(co.y/WHEEL_R)*(HALF-M); v=cv+((co.z-Z_AXLE)/WHEEL_R)*(HALF-M)
            else:
                # Laufflaeche (Reifen) -> dunkle Ecke des Rad-Quadranten
                u=cu-(HALF-M)*0.95; v=cv+(HALF-M)*0.95
            uvl[li].uv=(u,v)
for o in objs: uv_solid(o)
for o in wheels: uv_wheel(o)

# ================= 4) Material =================
mat=bpy.data.materials.new("t2blur"); mat.use_nodes=True
nt=mat.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
out=nt.nodes.new("ShaderNodeOutputMaterial")
bsdf=nt.nodes.new("ShaderNodeBsdfPrincipled")
timg=nt.nodes.new("ShaderNodeTexImage"); timg.image=bpy.data.images.load(TEXOUT)
timg.interpolation='Linear'
nt.links.new(bsdf.inputs["Base Color"],timg.outputs["Color"])
nt.links.new(out.inputs["Surface"],bsdf.outputs["BSDF"])
allobjs=objs+wheels
for o in allobjs:
    o.data.materials.clear(); o.data.materials.append(mat)

# ================= 5) joinen + export =================
bpy.ops.object.select_all(action='DESELECT')
for o in allobjs: o.select_set(True)
bpy.context.view_layer.objects.active=allobjs[0]
bpy.ops.object.join()
cart=bpy.context.view_layer.objects.active; cart.name="Holzwagen_T2_blur"
bpy.ops.object.select_all(action='DESELECT'); cart.select_set(True)
bpy.context.view_layer.objects.active=cart
bpy.ops.export_scene.fbx(filepath=FBXOUT,use_selection=True,apply_unit_scale=True,object_types={'MESH'})
print("EXPORT:",FBXOUT)

import sys
sys.exit(0)  # Headless ohne GPU: Render uebersprungen. Loeschen, um Vorschau zu rendern.
# ================= 6) Vorschau rendern =================
# Kamera seitlich (auf die Rad-Scheibe schauen = +X)
cam_data=bpy.data.cameras.new("cam"); cam=bpy.data.objects.new("cam",cam_data)
bpy.context.scene.collection.objects.link(cam)
cam.location=(3.2,-0.2,0.7); cam.rotation_euler=(math.radians(82),0,math.radians(86))
cam_data.lens=50
bpy.context.scene.camera=cam
sun_data=bpy.data.lights.new("sun",type='SUN'); sun_data.energy=4
sun=bpy.data.objects.new("sun",sun_data); bpy.context.scene.collection.objects.link(sun)
sun.rotation_euler=(math.radians(50),math.radians(20),math.radians(30))
sc=bpy.context.scene
sc.render.engine='BLENDER_WORKBENCH'
sc.display.shading.light='STUDIO'
sc.display.shading.color_type='TEXTURE'
sc.render.resolution_x=640; sc.render.resolution_y=480
sc.render.film_transparent=False
sc.render.filepath="/home/user/pz-Holzwagen-mod-/scratch_t2_render.png"
bpy.ops.render.render(write_still=True)
print("RENDER done")
PY
