"""AK-47：玩具化步枪，识别色 = 木质护木和枪托 + 香蕉弹匣。"""
import math

import bmesh
from mathutils import Vector

from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def banana_mag():
    """弧形弹匣：沿弧线扫出的方截面，底部加一块底板。"""
    pts = []
    n = 9
    for i in range(n):
        t = i / (n - 1)
        pts.append((0.044 + 0.045 * t * t + 0.004 * t, 0.004 - 0.082 * t))
    mag = shapes.swept_box("mag", pts, 0.022, 0.032, "gun_dark", style.MAT_METAL, bevel=0.004)
    base = shapes.rounded_box("magbase", (0, 0.094, -0.08), (0.025, 0.036, 0.008), 0.003, 1, "gun_darker", style.MAT_METAL, rot=(deg(-30), 0, 0))
    ribs = []
    for k in range(3):
        t = 0.3 + k * 0.2
        y = 0.044 + 0.045 * t * t + 0.004 * t
        z = 0.004 - 0.082 * t
        ribs.append(shapes.rounded_box(f"magrib{k}", (0, y, z), (0.0235, 0.03, 0.004), 0.001, 1, "gun_darker", style.MAT_METAL, rot=(deg(-25 * t), 0, 0)))
    return shapes.join([mag, base] + ribs, "mag")


def build(ctx):
    P = []
    # 机匣
    P.append(shapes.rounded_box("receiver", (0, 0.016, 0.018), (0.034, 0.1, 0.036), 0.006, 2, "gun_metal", style.MAT_METAL))
    P.append(shapes.rounded_box("cover", (0, 0.012, 0.039), (0.03, 0.09, 0.01), 0.004, 2, "gun_dark", style.MAT_METAL))
    P.append(shapes.rounded_box("rearsight", (0, 0.06, 0.046), (0.012, 0.014, 0.008), 0.002, 1, "gun_darker", style.MAT_METAL))
    # 拉机柄
    P.append(shapes.cylinder("charge", (0.022, 0.05, 0.026), 0.0045, None, 0.014, "X", 8, 0.001, "gun_steel", style.MAT_METAL))
    # 握把
    P.append(shapes.rounded_box("grip", (0, -0.004, -0.02), (0.026, 0.028, 0.05), 0.006, 2, "gun_darker", style.MAT_TOON, rot=(deg(-18), 0, 0)))
    P.append(shapes.torus("guard", (0, 0.018, -0.004), 0.012, 0.003, "X", 18, 6, "gun_dark", style.MAT_METAL, scale=(1.0, 1.3, 1.0)))
    # 枪托（木）：梯形剖面挤出
    stock = shapes.extrude_profile("stock", [(-0.034, 0.03), (-0.034, 0.002), (-0.16, -0.026), (-0.168, -0.022), (-0.168, 0.032), (-0.16, 0.036)], 0.028, plane="YZ", bevel=0.004, color="wood")
    P.append(stock)
    P.append(shapes.rounded_box("buttplate", (0, -0.17, 0.004), (0.03, 0.006, 0.062), 0.002, 1, "gun_darker", style.MAT_TOON))
    # 护木（木）+ 上护木
    P.append(shapes.rounded_box("handguard", (0, 0.1, 0.012), (0.034, 0.074, 0.03), 0.008, 2, "wood", style.MAT_TOON))
    for i in range(3):
        P.append(shapes.rounded_box(f"hgline{i}", (0.0172, 0.078 + i * 0.022, 0.012), (0.0012, 0.004, 0.022), 0.0, 1, "wood_dark", style.MAT_FLAT))
        P.append(shapes.rounded_box(f"hgline_l{i}", (-0.0172, 0.078 + i * 0.022, 0.012), (0.0012, 0.004, 0.022), 0.0, 1, "wood_dark", style.MAT_FLAT))
    P.append(shapes.rounded_box("upperhg", (0, 0.095, 0.033), (0.022, 0.06, 0.012), 0.005, 2, "wood_dark", style.MAT_TOON))
    # 枪管 + 导气管 + 准星 + 枪口制退器
    P.append(shapes.cylinder("barrel", (0, 0.19, 0.016), 0.0085, None, 0.13, "Y", 14, 0.001, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("gastube", (0, 0.155, 0.032), 0.0065, None, 0.06, "Y", 12, 0.001, "gun_metal", style.MAT_METAL))
    P.append(shapes.rounded_box("fsight", (0, 0.226, 0.03), (0.008, 0.01, 0.022), 0.002, 1, "gun_darker", style.MAT_METAL))
    P.append(shapes.cylinder("brake", (0, 0.262, 0.016), 0.011, None, 0.022, "Y", 14, 0.002, "gun_darker", style.MAT_METAL))
    P.append(shapes.cylinder("bore", (0, 0.2735, 0.016), 0.005, None, 0.002, "Y", 10, 0, "rubber", style.MAT_FLAT))
    P.append(banana_mag())
    P += g.eject_port("eject", 0.02, 0.026, 0.017, 0.034, 0.012)
    P += g.screws("screw", -0.02, 0.008, 0.017)
    P += g.screws("screw2", 0.05, 0.008, 0.017)
    P.append(g.sling_loop("sling", (0, -0.15, -0.012)))
    P.append(g.sling_loop("sling2", (0, 0.23, 0.006)))
    P += g.side_decal("stockline", -0.1, 0.015, 0.08, 0.003, "wood_dark", 0.014)
    P += g.paw("paw", (0.014 + g.D, -0.12, 0.012), "X", 0.012, "sticker_white")
    root = weapon_kit.finish("wpn_ak47", P, "rifle", {
        "muzzle": (0, 0.276, 0.016),
        "att_muzzle": (0, 0.272, 0.016),
        "att_scope": (0, 0.012, 0.05),
        "att_drum": (0, 0.05, -0.04),
        "att_tank": (-0.024, 0.11, 0.01),
        "att_coil": (0, 0.19, 0.016),
        "att_radar": (0, -0.04, 0.045),
        "att_torch": (0.024, 0.13, 0.008),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_ak47"), outline=0.0016)
