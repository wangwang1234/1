"""仓鼠的强化外观挂件（批次 2 简化版；批次 3 统一精修）。每个挂件一个 glb，几何直接用仓鼠模型空间坐标，
游戏里挂到对应骨骼上（HamsterView.ACC 表）：
  acc_vest 护甲背心（spine）  acc_glasses 学者眼镜（head）  acc_nvg 夜视镜（head）  acc_antenna 侦察天线（head）
  acc_headband 狂暴头带（head）  acc_clover 幸运草（head）  acc_fangs 吸血尖牙（head）  acc_bando 子弹带（spine）
  acc_belt 道具腰带（pelvis）  acc_magnet 磁铁（spine）  acc_coilpack 电弧背包（spine）  acc_banner 队旗（spine）
  acc_shoe_L / acc_shoe_R 跑鞋（shin_L / shin_R）
坐标：+Y 朝前，+Z 向上（和 chr_hamster 一致）。预览时临时摆一个仓鼠替身（头、身体、帽子、脚）方便检查位置。
"""
import math

import bpy
from mathutils import Matrix, Vector

from lib import shapes, style
from lib.anim import deg

HEAD_C = Vector((0, 0.012, 0.212))
HEAD_R = Vector((0.135, 0.122, 0.118))
BODY_C = Vector((0, -0.008, 0.098))
BODY_R = Vector((0.104, 0.104, 0.09))


def _root(name, objs):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH":
            shapes.bake_outline_normals(o)
    return root


def _xf(o, m):
    o.data.transform(m)
    return o


def _body_r(z, pad):
    k = 1.0 - ((z - BODY_C.z) / BODY_R.z) ** 2
    return BODY_R.x * math.sqrt(max(0.0, k)) + pad


def vest():
    prof = [(_body_r(z, 0.008), z) for z in (0.034, 0.05, 0.07, 0.09, 0.11, 0.128, 0.14)]
    band = shapes.lathe("vest_band", prof, 28, color="vest_olive", mat=style.MAT_TOON, cap_top=False, cap_bottom=False)
    _xf(band, Matrix.Translation((0, BODY_C.y, 0)))
    P = [band]
    for s in (-1, 1):
        P.append(shapes.rounded_box(f"pocket{s}", (s * 0.042, BODY_C.y + 0.104, 0.085), (0.034, 0.014, 0.03), 0.004, 2, "vest_dark", style.MAT_TOON))
        P.append(shapes.rounded_box(f"flap{s}", (s * 0.042, BODY_C.y + 0.108, 0.1), (0.036, 0.012, 0.008), 0.002, 1, "vest_dark", style.MAT_TOON))
    P.append(shapes.torus("vest_trim", (0, BODY_C.y, 0.136), _body_r(0.136, 0.009), 0.005, "Z", 28, 6, "vest_dark", style.MAT_TOON))
    P.append(shapes.torus("vest_hem", (0, BODY_C.y, 0.036), _body_r(0.036, 0.009), 0.005, "Z", 28, 6, "vest_dark", style.MAT_TOON))
    return _root("acc_vest", [shapes.join(P, "vest")])


def glasses():
    P = []
    for s in (-1, 1):
        r = shapes.torus(f"rim{s}", (s * 0.052, 0.0, 0.0), 0.03, 0.0035, "Y", 24, 6, "gun_darker", style.MAT_METAL)
        _xf(r, Matrix.Translation((0, 0.138, 0.226)))
        P.append(r)
        lens = shapes.cylinder(f"lens{s}", (s * 0.052, 0.137, 0.226), 0.027, None, 0.002, "Y", 20, 0.0, "lens", style.MAT_GLASS)
        P.append(lens)
        P.append(shapes.capsule(f"temple{s}", (s * 0.081, 0.13, 0.232), (s * 0.118, 0.04, 0.245), 0.003, 6, 2, "gun_darker", style.MAT_METAL))
    P.append(shapes.capsule("bridge", (-0.022, 0.142, 0.232), (0.022, 0.142, 0.232), 0.003, 6, 2, "gun_darker", style.MAT_METAL))
    return _root("acc_glasses", [shapes.join(P, "glasses")])


