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
    # 油亮的背壳：翅膀上两道浅色高光条 + 前胸背板浅色边
    for sgn in (-1, 1):
        for k, (y, L) in enumerate(((-0.0, 0.07), (-0.07, 0.05))):
            hl = shapes.rounded_box(f"gloss{sgn}{k}", (sgn * (0.03 - k * 0.004), y, 0.0945 - k * 0.004), (0.006, L, 0.002), 0.0, 1, "cardboard_light", style.MAT_FLAT)
            shapes.transform(hl, rot=(0, 0, deg(-7 * sgn)))
            body.append(hl)
    body.append(shapes.torus("rim", (0, 0.07, 0.07), 0.05, 0.005, "Z", 18, 4, "cardboard_dark", style.MAT_TOON, scale=(1.1, 0.85, 1.0)))
    for sgn in (-1, 1):
        body.append(shapes.capsule(f"mandible{sgn}", (sgn * 0.012, 0.135, 0.032), (sgn * 0.004, 0.152, 0.026), 0.004, 6, 2, "roach_dark", style.MAT_TOON))
    bodym = shapes.join(body, "body")

    def leg(i, sgn, name):
        bx = i * 0.045
        kx = bx + i * 0.03
        fx = bx + i * 0.045
        out = [
            shapes.capsule(name + "a", (sgn * 0.045, bx, 0.042), (sgn * 0.1, kx, 0.068), 0.0075, 6, 2, "roach_dark", style.MAT_TOON),
            shapes.capsule(name + "b", (sgn * 0.1, kx, 0.068), (sgn * 0.14, fx, 0.004), 0.0055, 6, 2, "roach_dark", style.MAT_TOON),
        ]
        # 腿上的小刺
        for t in (0.35, 0.65):
            px = sgn * (0.1 + 0.04 * t)
            py = kx + (fx - kx) * t
            pz = 0.068 - 0.064 * t
            out.append(shapes.capsule(name + f"sp{t}", (px, py, pz), (px + sgn * 0.012, py - 0.006, pz + 0.008), 0.0022, 4, 1, "roach_dark", style.MAT_TOON, radius1=0.0006))
        return out
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
        # 斜挎弹带 + 黄铜子弹
        for i in range(7):
            t = i / 6
            bx = (-0.11 + 0.22 * t) * k
            bz = (0.08 + 0.17 * t) * k
            by = (0.1 + 0.05 * (1 - abs(t - 0.5) * 2)) * k
            body.append(shapes.rounded_box(f"bando{i}", (bx, by, bz), (0.03 * k, 0.012 * k, 0.03 * k), 0.004 * k, 1, "vest_dark", style.MAT_TOON, rot=(0, deg(-38), 0)))
            body.append(shapes.cylinder(f"bullet{i}", (bx, by + 0.008 * k, bz), 0.0065 * k, None, 0.026 * k, "Z", 8, 0.001, "brass", style.MAT_METAL))
            shapes.transform(body[-1], loc=(0, 0, 0))
        body.append(shapes.rounded_box("belt", S((0, 0.0, 0.08)), S((0.25, 0.25, 0.026)), 0.01 * k, 2, "vest_dark", style.MAT_TOON))
        body.append(shapes.rounded_box("buckle", S((0, 0.125, 0.08)), S((0.04, 0.012, 0.03)), 0.004 * k, 1, "brass", style.MAT_METAL))
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
    # 耳朵缺口 + 脸上的疤
    head.append(shapes.cylinder("notch", S((0.12, -0.028, 0.13)), 0.014 * k, None, 0.024 * k, "Y", 10, 0.0, "rat_dark", style.MAT_TOON))
    head.append(shapes.rounded_box("scar", S((-0.06, 0.085, 0.055)), S((0.004, 0.004, 0.04)), 0.0, 1, "ear_inner", style.MAT_FLAT, rot=(0, deg(30), 0)))
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
    gmetal = "gun_gold" if boss else "gun_dark"
    gun = [
        shapes.rounded_box("gbody", S((0, 0.06, 0)), S((0.05, 0.18, 0.055)), 0.01 * k, 2, gmetal, style.MAT_METAL),
        shapes.rounded_box("gstripe", S((0, 0.04, 0.0285)), S((0.052, 0.08, 0.004)), 0.0, 1, "boss_robe" if boss else "snack_orange", style.MAT_FLAT),
        shapes.cylinder("gbarrel", S((0, 0.19, 0.008)), 0.012 * k, None, 0.09 * k, "Y", 12, 0.002 * k, "gun_darker", style.MAT_METAL),
        shapes.cylinder("gjacket", S((0, 0.175, 0.008)), 0.018 * k, None, 0.05 * k, "Y", 12, 0.002 * k, gmetal, style.MAT_METAL),
        shapes.cylinder("gmuzzle", S((0, 0.236, 0.008)), 0.016 * k, None, 0.014 * k, "Y", 12, 0.002 * k, "gun_darker", style.MAT_METAL),
        shapes.cylinder("gdrum", S((0, 0.07, -0.05)), 0.042 * k, None, 0.034 * k, "X", 18, 0.004 * k, "gun_darker" if boss else "polymer_olive", style.MAT_METAL),
        shapes.cylinder("gdrumcap", S((0.018, 0.07, -0.05)), 0.02 * k, None, 0.004 * k, "X", 14, 0.001 * k, "crown_gold" if boss else "brass", style.MAT_METAL),
        shapes.rounded_box("gstock", S((0, -0.07, -0.005)), S((0.034, 0.1, 0.04)), 0.008 * k, 2, "wood_red", style.MAT_TOON),
        shapes.rounded_box("gfore", S((0, 0.13, -0.03)), S((0.026, 0.03, 0.04)), 0.006 * k, 2, "wood_red", style.MAT_TOON),
    ]
    for kk in range(3):
        gun.append(shapes.cylinder(f"ghole{kk}", S((0.0182, 0.162 + kk * 0.014, 0.008)), 0.004 * k, None, 0.002, "X", 8, 0, "rubber", style.MAT_FLAT))
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
    shapes.empty("muzzle", (0.06, 0.44, 0.178), parent=root, size=0.02)
    return root


