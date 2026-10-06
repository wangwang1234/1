"""冲锋枪：短小机匣 + 长直弹匣 + 折叠钢丝托，识别色 = 薄荷绿贴纸。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    P.append(g.box("receiver", (0, 0.04, 0.02), (0.032, 0.13, 0.036), "gun_metal", bevel=0.006))
    P.append(g.box("cover", (0, 0.035, 0.041), (0.026, 0.11, 0.008), "gun_dark", bevel=0.003))
    P += g.barrel("barrel", 0.105, 0.045, 0.024, 0.0075, "gun_dark")
    P.append(g.box("shroud", (0, 0.105, 0.024), (0.022, 0.03, 0.024), "gun_darker", bevel=0.004))
    for k in range(3):
        P.append(g.box(f"vent{k}", (0.0115, 0.096 + k * 0.009, 0.024), (0.002, 0.004, 0.012), "rubber", style.MAT_FLAT, 0.0, seg=1))
    P += g.mag("mag", 0.045, -0.035, (0.02, 0.026, 0.07), -6)
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.024, 0.026, 0.046), angle=-16))
    P += g.guard(y=0.016, z=-0.004)
    # 前握把
    P.append(g.box("foregrip", (0, 0.082, -0.012), (0.018, 0.018, 0.036), "gun_darker", style.MAT_TOON, 0.005))
    # 钢丝托
    for s in (-1, 1):
        P.append(shapes.capsule(f"wire{s}", (s * 0.01, -0.025, 0.026), (s * 0.01, -0.1, 0.012), 0.003, 8, 2, "gun_steel", style.MAT_METAL))
    P.append(shapes.capsule("wireend", (-0.012, -0.1, 0.012), (0.012, -0.1, 0.012), 0.004, 8, 2, "gun_steel", style.MAT_METAL))
    P.append(g.box("sticker", (0.0165, 0.06, 0.022), (0.0015, 0.03, 0.014), "sticker_mint", style.MAT_FLAT, 0.0, seg=1))
    P.append(g.sight("fsight", 0.09, 0.048))
    root = weapon_kit.finish("wpn_smg", P, "rifle", {
        "muzzle": (0, 0.151, 0.024), "att_muzzle": (0, 0.149, 0.024), "att_scope": (0, 0.03, 0.05),
        "att_drum": (0, 0.045, -0.06), "att_tank": (-0.022, 0.04, 0.02), "att_coil": (0, 0.13, 0.024),
        "att_radar": (0, -0.01, 0.052), "att_torch": (0, 0.11, 0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_smg"), outline=0.0016)