def nvg():
    P = [shapes.torus("strap", (0, 0.012, 0.272), 0.118, 0.006, "Z", 32, 6, "rubber", style.MAT_TOON, scale=(1.0, 0.92, 1.0))]
    P.append(shapes.rounded_box("bridge", (0, 0.124, 0.278), (0.05, 0.02, 0.02), 0.006, 2, "gun_dark", style.MAT_METAL))
    for s in (-1, 1):
        P.append(shapes.cylinder(f"tube{s}", (s * 0.036, 0.135, 0.28), 0.019, 0.016, 0.036, "Y", 18, 0.003, "gun_darker", style.MAT_METAL))
        P.append(shapes.cylinder(f"glass{s}", (s * 0.036, 0.154, 0.28), 0.014, None, 0.003, "Y", 16, 0.0, "poison_green", style.MAT_EMISSIVE))
    return _root("acc_nvg", [shapes.join(P, "nvg")])


def antenna():
    P = [
        shapes.cylinder("base", (0.05, -0.03, 0.352), 0.011, 0.013, 0.012, "Z", 12, 0.002, "gun_dark", style.MAT_METAL),
        shapes.capsule("rod", (0.05, -0.03, 0.355), (0.075, -0.05, 0.45), 0.0028, 6, 2, "gun_steel", style.MAT_METAL),
        shapes.uv_sphere("tip", (0.076, -0.051, 0.456), (0.011, 0.011, 0.011), 12, 8, "flare_red", style.MAT_EMISSIVE),
    ]
    return _root("acc_antenna", [shapes.join(P, "antenna")])


def headband():
    band = shapes.torus("band", (0, 0, 0), 0.121, 0.009, "Z", 36, 6, "headband_red", style.MAT_TOON, scale=(1.0, 0.905, 1.55))
    _xf(band, Matrix.Rotation(deg(-7), 4, "X"))
    _xf(band, Matrix.Translation((0, 0.012, 0.266)))
    P = [band]
    knot = shapes.uv_sphere("knot", (0, -0.104, 0.262), (0.016, 0.012, 0.013), 10, 6, "headband_red", style.MAT_TOON)
    P.append(knot)
    for s in (-1, 1):
        P.append(shapes.capsule(f"tail{s}", (0, -0.108, 0.26), (s * 0.03, -0.142, 0.215), 0.007, 8, 2, "headband_red", style.MAT_TOON, radius1=0.004))
    return _root("acc_headband", [shapes.join(P, "headband")])


def clover():
    c = Vector((0.092, 0.035, 0.318))
    P = []
    for i in range(4):
        a = i / 4 * math.tau + math.pi / 4
        P.append(shapes.uv_sphere(f"leaf{i}", c + Vector((math.cos(a) * 0.011, 0.004, math.sin(a) * 0.011)), (0.011, 0.004, 0.011), 10, 5, "clover", style.MAT_TOON))
    P.append(shapes.capsule("stem", c + Vector((0, 0.002, -0.004)), c + Vector((0.004, 0.0, -0.022)), 0.0018, 6, 2, "clover_dark", style.MAT_TOON))
    root = shapes.join(P, "clover")
    _xf(root, Matrix.Translation(-c) )
    _xf(root, Matrix.Rotation(deg(-55), 4, "Z"))
    _xf(root, Matrix.Translation(c))
    return _root("acc_clover", [root])


def fangs():
    P = []
    for s in (-1, 1):
        P.append(shapes.cylinder(f"fang{s}", (s * 0.012, 0.128, 0.168), 0.0055, 0.0, 0.016, "Z", 10, 0.0, "tooth", style.MAT_TOON))
    root = shapes.join(P, "fangs")
    # 尖朝下：圆锥默认尖朝上（r_bottom=0 在 -Z），这里翻一下
    _xf(root, Matrix.Translation((0, -0.128, -0.168)))
    _xf(root, Matrix.Rotation(math.pi, 4, "X"))
    _xf(root, Matrix.Translation((0, 0.128, 0.168)))
    return _root("acc_fangs", [root])


