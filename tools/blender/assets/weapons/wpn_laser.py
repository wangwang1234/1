"""激光枪：白色流线机身 + 粉色发光晶体枪口 + 粉色能量条 + 下挂电池，识别色 = 粉光。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    z = 0.028
    P.append(g.box("body", (0, 0.06, z - 0.004), (0.034, 0.15, 0.04), "white", style.MAT_TOON, 0.012))
    P.append(g.box("strip", (0, 0.06, z + 0.0172), (0.022, 0.1, 0.004), "laser_pink", style.MAT_EMISSIVE, 0.0015, seg=1))
    P.append(shapes.cylinder("emitter", (0, 0.16, z), 0.012, 0.016, 0.06, "Y", 16, 0.002, "lamp_dark", style.MAT_METAL))
    P.append(shapes.uv_sphere("crystal", (0, 0.195, z), (0.011, 0.011, 0.011), 14, 8, "laser_pink", style.MAT_EMISSIVE))
    for k in range(3):
        P.append(shapes.torus(f"fin{k}", (0, 0.145 + k * 0.014, z), 0.017, 0.0025, "Y", 16, 4, "gun_light", style.MAT_METAL))
    P.append(shapes.cylinder("battery", (0, 0.03, -0.032), 0.014, None, 0.05, "Y", 14, 0.003, "lamp_dark", style.MAT_METAL))
    P.append(shapes.cylinder("batcap", (0, 0.056, -0.032), 0.009, None, 0.006, "Y", 12, 0.001, "laser_pink", style.MAT_EMISSIVE))
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.026, 0.028, 0.05), angle=-16, color="lamp_dark"))
    P += g.guard(y=0.016, z=-0.004)
    for s in (-1, 1):
        P.append(g.box(f"wing{s}", (s * 0.02, 0.09, z + 0.004), (0.008, 0.05, 0.014), "lamp_dark", style.MAT_METAL, 0.003, seg=1))
        P.append(g.decal(f"wingstripe{s}", (s * (0.024 + g.D), 0.09, z + 0.004), (0.0012, 0.04, 0.004), "laser_pink"))
    P.append(g.box("screen", (0.0172, 0.03, z), (0.002, 0.03, 0.016), "screen_dark", style.MAT_EMISSIVE, 0.001, seg=1))
    P.append(g.decal("screenbar", (0.0186, 0.03, z), (0.0012, 0.02, 0.004), "laser_pink"))
    P.append(g.box("rearcap", (0, -0.016, z - 0.004), (0.03, 0.006, 0.034), "lamp_dark", style.MAT_METAL, 0.004, seg=1))
    P += g.paw("paw", (0, 0.1, z + 0.0162 + g.D), "Z", 0.011, "laser_pink")
    P += g.screws("screw", 0.0, z - 0.015, 0.017)
    root = weapon_kit.finish("wpn_laser", P, "beam", {
        "muzzle": (0, 0.207, z), "att_muzzle": (0, 0.19, z), "att_scope": (0, 0.05, z + 0.026),
        "att_drum": (0, 0.06, z - 0.034), "att_tank": (-0.024, 0.05, z), "att_coil": (0, 0.16, z),
        "att_radar": (0, -0.02, z + 0.026), "att_torch": (0, 0.13, z - 0.02),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_laser"), outline=0.0016)
