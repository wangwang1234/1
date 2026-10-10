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
    HW = 0.017
    P.append(g.top_decal("orangestrip", 0.11, 0.045, 0.06, 0.012, "sticker_orange"))
    P += g.eject_port("eject", 0.04, 0.03, HW, 0.03, 0.012)
    P += g.screws("screw", -0.01, 0.012, HW)
    P += g.screws("screw2", 0.11, 0.012, HW)
    P.append(shapes.torus("drumring", (0.0132, 0.065, -0.03), 0.024, 0.002, "X", 20, 4, "sticker_yellow", style.MAT_TOON))
    P.append(shapes.cylinder("drumface", (-0.0132, 0.065, -0.03), 0.022, None, 0.0014, "X", 18, 0, "sticker_yellow", style.MAT_FLAT))
    P.append(g.box("drumwind", (0.017, 0.065, -0.03), (0.004, 0.022, 0.004), "gun_steel", bevel=0.001, seg=1))
    P += g.holes("hshield", 0.14, 0, 4, 0.016, 0.003, "Z", surface=0.0415)
    for k in range(3):
        P.append(g.decal(f"pumpline{k}", (0.0152, 0.145 + k * 0.012, 0.008), (0.0012, 0.004, 0.018), "wood_red"))
    P.append(g.sling_loop("sling", (0, -0.1, 0.0)))
    root = weapon_kit.finish("wpn_autoshot", P, "shotgun", {
        "muzzle": (0, 0.236, 0.03), "att_muzzle": (0, 0.232, 0.03), "att_scope": (0, 0.03, 0.054),
        "att_drum": (0, 0.065, -0.065), "att_tank": (-0.026, 0.06, 0.02), "att_coil": (0, 0.19, 0.03),
        "att_radar": (0, -0.03, 0.05), "att_torch": (0.02, 0.17, 0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_autoshot"), outline=0.0016)
