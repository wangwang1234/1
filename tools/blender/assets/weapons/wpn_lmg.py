"""轻机枪：粗机匣 + 提把 + 橄榄色弹箱 + 黄铜弹链 + 折叠脚架，识别色 = 橄榄弹箱。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.05, 0.024), (0.036, 0.15, 0.042), "gun_metal", bevel=0.007))
    P.append(g.box("feedcover", (0, 0.06, 0.05), (0.032, 0.07, 0.012), "gun_dark", bevel=0.004))
    P.append(g.box("handle", (0, 0.08, 0.072), (0.01, 0.06, 0.008), "gun_darker", bevel=0.003))
    for s in (-1, 1):
        P.append(g.box(f"handlepost{s}", (0, 0.08 + s * 0.026, 0.062), (0.01, 0.008, 0.016), "gun_darker", bevel=0.002, seg=1))
    P += g.barrel("barrel", 0.125, 0.16, 0.03, 0.009, "gun_dark")
    P.append(shapes.cylinder("jacket", (0, 0.16, 0.03), 0.014, None, 0.07, "Y", 14, 0.002, "gun_darker", style.MAT_METAL))
    for k in range(5):
        P.append(shapes.cylinder(f"hole{k}", (0.0136, 0.135 + k * 0.012, 0.03), 0.003, None, 0.002, "X", 8, 0, "rubber", style.MAT_FLAT))
    P.append(g.box("ammobox", (0.004, 0.045, -0.025), (0.05, 0.05, 0.048), "polymer_olive", style.MAT_TOON, 0.006))
    for k in range(5):
        P.append(shapes.cylinder(f"belt{k}", (0.024, 0.03 + k * 0.009, 0.004 + k * 0.004), 0.003, None, 0.016, "Z", 8, 0.0008, "brass", style.MAT_METAL))
    P.append(g.stock("stock", -0.02, 0.1, z_top=0.035, drop=0.045, width=0.03, color="gun_darker"))
    P.append(g.grip(y=-0.006, z=-0.02, size=(0.026, 0.028, 0.05), angle=-14))
    P += g.guard(y=0.016, z=-0.004)
    P += g.bipod("bipod", 0.27, 0.02, 0.08)
    HW = 0.018
    P.append(g.top_decal("coverstripe", 0.06, 0.056, 0.05, 0.012, "polymer_olive"))
    P += g.stripes("haz", 0.12, 0.2, 0.044, 0.006, 6, "sticker_yellow", "rubber")
    P += g.eject_port("eject", 0.03, 0.02, HW, 0.03, 0.012)
    P += g.screws("screw", 0.0, 0.03, HW)
    P += g.screws("screw2", 0.11, 0.012, HW)
    P.append(g.decal("boxstencil", (0.0298, 0.045, -0.025), (0.0012, 0.03, 0.018), "sticker_yellow"))
    P.append(g.decal("boxstencil2", (0.0298, 0.045, -0.025), (0.0013, 0.022, 0.006), "polymer_olive"))
    P.append(g.box("boxlatch", (0.004, 0.071, -0.012), (0.03, 0.004, 0.008), "gun_dark", bevel=0.001, seg=1))
    P.append(g.top_decal("boxtop", 0.045, -0.001, 0.036, 0.034, "sand_tan", x=0.004))
    P.append(g.box("chhandle", (0.02, 0.09, 0.036), (0.012, 0.008, 0.006), "gun_steel", bevel=0.002, seg=1))
    P.append(g.sling_loop("sling", (0, -0.1, 0.02)))
    P.append(g.sling_loop("sling2", (0, 0.2, 0.014)))
    P += g.side_decal("stockline", -0.07, 0.02, 0.05, 0.004, "polymer_olive", 0.0152)
    root = weapon_kit.finish("wpn_lmg", P, "heavy", {
        "muzzle": (0, 0.287, 0.03), "att_muzzle": (0, 0.285, 0.03), "att_scope": (0, 0.03, 0.06),
        "att_drum": (0.004, 0.045, -0.055), "att_tank": (-0.026, 0.06, 0.02), "att_coil": (0, 0.22, 0.03),
        "att_radar": (0, -0.03, 0.05), "att_torch": (0, 0.2, 0.014),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_lmg"), outline=0.0016)