def bando():
    strap = shapes.torus("strap", (0, 0, 0), 0.113, 0.0065, "Z", 36, 6, "wood_dark", style.MAT_TOON, scale=(1.0, 1.0, 1.6))
    _xf(strap, Matrix.Rotation(deg(38), 4, "Y"))
    _xf(strap, Matrix.Translation((0, BODY_C.y, 0.09)))
    P = [strap]
    for i in range(7):
        t = -0.55 + i * 0.18
        # 沿前半圈摆子弹
        local = Vector((math.cos(math.pi / 2 + t) * 0.118, math.sin(math.pi / 2 + t) * 0.118, 0.0))
        p = Matrix.Translation((0, BODY_C.y, 0.09)) @ Matrix.Rotation(deg(38), 4, "Y") @ local
        sh = shapes.cylinder(f"shell{i}", (0, 0, 0), 0.006, None, 0.022, "Z", 8, 0.001, "brass", style.MAT_METAL)
        _xf(sh, Matrix.Rotation(deg(38), 4, "Y"))
        _xf(sh, Matrix.Translation(p))
        P.append(sh)
    return _root("acc_bando", [shapes.join(P, "bando")])


def belt():
    z = 0.052
    P = [shapes.torus("belt", (0, BODY_C.y, z), _body_r(z, 0.006), 0.0075, "Z", 32, 6, "wood_dark", style.MAT_TOON, scale=(1, 1, 1.4))]
    P.append(shapes.rounded_box("buckle", (0, BODY_C.y + _body_r(z, 0.012), z), (0.026, 0.006, 0.02), 0.002, 1, "gold_ring", style.MAT_METAL))
    for s in (-1, 1):
        a = math.radians(90 + s * 55)
        r = _body_r(z, 0.014)
        P.append(shapes.rounded_box(f"pouch{s}", (math.cos(a) * r, BODY_C.y + math.sin(a) * r, z - 0.006), (0.026, 0.02, 0.028), 0.005, 2, "vest_olive", style.MAT_TOON, rot=(0, 0, a - math.pi / 2)))
    return _root("acc_belt", [shapes.join(P, "belt")])


def magnet():
    y = -0.128
    P = []
    for s in (-1, 1):
        P.append(shapes.capsule(f"arm{s}", (s * 0.024, y, 0.112), (s * 0.024, y, 0.15), 0.011, 10, 3, "magnet_red", style.MAT_TOON))
        P.append(shapes.cylinder(f"tip{s}", (s * 0.024, y, 0.158), 0.0115, None, 0.014, "Z", 12, 0.002, "magnet_steel", style.MAT_METAL))
    for i in range(5):
        a0 = math.pi + i / 5 * math.pi
        a1 = math.pi + (i + 1) / 5 * math.pi
        P.append(shapes.capsule(f"arc{i}", (math.cos(a0) * 0.024, y, 0.112 + math.sin(a0) * 0.024), (math.cos(a1) * 0.024, y, 0.112 + math.sin(a1) * 0.024), 0.011, 10, 3, "magnet_red", style.MAT_TOON))
    P.append(shapes.capsule("strapL", (-0.03, y + 0.01, 0.13), (-0.06, 0.02, 0.15), 0.004, 6, 2, "rubber", style.MAT_TOON))
    P.append(shapes.capsule("strapR", (0.03, y + 0.01, 0.13), (0.06, 0.02, 0.15), 0.004, 6, 2, "rubber", style.MAT_TOON))
    return _root("acc_magnet", [shapes.join(P, "magnet")])


def coilpack():
    y = -0.128
    P = [shapes.rounded_box("pack", (0, y, 0.1), (0.07, 0.034, 0.075), 0.01, 2, "gun_dark", style.MAT_METAL)]
    for k in range(4):
        P.append(shapes.torus(f"coil{k}", (0, y - 0.004, 0.148 + k * 0.012), 0.014 - k * 0.002, 0.0035, "Z", 16, 6, "copper", style.MAT_METAL))
    P.append(shapes.capsule("rod", (0, y - 0.004, 0.14), (0, y - 0.004, 0.2), 0.004, 6, 2, "gun_steel", style.MAT_METAL))
    P.append(shapes.uv_sphere("orb", (0, y - 0.004, 0.207), (0.013, 0.013, 0.013), 12, 8, "rail_cyan", style.MAT_EMISSIVE))
    for s in (-1, 1):
        P.append(shapes.capsule(f"strap{s}", (s * 0.03, y + 0.015, 0.13), (s * 0.06, 0.02, 0.15), 0.004, 6, 2, "rubber", style.MAT_TOON))
    return _root("acc_coilpack", [shapes.join(P, "coilpack")])


