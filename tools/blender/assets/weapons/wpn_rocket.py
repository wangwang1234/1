"""火箭筒：橄榄绿发射管扛在肩上，前端露出红色弹头，木质握把段，识别色 = 红弹头。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    z = 0.04
    P.append(shapes.cylinder("tube", (0, 0.06, z), 0.022, None, 0.32, "Y", 18, 0.003, "polymer_olive", style.MAT_TOON))
    P.append(shapes.cylinder("woodband", (0, 0.03, z), 0.026, None, 0.08, "Y", 18, 0.003, "wood", style.MAT_TOON))
    P.append(shapes.cylinder("frontring", (0, 0.215, z), 0.026, None, 0.016, "Y", 18, 0.002, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("rearflare", (0, -0.105, z), 0.03, 0.022, 0.03, "Y", 18, 0.002, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("warhead", (0, 0.245, z), 0.018, 0.0, 0.05, "Y", 16, 0.002, "shell_red", style.MAT_TOON))
    P.append(shapes.cylinder("warheadbody", (0, 0.222, z), 0.02, None, 0.012, "Y", 16, 0.001, "shell_red", style.MAT_TOON))
    P.append(g.grip(y=-0.004, z=-0.004, size=(0.024, 0.026, 0.05), angle=-12, color="gun_darker"))
    P.append(g.grip("foregrip", y=0.1, z=0.0, size=(0.022, 0.022, 0.044), angle=-8, color="gun_darker"))
    P += g.guard(y=0.016, z=0.012)
    P.append(g.box("sightpost", (0.022, 0.12, z + 0.02), (0.006, 0.01, 0.024), "gun_darker", bevel=0.002, seg=1))
    P.append(g.box("sightframe", (0.022, 0.12, z + 0.034), (0.012, 0.004, 0.012), "gun_darker", bevel=0.001, seg=1))
    P.append(g.box("stencil", (0, 0.13, z + 0.0222), (0.012, 0.04, 0.0015), "sticker_yellow", style.MAT_FLAT, 0.0, seg=1))
    for k, y in enumerate((0.18, 0.195)):
        P.append(shapes.torus(f"band{k}", (0, y, z), 0.0225, 0.0022, "Y", 18, 4, "sticker_yellow", style.MAT_TOON))
    P.append(shapes.torus("bandrear", (0, -0.06, z), 0.0225, 0.0022, "Y", 18, 4, "sticker_yellow", style.MAT_TOON))
    P += g.paw("paw", (0, 0.07, z + 0.022 + g.D), "Z", 0.014, "sticker_white")
    P.append(g.box("shoulder", (0, -0.03, z - 0.02), (0.03, 0.05, 0.012), "rubber", style.MAT_TOON, 0.004, seg=1))
    P.append(shapes.cylinder("venturi", (0, -0.121, z), 0.022, None, 0.002, "Y", 18, 0, "rubber", style.MAT_FLAT))
    P.append(shapes.torus("venturiring", (0, -0.12, z), 0.014, 0.002, "Y", 14, 4, "gun_darker", style.MAT_METAL))
    P.append(g.sling_loop("sling", (0, -0.08, z - 0.024)))
    P.append(g.box("trigguard2", (0, 0.035, 0.016), (0.012, 0.02, 0.004), "gun_darker", bevel=0.001, seg=1))
    root = weapon_kit.finish("wpn_rocket", P, "launcher", {
        "muzzle": (0, 0.27, z), "att_muzzle": (0, 0.228, z), "att_scope": (0, 0.05, z + 0.03),
        "att_drum": (0, 0.06, z - 0.03), "att_tank": (-0.03, 0.03, z), "att_coil": (0, 0.16, z),
        "att_radar": (0, -0.06, z + 0.03), "att_torch": (0.026, 0.18, z),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_rocket"), outline=0.0016)
