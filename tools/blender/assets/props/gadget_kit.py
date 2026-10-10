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


def _decal(name, center, size, color, rot=(0, 0, 0)):
    return shapes.rounded_box(name, center, size, 0.0, 1, color, style.MAT_FLAT, rot=rot)


def _ring_decal(name, z, r, h, color, segs=20):
    """贴在圆柱外表面的一圈色带（比表面略大一点点）。"""
    return shapes.cylinder(name, (0, 0, z), r + 0.0008, None, h, "Z", segs, 0.0, color, style.MAT_FLAT, caps=False)


def _pin(prefix, x, z, ring_r=0.011):
    """保险销：一截销子 + 拉环。"""
    return [
        shapes.cylinder(prefix + "pin", (x * 0.5, 0, z), 0.0025, None, abs(x) + 0.004, "X", 8, 0.0, "gun_chrome", style.MAT_METAL),
        shapes.torus(prefix + "ring", (x, 0, z + 0.004), ring_r, 0.0022, "Y", 14, 4, "gun_chrome", style.MAT_METAL),
    ]


def molotov():
    """燃烧瓶：绿玻璃酒瓶 + 半瓶橙色燃料 + 纸标签（火焰图案）+ 瓶口塞布条 + 火苗。"""
    P = [
        shapes.lathe("bottle", [(0.032, 0.0), (0.036, 0.01), (0.036, 0.07), (0.03, 0.09), (0.013, 0.105), (0.012, 0.135)], 20, color="glass_green", mat=style.MAT_GLASS),
        shapes.cylinder("fuel", (0, 0, 0.033), 0.0335, None, 0.046, "Z", 18, 0.0, "path_a", style.MAT_TOON),
        shapes.cylinder("fuelband", (0, 0, 0.0565), 0.0345, None, 0.004, "Z", 18, 0.0, "sticker_yellow", style.MAT_TOON),
        shapes.torus("lip", (0, 0, 0.134), 0.0125, 0.0028, "Z", 14, 4, "glass_green", style.MAT_GLASS),
        shapes.torus("neckband", (0, 0, 0.108), 0.0135, 0.0024, "Z", 14, 4, "label_red", style.MAT_TOON),
    ]
    # 标签：纸 + 红色火焰图案
    P.append(_decal("label", (0, 0.0368, 0.05), (0.042, 0.0016, 0.034), "paper"))
    P.append(_decal("labelband", (0, 0.0376, 0.064), (0.042, 0.0012, 0.005), "label_red"))
    for i, (u, w, h) in enumerate(((-0.008, 0.008, 0.014), (0.0, 0.01, 0.022), (0.008, 0.008, 0.012))):
        P.append(_decal(f"flame{i}", (u, 0.0376, 0.044 + h * 0.3), (w, 0.0012, h), "sticker_orange" if i != 1 else "label_red", rot=(0, deg((i - 1) * 12), 0)))
    # 布条：两段弯折，带条纹
    P.append(shapes.capsule("rag", (0, 0, 0.128), (0.012, 0.01, 0.168), 0.009, 8, 2, "towel_cream", style.MAT_TOON))
    P.append(shapes.capsule("rag2", (0.012, 0.01, 0.168), (0.026, 0.02, 0.18), 0.007, 8, 2, "towel_cream", style.MAT_TOON))
    for k in range(3):
        P.append(shapes.torus(f"ragstripe{k}", (0.003 + k * 0.004, 0.0025 + k * 0.0035, 0.14 + k * 0.011), 0.0094, 0.0016, "Z", 10, 3, "towel_stripe", style.MAT_TOON))
    P.append(shapes.uv_sphere("flame", (0.03, 0.023, 0.196), (0.013, 0.013, 0.02), 10, 6, "torch_glass", style.MAT_EMISSIVE))
    P.append(shapes.uv_sphere("flamecore", (0.03, 0.023, 0.192), (0.008, 0.008, 0.012), 8, 6, "lens_orange", style.MAT_EMISSIVE))
    return _root("gad_molotov", [shapes.join(P, "molotov")])


