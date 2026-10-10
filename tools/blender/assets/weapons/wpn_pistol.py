"""手枪（初始武器）：玩具化粗短手枪，识别色 = 黄色握把贴片。"""
import math

from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    # 套筒（上半部）：前端略收、带后部防滑槽
    P.append(shapes.rounded_box("slide", (0, 0.034, 0.033), (0.032, 0.138, 0.036), 0.006, 2, "gun_metal", style.MAT_METAL))
    for i in range(5):
        P.append(shapes.rounded_box(f"serr{i}", (0, -0.026 + i * 0.0065, 0.033), (0.0335, 0.0025, 0.03), 0.0006, 1, "gun_darker", style.MAT_METAL))
    # 枪口露出的枪管
    P.append(shapes.cylinder("barrel", (0, 0.106, 0.031), 0.0085, None, 0.012, "Y", 14, 0.0015, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("bore", (0, 0.1125, 0.031), 0.0045, None, 0.002, "Y", 10, 0, "gun_darker", style.MAT_FLAT))
    # 准星 / 照门
    P.append(shapes.rounded_box("fsight", (0, 0.095, 0.054), (0.006, 0.008, 0.008), 0.0015, 1, "gun_darker", style.MAT_METAL))
    P.append(shapes.rounded_box("rsight", (0, -0.026, 0.054), (0.022, 0.006, 0.008), 0.0015, 1, "gun_darker", style.MAT_METAL))
    P.append(shapes.rounded_box("rsight_dot", (0, -0.0225, 0.0555), (0.004, 0.0012, 0.003), 0.0, 1, "white", style.MAT_FLAT))
    # 枪身下半（框架）+ 扳机护圈
    P.append(shapes.rounded_box("frame", (0, 0.03, 0.0095), (0.03, 0.12, 0.016), 0.004, 2, "gun_dark", style.MAT_METAL))
    P.append(shapes.torus("guard", (0, 0.03, -0.006), 0.014, 0.0035, "X", 20, 6, "gun_dark", style.MAT_METAL, scale=(1.0, 1.25, 1.0)))
    P.append(shapes.rounded_box("trigger", (0, 0.024, -0.006), (0.006, 0.006, 0.014), 0.002, 1, "gun_darker", style.MAT_METAL, rot=(deg(15), 0, 0)))
    # 握把（向后倾斜）+ 黄色识别贴片 + 弹匣底
    P.append(shapes.rounded_box("grip", (0, -0.008, -0.022), (0.03, 0.03, 0.06), 0.007, 2, "gun_darker", style.MAT_TOON, rot=(deg(-14), 0, 0)))
    for s in (-1, 1):
        P.append(shapes.rounded_box(f"panel{s}", (s * 0.0158, -0.01, -0.022), (0.002, 0.022, 0.042), 0.0008, 1, "sticker_yellow", style.MAT_TOON, rot=(deg(-14), 0, 0)))
    P.append(shapes.rounded_box("magbase", (0, -0.016, -0.054), (0.032, 0.033, 0.009), 0.003, 1, "gun_light", style.MAT_METAL, rot=(deg(-14), 0, 0)))
    # 侧面小贴纸
    P.append(shapes.rounded_box("sticker", (0.0165, 0.06, 0.034), (0.0015, 0.024, 0.014), 0.0, 1, "sticker_mint", style.MAT_FLAT))
    P += g.eject_port("eject", 0.026, 0.036, 0.016, 0.024, 0.011)
    P += g.screws("screw", 0.0, 0.01, 0.015)
    P += g.screws("screw2", 0.075, 0.01, 0.015)
    P.append(g.top_decal("topstripe", 0.045, 0.051, 0.07, 0.008, "sticker_yellow"))
    P += g.paw("paw", (-0.0165 - g.D, 0.06, 0.034), "X", 0.01, "sticker_yellow")
    root = weapon_kit.finish("wpn_pistol", P, "pistol", {
        "muzzle": (0, 0.115, 0.031),
        "att_muzzle": (0, 0.112, 0.031),
        "att_scope": (0, 0.03, 0.055),
        "att_drum": (0, -0.016, -0.06),
        "att_tank": (-0.02, 0.03, 0.02),
        "att_coil": (0, 0.085, 0.033),
        "att_radar": (0, -0.02, 0.06),
        "att_torch": (0, 0.075, -0.004),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_pistol"), outline=0.0016)
