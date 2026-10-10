"""预览渲染：游戏镜头 / 正面 / 侧面 / 转台 / 图标。

只用于自查和审阅（最终以 Godot 游戏镜头截图为准）。EEVEE + 三渲二节点材质 + 反向外壳描边。
"""
import math
import os

import bpy
from mathutils import Vector

from . import materials

GAME_PITCH_DEG = 56.0   # 与 Godot 镜头一致（ART_BIBLE 第 2 节）
GAME_FOV_DEG = 34.0


def _scene():
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE_NEXT"
    sc.render.film_transparent = False
    try:
        sc.eevee.taa_render_samples = 16
        sc.eevee.use_soft_shadows = True
        sc.eevee.shadow_cube_size = "1024"
        sc.eevee.shadow_cascade_size = "2048"
    except Exception:
        pass
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    return sc


def _world(color=(0.07, 0.055, 0.11), strength=1.0):
    w = bpy.data.worlds.get("preview_world") or bpy.data.worlds.new("preview_world")
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*color, 1)
    bg.inputs["Strength"].default_value = strength
    bpy.context.scene.world = w


def _light(name, kind, loc, rot, energy, color=(1, 1, 1), size=0.1, spot_deg=40):
    ld = bpy.data.lights.get(f"{name}_{kind}") or bpy.data.lights.new(f"{name}_{kind}", kind)
    ld.energy = energy
    ld.color = color
    if kind == "SUN":
        ld.angle = math.radians(3)
    else:
        ld.shadow_soft_size = size
    if kind == "SPOT":
        ld.spot_size = math.radians(spot_deg)
        ld.spot_blend = 0.25
    ob = bpy.data.objects.get(name)
    if ob is not None and ob.data != ld:
        bpy.data.objects.remove(ob, do_unlink=True)
        ob = None
    if ob is None:
        ob = bpy.data.objects.new(name, ld)
        bpy.context.scene.collection.objects.link(ob)
    ob.location = Vector(loc)
    ob.rotation_euler = rot
    return ob


def _camera(name="preview_cam"):
    cd = bpy.data.cameras.get(name) or bpy.data.cameras.new(name)
    ob = bpy.data.objects.get(name)
    if ob is None:
        ob = bpy.data.objects.new(name, cd)
        bpy.context.scene.collection.objects.link(ob)
    bpy.context.scene.camera = ob
    return ob


def _look_at(cam, target, eye):
    cam.location = Vector(eye)
    d = Vector(target) - Vector(eye)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type != "MESH":
            continue
        ev = o.evaluated_get(dg)
        for v in ev.to_mesh().vertices:
            w = o.matrix_world @ v.co
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
        ev.to_mesh_clear()
    return lo, hi


def setup_lighting(mode="studio"):
    for n in ("pv_key", "pv_fill", "pv_rim", "pv_spot"):
        o = bpy.data.objects.get(n)
        if o:
            bpy.data.objects.remove(o, do_unlink=True)
    if mode == "night":
        _world((0.035, 0.03, 0.07), 1.0)
        _light("pv_key", "SPOT", (0.6, -0.9, 1.4), (math.radians(50), 0, math.radians(30)), 60, (1.0, 0.92, 0.75), 0.05, 55)
        _light("pv_rim", "SUN", (0, 0, 0), (math.radians(60), 0, math.radians(200)), 1.2, (0.55, 0.6, 1.0))
    else:
        _world((0.10, 0.085, 0.15), 1.0)
        # 主光从前上方偏右照来（Blender 太阳光沿自身 -Z 方向照射）
        _light("pv_key", "SUN", (0, 0, 0), (math.radians(-48), 0, math.radians(-28)), 3.2, (1.0, 0.96, 0.9))
        _light("pv_fill", "SUN", (0, 0, 0), (math.radians(60), 0, math.radians(30)), 0.7, (0.6, 0.65, 1.0))


def render(path, objs, view="game", res=640, yaw_deg=0.0, transparent=False, margin=1.25, aim_yaw=None, ortho=False):
    """view: game / front / side / back / top / three_quarter / turntable(yaw_deg)"""
    sc = _scene()
    sc.render.resolution_x = res
    sc.render.resolution_y = res
    sc.render.film_transparent = transparent
    cam = _camera()
    lo, hi = bounds(objs)
    c = (lo + hi) / 2
    size = max((hi - lo).length, 0.05)
    cam.data.lens_unit = "FOV"
    if ortho:
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = size * margin
    else:
        cam.data.type = "PERSP"
    if view == "game":
        fov = math.radians(GAME_FOV_DEG)
        cam.data.angle = fov
        pitch = math.radians(GAME_PITCH_DEG)
        dist = size * margin / (2 * math.tan(fov / 2))
        eye = c + Vector((0, -math.cos(pitch) * dist, math.sin(pitch) * dist))
    else:
        fov = math.radians(30)
        cam.data.angle = fov
        dist = size * margin / (2 * math.tan(fov / 2))
        yaw = {"front": 0, "side": 90, "back": 180, "three_quarter": 35, "turntable": yaw_deg, "top": 0, "icon_side": 72, "icon3q": 30}.get(view, yaw_deg)
        elev = {"top": 89.0, "three_quarter": 22.0, "turntable": 12.0, "icon_side": 18.0, "icon3q": 30.0}.get(view, 6.0)
        y = math.radians(yaw)
        e = math.radians(elev)
        eye = c + Vector((math.sin(y) * math.cos(e) * dist, math.cos(y) * math.cos(e) * dist, math.sin(e) * dist))
    _look_at(cam, c, eye)
    cam.data.clip_start = 0.01
    cam.data.clip_end = 100
    sc.render.filepath = path
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    return path


def prepare(objs, outline=0.0035):
    materials.setup_preview_materials()
    if outline > 0:
        materials.add_preview_outlines([o for o in objs if o.type == "MESH"], outline)
