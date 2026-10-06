"""自动霰弹枪：方正机匣 + 下挂橄榄色弹鼓 + 短粗枪管，识别色 = 圆弹鼓。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.05, 0.024), (0.034, 0.16, 0.042), "gun_metal", bevel=0.007))
    P += g.rail_top("rail", 0.04, 0.047, 0.1, 6)
    P += g.barrel("barrel", 0.13, 0.1, 0.03, 0.011, "gun_dark")
    P.append(shapes.cylinder("brake", (0, 0.226, 0.03), 0.014, None, 0.018, "Y", 14, 0.002, "gun_darker", style.MAT_METAL))
    P.append(shapes.cylinder("drum", (0, 0.065, -0.03), 0.032, None, 0.026, "X", 22, 0.004, "polymer_olive", style.MAT_TOON))
    P.append(shapes.cylinder("drumcap", (0.014, 0.065, -0.03), 0.014, None, 0.004, "X", 16, 0.001, "gun_darker", style.MAT_METAL))
    P.append(g.stock("stock", -0.025, 0.1, z_top=0.035, drop=0.045, width=0.028, color="gun_darker"))
    P.append(g.grip(y=-0.008, z=-0.02, size=(0.026, 0.028, 0.05), angle=-16))
    P += g.guard(y=0.016, z=-0.004)
    P.append(g.box("pump", (0, 0.16, 0.008), (0.03, 0.05, 0.022), "shell_red", style.MAT_TOON, 0.006))
    root = weapon_kit.finish("wpn_autoshot", P, "shotgun", {
        "muzzle": (0, 0.236, 0.03), "att_muzzle": (0, 0.232, 0.03), "att_scope": (0, 0.03, 0.054),
        "att_drum": (0, 0.065, -0.065), "att_tank": (-0.026, 0.06, 0.02), "att_coil": (0, 0.19, 0.03),
        "att_radar": (0, -0.03, 0.05), "att_torch": (0.02, 0.17, 0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_autoshot"), outline=0.0016)
