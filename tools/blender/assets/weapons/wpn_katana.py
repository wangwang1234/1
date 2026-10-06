"""武士刀：缠绳刀柄 + 金色刀镡 + 长刀身（刃口淡蓝发光），识别色 = 刃口光。muzzle = 刀尖（剑气起点）。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    z = 0.0
    P.append(shapes.cylinder("hilt", (0, -0.004, z), 0.009, None, 0.075, "Y", 10, 0.002, "katana_wrap", style.MAT_TOON))
    for k in range(5):
        P.append(shapes.torus(f"wrap{k}", (0, -0.034 + k * 0.014, z), 0.0095, 0.0018, "Y", 12, 4, "paper", style.MAT_TOON))
    P.append(shapes.cylinder("pommel", (0, -0.044, z), 0.011, None, 0.008, "Y", 12, 0.002, "brass", style.MAT_METAL))
    P.append(shapes.torus("tsuba", (0, 0.037, z), 0.016, 0.004, "Y", 20, 6, "crown_gold", style.MAT_METAL, scale=(1.0, 1.0, 1.3)))
    P.append(shapes.cylinder("habaki", (0, 0.046, z), 0.007, None, 0.012, "Y", 10, 0.001, "brass", style.MAT_METAL))
    blade = shapes.extrude_profile("blade", [(0.05, -0.007), (0.05, 0.009), (0.31, 0.012), (0.345, 0.004), (0.335, -0.004), (0.3, -0.006)], 0.004, plane="YZ", bevel=0.0008, color="gun_chrome", mat=style.MAT_METAL)
    P.append(blade)
    edge = shapes.extrude_profile("edge", [(0.055, 0.008), (0.31, 0.0105), (0.343, 0.0045), (0.338, 0.0015), (0.306, 0.0075), (0.055, 0.0055)], 0.0046, plane="YZ", bevel=0.0, color="blade_edge", mat=style.MAT_EMISSIVE)
    P.append(edge)
    root = weapon_kit.finish("wpn_katana", P, "melee", {
        "muzzle": (0, 0.34, z), "att_muzzle": (0, 0.2, z + 0.006), "att_scope": (0, 0.15, z + 0.012),
        "att_drum": (0, 0.0, z - 0.012), "att_tank": (-0.012, 0.0, z), "att_coil": (0, 0.1, z),
        "att_radar": (0, -0.04, z + 0.012), "att_torch": (0, 0.25, z - 0.008),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_katana"), outline=0.0014)
