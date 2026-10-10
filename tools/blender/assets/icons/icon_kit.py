"""全套图标（ART_BIBLE 第 9 节：从 3D 模型直接渲染，统一 3/4 视角、带描边、透明底）。不导出模型，只出 PNG：
  game/assets/icons/gad_<道具>.png（13）、pet_<宠物>.png（3）、abl_<强化>.png（22）、tal_<天赋>.png（12）、
  evo_<配件类>_<a|b|c>.png（8 类 × 3 路线色 = 24；54 条进化路线按 evolutions.json 的 attachmentType 对应到这些图）。
武器图标 wpn_<武器>.png 由各武器脚本自己渲染（weapon_kit.previews）。
道具、宠物、配件、强化挂件直接复用对应资产脚本里的造型函数；没有模型的强化和天赋在这里做小徽记。
每个图标先烘成一个网格、居中、统一缩放到同样大小，描边粗细就一致。
"""
import importlib.util
import math
import os

import bpy
from mathutils import Matrix, Vector

from lib import materials, shapes, style
from lib.anim import deg

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
ICONS = os.path.join(ROOT, "game", "assets", "icons")
SIZE = 0.24          # 每个图标烘焙后最大边长（米）
T = style.MAT_TOON
F = style.MAT_FLAT
M = style.MAT_METAL
E = style.MAT_EMISSIVE


