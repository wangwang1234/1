"""冲锋枪：短小机匣 + 长直弹匣 + 折叠钢丝托，识别色 = 薄荷绿（顶盖色条、弹匣底、侧面贴纸）。"""
from lib import gun_parts as g, shapes, style, weapon_kit
from lib.anim import deg


def build(ctx):
    P = []
    HW = 0.016          # 机匣半宽
    P.append(g.box("receiver", (0, 0.04, 0.02), (0.032, 0.13, 0.036), "gun_metal", bevel=0.006))
    P.append(g.box("cover", (0, 0.035, 0.041), (0.026, 0.11, 0.008), "gun_dark", bevel=0.003))
    P.append(g.top_decal("topstripe", 0.03, 0.045, 0.07, 0.01, "sticker_mint"))
    P.append(g.box("chknob", (0, -0.005, 0.05), (0.008, 0.012, 0.008), "gun_steel", bevel=0.002, seg=1))
    # 枪管护套 + 散热槽
    P += g.barrel("barrel", 0.105, 0.045, 0.024, 0.0075, "gun_dark")
    P.append(g.box("shroud", (0, 0.105, 0.024), (0.022, 0.03, 0.024), "gun_darker", bevel=0.004))
    P += g.vents("vent", 0.096, 0.024, 3, 0.009, 0.011)
    P.append(shapes.cylinder("nut", (0, 0.124, 0.024), 0.0095, None, 0.006, "Y", 10, 0.001, "gun_steel", style.MAT_METAL))
    # 弹匣（长直）+ 薄荷绿底板
    P += g.mag("mag", 0.045, -0.035, (0.02, 0.026, 0.07), -6)
    P.append(g.box("magfoot", (0, 0.0485, -0.072), (0.023, 0.03, 0.006), "sticker_mint", style.MAT_TOON, 0.002, rot=(deg(-6), 0, 0), seg=1))
    for k in range(3):
        P.append(g.decal(f"magrib{k}R", (0.0108, 0.045 - k * 0.0012, -0.02 - k * 0.016), (0.0012, 0.02, 0.003), "gun_darker", rot=(deg(-6), 0, 0)))
    P.append(g.box("magwell", (0, 0.045, -0.002), (0.026, 0.032, 0.012), "gun_dark", bevel=0.003, seg=1))
    # 握把 + 防滑纹 + 扳机
    P.append(g.grip(y=-0.004, z=-0.02, size=(0.024, 0.026, 0.046), angle=-16))
    for k in range(3):
        P.append(g.decal(f"gripline{k}", (0.0122, -0.002 - k * 0.003, -0.012 - k * 0.011), (0.0012, 0.018, 0.0025), "gun_dark", rot=(deg(-16), 0, 0)))
    P += g.guard(y=0.016, z=-0.004)
    # 前握把
    P.append(g.box("foregrip", (0, 0.082, -0.012), (0.018, 0.018, 0.036), "gun_darker", style.MAT_TOON, 0.005))
    P.append(g.box("foregripcap", (0, 0.082, -0.031), (0.02, 0.02, 0.005), "sticker_mint", style.MAT_TOON, 0.002, seg=1))
    # 钢丝托 + 背带环
    for s in (-1, 1):
        P.append(shapes.capsule(f"wire{s}", (s * 0.01, -0.025, 0.026), (s * 0.01, -0.1, 0.012), 0.003, 8, 2, "gun_steel", style.MAT_METAL))
    P.append(shapes.capsule("wireend", (-0.012, -0.1, 0.012), (0.012, -0.1, 0.012), 0.004, 8, 2, "gun_steel", style.MAT_METAL))
    P.append(g.box("buttpad", (0, -0.102, 0.012), (0.03, 0.006, 0.014), "rubber", style.MAT_TOON, 0.002, seg=1))
    P.append(g.sling_loop("sling", (0, 0.12, 0.012)))
    # 抛壳窗、螺丝、侧面贴纸（爪印）
    P += g.eject_port("eject", 0.05, 0.028, HW, 0.024, 0.01)
    P += g.screws("screw", 0.0, 0.012, HW)
    P += g.screws("screw2", 0.09, 0.012, HW)
    P.append(g.decal("sticker", (HW + g.D, 0.075, 0.018), (0.0012, 0.026, 0.014), "sticker_mint"))
    P += g.paw("paw", (-HW - g.D, 0.045, 0.02), "X", 0.012, "sticker_mint")
    P.append(g.sight("fsight", 0.09, 0.048))
    P.append(g.box("rsight", (0, -0.008, 0.048), (0.014, 0.006, 0.006), "gun_darker", bevel=0.001, seg=1))
    root = weapon_kit.finish("wpn_smg", P, "rifle", {
        "muzzle": (0, 0.151, 0.024), "att_muzzle": (0, 0.149, 0.024), "att_scope": (0, 0.03, 0.05),
        "att_drum": (0, 0.045, -0.06), "att_tank": (-0.022, 0.04, 0.02), "att_coil": (0, 0.13, 0.024),
        "att_radar": (0, -0.01, 0.052), "att_torch": (0, 0.11, 0.006),
    })
    return ctx.Built([root], previews=weapon_kit.previews("wpn_smg"), outline=0.0016)
