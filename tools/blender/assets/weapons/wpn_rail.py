"""电磁炮：白色机身 + 双导轨 + 四圈青色发光线圈 + 顶部发光条，识别色 = 青色线圈。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    z = 0.03
    P.append(g.box("body", (0, 0.05, z - 0.004), (0.038, 0.13, 0.044), "white", style.MAT_TOON, 0.01))
    P.append(g.box("glowstrip", (0, 0.045, z + 0.019), (0.016, 0.08, 0.004), "rail_cyan", style.MAT_EMISSIVE, 0.0015, seg=1))
    for s in (-1, 1):
        P.append(g.box(f"rail{s}", (s * 0.012, 0.2, z), (0.008, 0.21, 0.01), "gun_metal", bevel=0.002))
    for k in range(4):
        P.append(shapes.torus(f"coil{k}", (0, 0.15 + k * 0.045, z), 0.02, 0.004, "Y", 20, 5, "rail_cyan", style.MAT_EMISSIVE))
    P.append(g.box("battery", (0, 0.02, -0.03), (0.026, 0.05, 0.03), "gun_dark", bevel=0.005))
    P.append(g.box("batlight", (0.0135, 0.02, -0.03), (0.002, 0.03, 0.006), "rail_cyan", style.MAT_EMISSIVE, 0.0, seg=1))
    P.append(g.stock("stock", -0.015, 0.09, z_top=0.04, drop=0.045, width=0.03, color="white"))
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.026, 0.028, 0.05), angle=-16))
    P += g.guard(y=0.016, z=-0.004)
    root = weapon_kit.finish("wpn_rail", P, "beam", {
        "muzzle": (0, 0.31, z), "att_muzzle": (0, 0.306, z), "att_scope": (0, 0.04, z + 0.03),
        "att_drum": (0, 0.06, z - 0.036), "att_tank": (-0.026, 0.05, z), "att_coil": (0, 0.26, z),
        "att_radar": (0, -0.03, z + 0.03), "att_torch": (0, 0.2, z - 0.012),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_rail"), outline=0.0016)
