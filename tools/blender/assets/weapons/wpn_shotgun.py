"""霰弹枪（泵动）：粗枪管 + 下挂管状弹仓 + 红色泵把，侧面弹托插着红色霰弹，识别色 = 红。"""
import math

from lib import shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    # 机匣
    P.append(shapes.rounded_box("receiver", (0, 0.012, 0.02), (0.036, 0.09, 0.04), 0.007, 2, "gun_metal", style.MAT_METAL))
    P.append(shapes.rounded_box("ejport", (0.0182, 0.02, 0.026), (0.0015, 0.03, 0.012), 0.0, 1, "gun_darker", style.MAT_FLAT))
    # 枪托（深红木）
    stock = shapes.extrude_profile("stock", [(-0.032, 0.034), (-0.032, 0.0), (-0.15, -0.024), (-0.158, -0.02), (-0.158, 0.034), (-0.15, 0.04)], 0.03, plane="YZ", bevel=0.005, color="wood_red")
    P.append(stock)
    P.append(shapes.rounded_box("pad", (0, -0.161, 0.008), (0.032, 0.008, 0.066), 0.003, 1, "rubber", style.MAT_TOON))
    # 握把与扳机护圈
    P.append(shapes.rounded_box("grip", (0, -0.006, -0.02), (0.026, 0.028, 0.05), 0.006, 2, "gun_darker", style.MAT_TOON, rot=(deg(-20), 0, 0)))
    P.append(shapes.torus("guard", (0, 0.016, -0.004), 0.012, 0.003, "X", 18, 6, "gun_dark", style.MAT_METAL, scale=(1.0, 1.3, 1.0)))
    # 粗枪管 + 散热护罩上的通风孔条
    P.append(shapes.cylinder("barrel", (0, 0.15, 0.03), 0.0125, None, 0.2, "Y", 16, 0.0015, "gun_dark", style.MAT_METAL))
    P.append(shapes.rounded_box("rib", (0, 0.15, 0.0435), (0.008, 0.19, 0.004), 0.0015, 1, "gun_darker", style.MAT_METAL))
    P.append(shapes.cylinder("bead", (0, 0.243, 0.047), 0.0028, None, 0.004, "Z", 8, 0, "brass", style.MAT_METAL))
    P.append(shapes.cylinder("bore", (0, 0.2505, 0.03), 0.0085, None, 0.002, "Y", 12, 0, "rubber", style.MAT_FLAT))
    # 下挂管状弹仓 + 泵把（红）
    P.append(shapes.cylinder("tube", (0, 0.125, 0.006), 0.0095, None, 0.16, "Y", 14, 0.0015, "gun_metal", style.MAT_METAL))
    P.append(shapes.cylinder("tubecap", (0, 0.207, 0.006), 0.0105, None, 0.008, "Y", 14, 0.0015, "gun_darker", style.MAT_METAL))
    pump = shapes.rounded_box("pump", (0, 0.1, 0.006), (0.036, 0.06, 0.028), 0.009, 2, "shell_red", style.MAT_TOON)
    P.append(pump)
    for i in range(4):
        P.append(shapes.rounded_box(f"pumpgroove{i}", (0, 0.078 + i * 0.014, -0.0075), (0.034, 0.004, 0.002), 0.0, 1, "wood_red", style.MAT_FLAT))
    # 侧面弹托 + 4 发红色霰弹
    P.append(shapes.rounded_box("carrier", (-0.0205, 0.012, 0.02), (0.006, 0.07, 0.03), 0.002, 1, "rubber", style.MAT_TOON))
    for i in range(4):
        P.append(shapes.cylinder(f"shell{i}", (-0.025, -0.012 + i * 0.016, 0.02), 0.0058, None, 0.026, "Z", 10, 0.0008, "shell_red", style.MAT_TOON))
        P.append(shapes.cylinder(f"shellb{i}", (-0.025, -0.012 + i * 0.016, 0.0335), 0.0062, None, 0.006, "Z", 10, 0.0008, "brass", style.MAT_METAL))
    root = weapon_kit.finish("wpn_shotgun", P, "shotgun", {
        "muzzle": (0, 0.252, 0.03),
        "att_muzzle": (0, 0.248, 0.03),
        "att_scope": (0, 0.01, 0.048),
        "att_drum": (0, 0.03, -0.035),
        "att_tank": (0.026, 0.06, 0.02),
        "att_coil": (0, 0.2, 0.03),
        "att_radar": (0, -0.05, 0.05),
        "att_torch": (0.02, 0.17, 0.0),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_shotgun"), outline=0.0016)
