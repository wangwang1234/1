"""喷火器：侧挂红色燃料罐 + 粗喷管 + 蓝色引火灯，识别色 = 红罐 + 蓝火苗。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("body", (0, 0.05, 0.022), (0.036, 0.11, 0.038), "lamp_dark", bevel=0.008))
    P.append(shapes.cylinder("nozzle", (0, 0.15, 0.026), 0.011, 0.014, 0.12, "Y", 14, 0.002, "gun_dark", style.MAT_METAL))
    P.append(shapes.cylinder("tip", (0, 0.214, 0.026), 0.016, None, 0.014, "Y", 14, 0.002, "gun_darker", style.MAT_METAL))
    P.append(shapes.uv_sphere("pilot", (0, 0.222, 0.008), (0.007, 0.007, 0.007), 10, 6, "pilot_blue", style.MAT_EMISSIVE))
    P.append(g.box("pilotarm", (0, 0.214, 0.012), (0.004, 0.006, 0.012), "gun_darker", bevel=0.001, seg=1))
    P.append(shapes.cylinder("tank", (-0.04, 0.03, 0.028), 0.026, None, 0.1, "Y", 18, 0.004, "shell_red", style.MAT_TOON))
    for s in (-1, 1):
        P.append(shapes.torus(f"tankband{s}", (-0.04, 0.03 + s * 0.035, 0.028), 0.026, 0.003, "Y", 18, 4, "crown_gold", style.MAT_METAL))
    P.append(shapes.capsule("hose", (-0.04, 0.08, 0.028), (-0.012, 0.1, 0.022), 0.005, 8, 2, "rubber", style.MAT_TOON))
    P.append(g.box("gauge", (-0.04, 0.03, 0.057), (0.012, 0.012, 0.006), "paper", style.MAT_FLAT, 0.002, seg=1))
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.026, 0.028, 0.05), angle=-14))
    P.append(g.grip("foregrip", y=0.1, z=-0.006, size=(0.02, 0.02, 0.036), angle=-5))
    P += g.guard(y=0.016, z=-0.004)
    HW = 0.018
    P.append(shapes.cylinder("gaugeface", (-0.04, 0.03, 0.0605), 0.007, None, 0.002, "Z", 14, 0, "sticker_white", style.MAT_FLAT))
    P.append(g.decal("needle", (-0.04, 0.032, 0.0618), (0.0012, 0.006, 0.0008), "gauge_red", rot=(0, 0, deg(35))))
    P.append(shapes.torus("gaugering", (-0.04, 0.03, 0.06), 0.0075, 0.0012, "Z", 14, 4, "gun_steel", style.MAT_METAL))
    for k in range(3):
        P.append(g.decal(f"flamedecal{k}", (-0.04 + (k - 1) * 0.006, 0.0, 0.0548), (0.004, 0.012 - abs(k - 1) * 0.004, 0.0012), "sticker_yellow" if k == 1 else "sticker_orange"))
    P.append(shapes.cylinder("shield", (0, 0.17, 0.026), 0.017, None, 0.05, "Y", 16, 0.002, "gun_light", style.MAT_METAL))
    P += g.holes("shieldhole", 0.152, 0, 4, 0.012, 0.0028, "Z", surface=0.0435)
    P += g.holes("shieldholeR", 0.152, 0, 4, 0.012, 0.0028, "X", z=0.026, surface=0.0172)
    P += g.screws("screw", 0.0, 0.01, HW)
    P += g.screws("screw2", 0.09, 0.01, HW)
    P.append(g.top_decal("bodystripe", 0.05, 0.041, 0.08, 0.01, "sticker_orange"))
    P.append(shapes.capsule("hose2", (-0.012, 0.1, 0.022), (-0.006, 0.12, 0.024), 0.005, 8, 2, "rubber", style.MAT_TOON))
    P.append(g.box("valve", (-0.04, -0.025, 0.028), (0.012, 0.01, 0.012), "gun_steel", bevel=0.002, seg=1))
    root = weapon_kit.finish("wpn_flame", P, "flame", {
        "muzzle": (0, 0.226, 0.026), "att_muzzle": (0, 0.214, 0.026), "att_scope": (0, 0.04, 0.046),
        "att_drum": (0, 0.05, -0.03), "att_tank": (0.032, 0.04, 0.022), "att_coil": (0, 0.16, 0.026),
        "att_radar": (0, -0.01, 0.046), "att_torch": (0, 0.17, 0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_flame"), outline=0.0016)