def _load(cat, name):
    spec = importlib.util.spec_from_file_location(f"icon_src_{name}", os.path.join(HERE, "..", cat, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def bake(name, src, yaw=0.0, tilt=0.0):
    """把物体（含子物体）烘成一个网格：世界变换写进顶点、居中、统一缩放到 SIZE。"""
    objs = src if isinstance(src, (list, tuple)) else [src]
    meshes = []
    empties = []
    for o in objs:
        for x in [o] + list(o.children_recursive):
            (meshes if x.type == "MESH" else empties).append(x)
    for m in meshes:
        mw = m.matrix_world.copy()
        m.parent = None
        m.data = m.data.copy()
        m.data.transform(mw)
        m.matrix_world = Matrix.Identity(4)
        for md in list(m.modifiers):
            m.modifiers.remove(md)
    for e in empties:
        bpy.data.objects.remove(e, do_unlink=True)
    ob = shapes.join(meshes, "icon_" + name)
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for v in ob.data.vertices:
        lo = Vector((min(lo.x, v.co.x), min(lo.y, v.co.y), min(lo.z, v.co.z)))
        hi = Vector((max(hi.x, v.co.x), max(hi.y, v.co.y), max(hi.z, v.co.z)))
    c = (lo + hi) / 2
    k = SIZE / max((hi - lo).length, 1e-4) * 1.6
    shapes.transform(ob, loc=(-c.x, -c.y, -c.z))
    shapes.transform(ob, rot=(tilt, 0, yaw), scale=(k, k, k))
    shapes.bake_outline_normals(ob)
    return ob


# =========================================================================== 新徽记（强化 / 天赋里没有模型的）

def em_dumbbell():
    P = [shapes.cylinder("bar", (0, 0, 0), 0.012, None, 0.22, "X", 12, 0.002, "gun_steel", M)]
    for s in (-1, 1):
        P.append(shapes.cylinder(f"w{s}", (s * 0.085, 0, 0), 0.05, None, 0.04, "X", 18, 0.006, "gun_dark", M))
        P.append(shapes.cylinder(f"w2{s}", (s * 0.115, 0, 0), 0.038, None, 0.02, "X", 18, 0.005, "headband_red", T))
    return shapes.join(P, "dumbbell")


def em_plus(color="regen_green", r=0.1):
    P = [shapes.rounded_box("v", (0, 0, 0), (0.06, 0.05, r * 2), 0.018, 2, color, T),
         shapes.rounded_box("h", (0, 0, 0), (r * 2, 0.05, 0.06), 0.018, 2, color, T)]
    return P


def em_regen():
    P = em_plus("regen_green")
    for k in range(3):
        a = k * 2.1
        P.append(shapes.uv_sphere(f"spark{k}", (math.cos(a) * 0.13, 0.0, math.sin(a) * 0.13), (0.02, 0.02, 0.02), 8, 6, "regen_green", E))
    return shapes.join(P, "regen")


def em_aura():
    P = em_plus("regen_green", 0.06)
    P.append(shapes.torus("ring", (0, 0, -0.06), 0.13, 0.014, "Z", 28, 6, "regen_green", E))
    P.append(shapes.torus("ring2", (0, 0, -0.06), 0.09, 0.008, "Z", 24, 4, "clover", T))
    return shapes.join(P, "aura")


def em_roll():
    """翻滚：一个滚动的毛球 + 两道残影弧线"""
    P = [shapes.quad_sphere("ball", (0.03, 0, 0), (0.07, 0.07, 0.07), 3, "fur_gold", T)]
    P.append(shapes.uv_sphere("ear", (0.07, 0.0, 0.06), (0.02, 0.015, 0.02), 8, 6, "fur_gold", T))
    for k in range(2):
        arc = []
        for i in range(6):
            a0 = math.radians(120 + i * 18)
            a1 = math.radians(120 + (i + 1) * 18)
            r = 0.1 + k * 0.035
            arc.append(shapes.capsule(f"arc{k}{i}", (0.03 + math.cos(a0) * r, 0, math.sin(a0) * r), (0.03 + math.cos(a1) * r, 0, math.sin(a1) * r), 0.008 - k * 0.002, 6, 2, "smoke_grey", T))
        P += arc
    return shapes.join(P, "roll")


def em_lens():
    P = [shapes.cylinder("body", (0, 0, 0), 0.08, 0.07, 0.07, "Y", 24, 0.008, "gun_dark", M),
         shapes.cylinder("glass", (0, 0.037, 0), 0.062, None, 0.006, "Y", 24, 0.0, "lens", style.MAT_GLASS),
         shapes.torus("ring", (0, 0.035, 0), 0.068, 0.008, "Y", 24, 6, "path_b", T),
         shapes.uv_sphere("hl", (-0.02, 0.042, 0.022), (0.014, 0.004, 0.01), 8, 4, "white", F)]
    return shapes.join(P, "lens")


def em_ear():
    P = [shapes.quad_sphere("ear", (0, 0, 0), (0.09, 0.03, 0.1), 3, "fur_gold", T),
         shapes.quad_sphere("in", (0, 0.022, 0), (0.06, 0.012, 0.07), 2, "ear_inner", T)]
    for k in range(3):
        P.append(shapes.torus(f"wave{k}", (0, 0.04, 0), 0.12 + k * 0.035, 0.007, "Y", 24, 4, "path_b", T, scale=(1, 1, 1)))
        # 只要右半边的声波弧
        me = P[-1].data
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.x < 0.05 or abs(v.co.z) > 0.09], context="VERTS")
        bm.to_mesh(me)
        bm.free()
    return shapes.join(P, "ear")


def em_ice():
    P = []
    for k in range(3):
        c = shapes.cylinder(f"spike{k}", (0, 0, 0), 0.0, 0.035, 0.22, "Z", 6, 0.0, "ice", style.MAT_GLASS)
        shapes.transform(c, rot=(0, k * math.pi / 3, 0))
        P.append(c)
    P.append(shapes.uv_sphere("core", (0, 0, 0), (0.04, 0.04, 0.04), 10, 6, "rail_cyan", E))
    return shapes.join(P, "ice")


def em_bolt(color="sticker_yellow"):
    pts = [(-0.02, 0.13), (0.06, 0.13), (0.01, 0.02), (0.07, 0.02), (-0.05, -0.14), (-0.01, -0.03), (-0.07, -0.03)]
    return shapes.extrude_profile("bolt", pts, 0.04, plane="XZ", bevel=0.006, color=color, mat=T)


