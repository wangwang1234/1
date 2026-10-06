"""榴弹发射器：粗橄榄色短管 + 转轮弹仓 + 木托，识别色 = 大口径管口。"""
import math

from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    z = 0.03
    P.append(shapes.cylinder("tube", (0, 0.13, z), 0.026, None, 0.14, "Y", 20, 0.003, "polymer_olive", style.MAT_TOON))
    P.append(shapes.torus("lip", (0, 0.2, z), 0.026, 0.004, "Y", 20, 5, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("bore", (0, 0.2005, z), 0.019, None, 0.002, "Y", 16, 0, "rubber", style.MAT_FLAT))
    P.append(shapes.cylinder("drum", (0, 0.035, z - 0.004), 0.034, None, 0.05, "Y", 20, 0.004, "gun_dark", style.MAT_METAL))
    for k in range(6):
        a = k / 6 * math.tau
        P.append(shapes.cylinder(f"flute{k}", (math.cos(a) * 0.034, 0.035, z - 0.004 + math.sin(a) * 0.034), 0.006, None, 0.044, "Y", 8, 0.001, "gun_darker", style.MAT_METAL))
    P.append(g.box("frame", (0, 0.04, z + 0.034), (0.012, 0.13, 0.008), "gun_darker", bevel=0.003))
    P.append(g.stock("stock", -0.005, 0.11, z_top=0.04, drop=0.05, width=0.03, color="wood"))
    P.append(g.grip(y=-0.004, z=-0.018, size=(0.026, 0.028, 0.05), angle=-16))
    P.append(g.grip("foregrip", y=0.1, z=-0.006, size=(0.02, 0.02, 0.036), angle=-6))
    P += g.guard(y=0.016, z=-0.004)
    root = weapon_kit.finish("wpn_gl", P, "launcher", {
        "muzzle": (0, 0.205, z), "att_muzzle": (0, 0.205, z), "att_scope": (0, 0.06, z + 0.045),
        "att_drum": (0, 0.035, z - 0.045), "att_tank": (-0.04, 0.04, z), "att_coil": (0, 0.15, z),
        "att_radar": (0, -0.02, z + 0.045), "att_torch": (0.028, 0.15, z - 0.01),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_gl"), outline=0.0016)
