"""野怪与宠物（批次 2，风格统一的简化版）：
- mob_roach：蟑螂（中立）。腿分两组 legsA / legsB（Godot 里交替摆动做爬行），触角 antennae。
- mob_rat：持枪老鼠（中立）。head / tail / gun 单独节点（头转向、尾巴摆、枪口后坐），muzzle 挂点。
- mob_boss：鼠王 Boss。老鼠放大 + 紫色披风 + 金链；crown 单独节点（击杀后掉落 / 归属特效用），muzzle 挂点。
- pet_chick：小鸡战友（啄人）。pet_firefly：萤火虫（发光尾部）。pet_hedgehog：刺猬炮台（背刺，muzzle 挂点）。
坐标：+Y 朝前，+Z 向上，脚底在 z=0。尺寸按 GDD 第 4 节的半径（原型单位 cm → 米）。
"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg


def _root(name, objs):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH":
            shapes.bake_outline_normals(o)
    return root


def _node(name, parts, pivot):
    """把若干部件合成一个可动节点，原点放在 pivot（旋转中心）。"""
    m = shapes.join(parts, name)
    pv = Vector(pivot)
    for v in m.data.vertices:
        v.co -= pv
    m.location = pv
    return m


# ---------------------------------------------------------------------------
# 蟑螂（半径 11 → 身长约 0.24 m）
# ---------------------------------------------------------------------------

def roach():
    s = 0.011  # 原型 q=10 → 0.1 m；这里按 0.011/单位 略放大
    body = [
        shapes.quad_sphere("abdomen", (0, -0.065, 0.05), (0.072, 0.085, 0.036), 2, "roach_dark", style.MAT_TOON),
        shapes.quad_sphere("thorax", (0, 0.0, 0.054), (0.075, 0.075, 0.042), 2, "roach_brown", style.MAT_TOON),
        shapes.quad_sphere("pronotum", (0, 0.07, 0.062), (0.058, 0.046, 0.024), 2, "wood", style.MAT_TOON),
        shapes.quad_sphere("head", (0, 0.11, 0.045), (0.04, 0.036, 0.034), 2, "roach_dark", style.MAT_TOON),
    ]
    for sgn in (-1, 1):
        w = shapes.quad_sphere(f"wing{sgn}", (sgn * 0.026, -0.03, 0.084), (0.034, 0.11, 0.01), 2, "wood", style.MAT_TOON)
        shapes.transform(w, rot=(0, 0, deg(-7 * sgn)))
        body.append(w)
        body.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.02, 0.135, 0.06), (0.015, 0.015, 0.015), 12, 8, "eye_white", style.MAT_EYE))
        body.append(shapes.uv_sphere(f"pupil{sgn}", (sgn * 0.022, 0.148, 0.062), (0.0075, 0.0075, 0.0075), 10, 6, "eye_black", style.MAT_EYE))
        body.append(shapes.capsule(f"cerci{sgn}", (sgn * 0.02, -0.14, 0.04), (sgn * 0.04, -0.19, 0.05), 0.004, 6, 2, "roach_dark", style.MAT_TOON))
    body.append(shapes.rounded_box("seam", (0, -0.03, 0.093), (0.004, 0.2, 0.004), 0.0, 1, "roach_dark", style.MAT_FLAT))
    bodym = shapes.join(body, "body")

    def leg(i, sgn, name):
        bx = i * 0.045
        kx = bx + i * 0.03
        fx = bx + i * 0.045
        return [
            shapes.capsule(name + "a", (sgn * 0.045, bx, 0.042), (sgn * 0.1, kx, 0.068), 0.0075, 6, 2, "roach_dark", style.MAT_TOON),
            shapes.capsule(name + "b", (sgn * 0.1, kx, 0.068), (sgn * 0.14, fx, 0.004), 0.0055, 6, 2, "roach_dark", style.MAT_TOON),
        ]
    LA = leg(1, -1, "la0") + leg(0, 1, "la1") + leg(-1, -1, "la2")
    LB = leg(1, 1, "lb0") + leg(0, -1, "lb1") + leg(-1, 1, "lb2")
    legsA = _node("legsA", LA, (0, 0, 0.05))
    legsB = _node("legsB", LB, (0, 0, 0.05))
    ant = []
    for sgn in (-1, 1):
        pts = [(sgn * 0.015, 0.13, 0.06), (sgn * 0.05, 0.19, 0.1), (sgn * 0.065, 0.25, 0.09), (sgn * 0.055, 0.3, 0.07)]
        for k in range(3):
            ant.append(shapes.capsule(f"ant{sgn}{k}", pts[k], pts[k + 1], 0.0032, 6, 2, "roach_dark", style.MAT_TOON))
    antennae = _node("antennae", ant, (0, 0.13, 0.06))
    return _root("mob_roach", [bodym, legsA, legsB, antennae])


# ---------------------------------------------------------------------------
# 持枪老鼠（半径 19 → 身长约 0.38 m）
# ---------------------------------------------------------------------------

def _rat_parts(k=1.0, boss=False):
    """返回 (body, head, tail, gun, feet, muzzle 位置)；k = 整体缩放。"""
    def S(v):
        return tuple(c * k for c in v)
    body = [
        shapes.quad_sphere("torso", S((0, -0.01, 0.17)), S((0.15, 0.17, 0.155)), 3, "rat_grey", style.MAT_TOON),
        shapes.quad_sphere("belly", S((0, 0.07, 0.15)), S((0.1, 0.085, 0.105)), 2, "can_grey", style.MAT_TOON),
        shapes.quad_sphere("back", S((0, -0.07, 0.24)), S((0.1, 0.1, 0.05)), 2, "rat_dark", style.MAT_TOON),
    ]
    if not boss:
        body.append(shapes.torus("scarf", S((0, 0.03, 0.25)), 0.1 * k, 0.026 * k, "Z", 20, 6, "shell_red", style.MAT_TOON, scale=(1.0, 0.9, 1.0)))
        body.append(shapes.rounded_box("scarftail", S((0.05, -0.06, 0.22)), S((0.04, 0.08, 0.02)), 0.008 * k, 2, "headband_red", style.MAT_TOON, rot=(deg(-30), deg(20), 0)))
    for sgn in (-1, 1):
        body.append(shapes.quad_sphere(f"foot{sgn}", S((sgn * 0.07, 0.05, 0.016)), S((0.035, 0.05, 0.018)), 2, "ear_inner", style.MAT_TOON))
        body.append(shapes.quad_sphere(f"hfoot{sgn}", S((sgn * 0.08, -0.1, 0.02)), S((0.04, 0.06, 0.022)), 2, "ear_inner", style.MAT_TOON))
    head = [
        shapes.quad_sphere("skull", S((0, 0.0, 0.0)), S((0.105, 0.11, 0.1)), 3, "rat_grey", style.MAT_TOON),
        shapes.quad_sphere("snout", S((0, 0.1, -0.03)), S((0.06, 0.08, 0.05)), 2, "can_grey", style.MAT_TOON),
        shapes.uv_sphere("nose", S((0, 0.17, -0.02)), S((0.018, 0.016, 0.016)), 12, 8, "nose_pink", style.MAT_TOON),
    ]
    for sgn in (-1, 1):
        head.append(shapes.quad_sphere(f"ear{sgn}", S((sgn * 0.09, -0.03, 0.09)), S((0.06, 0.02, 0.065)), 2, "rat_grey", style.MAT_TOON))
        head.append(shapes.quad_sphere(f"earin{sgn}", S((sgn * 0.09, -0.018, 0.09)), S((0.042, 0.008, 0.046)), 2, "ear_inner", style.MAT_TOON))
        head.append(shapes.rounded_box(f"tooth{sgn}", S((sgn * 0.009, 0.15, -0.065)), S((0.012, 0.008, 0.022)), 0.002 * k, 1, "tooth", style.MAT_TOON))
        head.append(shapes.uv_sphere(f"eye{sgn}", S((sgn * 0.045, 0.09, 0.03)), S((0.018, 0.012, 0.016)), 10, 6, "flare_red", style.MAT_EMISSIVE))
        for w in (-1, 1):
            head.append(shapes.capsule(f"wh{sgn}{w}", S((sgn * 0.04, 0.14, -0.02 + w * 0.008)), S((sgn * 0.13, 0.12, -0.01 + w * 0.02)), 0.002 * k, 4, 1, "rat_dark", style.MAT_FLAT))
    if boss:
        head.append(shapes.rounded_box("monocle", S((0.045, 0.1, 0.035)), S((0.004, 0.004, 0.004)), 0.0, 1, "crown_gold", style.MAT_METAL))
        head.append(shapes.torus("monoring", S((0.045, 0.1, 0.03)), 0.024 * k, 0.004 * k, "Y", 16, 4, "crown_gold", style.MAT_METAL))
    else:
        head.append(shapes.rounded_box("goggles", S((0, 0.085, 0.03)), S((0.13, 0.03, 0.035)), 0.01 * k, 2, "rubber", style.MAT_TOON))
        head.append(shapes.quad_sphere("cap", S((0, -0.01, 0.075)), S((0.1, 0.1, 0.055)), 2, "gear_navy", style.MAT_TOON))
        head.append(shapes.rounded_box("visor", S((0, 0.09, 0.07)), S((0.1, 0.07, 0.01)), 0.004 * k, 2, "gear_navy_light", style.MAT_TOON, rot=(deg(-12), 0, 0)))
        head.append(shapes.uv_sphere("badge", S((0, 0.075, 0.105)), S((0.015, 0.006, 0.015)), 10, 6, "snack_orange", style.MAT_TOON))
    tail_pts = [S((0, -0.15, 0.1)), S((0.04, -0.27, 0.05)), S((-0.03, -0.38, 0.06)), S((0.03, -0.48, 0.04)), S((0.0, -0.56, 0.05))]
    tail = []
    for i in range(len(tail_pts) - 1):
        r0 = 0.018 * k * (1 - i / 5)
        tail.append(shapes.capsule(f"tail{i}", tail_pts[i], tail_pts[i + 1], r0, 8, 2, "ear_inner", style.MAT_TOON))
    gun = [
        shapes.rounded_box("gbody", S((0, 0.06, 0)), S((0.05, 0.18, 0.055)), 0.01 * k, 2, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("gstripe", S((0, 0.04, 0.03)), S((0.052, 0.08, 0.01)), 0.0, 1, "snack_orange", style.MAT_FLAT),
        shapes.rounded_box("gbarrel", S((0, 0.18, 0.005)), S((0.03, 0.07, 0.03)), 0.008 * k, 2, "gun_darker", style.MAT_METAL),
    ]
    for sgn in (-1, 1):
        gun.append(shapes.quad_sphere(f"paw{sgn}", S((sgn * 0.035, 0.0 + (0.08 if sgn < 0 else 0.0), -0.02)), S((0.025, 0.022, 0.022)), 2, "can_grey", style.MAT_TOON))
    return body, head, tail, gun


def rat():
    body, head, tail, gun = _rat_parts(1.0)
    bm = shapes.join(body, "body")
    hd = _node("head", head, (0, 0, 0))
    hd.location = (0, 0.14, 0.33)
    tl = _node("tail", tail, (0, -0.15, 0.1))
    gn = _node("gun", gun, (0, 0, 0))
    gn.location = (0.06, 0.19, 0.17)
    root = _root("mob_rat", [bm, hd, tl, gn])
    shapes.empty("muzzle", (0.06, 0.42, 0.175), parent=root, size=0.02)
    return root


def boss():
    k = 2.4
    body, head, tail, gun = _rat_parts(k, boss=True)
    # 披风 + 金链 + 大肚子
    body.append(shapes.quad_sphere("cape", (0, -0.1 * k, 0.2 * k), (0.17 * k, 0.12 * k, 0.17 * k), 2, "boss_robe", style.MAT_TOON))
    body.append(shapes.torus("collar", (0, 0.0, 0.27 * k), 0.11 * k, 0.03 * k, "Z", 24, 6, "eye_white", style.MAT_TOON))
    for i in range(10):
        a = math.pi * (0.15 + 0.7 * i / 9)
        body.append(shapes.uv_sphere(f"chain{i}", (math.cos(a) * 0.1 * k, 0.04 * k + math.sin(a) * 0.05 * k, 0.24 * k - math.sin(a) * 0.05 * k), (0.012 * k, 0.012 * k, 0.012 * k), 8, 5, "crown_gold", style.MAT_METAL))
    body.append(shapes.uv_sphere("medal", (0, 0.11 * k, 0.17 * k), (0.03 * k, 0.012 * k, 0.03 * k), 12, 8, "crown_gold", style.MAT_METAL))
    bm = shapes.join(body, "body")
    hd = _node("head", head, (0, 0, 0))
    hd.location = (0, 0.14 * k, 0.33 * k)
    tl = _node("tail", tail, (0, -0.15 * k, 0.1 * k))
    gn = _node("gun", gun, (0, 0, 0))
    gn.location = (0.06 * k, 0.19 * k, 0.17 * k)
    cr = [shapes.torus("cband", (0, 0, 0), 0.09, 0.02, "Z", 24, 6, "crown_gold", style.MAT_METAL)]
    for i in range(5):
        a = i / 5 * math.tau
        cr.append(shapes.cylinder(f"cspike{i}", (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.05), 0.0, 0.022, 0.08, "Z", 8, 0.002, "crown_gold", style.MAT_METAL))
        cr.append(shapes.uv_sphere(f"cgem{i}", (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.1), (0.014, 0.014, 0.014), 10, 6, "flare_red", style.MAT_EMISSIVE))
    crown = _node("crown", cr, (0, 0, 0))
    crown.location = (0, 0.12 * k, 0.33 * k + 0.24)
    root = _root("mob_boss", [bm, hd, tl, gn, crown])
    shapes.empty("muzzle", (0.06 * k, 0.42 * k, 0.175 * k), parent=root, size=0.03)
    return root


# ---------------------------------------------------------------------------
# 宠物
# ---------------------------------------------------------------------------

def chick():
    P = [
        shapes.quad_sphere("body", (0, 0, 0.075), (0.08, 0.075, 0.072), 3, "chick_yellow", style.MAT_TOON),
        shapes.quad_sphere("head", (0, 0.045, 0.15), (0.055, 0.052, 0.05), 3, "chick_yellow", style.MAT_TOON),
        shapes.cylinder("beak", (0, 0.105, 0.145), 0.0, 0.016, 0.03, "Y", 8, 0.0, "path_a", style.MAT_TOON),
        shapes.capsule("tuft", (0, 0.04, 0.19), (0.008, 0.03, 0.215), 0.007, 6, 2, "chick_yellow", style.MAT_TOON),
    ]
    for sgn in (-1, 1):
        P.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.024, 0.09, 0.16), (0.009, 0.006, 0.011), 10, 6, "eye_black", style.MAT_EYE))
        P.append(shapes.quad_sphere(f"wing{sgn}", (sgn * 0.075, -0.005, 0.08), (0.016, 0.045, 0.03), 2, "spray_yellow", style.MAT_TOON))
        P.append(shapes.capsule(f"leg{sgn}", (sgn * 0.025, 0.0, 0.02), (sgn * 0.028, 0.012, 0.0), 0.005, 6, 2, "path_a", style.MAT_TOON))
    return _root("pet_chick", [shapes.join(P, "chick")])


def firefly():
    body = [
        shapes.quad_sphere("thorax", (0, 0.02, 0.0), (0.03, 0.035, 0.025), 2, "rubber", style.MAT_TOON),
        shapes.quad_sphere("head", (0, 0.055, 0.004), (0.02, 0.018, 0.018), 2, "rubber", style.MAT_TOON),
        shapes.quad_sphere("glow", (0, -0.035, -0.004), (0.03, 0.042, 0.028), 2, "firefly_glow", style.MAT_EMISSIVE),
    ]
    for sgn in (-1, 1):
        body.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.012, 0.067, 0.01), (0.007, 0.006, 0.007), 8, 5, "eye_white", style.MAT_EYE))
        body.append(shapes.capsule(f"ant{sgn}", (sgn * 0.006, 0.065, 0.015), (sgn * 0.02, 0.095, 0.035), 0.0018, 4, 1, "rubber", style.MAT_TOON))
    bm = shapes.join(body, "body")
    wings = []
    for sgn in (-1, 1):
        w = shapes.quad_sphere(f"wing{sgn}", (sgn * 0.04, 0.015, 0.02), (0.04, 0.02, 0.003), 2, "ice", style.MAT_GLASS)
        wings.append(w)
    wg = _node("wings", wings, (0, 0.015, 0.02))
    return _root("pet_firefly", [bm, wg])


def hedgehog():
    P = [
        shapes.quad_sphere("body", (0, -0.01, 0.065), (0.09, 0.1, 0.07), 3, "hedgehog_brown", style.MAT_TOON),
        shapes.quad_sphere("face", (0, 0.075, 0.055), (0.05, 0.045, 0.045), 2, "towel_cream", style.MAT_TOON),
        shapes.uv_sphere("nose", (0, 0.122, 0.055), (0.012, 0.011, 0.011), 10, 6, "eye_black", style.MAT_TOON),
    ]
    for sgn in (-1, 1):
        P.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.022, 0.1, 0.075), (0.008, 0.006, 0.01), 10, 6, "eye_black", style.MAT_EYE))
        P.append(shapes.quad_sphere(f"foot{sgn}", (sgn * 0.045, 0.04, 0.008), (0.018, 0.022, 0.01), 2, "towel_cream", style.MAT_TOON))
    for i in range(5):
        for j in range(5):
            a = -1.0 + j * 0.5
            b = -0.9 + i * 0.42
            x = math.sin(a) * 0.075
            y = -0.06 + b * 0.06
            z = 0.075 + math.cos(a) * 0.055
            d = Vector((x, y + 0.03, z - 0.05)).normalized()
            tip = Vector((x, y, z)) + d * 0.05
            P.append(shapes.capsule(f"sp{i}{j}", (x, y, z), tuple(tip), 0.007, 6, 2, "spike_dark", style.MAT_TOON, radius1=0.001))
    root = _root("pet_hedgehog", [shapes.join(P, "hedgehog")])
    shapes.empty("muzzle", (0, 0.0, 0.16), parent=root, size=0.02)
    return root


def build(ctx):
    items = [roach(), rat(), boss(), chick(), firefly(), hedgehog()]
    extras = [(r.name, [r]) for r in items]

    def layout(_ctx):
        xs = [0.0, 0.6, 1.6, 2.8, 3.2, 3.6]
        for x, r in zip(xs, items):
            r.location = Vector((x, 0, 0))

    pv = [("all", "three_quarter", {"margin": 1.02, "res": 1000}), ("all_game", "game", {"margin": 1.05, "res": 1000}), ("all_night", "three_quarter", {"margin": 1.02, "res": 1000, "light": "night"})]
    return ctx.Built([], previews=pv, outline=0.0035, extra_exports=extras, after_export=layout)