def em_heart(color="headband_red", s=1.0):
    pts = []
    for i in range(40):
        t = i / 40 * math.tau
        x = 16 * math.sin(t) ** 3
        z = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x * 0.0065 * s, z * 0.0065 * s))
    P = [shapes.extrude_profile("heart", pts, 0.06 * s, plane="XZ", bevel=0.012 * s, color=color, mat=T)]
    P.append(shapes.uv_sphere("hl", (-0.045 * s, -0.035 * s, 0.035 * s), (0.016 * s, 0.006 * s, 0.022 * s), 8, 4, "white", F))
    return P


def em_undying():
    P = em_heart()
    P.append(shapes.torus("halo", (0, 0, 0.14), 0.07, 0.01, "Z", 24, 6, "crown_gold", E))
    P.append(shapes.rounded_box("band", (0.01, -0.034, 0.0), (0.12, 0.01, 0.03), 0.004, 1, "paper", T, rot=(0, deg(30), 0)))
    return shapes.join(P, "undying")


def em_pepper():
    P = []
    pts = [(0.0, 0.1), (0.03, 0.06), (0.04, 0.0), (0.02, -0.06), (-0.03, -0.11)]
    for i in range(len(pts) - 1):
        r0 = 0.045 * (1 - i * 0.2)
        P.append(shapes.capsule(f"p{i}", (pts[i][0], 0, pts[i][1]), (pts[i + 1][0], 0, pts[i + 1][1]), r0, 12, 4, "headband_red", T, radius1=r0 * 0.75))
    P.append(shapes.cylinder("cap", (0, 0, 0.13), 0.04, 0.03, 0.03, "Z", 12, 0.004, "clover", T))
    P.append(shapes.capsule("stem", (0, 0, 0.14), (0.03, 0, 0.18), 0.008, 6, 2, "clover_dark", T))
    P.append(shapes.uv_sphere("hl", (0.0, -0.035, 0.06), (0.01, 0.006, 0.025), 8, 4, "white", F))
    return shapes.join(P, "pepper")


def em_squad():
    P = []
    for k, (x, y) in enumerate(((-0.08, 0.0), (0.08, 0.0), (0.0, -0.06))):
        P.append(shapes.quad_sphere(f"head{k}", (x, y, 0.0), (0.06, 0.055, 0.05), 2, "minion_fur", T))
        P.append(shapes.quad_sphere(f"helm{k}", (x, y, 0.03), (0.065, 0.06, 0.04), 2, "gear_navy_light", T))
        P.append(shapes.torus(f"rim{k}", (x, y, 0.025), 0.064, 0.006, "Z", 18, 4, "gear_navy", T))
        for s in (-1, 1):
            P.append(shapes.uv_sphere(f"eye{k}{s}", (x + s * 0.022, y + 0.05, 0.0), (0.009, 0.004, 0.011), 8, 4, "eye_black", F))
    return shapes.join(P, "squad")


def em_mushroom():
    P = [shapes.quad_sphere("cap", (0, 0, 0.05), (0.12, 0.12, 0.08), 3, "headband_red", T),
         shapes.cylinder("stem", (0, 0, -0.02), 0.05, 0.06, 0.1, "Z", 16, 0.01, "towel_cream", T)]
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(P[0].data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 0.03], context="VERTS")
    bm.to_mesh(P[0].data)
    bm.free()
    for k, (a, e) in enumerate(((0.3, 0.6), (2.2, 0.5), (4.0, 0.7), (1.2, 1.2), (5.2, 1.0))):
        x = math.cos(a) * math.cos(e) * 0.12
        y = math.sin(a) * math.cos(e) * 0.12
        z = 0.05 + math.sin(e) * 0.08
        P.append(shapes.uv_sphere(f"spot{k}", (x, y, z), (0.022, 0.022, 0.022), 8, 6, "white", T))
    for s in (-1, 1):
        P.append(shapes.uv_sphere(f"eye{s}", (s * 0.022, 0.058, -0.02), (0.008, 0.004, 0.012), 8, 4, "eye_black", F))
    return shapes.join(P, "mushroom")