def _cape(k):
    """斗篷曲面：身后 220° 的圆台面，上窄下宽、向后倾斜，带厚度；下摆起波浪褶。"""
    import bmesh
    bm = bmesh.new()
    NU, NV = 22, 8
    th0, th1 = math.radians(-110), math.radians(110)
    z_top, z_bot = 0.3 * k, 0.012 * k
    thick = 0.012 * k
    outer, inner = [], []
    for j in range(NV + 1):
        t = j / NV
        z = z_top + (z_bot - z_top) * t
        r = (0.105 + 0.11 * t ** 0.8) * k
        rowo, rowi = [], []
        for i in range(NU + 1):
            u = i / NU
            th = th0 + (th1 - th0) * u
            rr = r + 0.012 * k * math.sin(th * 5.0) * t * t
            back = 0.04 * k * t
            x = math.sin(th) * rr
            y = -math.cos(th) * rr * 0.85 - 0.06 * k - back
            rowo.append(bm.verts.new((x, y, z)))
            ri = rr - thick
            rowi.append(bm.verts.new((math.sin(th) * ri, -math.cos(th) * ri * 0.85 - 0.06 * k - back, z)))
        outer.append(rowo)
        inner.append(rowi)
    for j in range(NV):
        for i in range(NU):
            bm.faces.new((outer[j][i], outer[j + 1][i], outer[j + 1][i + 1], outer[j][i + 1]))
            bm.faces.new((inner[j][i], inner[j][i + 1], inner[j + 1][i + 1], inner[j + 1][i]))
    for j in range(NV):
        for i in (0, NU):
            a, b, c, d = outer[j][i], outer[j + 1][i], inner[j + 1][i], inner[j][i]
            bm.faces.new((a, d, c, b) if i == 0 else (a, b, c, d))
    for i in range(NU):
        for j in (0, NV):
            a, b, c, d = outer[j][i], outer[j][i + 1], inner[j][i + 1], inner[j][i]
            bm.faces.new((a, b, c, d) if j == 0 else (a, d, c, b))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = shapes.obj_from_bmesh("cape", bm)
    shapes.set_material(obj, style.MAT_TOON)
    shapes.paint(obj, "boss_robe")
    # 内衬（朝里的面）红色；下摆一圈金边
    shapes.paint_where(obj, "tassel_red", lambda c, n: (n.x * c.x + n.y * (c.y + 0.06 * k)) < 0)
    shapes.paint_where(obj, "crown_gold", lambda c, n: c.z < 0.045 * k)
    shapes.smooth(obj, 50)
    return obj


