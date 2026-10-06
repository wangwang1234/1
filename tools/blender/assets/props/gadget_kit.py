"""战术道具模型（批次 2 简化版；手雷沿用 prop_frag）。每个道具一个 glb：
gad_molotov 燃烧瓶、gad_flash 闪光弹、gad_mine 地雷（team 灯）、gad_sentry 自动炮台（head 节点可转、muzzle）、
gad_eshield 能量护盾手腕发生器、gad_smoke 烟雾弹、gad_flare 照明弹、gad_decoy 充气诱饵仓鼠（带气门嘴）、
gad_jetpack 喷气背包（nozzle_L / nozzle_R 挂点）、gad_medkit 急救瓜子包、gad_freeze 冰冻手雷、gad_beacon 传送信标（light 挂点）。
坐标：+Y 朝前，+Z 向上，底部在 z=0。
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


def molotov():
    P = [
        shapes.lathe("bottle", [(0.032, 0.0), (0.036, 0.01), (0.036, 0.07), (0.03, 0.09), (0.013, 0.105), (0.012, 0.135)], 20, color="glass_green", mat=style.MAT_GLASS),
        shapes.cylinder("fuel", (0, 0, 0.035), 0.033, None, 0.05, "Z", 18, 0.0, "path_a", style.MAT_TOON),
        shapes.rounded_box("label", (0, 0.035, 0.05), (0.04, 0.004, 0.03), 0.0, 1, "paper", style.MAT_FLAT),
        shapes.capsule("rag", (0, 0, 0.13), (0.015, 0.012, 0.175), 0.009, 8, 2, "towel_stripe", style.MAT_TOON),
        shapes.uv_sphere("flame", (0.018, 0.014, 0.19), (0.012, 0.012, 0.018), 10, 6, "torch_glass", style.MAT_EMISSIVE),
    ]
    return _root("gad_molotov", [shapes.join(P, "molotov")])


def flash():
    P = [
        shapes.cylinder("can", (0, 0, 0.05), 0.026, None, 0.09, "Z", 18, 0.004, "gun_light", style.MAT_METAL),
        shapes.torus("band", (0, 0, 0.07), 0.026, 0.004, "Z", 18, 4, "white", style.MAT_TOON),
        shapes.torus("band2", (0, 0, 0.03), 0.026, 0.004, "Z", 18, 4, "white", style.MAT_TOON),
        shapes.cylinder("top", (0, 0, 0.1), 0.012, None, 0.016, "Z", 12, 0.002, "gun_steel", style.MAT_METAL),
        shapes.rounded_box("lever", (0.014, 0, 0.08), (0.008, 0.014, 0.06), 0.002, 1, "gun_steel", style.MAT_METAL, rot=(0, deg(-12), 0)),
        shapes.torus("ring", (-0.014, 0, 0.11), 0.011, 0.0022, "Y", 12, 4, "gun_chrome", style.MAT_METAL),
    ]
    return _root("gad_flash", [shapes.join(P, "flash")])


def mine():
    P = [
        shapes.cylinder("base", (0, 0, 0.012), 0.07, 0.075, 0.024, "Z", 24, 0.004, "polymer_olive", style.MAT_TOON),
        shapes.cylinder("top", (0, 0, 0.03), 0.05, None, 0.014, "Z", 24, 0.004, "vest_dark", style.MAT_TOON),
        shapes.cylinder("plate", (0, 0, 0.039), 0.03, None, 0.006, "Z", 20, 0.002, "gun_steel", style.MAT_METAL),
    ]
    for i in range(6):
        a = i / 6 * math.tau
        P.append(shapes.rounded_box(f"bolt{i}", (math.cos(a) * 0.062, math.sin(a) * 0.062, 0.025), (0.008, 0.008, 0.006), 0.002, 1, "gun_dark", style.MAT_METAL))
    light = shapes.uv_sphere("light", (0, 0.04, 0.034), (0.007, 0.007, 0.007), 10, 6, "team_glow", style.MAT_TEAM)
    return _root("gad_mine", [shapes.join(P, "mine"), light])


def sentry():
    base = [
        shapes.cylinder("hub", (0, 0, 0.08), 0.022, None, 0.03, "Z", 16, 0.004, "gun_dark", style.MAT_METAL),
        shapes.cylinder("post", (0, 0, 0.12), 0.012, None, 0.06, "Z", 12, 0.002, "gun_metal", style.MAT_METAL),
    ]
    for i in range(3):
        a = i / 3 * math.tau + 0.5
        base.append(shapes.capsule(f"leg{i}", (0, 0, 0.08), (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.0), 0.007, 8, 2, "gun_dark", style.MAT_METAL))
        base.append(shapes.uv_sphere(f"foot{i}", (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.006), (0.012, 0.012, 0.008), 10, 6, "rubber", style.MAT_TOON))
    bm = shapes.join(base, "base")
    head = [
        shapes.rounded_box("box", (0, 0, 0), (0.07, 0.09, 0.055), 0.012, 2, "team_main", style.MAT_TEAM),
        shapes.cylinder("barrel", (0, 0.08, 0.0), 0.009, None, 0.08, "Y", 12, 0.002, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("eye", (0, 0.046, 0.015), (0.04, 0.004, 0.012), 0.002, 1, "team_glow", style.MAT_TEAM),
        shapes.cylinder("dish", (0, -0.03, 0.035), 0.02, None, 0.004, "Z", 14, 0.001, "gun_steel", style.MAT_METAL),
    ]
    hm = shapes.join(head, "head")
    hm.location = (0, 0, 0.17)
    root = _root("gad_sentry", [bm, hm])
    shapes.empty("muzzle", (0, 0.125, 0.17), parent=root, size=0.015)
    return root


def eshield():
    """手腕护盾发生器（显示在仓鼠左手；护罩本身由 Godot 的六边形着色器画）。"""
    P = [
        shapes.cylinder("cuff", (0, 0, 0), 0.022, None, 0.03, "Y", 16, 0.004, "gun_metal", style.MAT_METAL),
        shapes.rounded_box("emitter", (0, 0, 0.022), (0.026, 0.026, 0.012), 0.004, 2, "lamp_dark", style.MAT_METAL),
        shapes.cylinder("lens", (0, 0, 0.029), 0.009, None, 0.003, "Z", 12, 0, "rail_cyan", style.MAT_EMISSIVE),
    ]
    return _root("gad_eshield", [shapes.join(P, "eshield")])


def smoke():
    P = [
        shapes.cylinder("can", (0, 0, 0.055), 0.026, None, 0.1, "Z", 18, 0.004, "smoke_grey", style.MAT_TOON),
        shapes.rounded_box("stripe", (0, 0, 0.065), (0.054, 0.054, 0.016), 0.004, 2, "gun_dark", style.MAT_TOON),
        shapes.cylinder("top", (0, 0, 0.11), 0.012, None, 0.014, "Z", 12, 0.002, "gun_steel", style.MAT_METAL),
        shapes.torus("ring", (-0.014, 0, 0.12), 0.011, 0.0022, "Y", 12, 4, "gun_chrome", style.MAT_METAL),
    ]
    for i in range(4):
        a = i / 4 * math.tau
        P.append(shapes.cylinder(f"hole{i}", (math.cos(a) * 0.026, math.sin(a) * 0.026, 0.03), 0.004, None, 0.002, "Z", 8, 0, "rubber", style.MAT_FLAT))
    return _root("gad_smoke", [shapes.join(P, "smoke")])


def flare():
    P = [
        shapes.cylinder("stick", (0, 0, 0.07), 0.013, None, 0.14, "Z", 14, 0.003, "flare_red", style.MAT_TOON),
        shapes.cylinder("cap", (0, 0, 0.146), 0.015, None, 0.014, "Z", 14, 0.002, "white", style.MAT_TOON),
        shapes.uv_sphere("spark", (0, 0, 0.17), (0.016, 0.016, 0.02), 10, 6, "flare_red", style.MAT_EMISSIVE),
        shapes.rounded_box("label", (0, 0.0135, 0.07), (0.018, 0.002, 0.05), 0.0, 1, "paper", style.MAT_FLAT),
    ]
    return _root("gad_flare", [shapes.join(P, "flare")])


def decoy():
    """充气诱饵仓鼠：胖乎乎的气球仓鼠（浅色塑料感）+ 气门嘴 + 画上去的五官。"""
    P = [
        shapes.quad_sphere("body", (0, 0, 0.15), (0.15, 0.14, 0.15), 3, "towel_cream", style.MAT_GLASS),
        shapes.quad_sphere("head", (0, 0.04, 0.3), (0.11, 0.1, 0.095), 3, "towel_cream", style.MAT_GLASS),
        shapes.cylinder("valve", (0.0, -0.13, 0.2), 0.012, None, 0.03, "Y", 10, 0.002, "shell_red", style.MAT_TOON),
        shapes.cylinder("valvecap", (0.0, -0.148, 0.2), 0.016, None, 0.008, "Y", 10, 0.002, "shell_red", style.MAT_TOON),
        shapes.uv_sphere("nose", (0, 0.135, 0.29), (0.014, 0.01, 0.012), 10, 6, "nose_pink", style.MAT_FLAT),
    ]
    for sgn in (-1, 1):
        P.append(shapes.quad_sphere(f"ear{sgn}", (sgn * 0.08, 0.0, 0.38), (0.04, 0.02, 0.04), 2, "towel_cream", style.MAT_GLASS))
        P.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.045, 0.125, 0.32), (0.012, 0.004, 0.016), 10, 6, "eye_black", style.MAT_FLAT))
        P.append(shapes.capsule(f"seam{sgn}", (sgn * 0.148, -0.02, 0.06), (sgn * 0.148, 0.02, 0.24), 0.003, 6, 2, "towel_stripe", style.MAT_FLAT))
    return _root("gad_decoy", [shapes.join(P, "decoy")])


def jetpack():
    P = [
        shapes.rounded_box("pack", (0, 0, 0.0), (0.12, 0.05, 0.13), 0.02, 2, "gun_metal", style.MAT_METAL),
        shapes.rounded_box("strap", (0, 0.03, 0.03), (0.13, 0.012, 0.02), 0.005, 1, "rubber", style.MAT_TOON),
        shapes.rounded_box("panel", (0, -0.026, 0.01), (0.06, 0.004, 0.06), 0.004, 1, "sticker_yellow", style.MAT_FLAT),
    ]
    for sgn in (-1, 1):
        P.append(shapes.cylinder(f"tank{sgn}", (sgn * 0.045, -0.02, 0.0), 0.022, None, 0.13, "Z", 16, 0.004, "shell_red", style.MAT_TOON))
        P.append(shapes.cylinder(f"nozzle{sgn}", (sgn * 0.045, -0.02, -0.08), 0.012, 0.018, 0.03, "Z", 14, 0.002, "gun_dark", style.MAT_METAL))
    root = _root("gad_jetpack", [shapes.join(P, "jetpack")])
    shapes.empty("nozzle_L", (-0.045, -0.02, -0.095), parent=root, size=0.01)
    shapes.empty("nozzle_R", (0.045, -0.02, -0.095), parent=root, size=0.01)
    return root


def medkit():
    """急救瓜子包：红色小包 + 白十字 + 包口露出瓜子。"""
    P = [
        shapes.rounded_box("bag", (0, 0, 0.05), (0.12, 0.07, 0.1), 0.02, 3, "label_red", style.MAT_TOON),
        shapes.rounded_box("crossV", (0, 0.036, 0.05), (0.02, 0.004, 0.06), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("crossH", (0, 0.036, 0.05), (0.06, 0.004, 0.02), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("fold", (0, 0, 0.102), (0.124, 0.074, 0.012), 0.006, 2, "headband_red", style.MAT_TOON),
    ]
    for i in range(4):
        sd = shapes.uv_sphere(f"seed{i}", (0, 0, 0), (0.008, 0.02, 0.006), 8, 6, "seed_shell", style.MAT_TOON)
        shapes.transform(sd, rot=(deg(70), 0, i * 0.7), loc=(-0.03 + i * 0.02, 0.0, 0.115))
        P.append(sd)
    return _root("gad_medkit", [shapes.join(P, "medkit")])


def freeze():
    P = [
        shapes.quad_sphere("body", (0, 0, 0.055), (0.046, 0.046, 0.056), 2, "ice", style.MAT_GLASS),
        shapes.torus("band", (0, 0, 0.055), 0.046, 0.006, "Z", 20, 6, "rail_cyan", style.MAT_EMISSIVE),
        shapes.cylinder("top", (0, 0, 0.118), 0.016, None, 0.022, "Z", 12, 0.003, "gun_steel", style.MAT_METAL),
        shapes.torus("ring", (-0.016, 0, 0.13), 0.012, 0.0025, "Y", 14, 4, "gun_chrome", style.MAT_METAL),
    ]
    for i in range(3):
        a = i / 3 * math.tau
        P.append(shapes.cylinder(f"crystal{i}", (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.09), 0.0, 0.01, 0.03, "Z", 6, 0.0, "ice", style.MAT_GLASS))
    return _root("gad_freeze", [shapes.join(P, "freeze")])


def beacon():
    P = [
        shapes.cylinder("stake", (0, 0, 0.06), 0.008, 0.002, 0.12, "Z", 10, 0.001, "gun_steel", style.MAT_METAL),
        shapes.cylinder("body", (0, 0, 0.13), 0.022, None, 0.05, "Z", 16, 0.004, "white", style.MAT_TOON),
        shapes.torus("ring", (0, 0, 0.14), 0.024, 0.004, "Z", 16, 4, "rail_cyan", style.MAT_EMISSIVE),
        shapes.uv_sphere("bulb", (0, 0, 0.17), (0.016, 0.016, 0.018), 12, 8, "rail_cyan", style.MAT_EMISSIVE),
    ]
    for i in range(3):
        a = i / 3 * math.tau
        P.append(shapes.rounded_box(f"fin{i}", (math.cos(a) * 0.022, math.sin(a) * 0.022, 0.11), (0.004, 0.02, 0.03), 0.002, 1, "gun_metal", style.MAT_METAL, rot=(0, 0, a + math.pi / 2)))
    root = _root("gad_beacon", [shapes.join(P, "beacon")])
    shapes.empty("light", (0, 0, 0.18), parent=root, size=0.01)
    return root


def build(ctx):
    items = [molotov(), flash(), mine(), sentry(), eshield(), smoke(), flare(), decoy(), jetpack(), medkit(), freeze(), beacon()]
    extras = [(r.name, [r]) for r in items]

    def layout(_ctx):
        for i, r in enumerate(items):
            r.location = Vector(((i % 4) * 0.42, -(i // 4) * 0.42, 0))

    pv = [("all", "three_quarter", {"margin": 1.02, "res": 1000}), ("all_game", "game", {"margin": 1.05, "res": 1000})]
    return ctx.Built([], previews=pv, outline=0.003, extra_exports=extras, after_export=layout)
