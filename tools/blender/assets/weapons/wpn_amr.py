"""反器材狙击枪：超长枪管 + 方形大枪口制退器 + 橙色镜片大瞄准镜 + 脚架，识别色 = 沙色机匣 + 橙镜片。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.03, 0.022), (0.036, 0.17, 0.044), "sand_tan", style.MAT_TOON, 0.008))
    P += g.barrel("barrel", 0.115, 0.27, 0.03, 0.01, "gun_dark")
    P.append(g.box("brake", (0, 0.4, 0.03), (0.036, 0.04, 0.03), "rubber", style.MAT_METAL, 0.005))
    for s in (-1, 1):
        P.append(g.box(f"port{s}", (s * 0.018, 0.4, 0.03), (0.002, 0.026, 0.016), "gun_darker", style.MAT_FLAT, 0.0, seg=1))
    P += g.scope("scope", 0.04, 0.072, 0.14, 0.017, lens="lens_orange")
    P += g.mag("mag", 0.055, -0.02, (0.024, 0.036, 0.04), 0, "gun_dark")
    P.append(g.box("stock", (0, -0.09, 0.016), (0.03, 0.08, 0.05), "sand_tan", style.MAT_TOON, 0.008))
    P.append(g.box("pad", (0, -0.133, 0.012), (0.032, 0.008, 0.06), "rubber", style.MAT_TOON, 0.003))
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.026, 0.028, 0.05), angle=-14))
    P += g.guard(y=0.016, z=-0.004)
    P += g.bipod("bipod", 0.3, 0.018, 0.09, 0.016)
    HW = 0.018
    P.append(g.top_decal("topstripe", 0.02, 0.044, 0.12, 0.008, "sand_dark"))
    P += g.eject_port("eject", 0.05, 0.032, HW, 0.036, 0.014)
    P += g.screws("screw", -0.04, 0.01, HW, 0.003)
    P += g.screws("screw2", 0.1, 0.01, HW, 0.003)
    for s in (-1, 1):
        P.append(g.box(f"cap{s}", (0, 0.04 + s * 0.082, 0.072), (0.036, 0.006, 0.036), "sand_dark", style.MAT_TOON, 0.003, seg=1))
    P.append(g.box("turret", (0, 0.04, 0.093), (0.014, 0.014, 0.01), "gun_dark", bevel=0.002, seg=1))
    for s in (-1, 1):
        P.append(g.box(f"brakeport{s}b", (s * 0.018, 0.39, 0.03), (0.002, 0.008, 0.02), "gun_darker", style.MAT_FLAT, 0.0, seg=1))
    P.append(g.box("cheek", (0, -0.085, 0.045), (0.028, 0.05, 0.01), "sand_dark", style.MAT_TOON, 0.003, seg=1))
    P.append(g.box("monopod", (0, -0.11, -0.02), (0.008, 0.008, 0.03), "gun_darker", bevel=0.002, seg=1))
    P.append(g.box("handle", (0, 0.13, 0.05), (0.01, 0.05, 0.006), "gun_darker", bevel=0.002, seg=1))
    for s in (-1, 1):
        P.append(g.box(f"hpost{s}", (0, 0.13 + s * 0.02, 0.043), (0.01, 0.006, 0.012), "gun_darker", bevel=0.001, seg=1))
    P += g.paw("paw", (HW + g.D, -0.085, 0.015), "X", 0.014, "sand_dark")
    root = weapon_kit.finish("wpn_amr", P, "rifle", {
        "muzzle": (0, 0.42, 0.03), "att_muzzle": (0, 0.42, 0.03), "att_scope": (0, 0.04, 0.094),
        "att_drum": (0, 0.055, -0.045), "att_tank": (-0.026, 0.06, 0.022), "att_coil": (0, 0.28, 0.03),
        "att_radar": (0, -0.05, 0.048), "att_torch": (0, 0.24, 0.016),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_amr"), outline=0.0016)