def em_moon():
    P = [shapes.uv_sphere("moon", (0, 0, 0), (0.1, 0.04, 0.1), 20, 12, "bulb", E)]
    cut = shapes.uv_sphere("cut", (0.05, -0.02, 0.03), (0.085, 0.06, 0.085), 20, 12, "bulb", E)
    mod = P[0].modifiers.new("cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cut
    shapes.apply_modifiers(P[0])
    bpy.data.objects.remove(cut, do_unlink=True)
    for k, (x, z, r) in enumerate(((0.09, 0.08, 0.02), (0.11, -0.04, 0.014))):
        P.append(shapes.cylinder(f"star{k}", (x, 0, z), r * 1.6, None, 0.012, "Y", 5, 0.0, "sticker_yellow", T))
    return shapes.join(P, "moon")


def em_bullets():
    P = []
    for k in range(3):
        a = deg(-28 + k * 28)
        b = [shapes.cylinder(f"case{k}", (0, 0, 0.0), 0.026, None, 0.11, "Z", 14, 0.003, "brass", M),
             shapes.cylinder(f"tip{k}", (0, 0, 0.085), 0.0, 0.026, 0.06, "Z", 14, 0.0, "copper", M),
             shapes.torus(f"rim{k}", (0, 0, -0.052), 0.027, 0.005, "Z", 14, 4, "brass", M)]
        for o in b:
            shapes.transform(o, loc=(0, 0, 0.07))
            shapes.transform(o, rot=(0, a, 0))
        P += b
        P.append(shapes.capsule(f"spd{k}", (math.sin(a) * 0.22, 0, math.cos(a) * 0.22 + 0.0), (math.sin(a) * 0.27, 0, math.cos(a) * 0.27), 0.01, 6, 2, "sticker_orange", T))
    return shapes.join(P, "bullets")


def em_slash():
    """刀身光：一道月牙形剑气（路线色）"""
    pts = []
    for i in range(13):
        t = math.radians(-70 + i * 140 / 12)
        pts.append((math.sin(t) * 0.14, math.cos(t) * 0.14 - 0.06))
    for i in range(13):
        t = math.radians(70 - i * 140 / 12)
        pts.append((math.sin(t) * 0.1 + 0.0, math.cos(t) * 0.09 - 0.03))
    P = [shapes.extrude_profile("slash", pts, 0.025, plane="XZ", bevel=0.004, color="path_a", mat="M_path")]
    # 剑气后面拖两道细的残影
    for k in range(2):
        r = 0.165 + k * 0.03
        for i in range(5):
            t0 = math.radians(-40 + i * 16 + k * 8)
            t1 = math.radians(-40 + (i + 1) * 16 + k * 8)
            P.append(shapes.capsule(f"trail{k}{i}", (math.sin(t0) * r, 0, math.cos(t0) * r - 0.06), (math.sin(t1) * r, 0, math.cos(t1) * r - 0.06), 0.006 - k * 0.002, 6, 2, "path_a", "M_path"))
    return shapes.join(P, "slash")


def em_shield():
    pts = [(-0.1, 0.11), (0.1, 0.11), (0.1, 0.0), (0.0, -0.13), (-0.1, 0.0)]
    P = [shapes.extrude_profile("sh", pts, 0.04, plane="XZ", bevel=0.01, color="path_b", mat=T)]
    pts2 = [(-0.07, 0.085), (0.07, 0.085), (0.07, 0.0), (0.0, -0.095), (-0.07, 0.0)]
    P.append(shapes.extrude_profile("inner", pts2, 0.05, plane="XZ", bevel=0.006, color="pilot_blue", mat=E))
    P.append(shapes.uv_sphere("gem", (0, -0.03, 0.01), (0.025, 0.02, 0.025), 10, 6, "crown_gold", M))
    rim = shapes.extrude_profile("rim", [(-0.112, 0.122), (0.112, 0.122), (0.112, 0.0), (0.0, -0.145), (-0.112, 0.0)], 0.03, plane="XZ", bevel=0.006, color="crown_gold", mat=M)
    P.append(rim)
    return shapes.join(P, "shield")


def em_bomb():
    P = [shapes.uv_sphere("ball", (0, 0, 0), (0.1, 0.1, 0.1), 20, 12, "gun_darker", M),
         shapes.cylinder("neck", (0.04, 0, 0.09), 0.03, None, 0.04, "Z", 12, 0.006, "gun_dark", M),
         shapes.capsule("fuse", (0.045, 0, 0.11), (0.09, 0, 0.16), 0.008, 6, 2, "towel_stripe", T),
         shapes.uv_sphere("spark", (0.095, 0, 0.17), (0.03, 0.03, 0.03), 10, 6, "torch_glass", E),
         shapes.uv_sphere("hl", (-0.04, -0.07, 0.04), (0.02, 0.01, 0.03), 8, 4, "white", F)]
    for k in range(5):
        a = k / 5 * math.tau
        P.append(shapes.capsule(f"ray{k}", (0.095 + math.cos(a) * 0.035, 0, 0.17 + math.sin(a) * 0.035), (0.095 + math.cos(a) * 0.06, 0, 0.17 + math.sin(a) * 0.06), 0.006, 6, 2, "sticker_orange", T))
    return shapes.join(P, "bomb")


def em_ghost():
    P = [shapes.quad_sphere("body", (0, 0, 0.03), (0.09, 0.08, 0.12), 3, "smoke_grey", style.MAT_GLASS)]
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(P[0].data)
    for v in bm.verts:
        if v.co.z < 0.0:
            v.co.z = -0.09 + 0.02 * math.sin(math.atan2(v.co.y, v.co.x) * 5)
    bm.to_mesh(P[0].data)
    bm.free()
    for s in (-1, 1):
        P.append(shapes.uv_sphere(f"eye{s}", (s * 0.03, 0.075, 0.06), (0.014, 0.006, 0.02), 8, 4, "eye_black", F))
    P.append(shapes.uv_sphere("mouth", (0, 0.078, 0.015), (0.015, 0.005, 0.012), 8, 4, "eye_black", F))
    for k in range(2):
        P.append(shapes.capsule(f"wind{k}", (-0.13 - k * 0.02, 0, 0.06 - k * 0.07), (-0.2 - k * 0.02, 0, 0.06 - k * 0.07), 0.008, 6, 2, "pilot_blue", T))
    return shapes.join(P, "ghost")


def em_drop():
    P = [shapes.uv_sphere("drop", (0, 0, -0.03), (0.08, 0.08, 0.08), 18, 10, "headband_red", style.MAT_GLASS),
         shapes.cylinder("tip", (0, 0, 0.06), 0.0, 0.07, 0.12, "Z", 18, 0.0, "headband_red", style.MAT_GLASS)]
    for s in (-1, 1):
        P.append(shapes.cylinder(f"fang{s}", (s * 0.03, 0.075, -0.03), 0.0, 0.015, 0.04, "Z", 8, 0.0, "tooth", T))
        shapes.transform(P[-1], rot=(0, deg(180), 0))
        shapes.transform(P[-1], loc=(s * 0.06, 0.075, -0.06))
    P.append(shapes.uv_sphere("hl", (-0.03, -0.065, 0.0), (0.015, 0.006, 0.03), 8, 4, "white", F))
    return shapes.join(P, "drop")


def em_infinity():
    P = []
    for s in (-1, 1):
        P.append(shapes.torus(f"loop{s}", (s * 0.065, 0, 0), 0.06, 0.018, "Y", 28, 8, "brass", M))
    P.append(shapes.cylinder("b", (0, 0.0, 0.09), 0.018, None, 0.06, "Z", 12, 0.003, "brass", M))
    P.append(shapes.cylinder("bt", (0, 0.0, 0.135), 0.0, 0.018, 0.035, "Z", 12, 0.0, "copper", M))
    return shapes.join(P, "infinity")


# =========================================================================== 组装

def build(ctx):
    gk = _load("props", "gadget_kit")
    pk = _load("props", "prop_kit")
    mk = _load("units", "mob_kit")
    ak = _load("attachments", "att_kit")
    ck = _load("characters", "acc_kit")

    icons = []          # (文件名, 物体, 路线编号或 None)

    def add(fname, src, yaw=0.0, tilt=0.0, path=None):
        icons.append((fname, bake(fname, src, yaw, tilt), path))

    # 道具（frag 在 prop_kit 里）
    gad = {"frag": pk.frag, "molotov": gk.molotov, "flash": gk.flash, "mine": gk.mine, "sentry": gk.sentry, "eshield": gk.eshield, "smoke": gk.smoke,
           "flare": gk.flare, "decoy": gk.decoy, "jetpack": gk.jetpack, "medkit": gk.medkit, "freeze": gk.freeze, "beacon": gk.beacon}
    for k, fn in gad.items():
        add("gad_" + k, fn(), yaw=deg(180) if k == "jetpack" else 0.0)
    for k, fn in (("chick", mk.chick), ("firefly", mk.firefly), ("hedgehog", mk.hedgehog)):
        add("pet_" + k, fn())
    # 进化配件：8 类 × 3 路线色
    att = {"scope": ak.scope, "muzzle": ak.muzzle, "drum": ak.drum, "tank": ak.tank, "coil": ak.coil, "radar": ak.radar, "torch": lambda: ak.torch(False), "blade": em_slash}
    for k, fn in att.items():
        for pi, p in enumerate("abc"):
            add(f"evo_{k}_{p}", fn(), yaw=deg(-60) if k != "blade" else deg(-20), path=pi)
    # 强化：有挂件模型的直接用，没有的用徽记
    abl = {
        "strong": em_dumbbell(), "armor": ck.vest(), "regen": em_regen(), "vamp": ck.fangs(), "speed": ck.shoe("R"), "dash": em_roll(),
        "magnet": ck.magnet(), "torch": ak.torch(True, False), "wide": em_lens(), "ears": em_ear(), "nvg": ck.nvg(), "recon": ck.antenna(),
        "rage": ck.headband(), "crit": ck.clover(), "rate": ak.gold_ring(), "frost": em_ice(), "chain": em_bolt("rail_cyan"), "scholar": ck.glasses(),
        "scav": ck.bando(), "gcd": ck.belt(), "aura": em_aura(), "banner": ck.banner(),
    }
    yaw = {"speed": deg(-50), "torch": deg(-60), "rate": deg(-60), "nvg": deg(-30), "glasses": 0.0}
    for k, o in abl.items():
        add("abl_" + k, o, yaw=yaw.get(k, 0.0))
    tal = {
        "undying": em_undying(), "berserk": em_pepper(), "squad": em_squad(), "giant": em_mushroom(), "nightvision": em_moon(),
        "overdrive": em_bullets(), "aegis": em_shield(), "storm": em_bolt(), "detonate": em_bomb(), "phantom": em_ghost(),
        "vampire": em_drop(), "bottomless": em_infinity(),
    }
    for k, o in tal.items():
        add("tal_" + k, o)

    # 排开（互不遮挡），每个单独渲染
    for i, (fname, ob, _p) in enumerate(icons):
        shapes.transform(ob, loc=((i % 12) * 0.6, -(i // 12) * 0.6, 0))

    def path(p):
        def f(_ctx):
            materials.PREVIEW["path"] = p
        return f

    pv = []
    for fname, ob, p in icons:
        kw = {"only": (lambda o, ob=ob: o is ob), "transparent": True, "res": 256, "margin": 1.08, "out": os.path.join(ICONS, fname + ".png")}
        if p is not None:
            kw["pre"] = path(p)
        pv.append((fname, "icon3q", kw))
    # 总览（审阅用）
    pv.append(("sheet", "three_quarter", {"pre": path(0), "res": 1600, "margin": 1.0}))
    return ctx.Built([], previews=pv, outline=0.0045, preview_objs=[ob for _, ob, _ in icons])
