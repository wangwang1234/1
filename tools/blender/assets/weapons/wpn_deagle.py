"""沙漠之鹰：大口径手枪，镀铬长套筒 + 三角形套筒前端，识别色 = 银白。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("slide", (0, 0.05, 0.036), (0.034, 0.18, 0.042), "gun_chrome", bevel=0.006))
    P.append(g.box("rib", (0, 0.06, 0.06), (0.012, 0.16, 0.008), "gun_steel", bevel=0.002, seg=1))
    for i in range(6):
        P.append(g.box(f"serr{i}", (0, -0.025 + i * 0.006, 0.036), (0.0355, 0.0025, 0.034), "gun_steel", bevel=0.0005, seg=1))
    P.append(g.box("frame", (0, 0.04, 0.008), (0.03, 0.15, 0.018), "gun_dark", bevel=0.004))
    P += g.barrel("barrel", 0.138, 0.008, 0.034, 0.01, "gun_steel")
    P.append(g.sight("fsight", 0.13, 0.064))
    P.append(g.sight("rsight", -0.024, 0.064, w=0.02))
    P += g.guard(y=0.03, z=-0.008, r=0.014)
    P.append(g.grip(size=(0.03, 0.034, 0.062), z=-0.026, angle=-14, color="gun_darker"))
    for s in (-1, 1):
        P.append(g.box(f"panel{s}", (s * 0.0158, -0.008, -0.026), (0.002, 0.026, 0.044), "rubber", style.MAT_TOON, 0.001, rot=(deg(-14), 0, 0), seg=1))
    P.append(g.box("hammer", (0, -0.042, 0.046), (0.008, 0.012, 0.012), "gun_darker", bevel=0.002, rot=(deg(25), 0, 0), seg=1))
    root = weapon_kit.finish("wpn_deagle", P, "pistol", {
        "muzzle": (0, 0.148, 0.034), "att_muzzle": (0, 0.146, 0.034), "att_scope": (0, 0.04, 0.064),
        "att_drum": (0, -0.016, -0.064), "att_tank": (-0.022, 0.04, 0.02), "att_coil": (0, 0.11, 0.036),
        "att_radar": (0, -0.02, 0.07), "att_torch": (0, 0.09, -0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_deagle"), outline=0.0016)
