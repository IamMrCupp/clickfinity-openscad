"""Render a studio-style product preview of an STL with Blender, headless.

    blender -b -P tools/render_preview.py -- <input.stl> <output.png>

Soft 3-point sun lighting, a shadow-catcher floor over a gradient backdrop, a
bevelled matte-plastic material, a perspective 3/4 camera framed from the mesh
bounds, and AgX tone-mapping. Scale-robust (sun lights) so it works for a 40 mm
bin or a 500 mm case. CYCLES on CPU; denoises when the build supports it.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

# Quality knobs — high by default (committed README previews, rendered locally);
# CI/release sets them low via env (tools/build_release.sh) so the per-part
# render stays fast on a denoiser-less CPU runner.
SAMPLES = int(os.environ.get("PREVIEW_SAMPLES", "160"))
RES_X = int(os.environ.get("PREVIEW_RES_X", "1600"))
RES_Y = int(os.environ.get("PREVIEW_RES_Y", "1200"))

argv = sys.argv[sys.argv.index("--") + 1:]
if len(argv) < 2:
    raise SystemExit(
        "usage: blender -b -P render_preview.py -- <in.stl> <out.png> [#hexcolor]\n"
        "   or: blender -b -P render_preview.py -- <out.png> <in.stl[,#hex]> ...")

def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _hex_color(s, fallback=(0.82, 0.42, 0.14)):
    s = (s or "").lstrip("#")
    if len(s) != 6:
        return (*fallback, 1.0)
    rgb = tuple(int(s[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    return (*tuple(_srgb_to_linear(c) for c in rgb), 1.0)

# Two calling conventions (backward compatible):
#   legacy single: <in.stl> <out.png> [#hex]
#   multi-part:    <out.png> <in.stl[,#hex]> <in.stl[,#hex]> ...  (parts share an
#                  origin and keep their relative positions — for assembled or
#                  two-colour models)
DEFAULT_COLOR = "d26b1f"   # warm orange (legacy default)
if argv[0].lower().endswith(".stl"):
    out_png = argv[1]
    parts = [(argv[0], argv[2] if len(argv) >= 3 else None)]
else:
    out_png = argv[0]
    parts = [(tok.partition(",")[0], tok.partition(",")[2] or None) for tok in argv[1:]]

# --- clean scene ---------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def _import_stl(path):
    """Import one STL (operator name varies by Blender version); return its mesh."""
    for op in (lambda: bpy.ops.wm.stl_import(filepath=path),
               lambda: bpy.ops.import_mesh.stl(filepath=path)):
        before = set(scene.objects)
        try:
            op()
        except (AttributeError, RuntimeError):
            continue
        new = [o for o in scene.objects if o not in before and o.type == "MESH"]
        if new:
            return new[0]
    raise SystemExit(f"no working STL importer / import failed: {path}")

def _world_bounds(objects):
    corners = [ob.matrix_world @ Vector(c) for ob in objects for c in ob.bound_box]
    bb_min = Vector(min(c[i] for c in corners) for i in range(3))
    bb_max = Vector(max(c[i] for c in corners) for i in range(3))
    return bb_min, bb_max

# --- import every part, assign its colour --------------------------------
objs = []
for path, hexc in parts:
    o = _import_stl(path)
    mat = bpy.data.materials.new("plastic")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = _hex_color(hexc or DEFAULT_COLOR)
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.45
    o.data.materials.clear(); o.data.materials.append(mat)
    objs.append(o)
bpy.context.view_layer.update()

# centre the group in XY and sit it on the floor (z=0), keeping relative poses
bb_min, bb_max = _world_bounds(objs)
delta = Vector((-(bb_min.x + bb_max.x) / 2, -(bb_min.y + bb_max.y) / 2, -bb_min.z))
for o in objs:
    o.location = o.location + delta
bpy.context.view_layer.update()
size = max(bb_max - bb_min) or 1.0

# rounded edges so they catch light like a printed part
for o in objs:
    bev = o.modifiers.new("bevel", "BEVEL")
    bev.width = max(size * 0.0015, 0.3); bev.segments = 2
    bev.limit_method = "ANGLE"; bev.angle_limit = math.radians(35)

# --- shadow-catcher floor ------------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=size * 40, location=(0, 0, 0))
floor = bpy.context.active_object
floor.is_shadow_catcher = True

# --- gradient backdrop ---------------------------------------------------
world = bpy.data.worlds.new("world"); scene.world = world; world.use_nodes = True
wnt = world.node_tree
bg = wnt.nodes["Background"]
tc = wnt.nodes.new("ShaderNodeTexCoord")
sep = wnt.nodes.new("ShaderNodeSeparateXYZ")
ramp = wnt.nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.35
ramp.color_ramp.elements[0].color = (0.045, 0.05, 0.06, 1)   # darker low
ramp.color_ramp.elements[1].position = 0.85
ramp.color_ramp.elements[1].color = (0.22, 0.24, 0.27, 1)    # lighter high
wnt.links.new(tc.outputs["Window"], sep.inputs["Vector"])
wnt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
wnt.links.new(ramp.outputs["Color"], bg.inputs["Color"])

# --- 3-point sun lighting (scale-independent) ----------------------------
def sun(name, energy, rot, angle_deg):
    d = bpy.data.lights.new(name, "SUN"); d.energy = energy; d.angle = math.radians(angle_deg)
    o = bpy.data.objects.new(name, d); scene.collection.objects.link(o)
    o.rotation_euler = [math.radians(a) for a in rot]
sun("key",  4.0, (55, 0, 35), 6)     # key, soft
sun("fill", 1.3, (65, 0, -60), 10)   # fill from the other side
sun("rim",  3.0, (-50, 0, 200), 4)   # rim/back

# --- perspective camera, framed from the world-space bounding sphere ------
bpy.context.view_layer.update()
bb_min, bb_max = _world_bounds(objs)
center = (bb_min + bb_max) / 2
radius = (bb_max - bb_min).length / 2 or 1.0

cam_data = bpy.data.cameras.new("cam"); cam_data.type = "PERSP"; cam_data.lens = 70
cam_data.clip_end = radius * 20
cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
# fit the bounding sphere to the (narrower) vertical FOV so any shape fits
fov_h = 2 * math.atan((cam_data.sensor_width / 2) / cam_data.lens)
fov_v = 2 * math.atan(math.tan(fov_h / 2) * 1200 / 1600)
dist = radius / math.sin(min(fov_h, fov_v) / 2) * 1.12
cam.location = center + Vector((0.6, -1.0, 0.55)).normalized() * dist
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()

# --- render --------------------------------------------------------------
scene.render.engine = "CYCLES"
scene.cycles.samples = SAMPLES
scene.cycles.device = "CPU"
scene.cycles.use_denoising = True               # clean locally; fallback below for denoiser-less builds
try:
    scene.view_settings.view_transform = "AgX"  # filmic tone-mapping (Blender 4.0+)
except Exception:
    pass
scene.render.film_transparent = False
scene.render.resolution_x = RES_X
scene.render.resolution_y = RES_Y
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = out_png

# Denoising errors AT RENDER on builds without OpenImageDenoise (e.g. CI's
# apt Blender). Try denoised; on failure, turn it off and re-render.
try:
    bpy.ops.render.render(write_still=True)
except RuntimeError:
    scene.cycles.use_denoising = False
    bpy.ops.render.render(write_still=True)
print(f"wrote {out_png}")