def flash():
    """闪光弹：浅灰金属罐 + 白色色带 + 一圈出光孔 + 握片 + 拉环。"""
    P = [
        shapes.cylinder("can", (0, 0, 0.05), 0.026, None, 0.09, "Z", 18, 0.004, "gun_light", style.MAT_METAL),
        _ring_decal("band", 0.074, 0.026, 0.012, "white"),
        _ring_decal("band2", 0.026, 0.026, 0.012, "white"),
        _ring_decal("bandmid", 0.05, 0.026, 0.004, "sticker_yellow"),
        shapes.cylinder("top", (0, 0, 0.1), 0.014, None, 0.016, "Z", 12, 0.002, "gun_steel", style.MAT_METAL),
        shapes.cylinder("fuse", (0, 0, 0.112), 0.008, None, 0.01, "Z", 10, 0.002, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("lever", (0.016, 0, 0.078), (0.008, 0.014, 0.064), 0.002, 1, "gun_steel", style.MAT_METAL, rot=(0, deg(-10), 0)),
        shapes.cylinder("base", (0, 0, 0.004), 0.024, None, 0.006, "Z", 18, 0.002, "gun_dark", style.MAT_METAL),
    ]
    P += _pin("p", -0.016, 0.108)
    for i in range(8):
        a = i / 8 * math.tau
        P.append(shapes.transform(shapes.cylinder(f"port{i}", (0.0262, 0, 0), 0.0035, None, 0.0014, "X", 8, 0, "rubber", style.MAT_FLAT), loc=(0, 0, 0.05), rot=(0, 0, a)))
    return _root("gad_flash", [shapes.join(P, "flash")])


def mine():
    """地雷：橄榄色圆饼 + 警示色带 + 压力触发板 + 三根触发针 + 队伍色指示灯。"""
    P = [
        shapes.cylinder("base", (0, 0, 0.012), 0.07, 0.075, 0.024, "Z", 24, 0.004, "polymer_olive", style.MAT_TOON),
        shapes.cylinder("top", (0, 0, 0.03), 0.05, None, 0.014, "Z", 24, 0.004, "vest_dark", style.MAT_TOON),
        shapes.cylinder("plate", (0, 0, 0.039), 0.03, None, 0.006, "Z", 20, 0.002, "gun_steel", style.MAT_METAL),
        shapes.cylinder("platecap", (0, 0, 0.0428), 0.012, None, 0.003, "Z", 14, 0.001, "gun_darker", style.MAT_METAL),
    ]
    # 侧面黄黑警示带
    for i in range(16):
        a = i / 16 * math.tau
        c = "sticker_yellow" if i % 2 == 0 else "rubber"
        P.append(shapes.transform(_decal(f"haz{i}", (0.0728, 0, 0), (0.0012, 0.026, 0.01), c), loc=(0, 0, 0.013), rot=(0, 0, a)))
    for i in range(6):
        a = i / 6 * math.tau
        P.append(shapes.rounded_box(f"bolt{i}", (math.cos(a) * 0.062, math.sin(a) * 0.062, 0.025), (0.008, 0.008, 0.006), 0.002, 1, "gun_dark", style.MAT_METAL))
    for i in range(3):
        a = i / 3 * math.tau + 0.5
        P.append(shapes.cylinder(f"prong{i}", (math.cos(a) * 0.018, math.sin(a) * 0.018, 0.05), 0.0018, None, 0.016, "Z", 6, 0.0, "gun_chrome", style.MAT_METAL))
        P.append(shapes.uv_sphere(f"prongtip{i}", (math.cos(a) * 0.018, math.sin(a) * 0.018, 0.058), (0.003, 0.003, 0.003), 6, 4, "gun_chrome", style.MAT_METAL))
    P.append(shapes.rounded_box("lighthouse", (0, 0.04, 0.033), (0.018, 0.014, 0.008), 0.003, 1, "gun_darker", style.MAT_METAL))
    light = shapes.uv_sphere("light", (0, 0.04, 0.038), (0.007, 0.007, 0.007), 10, 6, "team_glow", style.MAT_TEAM)
    return _root("gad_mine", [shapes.join(P, "mine"), light])


def sentry():
    """自动炮台：三脚架 + 转台 + 队伍色机头（护罩、摄像头、散热孔）+ 侧挂弹箱 + 天线。"""
    base = [
        shapes.cylinder("hub", (0, 0, 0.08), 0.024, None, 0.03, "Z", 16, 0.004, "gun_dark", style.MAT_METAL),
        shapes.cylinder("post", (0, 0, 0.12), 0.012, None, 0.06, "Z", 12, 0.002, "gun_metal", style.MAT_METAL),
        shapes.cylinder("turntable", (0, 0, 0.145), 0.026, None, 0.01, "Z", 18, 0.003, "gun_darker", style.MAT_METAL),
        _ring_decal("hubband", 0.08, 0.024, 0.008, "sticker_yellow", 16),
    ]
    for i in range(3):
        a = i / 3 * math.tau + 0.5
        base.append(shapes.capsule(f"leg{i}", (0, 0, 0.08), (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.0), 0.007, 8, 2, "gun_dark", style.MAT_METAL))
        base.append(shapes.uv_sphere(f"hinge{i}", (math.cos(a) * 0.022, math.sin(a) * 0.022, 0.074), (0.009, 0.009, 0.009), 8, 6, "gun_steel", style.MAT_METAL))
        base.append(shapes.uv_sphere(f"foot{i}", (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.006), (0.013, 0.013, 0.008), 10, 6, "rubber", style.MAT_TOON))
    bm = shapes.join(base, "base")
    head = [
        shapes.rounded_box("box", (0, 0, 0), (0.07, 0.09, 0.055), 0.012, 2, "team_main", style.MAT_TEAM),
        shapes.rounded_box("visor", (0, 0.036, 0.018), (0.06, 0.024, 0.016), 0.006, 2, "team_dark", style.MAT_TEAM),
        shapes.cylinder("shroud", (0, 0.07, -0.002), 0.014, None, 0.05, "Y", 14, 0.002, "gun_dark", style.MAT_METAL),
        shapes.cylinder("barrel", (0, 0.1, -0.002), 0.008, None, 0.05, "Y", 12, 0.002, "gun_darker", style.MAT_METAL),
        shapes.cylinder("brake", (0, 0.122, -0.002), 0.011, None, 0.012, "Y", 12, 0.002, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("eye", (0, 0.046, 0.016), (0.04, 0.004, 0.01), 0.002, 1, "team_glow", style.MAT_TEAM),
        shapes.cylinder("cam", (0.024, 0.045, -0.012), 0.008, None, 0.01, "Y", 12, 0.002, "gun_darker", style.MAT_METAL),
        shapes.cylinder("camlens", (0.024, 0.0505, -0.012), 0.005, None, 0.002, "Y", 10, 0, "lens", style.MAT_GLASS),
        shapes.cylinder("dish", (0, -0.03, 0.035), 0.02, None, 0.004, "Z", 14, 0.001, "gun_steel", style.MAT_METAL),
        shapes.cylinder("antenna", (-0.026, -0.03, 0.055), 0.002, None, 0.05, "Z", 6, 0.0, "gun_steel", style.MAT_METAL),
        shapes.uv_sphere("antennatip", (-0.026, -0.03, 0.082), (0.005, 0.005, 0.005), 8, 6, "led_red", style.MAT_EMISSIVE),
        shapes.rounded_box("ammo", (-0.046, 0.0, -0.008), (0.024, 0.05, 0.036), 0.004, 1, "polymer_olive", style.MAT_TOON),
        _decal("ammostencil", (-0.0582, 0.0, -0.008), (0.0012, 0.03, 0.012), "sticker_yellow"),
    ]
    for k in range(3):
        head.append(shapes.cylinder(f"vent{k}", (0.0352, -0.02 + k * 0.014, 0.0), 0.0035, None, 0.0014, "X", 8, 0, "rubber", style.MAT_FLAT))
    hm = shapes.join(head, "head")
    hm.location = (0, 0, 0.17)
    root = _root("gad_sentry", [bm, hm])
    shapes.empty("muzzle", (0, 0.13, 0.168), parent=root, size=0.015)
    return root


def eshield():
    """手腕护盾发生器（显示在仓鼠左手；护罩本身由 Godot 的六边形着色器画）：护腕 + 六边形发射器 + 青色指示灯。"""
    P = [
        shapes.cylinder("cuff", (0, 0, 0), 0.022, None, 0.03, "Y", 16, 0.004, "gun_metal", style.MAT_METAL),
        shapes.torus("cuffring", (0, 0.015, 0), 0.022, 0.0025, "Y", 16, 4, "rail_cyan", style.MAT_EMISSIVE),
        shapes.torus("cuffring2", (0, -0.015, 0), 0.022, 0.0025, "Y", 16, 4, "gun_dark", style.MAT_METAL),
        shapes.cylinder("emitter", (0, 0, 0.024), 0.017, None, 0.012, "Z", 6, 0.002, "lamp_dark", style.MAT_METAL),
        shapes.cylinder("lens", (0, 0, 0.0305), 0.011, None, 0.003, "Z", 6, 0, "rail_cyan", style.MAT_EMISSIVE),
        shapes.rounded_box("strap", (0, 0, -0.022), (0.03, 0.026, 0.006), 0.003, 1, "rubber", style.MAT_TOON),
    ]
    for i in range(3):
        P.append(_decal(f"led{i}", (0.0225, -0.008 + i * 0.008, 0.004), (0.0012, 0.004, 0.004), "led_green" if i < 2 else "led_amber"))
    return _root("gad_eshield", [shapes.join(P, "eshield")])


def smoke():
    """烟雾弹：灰色罐 + 深色色带 + 白色云朵贴花 + 顶部出烟孔 + 拉环。"""
    P = [
        shapes.cylinder("can", (0, 0, 0.055), 0.026, None, 0.1, "Z", 18, 0.004, "smoke_grey", style.MAT_TOON),
        _ring_decal("stripe", 0.068, 0.026, 0.016, "gun_dark"),
        shapes.cylinder("top", (0, 0, 0.11), 0.014, None, 0.014, "Z", 12, 0.002, "gun_steel", style.MAT_METAL),
        shapes.cylinder("base", (0, 0, 0.004), 0.024, None, 0.006, "Z", 18, 0.002, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("lever", (0.016, 0, 0.088), (0.008, 0.014, 0.05), 0.002, 1, "gun_steel", style.MAT_METAL, rot=(0, deg(-10), 0)),
    ]
    P += _pin("p", -0.016, 0.116)
    for i in range(6):
        a = i / 6 * math.tau
        P.append(shapes.cylinder(f"hole{i}", (math.cos(a) * 0.017, math.sin(a) * 0.017, 0.1055), 0.0032, None, 0.0014, "Z", 8, 0, "rubber", style.MAT_FLAT))
    # 云朵贴花（正面）
    for i, (u, v, r) in enumerate(((-0.008, 0.036, 0.007), (0.0, 0.039, 0.009), (0.009, 0.036, 0.007), (0.0, 0.033, 0.008))):
        P.append(shapes.cylinder(f"cloud{i}", (u, 0.0266, v), r, None, 0.0012, "Y", 12, 0, "white", style.MAT_FLAT))
    return _root("gad_smoke", [shapes.join(P, "smoke")])


def flare():
    """照明弹：红色信号棒 + 白色擦火帽 + 标签 + 顶端火花。"""
    P = [
        shapes.cylinder("stick", (0, 0, 0.07), 0.013, None, 0.14, "Z", 14, 0.003, "flare_red", style.MAT_TOON),
        shapes.cylinder("cap", (0, 0, 0.146), 0.015, None, 0.014, "Z", 14, 0.002, "white", style.MAT_TOON),
        shapes.cylinder("butt", (0, 0, 0.004), 0.0145, None, 0.008, "Z", 14, 0.002, "gun_dark", style.MAT_TOON),
        _ring_decal("band", 0.11, 0.013, 0.006, "white", 14),
        _ring_decal("band2", 0.03, 0.013, 0.006, "white", 14),
        _decal("label", (0, 0.0138, 0.07), (0.018, 0.0012, 0.05), "paper"),
        _decal("labelstar", (0, 0.0146, 0.075), (0.008, 0.0012, 0.008), "flare_red", rot=(0, deg(45), 0)),
        _decal("labelbar", (0, 0.0146, 0.058), (0.012, 0.0012, 0.003), "gun_dark"),
        shapes.uv_sphere("spark", (0, 0, 0.17), (0.016, 0.016, 0.02), 10, 6, "flare_red", style.MAT_EMISSIVE),
        shapes.uv_sphere("sparkcore", (0, 0, 0.168), (0.009, 0.009, 0.011), 8, 6, "torch_glass", style.MAT_EMISSIVE),
    ]
    return _root("gad_flare", [shapes.join(P, "flare")])


def decoy():
    """充气诱饵仓鼠：胖乎乎的气球仓鼠（塑料感）+ 气门嘴 + 画上去的五官、腮红、小手 + 接缝。"""
    P = [
        shapes.quad_sphere("body", (0, 0, 0.15), (0.15, 0.14, 0.15), 3, "towel_cream", style.MAT_GLASS),
        shapes.quad_sphere("belly", (0, 0.05, 0.13), (0.11, 0.1, 0.11), 3, "white", style.MAT_GLASS),
        shapes.quad_sphere("head", (0, 0.04, 0.3), (0.11, 0.1, 0.095), 3, "towel_cream", style.MAT_GLASS),
        shapes.cylinder("valve", (0.0, -0.13, 0.2), 0.012, None, 0.03, "Y", 10, 0.002, "shell_red", style.MAT_TOON),
        shapes.cylinder("valvecap", (0.0, -0.148, 0.2), 0.016, None, 0.008, "Y", 10, 0.002, "shell_red", style.MAT_TOON),
        shapes.uv_sphere("nose", (0, 0.135, 0.29), (0.014, 0.01, 0.012), 10, 6, "nose_pink", style.MAT_FLAT),
        shapes.capsule("mouth", (-0.012, 0.133, 0.272), (0.012, 0.133, 0.272), 0.002, 6, 2, "mouth", style.MAT_FLAT),
        shapes.transform(shapes.cylinder("patch", (0, 0, 0), 0.022, None, 0.002, "Y", 12, 0, "sticker_yellow", style.MAT_FLAT), loc=(0.095, 0.085, 0.08), rot=(0, 0, deg(-45))),
    ]
    for sgn in (-1, 1):
        P.append(shapes.quad_sphere(f"ear{sgn}", (sgn * 0.08, 0.0, 0.38), (0.04, 0.02, 0.04), 2, "towel_cream", style.MAT_GLASS))
        P.append(shapes.quad_sphere(f"earin{sgn}", (sgn * 0.08, 0.016, 0.38), (0.026, 0.008, 0.026), 2, "ear_inner", style.MAT_FLAT))
        P.append(shapes.uv_sphere(f"eye{sgn}", (sgn * 0.045, 0.125, 0.32), (0.012, 0.004, 0.016), 10, 6, "eye_black", style.MAT_FLAT))
        P.append(shapes.uv_sphere(f"eyehl{sgn}", (sgn * 0.042, 0.1285, 0.326), (0.004, 0.002, 0.005), 6, 4, "white", style.MAT_FLAT))
        P.append(shapes.uv_sphere(f"blush{sgn}", (sgn * 0.075, 0.105, 0.28), (0.018, 0.004, 0.01), 8, 4, "blush", style.MAT_FLAT))
        P.append(shapes.quad_sphere(f"arm{sgn}", (sgn * 0.12, 0.09, 0.17), (0.03, 0.03, 0.045), 2, "towel_cream", style.MAT_GLASS))
        P.append(shapes.quad_sphere(f"foot{sgn}", (sgn * 0.07, 0.08, 0.02), (0.04, 0.05, 0.022), 2, "towel_cream", style.MAT_GLASS))
        P.append(shapes.capsule(f"seam{sgn}", (sgn * 0.148, -0.02, 0.06), (sgn * 0.148, 0.02, 0.24), 0.003, 6, 2, "towel_stripe", style.MAT_FLAT))
    return _root("gad_decoy", [shapes.join(P, "decoy")])


def jetpack():
    """喷气背包：金属背板 + 两个红色燃料罐（带白色色带和尾翼）+ 压力表 + 肩带 + 喷口。"""
    P = [
        shapes.rounded_box("pack", (0, 0, 0.0), (0.12, 0.05, 0.13), 0.02, 2, "gun_metal", style.MAT_METAL),
        shapes.rounded_box("strap", (0, 0.03, 0.03), (0.13, 0.012, 0.02), 0.005, 1, "rubber", style.MAT_TOON),
        shapes.rounded_box("strap2", (0, 0.03, -0.035), (0.13, 0.012, 0.016), 0.005, 1, "rubber", style.MAT_TOON),
        shapes.rounded_box("panel", (0, -0.026, 0.01), (0.06, 0.004, 0.06), 0.004, 1, "sticker_yellow", style.MAT_FLAT),
        shapes.cylinder("gauge", (0, -0.0285, 0.035), 0.01, None, 0.003, "Y", 14, 0, "sticker_white", style.MAT_FLAT),
        _decal("needle", (0.002, -0.0302, 0.036), (0.006, 0.0012, 0.0012), "gauge_red", rot=(0, deg(30), 0)),
        shapes.rounded_box("buckle", (0, 0.037, 0.03), (0.024, 0.006, 0.018), 0.002, 1, "gun_steel", style.MAT_METAL),
    ]
    for sgn in (-1, 1):
        P.append(shapes.cylinder(f"tank{sgn}", (sgn * 0.045, -0.02, 0.0), 0.022, None, 0.13, "Z", 16, 0.004, "shell_red", style.MAT_TOON))
        P.append(shapes.uv_sphere(f"tanktop{sgn}", (sgn * 0.045, -0.02, 0.065), (0.022, 0.022, 0.014), 14, 6, "shell_red", style.MAT_TOON))
        P.append(shapes.cylinder(f"tankband{sgn}", (sgn * 0.045, -0.02, 0.03), 0.0228, None, 0.008, "Z", 16, 0.0, "white", style.MAT_TOON))
        P.append(shapes.cylinder(f"valve{sgn}", (sgn * 0.045, -0.02, 0.082), 0.006, None, 0.012, "Z", 10, 0.001, "gun_steel", style.MAT_METAL))
        P.append(shapes.cylinder(f"nozzle{sgn}", (sgn * 0.045, -0.02, -0.08), 0.012, 0.018, 0.03, "Z", 14, 0.002, "gun_dark", style.MAT_METAL))
        P.append(shapes.rounded_box(f"fin{sgn}", (sgn * 0.072, -0.02, -0.05), (0.014, 0.004, 0.04), 0.002, 1, "gun_dark", style.MAT_METAL))
    root = _root("gad_jetpack", [shapes.join(P, "jetpack")])
    shapes.empty("nozzle_L", (-0.045, -0.02, -0.095), parent=root, size=0.01)
    shapes.empty("nozzle_R", (0.045, -0.02, -0.095), parent=root, size=0.01)
    return root


def medkit():
    """急救瓜子包：红色软包 + 白十字 + 拉链 + 提手 + 包口露出瓜子。"""
    P = [
        shapes.rounded_box("bag", (0, 0, 0.05), (0.12, 0.07, 0.1), 0.02, 3, "label_red", style.MAT_TOON),
        shapes.rounded_box("crossV", (0, 0.0362, 0.05), (0.02, 0.0016, 0.06), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("crossH", (0, 0.0362, 0.05), (0.06, 0.0016, 0.02), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("crossVb", (0, -0.0362, 0.05), (0.02, 0.0016, 0.06), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("crossHb", (0, -0.0362, 0.05), (0.06, 0.0016, 0.02), 0.0, 1, "white", style.MAT_FLAT),
        shapes.rounded_box("fold", (0, 0, 0.102), (0.124, 0.074, 0.012), 0.006, 2, "headband_red", style.MAT_TOON),
        shapes.rounded_box("zip", (0, 0, 0.1095), (0.11, 0.006, 0.002), 0.0, 1, "gun_darker", style.MAT_FLAT),
        shapes.rounded_box("zippull", (0.05, 0.006, 0.11), (0.006, 0.014, 0.003), 0.001, 1, "gun_steel", style.MAT_METAL),
        shapes.torus("handle", (0, 0, 0.118), 0.022, 0.004, "Y", 14, 4, "rubber", style.MAT_TOON, scale=(1.0, 1.0, 0.6)),
    ]
    # 包口露出一小堆瓜子（横躺、交错）
    seeds = [(-0.03, -0.008, 0.25, 0.4), (-0.008, 0.01, -0.3, 1.9), (0.016, -0.006, 0.35, 0.9), (0.038, 0.008, -0.2, 2.6), (0.002, -0.002, 0.15, 1.3)]
    for i, (x, y, tilt, yaw) in enumerate(seeds):
        z = 0.112 + (0.008 if i == 4 else 0.0)
        sd = shapes.uv_sphere(f"seed{i}", (0, 0, 0), (0.009, 0.019, 0.006), 8, 6, "seed_shell", style.MAT_TOON)
        shapes.transform(sd, rot=(tilt, 0, yaw), loc=(x, y, z))
        P.append(sd)
        st = shapes.capsule(f"seedst{i}", (0, -0.013, 0.0), (0, 0.013, 0.0), 0.0018, 6, 2, "seed_stripe", style.MAT_FLAT)
        shapes.transform(st, rot=(tilt, 0, yaw), loc=(x, y, z + 0.0055))
        P.append(st)
    return _root("gad_medkit", [shapes.join(P, "medkit")])


def freeze():
    """冰冻手雷：冰蓝卵形 + 发光色带 + 雪花贴花 + 冰晶尖刺 + 握片拉环。"""
    P = [
        shapes.quad_sphere("body", (0, 0, 0.055), (0.046, 0.046, 0.056), 2, "ice", style.MAT_GLASS),
        shapes.torus("band", (0, 0, 0.055), 0.046, 0.006, "Z", 20, 6, "rail_cyan", style.MAT_EMISSIVE),
        shapes.cylinder("top", (0, 0, 0.118), 0.016, None, 0.022, "Z", 12, 0.003, "gun_steel", style.MAT_METAL),
        shapes.rounded_box("lever", (0.014, 0, 0.1), (0.01, 0.016, 0.06), 0.003, 1, "gun_steel", style.MAT_METAL, rot=(0, deg(-18), 0)),
    ]
    P += _pin("p", -0.016, 0.124, 0.012)
    for i in range(5):
        a = i / 5 * math.tau
        P.append(shapes.cylinder(f"crystal{i}", (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.088), 0.0, 0.009, 0.028, "Z", 6, 0.0, "ice", style.MAT_GLASS))
    # 雪花贴花（正面）：三根交叉的短条
    for i in range(3):
        P.append(_decal(f"flake{i}", (0, 0.0466, 0.034), (0.022, 0.0012, 0.003), "white", rot=(0, deg(i * 60), 0)))
    return _root("gad_freeze", [shapes.join(P, "freeze")])


def beacon():
    """传送信标：地钉 + 白色机身 + 青色光环 + 尾翼 + 小屏幕 + 顶部灯泡。"""
    P = [
        shapes.cylinder("stake", (0, 0, 0.06), 0.008, 0.002, 0.12, "Z", 10, 0.001, "gun_steel", style.MAT_METAL),
        shapes.cylinder("body", (0, 0, 0.13), 0.022, None, 0.05, "Z", 16, 0.004, "white", style.MAT_TOON),
        shapes.cylinder("collar", (0, 0, 0.1), 0.016, 0.022, 0.012, "Z", 16, 0.002, "gun_metal", style.MAT_METAL),
        shapes.torus("ring", (0, 0, 0.14), 0.024, 0.004, "Z", 16, 4, "rail_cyan", style.MAT_EMISSIVE),
        shapes.torus("ring2", (0, 0, 0.118), 0.023, 0.0025, "Z", 16, 4, "gun_dark", style.MAT_METAL),
        shapes.uv_sphere("bulb", (0, 0, 0.17), (0.016, 0.016, 0.018), 12, 8, "rail_cyan", style.MAT_EMISSIVE),
        shapes.cylinder("bulbcage", (0, 0, 0.158), 0.018, None, 0.006, "Z", 12, 0.001, "gun_metal", style.MAT_METAL),
        shapes.rounded_box("screen", (0, 0.0215, 0.128), (0.016, 0.003, 0.012), 0.001, 1, "screen_dark", style.MAT_EMISSIVE),
        _decal("screenbar", (0, 0.0235, 0.128), (0.01, 0.0012, 0.003), "rail_cyan"),
    ]
    for i in range(3):
        a = i / 3 * math.tau
        P.append(shapes.rounded_box(f"fin{i}", (math.cos(a) * 0.024, math.sin(a) * 0.024, 0.108), (0.004, 0.024, 0.036), 0.002, 1, "gun_metal", style.MAT_METAL, rot=(0, 0, a + math.pi / 2)))
    root = _root("gad_beacon", [shapes.join(P, "beacon")])
    shapes.empty("light", (0, 0, 0.18), parent=root, size=0.01)
    return root


def fx_rocket():
    """飞行中的火箭弹（+Y 朝前，中心在原点，飞行时由表现层整体转向）。"""
    P = [
        shapes.cylinder("body", (0, 0.0, 0.0), 0.016, None, 0.11, "Y", 14, 0.003, "white", style.MAT_TOON),
        shapes.cylinder("nose", (0, 0.07, 0.0), 0.016, 0.0, 0.035, "Y", 14, 0.0, "label_red", style.MAT_TOON),
        shapes.cylinder("band", (0, 0.035, 0.0), 0.0168, None, 0.01, "Y", 14, 0.0, "label_red", style.MAT_TOON),
        shapes.cylinder("nozzle", (0, -0.062, 0.0), 0.011, 0.014, 0.016, "Y", 12, 0.0, "gun_dark", style.MAT_METAL),
    ]
    for i in range(4):
        a = i / 4 * math.tau
        P.append(shapes.rounded_box(f"fin{i}", (math.cos(a) * 0.02, -0.045, math.sin(a) * 0.02), (0.004, 0.03, 0.016), 0.001, 1, "polymer_olive", style.MAT_TOON, rot=(0, a, 0)))
    return _root("fx_rocket", [shapes.join(P, "rocket")])


def fx_gnade():
    """榴弹（橄榄色椭球 + 黄色弹带）。"""
    P = [
        shapes.uv_sphere("shell", (0, 0, 0), (0.024, 0.03, 0.024), 14, 8, "polymer_olive", style.MAT_TOON),
        shapes.cylinder("band", (0, 0.004, 0), 0.0245, None, 0.01, "Y", 14, 0.0, "sticker_yellow", style.MAT_TOON),
        shapes.cylinder("tip", (0, 0.03, 0), 0.008, None, 0.008, "Y", 10, 0.002, "brass", style.MAT_METAL),
    ]
    return _root("fx_gnade", [shapes.join(P, "gnade")])


def fx_bomb():
    """集束子炸弹（深色小球 + 红色环）。"""
    P = [
        shapes.uv_sphere("ball", (0, 0, 0), (0.02, 0.02, 0.02), 12, 8, "gun_darker", style.MAT_METAL),
        shapes.torus("ring", (0, 0, 0), 0.02, 0.003, "Z", 16, 6, "label_red", style.MAT_TOON),
        shapes.cylinder("fuse", (0, 0, 0.022), 0.003, None, 0.008, "Z", 8, 0.0, "rubber", style.MAT_TOON),
    ]
    return _root("fx_bomb", [shapes.join(P, "bomb")])


def build(ctx):
    items = [molotov(), flash(), mine(), sentry(), eshield(), smoke(), flare(), decoy(), jetpack(), medkit(), freeze(), beacon(), fx_rocket(), fx_gnade(), fx_bomb()]
    extras = [(r.name, [r]) for r in items]

    def layout(_ctx):
        for i, r in enumerate(items):
            r.location = Vector(((i % 4) * 0.42, -(i // 4) * 0.42, 0))

    pv = [("all", "three_quarter", {"margin": 1.02, "res": 1000}), ("all_game", "game", {"margin": 1.05, "res": 1000})]
    ip = [("three_quarter", {"margin": 1.15, "res": 360}), ("game", {"margin": 1.3, "res": 360})]
    return ctx.Built([], previews=pv, outline=0.003, extra_exports=extras, after_export=layout, item_previews=ip)
