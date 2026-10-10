"""双持手枪：两把小手枪，右手在原点，左手那把在 -X 0.13 米处（左手握把挂点 grip_L 就在它的握把上）。
两把各自一个枪口：muzzle（右）和 muzzle_L（左），表现层交替开火。识别色 = 两把枪身上的黄色贴片。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def pistol(prefix, x):
    P = []
    P.append(g.box(prefix + "slide", (x, 0.036, 0.032), (0.03, 0.13, 0.034), "gun_metal", bevel=0.006))
    P.append(g.box(prefix + "frame", (x, 0.03, 0.01), (0.028, 0.11, 0.015), "gun_dark", bevel=0.004))
    P += g.barrel(prefix + "barrel", 0.1, 0.008, 0.03, 0.008, "gun_dark", x=x)
    P.append(g.grip(prefix + "grip", y=-0.008, z=-0.02, size=(0.028, 0.03, 0.056), angle=-14, x=x))
    for s in (-1, 1):
        P.append(g.box(f"{prefix}panel{s}", (x + s * 0.0148, -0.01, -0.02), (0.002, 0.02, 0.038), "sticker_yellow", style.MAT_TOON, 0.0008, rot=(deg(-14), 0, 0), seg=1))
    P += g.guard(prefix + "guard", y=0.028, z=-0.006, r=0.013, x=x)
    P.append(g.top_decal(prefix + "topstripe", 0.04, 0.049, 0.1, 0.008, "sticker_yellow", x=x))
    for i in range(4):
        P.append(g.box(f"{prefix}serr{i}", (x, -0.02 + i * 0.0065, 0.032), (0.0315, 0.0025, 0.028), "gun_darker", style.MAT_METAL, 0.0005, seg=1))
    P.append(g.decal(prefix + "eject", (x + 0.0158, 0.05, 0.036), (0.0012, 0.022, 0.01), "rubber"))
    P.append(g.box(prefix + "fs", (x, 0.09, 0.052), (0.005, 0.007, 0.007), "gun_darker", bevel=0.001, seg=1))
    P.append(g.box(prefix + "rs", (x, -0.022, 0.052), (0.018, 0.005, 0.007), "gun_darker", bevel=0.001, seg=1))
    P.append(g.box(prefix + "magbase", (x, -0.016, -0.05), (0.03, 0.032, 0.008), "gun_light", style.MAT_METAL, 0.002, rot=(deg(-14), 0, 0), seg=1))
    P += g.paw(prefix + "paw", (x - 0.0152 - g.D, 0.05, 0.034), "X", 0.009, "sticker_yellow")
    return P


def build(ctx):
    P = pistol("r_", 0.0) + pistol("l_", -0.13)
    root = weapon_kit.finish("wpn_dual", P, "dual", {
        "muzzle": (0, 0.11, 0.03), "att_muzzle": (0, 0.108, 0.03), "att_scope": (0, 0.03, 0.052),
        "att_drum": (0, -0.016, -0.056), "att_tank": (0.02, 0.03, 0.02), "att_coil": (0, 0.08, 0.032),
        "att_radar": (-0.13, 0.0, 0.052), "att_torch": (0, 0.07, -0.004),
    })
    from lib import shapes as sh
    sh.empty("muzzle_L", (-0.13, 0.11, 0.03), parent=root, size=0.01)
    return ctx.Built([root], previews=weapon_kit.previews("wpn_dual"), outline=0.0016)
