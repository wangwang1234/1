"""狙击枪：木托 + 长枪管 + 大瞄准镜（青色镜片），识别色 = 镜片青光。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.035, 0.024), (0.032, 0.11, 0.034), "gun_metal", bevel=0.006))
    P.append(g.stock("stock", -0.015, 0.13, z_top=0.03, drop=0.05, width=0.03, color="wood_red"))
    P.append(g.box("cheek", (0, -0.075, 0.04), (0.026, 0.06, 0.012), "wood_dark", style.MAT_TOON, 0.004))
    P.append(g.box("fore", (0, 0.13, 0.016), (0.03, 0.09, 0.03), "wood_red", style.MAT_TOON, 0.006))
    P += g.barrel("barrel", 0.09, 0.22, 0.028, 0.008, "gun_dark")
    P.append(shapes.cylinder("brake", (0, 0.315, 0.028), 0.011, None, 0.02, "Y", 12, 0.002, "gun_darker", style.MAT_METAL))
    P += g.scope("scope", 0.045, 0.062, 0.12, 0.014, lens="lens")
    P.append(shapes.capsule("bolt", (0.018, 0.02, 0.03), (0.034, 0.012, 0.03), 0.003, 8, 2, "gun_steel", style.MAT_METAL))
    P.append(shapes.uv_sphere("boltknob", (0.036, 0.012, 0.03), (0.006, 0.006, 0.006), 10, 6, "gun_darker", style.MAT_METAL))
    P += g.mag("mag", 0.045, -0.012, (0.02, 0.03, 0.03), 0, "gun_dark")
    P.append(g.grip(y=-0.008, z=-0.018, size=(0.024, 0.026, 0.044), angle=-22, color="wood_red"))
    P += g.guard(y=0.014, z=-0.004)
    HW = 0.016
    P += g.eject_port("eject", 0.035, 0.03, HW, 0.03, 0.01)
    P += g.screws("screw", 0.0, 0.012, HW)
    for s in (-1, 1):
        P.append(g.box(f"cap{s}", (0, 0.045 + s * 0.072, 0.062), (0.03, 0.006, 0.03), "sticker_yellow", style.MAT_TOON, 0.003, seg=1))
    P.append(g.top_decal("scopeband", 0.045, 0.076, 0.012, 0.012, "sticker_yellow"))
    P.append(g.box("turret", (0, 0.045, 0.08), (0.012, 0.012, 0.008), "gun_dark", bevel=0.002, seg=1))
    P.append(g.box("turret2", (0.017, 0.045, 0.062), (0.008, 0.012, 0.012), "gun_dark", bevel=0.002, seg=1))
    for k in range(3):
        P.append(g.decal(f"flute{k}", (0.0082, 0.18 + k * 0.03, 0.028), (0.0012, 0.022, 0.0025), "gun_darker"))
    P.append(g.sling_loop("sling", (0, -0.1, -0.015)))
    P.append(g.sling_loop("sling2", (0, 0.16, 0.0)))
    P += g.side_decal("woodline", -0.06, 0.012, 0.07, 0.003, "wood_dark", 0.0152)
    P += g.paw("paw", (0.0152 + g.D, -0.09, 0.02), "X", 0.011, "sticker_white")
    root = weapon_kit.finish("wpn_sniper", P, "rifle", {
        "muzzle": (0, 0.326, 0.028), "att_muzzle": (0, 0.322, 0.028), "att_scope": (0, 0.045, 0.08),
        "att_drum": (0, 0.045, -0.03), "att_tank": (-0.024, 0.06, 0.02), "att_coil": (0, 0.24, 0.028),
        "att_radar": (0, -0.03, 0.05), "att_torch": (0, 0.2, 0.012),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_sniper"), outline=0.0016)