def banner():
    x, y = 0.032, -0.125
    P = [
        shapes.cylinder("pole", (x, y, 0.25), 0.0045, None, 0.34, "Z", 8, 0.001, "gun_dark", style.MAT_METAL),
        shapes.uv_sphere("knob", (x, y, 0.425), (0.008, 0.008, 0.008), 10, 6, "gold_ring", style.MAT_METAL),
        shapes.rounded_box("holder", (x, y + 0.01, 0.1), (0.016, 0.02, 0.04), 0.004, 1, "rubber", style.MAT_TOON),
    ]
    flag = shapes.extrude_profile("flag", [(0.0, 0.0), (-0.085, 0.004), (-0.075, -0.03), (-0.085, -0.064), (0.0, -0.06)], 0.004, plane="YZ", color="team_main", mat=style.MAT_TEAM)
    _xf(flag, Matrix.Translation((x, y - 0.004, 0.41)))
    P.append(flag)
    P.append(shapes.rounded_box("emblem", (x + 0.003, y - 0.045, 0.378), (0.003, 0.024, 0.024), 0.004, 1, "team_light", style.MAT_TEAM))
    return _root("acc_banner", [shapes.join(P, "banner")])


def shoe(side):
    s = -1 if side == "L" else 1
    c = Vector((s * 0.055, 0.047, 0.013))
    P = [
        shapes.uv_sphere("shoe", c, (0.031, 0.046, 0.02), 14, 8, "shoe_red", style.MAT_TOON),
        shapes.cylinder("sole", c + Vector((0, 0, -0.011)), 0.03, None, 0.006, "Z", 16, 0.002, "white", style.MAT_TOON),
        shapes.capsule("stripe", c + Vector((s * 0.026, -0.02, 0.006)), c + Vector((s * 0.03, 0.012, 0.0)), 0.004, 6, 2, "white", style.MAT_TOON),
    ]
    sole = P[1]
    sole.scale = (1.0, 1.5, 1.0)
    return _root("acc_shoe_" + side, [shapes.join(P, "shoe_" + side)])


def _proxy(parent):
    """预览用仓鼠替身（不导出）"""
    import importlib.util, os
    here = os.path.dirname(__file__)
    spec = importlib.util.spec_from_file_location("chr_hamster_ref", os.path.join(here, "chr_hamster.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    objs = [
        shapes.quad_sphere("px_head", HEAD_C, HEAD_R, subdiv=3, color="fur_gold", mat=style.MAT_SKIN),
        shapes.quad_sphere("px_body", BODY_C, BODY_R, subdiv=3, color="fur_gold", mat=style.MAT_SKIN),
        mod.build_cap(),
    ]
    for s in (-1, 1):
        objs.append(shapes.uv_sphere(f"px_foot{s}", (s * 0.055, 0.046, 0.012), (0.025, 0.037, 0.013), 10, 6, "paw", style.MAT_TOON))
        objs.append(shapes.uv_sphere(f"px_eye{s}", (s * 0.052, 0.13, 0.228), (0.02, 0.008, 0.026), 10, 6, "eye_black", style.MAT_EYE))
    for o in objs:
        o.parent = parent
        shapes.bake_outline_normals(o)


def build(ctx):
    items = [vest(), glasses(), nvg(), antenna(), headband(), clover(), fangs(), bando(), belt(), magnet(), coilpack(), banner(), shoe("L"), shoe("R")]
    extras = [(r.name, [r]) for r in items]
    holder = {}

    def after(_ctx):
        root = bpy.data.objects.new("preview_proxy", None)
        bpy.context.scene.collection.objects.link(root)
        root.parent = items[0]
        _proxy(root)

    pv = [("all_front", "front", {"margin": 1.15, "res": 900}), ("all_back", "back", {"margin": 1.15, "res": 900}),
          ("all_three", "three_quarter", {"margin": 1.15, "res": 900})]
    return ctx.Built([], previews=pv, outline=0.0035, extra_exports=extras, after_export=after)