def boss():
    k = 2.4
    body, head, tail, gun = _rat_parts(k, boss=True)
    # 貂皮领（白底黑点）+ 红色绶带 + 金链 + 勋章 + 大肚子
    body.append(shapes.torus("collar", (0, 0.0, 0.27 * k), 0.115 * k, 0.034 * k, "Z", 24, 6, "eye_white", style.MAT_TOON))
    for i in range(14):
        a = i / 14 * math.tau
        r = 0.115 * k + 0.02 * k * (1 if i % 2 else -1) * 0.5
        body.append(shapes.uv_sphere(f"ermine{i}", (math.cos(a) * r, math.sin(a) * r, 0.27 * k + 0.03 * k), (0.008 * k, 0.008 * k, 0.004 * k), 6, 4, "eye_black", style.MAT_FLAT))
    for i in range(9):
        t = i / 8
        sx = (-0.12 + 0.24 * t) * k
        sz = (0.26 - 0.19 * t) * k
        sy = (0.11 + 0.05 * (1 - abs(t - 0.5) * 2)) * k
        body.append(shapes.rounded_box(f"sash{i}", (sx, sy, sz), (0.06 * k, 0.014 * k, 0.03 * k), 0.006 * k, 1, "tassel_red", style.MAT_TOON, rot=(0, deg(40), 0)))
    for i in range(10):
        a = math.pi * (0.15 + 0.7 * i / 9)
        body.append(shapes.uv_sphere(f"chain{i}", (math.cos(a) * 0.1 * k, 0.04 * k + math.sin(a) * 0.05 * k, 0.24 * k - math.sin(a) * 0.05 * k), (0.012 * k, 0.012 * k, 0.012 * k), 8, 5, "crown_gold", style.MAT_METAL))
    body.append(shapes.uv_sphere("medal", (0, 0.13 * k, 0.17 * k), (0.032 * k, 0.012 * k, 0.032 * k), 12, 8, "crown_gold", style.MAT_METAL))
    body.append(shapes.uv_sphere("medalgem", (0, 0.142 * k, 0.17 * k), (0.012 * k, 0.006 * k, 0.012 * k), 10, 6, "flare_red", style.MAT_EMISSIVE))
    bm = shapes.join(body, "body")
    # 披风：单独节点（肩部为轴，Godot 里随移动和呼吸摆动）——从肩膀垂到地面的弧形斗篷，下摆有褶皱，紫色外层 + 红色内衬 + 金边
    cp = [_cape(k)]
    for i in range(5):
        a = math.radians(-60 + 30 * i)
        r = 0.205 * k
        cp.append(shapes.uv_sphere(f"capestar{i}", (math.sin(a) * r, -math.cos(a) * r * 0.85 - 0.06 * k - 0.006 * k, 0.1 * k), (0.016 * k, 0.016 * k, 0.016 * k), 8, 4, "crown_gold", style.MAT_METAL))
    cape = _node("cape", cp, (0, -0.06 * k, 0.3 * k))
    hd = _node("head", head, (0, 0, 0))
    hd.location = (0, 0.14 * k, 0.33 * k)
    tl = _node("tail", tail, (0, -0.15 * k, 0.1 * k))
    gn = _node("gun", gun, (0, 0, 0))
    gn.location = (0.06 * k, 0.19 * k, 0.17 * k)
    # 王冠：金冠圈 + 5 个尖 + 宝石 + 红丝绒内帽 + 白色毛边
    cr = [
        shapes.cylinder("cband", (0, 0, 0.02), 0.12, 0.115, 0.05, "Z", 24, 0.004, "crown_gold", style.MAT_METAL, caps=False),
        shapes.torus("cbase", (0, 0, 0.0), 0.12, 0.016, "Z", 24, 6, "eye_white", style.MAT_TOON),
        shapes.quad_sphere("cvelvet", (0, 0, 0.05), (0.105, 0.105, 0.07), 2, "tassel_red", style.MAT_TOON),
        shapes.uv_sphere("ctopball", (0, 0, 0.13), (0.02, 0.02, 0.02), 10, 6, "crown_gold", style.MAT_METAL),
    ]
    for i in range(5):
        a = i / 5 * math.tau
        cr.append(shapes.cylinder(f"cspike{i}", (math.cos(a) * 0.115, math.sin(a) * 0.115, 0.075), 0.0, 0.028, 0.1, "Z", 8, 0.002, "crown_gold", style.MAT_METAL))
        cr.append(shapes.uv_sphere(f"ctip{i}", (math.cos(a) * 0.115, math.sin(a) * 0.115, 0.13), (0.012, 0.012, 0.012), 8, 6, "crown_gold", style.MAT_METAL))
        b = a + math.tau / 10
        cr.append(shapes.uv_sphere(f"cgem{i}", (math.cos(b) * 0.122, math.sin(b) * 0.122, 0.022), (0.016, 0.01, 0.016), 10, 6, "flare_red" if i % 2 == 0 else "pilot_blue", style.MAT_EMISSIVE))
    crown = _node("crown", cr, (0, 0, 0))
    crown.location = (0, 0.12 * k, 0.33 * k + 0.2)
    root = _root("mob_boss", [bm, cape, hd, tl, gn, crown])
    shapes.empty("muzzle", (0.06 * k, 0.44 * k, 0.178 * k), parent=root, size=0.03)
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
        P.append(shapes.uv_sphere(f"blush{sgn}", (sgn * 0.038, 0.082, 0.138), (0.011, 0.004, 0.007), 8, 4, "blush", style.MAT_FLAT))
        P.append(shapes.uv_sphere(f"eyehl{sgn}", (sgn * 0.022, 0.095, 0.165), (0.003, 0.002, 0.003), 6, 4, "white", style.MAT_FLAT))
        P.append(shapes.capsule(f"toe{sgn}", (sgn * 0.028, 0.012, 0.0), (sgn * 0.036, 0.026, 0.0), 0.003, 6, 2, "path_a", style.MAT_TOON))
    # 尾羽 + 队伍色小围巾（看得出是谁的宠物）
    for i in range(3):
        P.append(shapes.capsule(f"tail{i}", (0, -0.06, 0.09), ((i - 1) * 0.014, -0.095, 0.12), 0.008, 6, 2, "spray_yellow", style.MAT_TOON))
    P.append(shapes.torus("scarf", (0, 0.03, 0.112), 0.05, 0.011, "Z", 18, 5, "team_main", style.MAT_TEAM, scale=(1.0, 0.95, 1.0)))
    P.append(shapes.rounded_box("scarftail", (0.03, -0.035, 0.1), (0.02, 0.03, 0.008), 0.004, 1, "team_dark", style.MAT_TEAM, rot=(deg(-30), deg(15), 0)))
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
        body.append(shapes.uv_sphere(f"anttip{sgn}", (sgn * 0.02, 0.095, 0.035), (0.004, 0.004, 0.004), 6, 4, "firefly_glow", style.MAT_EMISSIVE))
    for i in range(2):
        body.append(shapes.torus(f"stripe{i}", (0, -0.012 - i * 0.016, -0.003), 0.0285 - i * 0.002, 0.003, "Y", 14, 4, "rubber", style.MAT_TOON, scale=(1.0, 1.0, 0.95)))
    body.append(shapes.torus("collar", (0, 0.04, 0.002), 0.018, 0.004, "Y", 14, 4, "team_main", style.MAT_TEAM))
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
        P.append(shapes.quad_sphere(f"ear{sgn}", (sgn * 0.035, 0.07, 0.1), (0.014, 0.008, 0.014), 2, "hedgehog_brown", style.MAT_TOON))
        P.append(shapes.uv_sphere(f"blush{sgn}", (sgn * 0.034, 0.105, 0.05), (0.01, 0.004, 0.006), 8, 4, "blush", style.MAT_FLAT))
        P.append(shapes.uv_sphere(f"eyehl{sgn}", (sgn * 0.02, 0.106, 0.079), (0.0025, 0.002, 0.003), 6, 4, "white", style.MAT_FLAT))
    P.append(shapes.torus("scarf", (0, 0.05, 0.05), 0.055, 0.011, "Z", 18, 5, "team_main", style.MAT_TEAM, scale=(1.0, 0.8, 1.0)))
    P.append(shapes.rounded_box("scarfknot", (0.0, 0.09, 0.044), (0.022, 0.012, 0.018), 0.005, 1, "team_dark", style.MAT_TEAM))
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
    ip = [("three_quarter", {"margin": 1.15, "res": 420}), ("game", {"margin": 1.3, "res": 420})]
    return ctx.Built([], previews=pv, outline=0.0035, extra_exports=extras, after_export=layout, item_previews=ip)
