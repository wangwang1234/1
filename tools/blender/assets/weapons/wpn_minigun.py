"""加特林：方机匣 + 六根旋转枪管（单独的 spin 节点，Godot 里开火时转）+ 橄榄弹箱 + 提把，识别色 = 六管。"""
import math

from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.03, 0.026), (0.044, 0.11, 0.05), "gun_metal", bevel=0.008))
    P.append(g.box("motor", (0, 0.095, 0.026), (0.034, 0.03, 0.04), "gun_dark", bevel=0.006))
    P.append(g.box("ammobox", (0.012, 0.02, -0.03), (0.056, 0.06, 0.05), "polymer_olive", style.MAT_TOON, 0.006))
    for k in range(6):
        P.append(shapes.cylinder(f"belt{k}", (0.036, 0.0 + k * 0.009, 0.0 + k * 0.004), 0.003, None, 0.016, "Z", 8, 0.0008, "brass", style.MAT_METAL))
    P.append(g.box("handle", (0, 0.03, 0.068), (0.012, 0.07, 0.01), "gun_darker", bevel=0.004))
    for s in (-1, 1):
        P.append(g.box(f"hpost{s}", (0, 0.03 + s * 0.03, 0.057), (0.012, 0.008, 0.016), "gun_darker", bevel=0.002, seg=1))
    P.append(g.grip(y=-0.006, z=-0.018, size=(0.026, 0.028, 0.048), angle=-10))
    P += g.guard(y=0.016, z=-0.002)
    HW = 0.022
    P += g.stripes("haz", -0.01, 0.075, 0.051, 0.03, 7, "sticker_yellow", "rubber")
    P += g.vents("vent", 0.084, 0.026, 4, 0.007, 0.017, h=0.024)
    P.append(g.decal("boxstencil", (0.0402, 0.02, -0.03), (0.0012, 0.034, 0.02), "sticker_yellow"))
    P.append(g.decal("boxstencil2", (0.0403, 0.02, -0.03), (0.0013, 0.026, 0.007), "polymer_olive"))
    P.append(g.top_decal("boxtop", 0.02, -0.005, 0.05, 0.05, "sand_tan", x=0.012))
    P.append(shapes.capsule("feedchute", (0.03, 0.045, -0.006), (0.02, 0.07, 0.012), 0.007, 8, 2, "hose_dark", style.MAT_TOON))
    P.append(shapes.capsule("cable", (-0.022, 0.0, 0.01), (-0.018, 0.09, 0.012), 0.003, 8, 2, "hose_dark", style.MAT_TOON))
    P.append(g.box("battery", (-0.026, 0.0, 0.02), (0.012, 0.04, 0.024), "gun_dark", bevel=0.003, seg=1))
    P.append(g.decal("led", (-0.0322, 0.0, 0.026), (0.0012, 0.006, 0.006), "led_green"))
    P += g.screws("screw", -0.012, 0.012, HW)
    P += g.screws("screw2", 0.07, 0.012, HW)
    P.append(g.box("spade", (0, -0.03, 0.04), (0.03, 0.01, 0.012), "gun_darker", bevel=0.003, seg=1))
    root = weapon_kit.finish("wpn_minigun", P, "heavy", {
        "muzzle": (0, 0.29, 0.026), "att_muzzle": (0, 0.275, 0.026), "att_scope": (0, 0.03, 0.08),
        "att_drum": (0.012, 0.02, -0.06), "att_tank": (-0.03, 0.03, 0.026), "att_coil": (0, 0.2, 0.026),
        "att_radar": (0, -0.025, 0.06), "att_torch": (0, 0.16, 0.0),
    })
    # 旋转枪管组：原点在枪管轴心，Godot 里绕自身 Y 轴转
    S = []
    for k in range(6):
        a = k / 6 * math.tau
        S.append(shapes.cylinder(f"tube{k}", (math.cos(a) * 0.014, 0.08, math.sin(a) * 0.014), 0.0055, None, 0.17, "Y", 10, 0.001, "gun_dark", style.MAT_METAL))
        S.append(shapes.cylinder(f"bore{k}", (math.cos(a) * 0.014, 0.1655, math.sin(a) * 0.014), 0.003, None, 0.002, "Y", 8, 0, "rubber", style.MAT_FLAT))
    for y in (0.02, 0.14):
        S.append(shapes.torus(f"clamp{y}", (0, y, 0), 0.02, 0.0035, "Y", 18, 5, "gun_light", style.MAT_METAL))
    S.append(shapes.cylinder("hub", (0, 0.0, 0), 0.012, None, 0.012, "Y", 14, 0.002, "gun_darker", style.MAT_METAL))
    spin = shapes.join(S, "spin")
    shapes.bake_outline_normals(spin)
    spin.location = (0, 0.11, 0.026)
    spin.parent = root
    return ctx.Built([root], previews=weapon_kit.previews("wpn_minigun"), outline=0.0016)
