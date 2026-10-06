"""左轮手枪：钢色长枪管 + 六孔转轮 + 木握把，识别色 = 转轮。"""
import math

from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P += g.barrel("barrel", 0.035, 0.115, 0.034, 0.008, "gun_steel")
    P.append(g.box("lug", (0, 0.1, 0.026), (0.014, 0.1, 0.01), "gun_steel", bevel=0.003))
    P.append(g.box("frame", (0, 0.015, 0.03), (0.026, 0.06, 0.036), "gun_steel", bevel=0.006))
    P.append(shapes.cylinder("cylinder", (0, 0.03, 0.03), 0.019, None, 0.036, "Y", 18, 0.003, "gun_light", style.MAT_METAL))
    for k in range(6):
        a = k / 6 * math.tau + 0.5
        P.append(shapes.cylinder(f"ch{k}", (math.cos(a) * 0.011, 0.0488, 0.03 + math.sin(a) * 0.011), 0.0038, None, 0.002, "Y", 8, 0, "rubber", style.MAT_FLAT))
    P.append(g.box("hammer", (0, -0.018, 0.05), (0.007, 0.012, 0.014), "gun_dark", bevel=0.002, rot=(deg(30), 0, 0), seg=1))
    P.append(g.sight("fsight", 0.145, 0.046))
    P.append(g.grip(y=-0.012, z=-0.016, size=(0.026, 0.03, 0.054), angle=-22, color="wood_red"))
    P += g.guard(y=0.012, z=0.004, r=0.012)
    root = weapon_kit.finish("wpn_revolver", P, "pistol", {
        "muzzle": (0, 0.152, 0.034), "att_muzzle": (0, 0.15, 0.034), "att_scope": (0, 0.06, 0.05),
        "att_drum": (0, 0.03, 0.006), "att_tank": (-0.022, 0.03, 0.02), "att_coil": (0, 0.12, 0.034),
        "att_radar": (0, -0.02, 0.058), "att_torch": (0, 0.09, 0.012),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_revolver"), outline=0.0016)
