"""批次 3：分区美术模块（夜里的屋子，仓鼠视角；物件约为真实尺寸的 5 倍，摆放时按 1 倍放）。

区域（ART_BIBLE 第 1 节）：蓝方书房（木地板）/ 红方厨房（瓷砖）/ 中路客厅地毯 / 上路书架 / 下路沙发底 / 鼠王冰箱区 / 大礼箱派对区。
- 地面：floor_tile_white（冰箱前的白瓷砖）、floor_wood_dusty（沙发底：落灰的深色木地板）、rug_party（礼物区圆地毯，直径 5 米）
- 边界：fridge（冰箱底部 2 米段：白色机身 + 通风格栅 + 踢脚板）、cabinet（厨房橱柜底 2 米段）、sofa_skirt（沙发裙边 2 米段，低矮）、sofa_leg（沙发腿）
- 装饰（无碰撞，按区域散布），每个导出 env_deco_<名>.glb：
  书房：pen tape sharpener tack band notebook glue staples highlighter paper
  厨房：spoon fork sugar cookie cereal pasta peas teabag match chopstick
  客厅：car puzzle card popcorn chip wrapper
  沙发底：dust sock hairtie remote crumbs
  冰箱：magnet ice grape puddle
  礼物区：ribbon bow confetti tag balloon
坐标：原点在地面中心，+Z 向上。
"""
import math
import random

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg

RNG = random.Random(11)
F = style.MAT_FLAT
T = style.MAT_TOON
M = style.MAT_METAL
G = style.MAT_GLASS


def _root(name, objs):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH":
            shapes.bake_outline_normals(o)
    return root


def _one(name, parts):
    return _root(name, [shapes.join(parts, name + "_mesh")])


def lay(objs, rot=(0, 0, 0), loc=(0, 0, 0)):
    for o in objs:
        shapes.transform(o, rot=rot)
        shapes.transform(o, loc=loc)
    return objs


def lumpy(obj, amp, f=(9, 7, 8), center=(0, 0, 0)):
    c = Vector(center)
    for v in obj.data.vertices:
        n = (v.co - c).normalized()
        v.co += n * amp * math.sin(n.x * f[0] + 1) * math.sin(n.y * f[1]) * math.sin(n.z * f[2] + 2)
    return obj


# =========================================================================== 地面

def floor_tile_white():
    P = [shapes.rounded_box("grout", (0, 0, -0.02), (2.0, 2.0, 0.03), 0.0, 1, "can_grey_dark", T)]
    n = 5
    s = 2.0 / n
    for i in range(n):
        for j in range(n):
            c = "tile_white_dim" if (i + j) % 2 == 0 else "tile_cream"
            P.append(shapes.rounded_box(f"t{i}{j}", (-1 + s * (i + 0.5), -1 + s * (j + 0.5), -0.004), (s - 0.018, s - 0.018, 0.012), 0.004, 1, c, T))
    return _one("env_floor_tile_white", P)


def floor_wood_dusty():
    P = [shapes.rounded_box("sub", (0, 0, -0.03), (2.0, 2.0, 0.04), 0.0, 1, "floor_wood_dark", T)]
    cols = ["floor_wood_dark", "floor_wood", "floor_wood_dark", "seed_shell"]
    w = 0.25
    for i in range(8):
        x = -1.0 + w * (i + 0.5)
        cut = RNG.uniform(-0.9, 0.9)
        edges = sorted([-1.0, 1.0] + [c for c in (cut - 1.2, cut, cut + 1.2) if -0.95 < c < 0.95])
        for a, b in zip(edges[:-1], edges[1:]):
            c = cols[RNG.randrange(len(cols))]
            P.append(shapes.rounded_box(f"pl{i}_{a:.2f}", (x, (a + b) / 2, -0.005), (w - 0.012, (b - a) - 0.012, 0.012), 0.004, 1, c, T))
    # 灰尘：几团浅灰色平涂
    for k in range(6):
        x, y = RNG.uniform(-0.85, 0.85), RNG.uniform(-0.85, 0.85)
        P.append(shapes.uv_sphere(f"dust{k}", (x, y, 0.002), (RNG.uniform(0.06, 0.14), RNG.uniform(0.04, 0.1), 0.002), 10, 3, "dust_grey", F))
    return _one("env_floor_wood_dusty", P)


def rug_party():
    """礼物区的圆形派对地毯：外圈流苏、彩色同心圈、星星花纹。直径 5 米。"""
    R = 2.5
    P = [shapes.cylinder("base", (0, 0, 0.008), R, None, 0.016, "Z", 64, 0.0, "boss_robe", T)]
    rings = [(2.25, "sticker_yellow"), (2.0, "boss_robe"), (1.6, "laser_pink"), (1.35, "snack_purple"), (0.85, "sticker_yellow"), (0.6, "snack_purple")]
    for k, (r, c) in enumerate(rings):
        P.append(shapes.cylinder(f"ring{k}", (0, 0, 0.017 + k * 0.001), r, None, 0.002, "Z", 64, 0.0, c, F))
    for k in range(10):
        a = k / 10 * math.tau
        for (rr, sz, c) in ((1.8, 0.16, "sticker_white"), (1.1, 0.12, "sticker_orange")):
            star = shapes.cylinder(f"star{k}{rr}", (math.cos(a) * rr, math.sin(a) * rr, 0.024), sz, None, 0.002, "Z", 5, 0.0, c, F)
            P.append(star)
    for k in range(72):
        a = k / 72 * math.tau
        P.append(shapes.capsule(f"fr{k}", (math.cos(a) * (R - 0.02), math.sin(a) * (R - 0.02), 0.01), (math.cos(a) * (R + 0.1), math.sin(a) * (R + 0.1), 0.006), 0.014, 5, 1, "towel_cream", T))
    return _one("env_rug_party", P)


# =========================================================================== 边界

def fridge():
    """冰箱底部（2 米段，和墙同高 1.6 米）：白色机身 + 黑色通风格栅 + 踢脚板 + 冰箱贴。"""
    P = [
        shapes.rounded_box("body", (0, 0.1, 0.85), (2.0, 0.2, 1.7), 0.03, 2, "towel_cream", T),
        shapes.rounded_box("door", (0, -0.004, 1.15), (1.96, 0.03, 1.0), 0.02, 2, "white", T),
        shapes.rounded_box("handle", (0.8, -0.04, 0.9), (0.3, 0.05, 0.05), 0.02, 2, "gun_steel", M),
        shapes.rounded_box("kick", (0, -0.01, 0.22), (2.0, 0.04, 0.44), 0.01, 1, "gun_darker", T),
    ]
    for k in range(18):
        P.append(shapes.rounded_box(f"grille{k}", (-0.85 + k * 0.1, -0.034, 0.24), (0.05, 0.012, 0.3), 0.0, 1, "rubber", F))
    for sx in (-0.95, 0.95):
        P.append(shapes.cylinder(f"foot{sx}", (sx, -0.05, 0.03), 0.06, None, 0.06, "Z", 12, 0.01, "gun_dark", M))
    # 冰箱贴 + 便条
    for k, (x, z, c) in enumerate(((-0.6, 1.25, "label_red"), (-0.2, 1.4, "sticker_blue"), (0.3, 1.2, "sticker_yellow"), (-0.4, 0.95, "clover"))):
        P.append(shapes.cylinder(f"mag{k}", (x, -0.022, z), 0.06, None, 0.02, "Y", 12, 0.006, c, T))
    P.append(shapes.rounded_box("note", (0.0, -0.021, 1.05), (0.28, 0.006, 0.34), 0.0, 1, "paper", F, rot=(0, deg(6), 0)))
    for k in range(4):
        P.append(shapes.rounded_box(f"noteline{k}", (0.0, -0.025, 1.14 - k * 0.06), (0.2, 0.002, 0.012), 0.0, 1, "book_blue", F, rot=(0, deg(6), 0)))
    return _one("env_fridge", P)


def cabinet():
    """厨房橱柜底（2 米段）：两扇柜门 + 把手 + 黑色踢脚 + 台面边。高 1.6 米，和墙对齐。"""
    P = [
        shapes.rounded_box("body", (0, 0.1, 0.85), (2.0, 0.2, 1.7), 0.02, 2, "wood_red", T),
        shapes.rounded_box("kick", (0, -0.02, 0.1), (2.0, 0.04, 0.2), 0.01, 1, "gun_darker", T),
        shapes.rounded_box("top", (0, 0.02, 1.62), (2.04, 0.3, 0.08), 0.015, 2, "smoke_grey", T),
    ]
    for sx in (-0.5, 0.5):
        P.append(shapes.rounded_box(f"door{sx}", (sx, -0.006, 0.9), (0.94, 0.03, 1.3), 0.02, 2, "wood", T))
        P.append(shapes.rounded_box(f"panel{sx}", (sx, -0.024, 0.9), (0.7, 0.008, 1.05), 0.01, 1, "wood_red", F))
        P.append(shapes.rounded_box(f"knob{sx}", (sx + (-0.36 if sx > 0 else 0.36), -0.05, 1.2), (0.04, 0.05, 0.18), 0.015, 2, "gun_steel", M))
    return _one("env_cabinet", P)


def sofa_skirt():
    """沙发裙边（2 米段）：低矮的布帘 + 底部流苏，挂在地图下边界外侧。高 0.36 米（不挡镜头）。"""
    P = [shapes.rounded_box("skirt", (0, 0.08, 0.26), (2.0, 0.16, 0.2), 0.02, 2, "snack_purple", T)]
    for k in range(10):
        x = -0.9 + k * 0.2
        P.append(shapes.rounded_box(f"pleat{k}", (x, -0.005, 0.26), (0.03, 0.02, 0.2), 0.008, 1, "boss_robe", T))
    for k in range(25):
        x = -0.96 + k * 0.08
        P.append(shapes.capsule(f"fr{k}", (x, 0.0, 0.16), (x + RNG.uniform(-0.01, 0.01), -0.01, 0.06), 0.012, 6, 2, "sticker_yellow", T))
    return _one("env_sofa_skirt", P)


def sofa_leg():
    P = [
        shapes.cylinder("leg", (0, 0, 0.22), 0.1, 0.07, 0.44, "Z", 16, 0.01, "wood_dark", T),
        shapes.cylinder("cap", (0, 0, 0.02), 0.075, None, 0.04, "Z", 16, 0.008, "brass", M),
    ]
    return _one("env_sofa_leg", P)


# =========================================================================== 装饰：书房

def deco_pen():
    P = [
        shapes.cylinder("body", (0, 0, 0), 0.04, None, 0.56, "Y", 12, 0.008, "sticker_blue", T),
        shapes.cylinder("grip", (0, 0.2, 0), 0.043, None, 0.12, "Y", 12, 0.006, "rubber", T),
        shapes.cylinder("tip", (0, 0.3, 0), 0.008, 0.04, 0.06, "Y", 12, 0.0, "gun_steel", M),
        shapes.cylinder("cap", (0, -0.31, 0), 0.044, None, 0.08, "Y", 12, 0.008, "sticker_blue", T),
        shapes.rounded_box("clip", (0, -0.24, 0.048), (0.02, 0.2, 0.012), 0.004, 1, "gun_chrome", M),
    ]
    return _one("env_deco_pen", lay(P, loc=(0, 0, 0.044)))


def deco_tape():
    P = [
        shapes.cylinder("roll", (0, 0, 0.05), 0.2, None, 0.1, "Z", 28, 0.01, "lens", G),
        shapes.cylinder("core", (0, 0, 0.051), 0.12, None, 0.104, "Z", 24, 0.004, "cardboard", T),
        shapes.cylinder("hole", (0, 0, 0.052), 0.1, None, 0.11, "Z", 24, 0.0, "rubber", F),
        shapes.rounded_box("tail", (0.16, -0.16, 0.002), (0.1, 0.18, 0.002), 0.0, 1, "lens", G, rot=(0, 0, deg(40))),
    ]
    return _one("env_deco_tape", P)


def deco_sharpener():
    P = [
        shapes.rounded_box("body", (0, 0, 0.06), (0.16, 0.11, 0.12), 0.02, 2, "label_red", T),
        shapes.cylinder("hole", (0, -0.056, 0.07), 0.035, None, 0.004, "Y", 12, 0.0, "rubber", F),
        shapes.rounded_box("blade", (0, 0, 0.122), (0.1, 0.06, 0.006), 0.002, 1, "gun_chrome", M),
        shapes.cylinder("screw", (0, 0, 0.127), 0.012, None, 0.006, "Z", 8, 0.002, "gun_steel", M),
    ]
    for k in range(4):
        P.append(shapes.capsule(f"shav{k}", (0.12 + k * 0.03, -0.05 + RNG.uniform(-0.04, 0.04), 0.01), (0.15 + k * 0.03, 0.0, 0.012), 0.012, 6, 2, "floor_wood_light", T))
    return _one("env_deco_sharpener", P)


def deco_tack():
    P = [
        shapes.cylinder("head", (0, 0, 0.03), 0.06, None, 0.03, "Z", 18, 0.01, "label_red", T),
        shapes.cylinder("neck", (0, 0, 0.06), 0.025, 0.035, 0.04, "Z", 12, 0.005, "label_red", T),
        shapes.cylinder("pin", (0.06, 0, 0.015), 0.006, 0.0, 0.1, "X", 8, 0.0, "gun_chrome", M),
    ]
    return _one("env_deco_tack", P)


def deco_band():
    P = [shapes.torus("band", (0, 0, 0.01), 0.15, 0.012, "Z", 32, 6, "snack_orange", T, scale=(1.0, 0.6, 1.0))]
    for v in P[0].data.vertices:
        v.co.z += 0.008 * math.sin(v.co.x * 20)
    return _one("env_deco_band", P)


def deco_notebook():
    P = [
        shapes.rounded_box("cover", (0, 0, 0.03), (0.5, 0.7, 0.06), 0.01, 1, "clover_dark", T),
        shapes.rounded_box("pages", (0.006, 0, 0.03), (0.48, 0.68, 0.05), 0.004, 1, "paper", T),
        shapes.rounded_box("label", (0, 0.1, 0.0615), (0.3, 0.14, 0.002), 0.0, 1, "paper", F),
    ]
    for k in range(9):
        P.append(shapes.torus(f"spiral{k}", (-0.25, -0.3 + k * 0.075, 0.03), 0.03, 0.006, "Y", 12, 4, "gun_steel", M))
    return _one("env_deco_notebook", P)


def deco_glue():
    P = [
        shapes.cylinder("tube", (0, 0, 0), 0.06, None, 0.34, "Y", 16, 0.01, "white", T),
        shapes.cylinder("lab", (0, 0.02, 0), 0.062, None, 0.18, "Y", 16, 0.0, "snack_purple", T),
        shapes.cylinder("cap", (0, 0.21, 0), 0.064, None, 0.1, "Y", 16, 0.01, "snack_purple", T),
        shapes.cylinder("base", (0, -0.18, 0), 0.064, None, 0.04, "Y", 16, 0.008, "snack_purple", T),
    ]
    return _one("env_deco_glue", lay(P, loc=(0, 0, 0.064)))


def deco_staples():
    P = []
    for k in range(3):
        P.append(shapes.rounded_box(f"strip{k}", (0, k * 0.07, 0.018), (0.36, 0.05, 0.036), 0.004, 1, "gun_chrome", M))
        P.append(shapes.rounded_box(f"line{k}", (0, k * 0.07, 0.0365), (0.34, 0.004, 0.002), 0.0, 1, "gun_steel", F))
    return _one("env_deco_staples", lay(P, rot=(0, 0, deg(10))))


def deco_highlighter():
    P = [
        shapes.rounded_box("body", (0, 0, 0), (0.12, 0.5, 0.1), 0.03, 2, "regen_green", T),
        shapes.rounded_box("cap", (0, 0.29, 0), (0.125, 0.12, 0.105), 0.03, 2, "clover", T),
        shapes.rounded_box("clip", (0, 0.25, 0.06), (0.03, 0.14, 0.02), 0.008, 1, "clover", T),
        shapes.rounded_box("lab", (0, -0.05, 0.051), (0.08, 0.2, 0.002), 0.0, 1, "paper", F),
    ]
    return _one("env_deco_highlighter", lay(P, loc=(0, 0, 0.052)))


def deco_paper():
    P = [shapes.rounded_box("sheet", (0, 0, 0.004), (0.72, 1.0, 0.008), 0.0, 1, "paper", T)]
    for k in range(10):
        P.append(shapes.rounded_box(f"l{k}", (0.03, -0.38 + k * 0.08, 0.0085), (0.58, 0.008, 0.001), 0.0, 1, "sticker_blue", F))
    P.append(shapes.rounded_box("margin", (-0.26, 0, 0.0086), (0.008, 0.96, 0.001), 0.0, 1, "label_red", F))
    for k in range(3):
        P.append(shapes.rounded_box(f"scrib{k}", (0.0 + k * 0.08, 0.3 - k * 0.16, 0.009), (0.3 - k * 0.06, 0.014, 0.001), 0.0, 1, "rubber", F, rot=(0, 0, deg(-8 + k * 6))))
    # 一角卷起
    P.append(shapes.rounded_box("curl", (0.33, 0.47, 0.04), (0.12, 0.12, 0.008), 0.0, 1, "paper", T, rot=(deg(40), deg(-30), 0)))
    return _one("env_deco_paper", P)


# =========================================================================== 装饰：厨房

def deco_spoon():
    P = [
        shapes.rounded_box("handle", (0, -0.2, 0.02), (0.07, 0.5, 0.02), 0.008, 1, "gun_chrome", M),
        shapes.uv_sphere("bowl", (0, 0.15, 0.03), (0.11, 0.16, 0.035), 14, 8, "gun_chrome", M),
        shapes.uv_sphere("bowlin", (0, 0.15, 0.058), (0.085, 0.13, 0.006), 12, 4, "gun_steel", F),
    ]
    return _one("env_deco_spoon", P)


def deco_fork():
    P = [
        shapes.rounded_box("handle", (0, -0.22, 0.02), (0.07, 0.48, 0.02), 0.008, 1, "gun_chrome", M),
        shapes.rounded_box("neck", (0, 0.06, 0.02), (0.11, 0.1, 0.02), 0.01, 1, "gun_chrome", M),
    ]
    for k in range(4):
        P.append(shapes.rounded_box(f"tine{k}", (-0.045 + k * 0.03, 0.2, 0.02), (0.016, 0.2, 0.016), 0.005, 1, "gun_chrome", M))
    return _one("env_deco_fork", P)


def deco_sugar():
    P = []
    for k, (x, y, a) in enumerate(((0, 0, 0.2), (0.11, 0.04, 0.8), (0.04, 0.12, 1.4))):
        P.append(shapes.rounded_box(f"c{k}", (x, y, 0.045), (0.09, 0.09, 0.09), 0.012, 2, "white", T, rot=(0, 0, a)))
    return _one("env_deco_sugar", P)


def deco_cookie():
    P = [shapes.cylinder("c", (0, 0, 0.025), 0.16, None, 0.05, "Z", 20, 0.015, "cardboard_light", T)]
    lumpy(P[0], 0.01, center=(0, 0, 0.025))
    for k in range(6):
        a = k * 1.1
        r = 0.04 + (k % 3) * 0.035
        P.append(shapes.uv_sphere(f"chip{k}", (math.cos(a) * r, math.sin(a) * r, 0.05), (0.022, 0.022, 0.014), 8, 5, "seed_shell", T))
    P.append(shapes.uv_sphere("bite", (0.15, 0.06, 0.03), (0.05, 0.05, 0.05), 10, 6, "cardboard_dark", F))
    return _one("env_deco_cookie", P)


def deco_cereal():
    P = []
    for k in range(5):
        x, y = RNG.uniform(-0.12, 0.12), RNG.uniform(-0.12, 0.12)
        P.append(shapes.torus(f"r{k}", (x, y, 0.016), 0.04, 0.016, "Z", 14, 6, "snack_orange" if k % 2 else "sticker_yellow", T))
    return _one("env_deco_cereal", P)


def deco_pasta():
    P = []
    for k in range(4):
        p = shapes.cylinder(f"p{k}", (0, 0, 0), 0.035, None, 0.14, "Y", 10, 0.0, "spray_yellow", T)
        hole = shapes.cylinder(f"h{k}", (0, 0.0705, 0), 0.02, None, 0.002, "Y", 8, 0.0, "cardboard", F)
        lay([p, hole], rot=(0, 0, RNG.uniform(0, 6.28)), loc=(RNG.uniform(-0.12, 0.12), RNG.uniform(-0.12, 0.12), 0.035))
        P += [p, hole]
    return _one("env_deco_pasta", P)


def deco_peas():
    P = []
    for k in range(4):
        P.append(shapes.uv_sphere(f"p{k}", (RNG.uniform(-0.1, 0.1), RNG.uniform(-0.1, 0.1), 0.04), (0.042, 0.042, 0.04), 10, 6, "clover", T))
    return _one("env_deco_peas", P)


def deco_teabag():
    P = [
        shapes.rounded_box("bag", (0, 0, 0.02), (0.24, 0.3, 0.04), 0.015, 2, "towel_cream", T),
        shapes.rounded_box("tea", (0, -0.02, 0.041), (0.16, 0.18, 0.002), 0.0, 1, "wood_red", F),
        shapes.capsule("string", (0, 0.15, 0.01), (0.1, 0.38, 0.004), 0.004, 4, 1, "white", T),
        shapes.rounded_box("tag", (0.13, 0.44, 0.004), (0.1, 0.08, 0.008), 0.0, 1, "label_red", T),
    ]
    return _one("env_deco_teabag", P)


def deco_match():
    P = [
        shapes.rounded_box("stick", (0, 0, 0.018), (0.035, 0.36, 0.035), 0.004, 1, "floor_wood_light", T),
        shapes.uv_sphere("head", (0, 0.19, 0.02), (0.03, 0.04, 0.03), 10, 6, "label_red", T),
    ]
    P2 = [shapes.rounded_box("stick2", (0, 0, 0.018), (0.035, 0.36, 0.035), 0.004, 1, "floor_wood_light", T),
          shapes.uv_sphere("head2", (0, 0.19, 0.02), (0.03, 0.04, 0.03), 10, 6, "seed_shell", T)]
    lay(P2, rot=(0, 0, deg(35)), loc=(0.1, 0.02, 0.0))
    return _one("env_deco_match", P + P2)


def deco_chopstick():
    P = []
    for k in range(2):
        c = shapes.cylinder(f"c{k}", (0, 0, 0), 0.016, 0.026, 1.0, "Y", 8, 0.0, "wood" if k == 0 else "wood_red", T)
        lay([c], rot=(0, 0, deg(4 - k * 9)), loc=(k * 0.06, 0, 0.026))
        P.append(c)
    return _one("env_deco_chopstick", P)


# =========================================================================== 装饰：客厅

def deco_car():
    P = [
        shapes.rounded_box("body", (0, 0, 0.08), (0.2, 0.38, 0.09), 0.03, 2, "label_red", T),
        shapes.rounded_box("cab", (0, -0.03, 0.15), (0.17, 0.18, 0.08), 0.03, 2, "label_red", T),
        shapes.rounded_box("win", (0, 0.06, 0.15), (0.15, 0.012, 0.06), 0.004, 1, "lens", G),
        shapes.rounded_box("stripe", (0, 0.0, 0.126), (0.06, 0.38, 0.004), 0.0, 1, "white", F),
    ]
    for sx in (-1, 1):
        for sy in (-1, 1):
            P.append(shapes.cylinder(f"w{sx}{sy}", (sx * 0.1, sy * 0.12, 0.045), 0.045, None, 0.04, "X", 14, 0.01, "rubber", T))
            P.append(shapes.cylinder(f"hub{sx}{sy}", (sx * 0.121, sy * 0.12, 0.045), 0.02, None, 0.004, "X", 10, 0.0, "gun_chrome", F))
    return _one("env_deco_car", P)


def deco_puzzle():
    P = [shapes.rounded_box("p", (0, 0, 0.015), (0.3, 0.3, 0.03), 0.006, 1, "sticker_blue", T)]
    P.append(shapes.cylinder("knob1", (0.19, 0, 0.015), 0.06, None, 0.03, "Z", 14, 0.006, "sticker_blue", T))
    P.append(shapes.cylinder("knob2", (0, 0.19, 0.015), 0.06, None, 0.03, "Z", 14, 0.006, "sticker_blue", T))
    P.append(shapes.cylinder("slot", (-0.12, 0, 0.031), 0.055, None, 0.002, "Z", 14, 0.0, "rubber", F))
    P.append(shapes.rounded_box("pic", (0.02, -0.02, 0.0305), (0.18, 0.14, 0.001), 0.0, 1, "clover", F))
    return _one("env_deco_puzzle", P)


def deco_card():
    P = [shapes.rounded_box("c", (0, 0, 0.004), (0.32, 0.46, 0.008), 0.02, 2, "white", T)]
    P.append(shapes.uv_sphere("heart1", (-0.02, 0.02, 0.009), (0.05, 0.05, 0.002), 10, 3, "label_red", F))
    P.append(shapes.uv_sphere("heart2", (0.02, 0.02, 0.009), (0.05, 0.05, 0.002), 10, 3, "label_red", F))
    P.append(shapes.cylinder("heart3", (0.0, -0.03, 0.009), 0.0, 0.07, 0.002, "Z", 3, 0.0, "label_red", F))
    for (x, y) in ((-0.11, 0.18), (0.11, -0.18)):
        P.append(shapes.rounded_box(f"idx{x}", (x, y, 0.009), (0.03, 0.05, 0.001), 0.0, 1, "label_red", F))
    return _one("env_deco_card", lay(P, rot=(0, 0, deg(20))))


def deco_popcorn():
    P = []
    for k in range(3):
        x, y = RNG.uniform(-0.1, 0.1), RNG.uniform(-0.1, 0.1)
        b = shapes.quad_sphere(f"p{k}", (0, 0, 0), (0.06, 0.055, 0.05), 2, "towel_cream")
        lumpy(b, 0.02, f=(6, 5, 7))
        lay([b], loc=(x, y, 0.045))
        P.append(b)
        P.append(shapes.uv_sphere(f"k{k}", (x + 0.03, y - 0.02, 0.02), (0.018, 0.018, 0.014), 6, 4, "sticker_yellow", T))
    return _one("env_deco_popcorn", P)


def deco_chip():
    P = []
    for k in range(2):
        c = shapes.uv_sphere(f"c{k}", (0, 0, 0), (0.11, 0.09, 0.02), 14, 6, "spray_yellow", T)
        for v in c.data.vertices:
            v.co.z += 0.03 * (v.co.x / 0.11) ** 2
        lay([c], rot=(deg(RNG.uniform(-15, 15)), 0, RNG.uniform(0, 6.28)), loc=(k * 0.12, k * 0.05, 0.03))
        P.append(c)
    return _one("env_deco_chip", P)


def deco_wrapper():
    P = [shapes.cylinder("w", (0, 0, 0), 0.05, None, 0.14, "Y", 12, 0.01, "laser_pink", T)]
    for s in (-1, 1):
        P.append(shapes.cylinder(f"tw{s}", (0, s * 0.1, 0), 0.05, 0.012, 0.06, "Y", 10, 0.0, "laser_pink", T))
        if s < 0:
            shapes.transform(P[-1], loc=(0, 0, 0))
    P.append(shapes.cylinder("stripe", (0, 0, 0), 0.052, None, 0.03, "Y", 12, 0.0, "sticker_white", T))
    return _one("env_deco_wrapper", lay(P, rot=(0, 0, deg(30)), loc=(0, 0, 0.05)))


# =========================================================================== 装饰：沙发底

def deco_dust():
    b = shapes.quad_sphere("d", (0, 0, 0.08), (0.16, 0.13, 0.08), 3, "smoke_grey")
    lumpy(b, 0.035, f=(11, 9, 13), center=(0, 0, 0.08))
    shapes.flat(b)
    P = [b]
    for k in range(5):
        a = k * 1.3
        P.append(shapes.capsule(f"h{k}", (math.cos(a) * 0.12, math.sin(a) * 0.1, 0.06), (math.cos(a) * 0.24, math.sin(a) * 0.18, 0.02), 0.006, 4, 1, "wall_trim", T))
    return _one("env_deco_dust", P)


def deco_sock():
    P = [
        shapes.capsule("leg", (0, -0.25, 0.05), (0, 0.15, 0.05), 0.09, 10, 3, "white", T),
        shapes.capsule("foot", (0, 0.15, 0.05), (0.18, 0.28, 0.045), 0.085, 10, 3, "white", T),
        shapes.uv_sphere("heel", (-0.02, 0.17, 0.045), (0.09, 0.08, 0.04), 10, 6, "label_red", T),
        shapes.uv_sphere("toe", (0.2, 0.3, 0.045), (0.07, 0.06, 0.04), 10, 6, "label_red", T),
    ]
    for k in range(3):
        P.append(shapes.torus(f"st{k}", (0, -0.2 + k * 0.08, 0.05), 0.091, 0.012, "Y", 14, 4, "sticker_blue", T, scale=(1.0, 1.0, 0.55)))
    for o in P:
        for v in o.data.vertices:
            v.co.z = 0.012 + (v.co.z - 0.012) * 0.45 if v.co.z > 0.012 else v.co.z
    return _one("env_deco_sock", P)


def deco_hairtie():
    return _one("env_deco_hairtie", [shapes.torus("t", (0, 0, 0.022), 0.08, 0.022, "Z", 24, 8, "laser_pink", T)])


def deco_remote():
    P = [shapes.rounded_box("body", (0, 0, 0.045), (0.26, 0.9, 0.09), 0.04, 2, "gun_dark", T)]
    P.append(shapes.cylinder("power", (0.07, 0.36, 0.091), 0.025, None, 0.012, "Z", 12, 0.004, "label_red", T))
    for i in range(3):
        for j in range(4):
            P.append(shapes.rounded_box(f"b{i}{j}", (-0.07 + i * 0.07, 0.15 - j * 0.08, 0.092), (0.045, 0.05, 0.012), 0.008, 1, "gun_light", T))
    P.append(shapes.cylinder("dpad", (0, -0.22, 0.092), 0.07, None, 0.012, "Z", 16, 0.004, "gun_light", T))
    P.append(shapes.rounded_box("ir", (0, 0.452, 0.045), (0.12, 0.004, 0.04), 0.0, 1, "led_red", F))
    return _one("env_deco_remote", lay(P, rot=(0, 0, deg(-25))))


def deco_crumbs():
    P = []
    for k in range(8):
        sz = RNG.uniform(0.02, 0.045)
        P.append(shapes.rounded_box(f"c{k}", (RNG.uniform(-0.15, 0.15), RNG.uniform(-0.15, 0.15), sz / 2), (sz, sz * 1.2, sz), 0.006, 1, "cardboard_light" if k % 3 else "cardboard_dark", T, rot=(0, 0, RNG.uniform(0, 6))))
    return _one("env_deco_crumbs", P)


# =========================================================================== 装饰：冰箱区

def deco_magnet():
    P = []
    # 字母磁贴 O / I / L
    P.append(shapes.torus("O", (0, 0, 0.025), 0.07, 0.025, "Z", 20, 6, "label_red", T))
    P.append(shapes.rounded_box("I", (0.16, 0.04, 0.025), (0.05, 0.18, 0.05), 0.012, 2, "sticker_blue", T, rot=(0, 0, deg(20))))
    L = [shapes.rounded_box("L1", (0, 0, 0.025), (0.05, 0.18, 0.05), 0.012, 2, "sticker_yellow", T),
         shapes.rounded_box("L2", (0.05, -0.065, 0.025), (0.1, 0.05, 0.05), 0.012, 2, "sticker_yellow", T)]
    lay(L, rot=(0, 0, deg(-30)), loc=(-0.14, -0.1, 0))
    return _one("env_deco_magnet", P + L)


def deco_ice():
    P = [
        shapes.cylinder("puddle", (0, 0, 0.002), 0.2, None, 0.004, "Z", 16, 0.0, "lens", G),
        shapes.rounded_box("cube", (0.0, 0.0, 0.07), (0.13, 0.13, 0.12), 0.03, 2, "ice", G, rot=(0, 0, deg(20))),
        shapes.rounded_box("cube2", (0.14, 0.08, 0.05), (0.09, 0.09, 0.08), 0.025, 2, "ice", G, rot=(0, 0, deg(50))),
    ]
    lumpy(P[0], 0.04, f=(5, 4, 1))
    return _one("env_deco_ice", P)


def deco_grape():
    P = []
    for k, (x, y) in enumerate(((0, 0), (0.1, 0.05), (0.04, 0.11))):
        P.append(shapes.uv_sphere(f"g{k}", (x, y, 0.055), (0.06, 0.06, 0.055), 12, 8, "snack_purple", G))
    P.append(shapes.capsule("stem", (0.04, 0.05, 0.11), (0.08, 0.12, 0.13), 0.008, 6, 2, "clover_dark", T))
    return _one("env_deco_grape", P)


def deco_puddle():
    p = shapes.cylinder("p", (0, 0, 0.002), 0.35, None, 0.004, "Z", 20, 0.0, "lens", G)
    lumpy(p, 0.08, f=(4, 3, 1))
    return _one("env_deco_puddle", [p])


# =========================================================================== 装饰：礼物区

def deco_ribbon():
    P = []
    pts = []
    for k in range(18):
        t = k / 17
        pts.append(Vector((math.cos(t * 9) * 0.07 + t * 0.4 - 0.2, math.sin(t * 9) * 0.07, 0.02 + 0.01 * math.sin(t * 9))))
    for i in range(len(pts) - 1):
        P.append(shapes.capsule(f"r{i}", pts[i], pts[i + 1], 0.012, 6, 2, "laser_pink", T))
    return _one("env_deco_ribbon", P)


def deco_bow():
    P = [shapes.uv_sphere("knot", (0, 0, 0.05), (0.05, 0.05, 0.045), 10, 6, "sticker_blue", T)]
    for s in (-1, 1):
        P.append(shapes.torus(f"loop{s}", (s * 0.11, 0, 0.06), 0.07, 0.022, "Y", 18, 6, "sticker_blue", T, scale=(1.0, 1.0, 0.7)))
        P.append(shapes.rounded_box(f"tail{s}", (s * 0.06, -0.12, 0.012), (0.05, 0.16, 0.02), 0.006, 1, "sticker_blue", T, rot=(0, 0, deg(s * 20))))
    return _one("env_deco_bow", P)


def deco_confetti():
    P = []
    cols = ["laser_pink", "sticker_yellow", "sticker_blue", "clover", "sticker_orange", "snack_purple"]
    for k in range(16):
        r = RNG.uniform(0, 0.3)
        a = RNG.uniform(0, 6.28)
        P.append(shapes.rounded_box(f"c{k}", (math.cos(a) * r, math.sin(a) * r, 0.003 + k * 0.0003), (0.05, 0.03, 0.004), 0.0, 1, cols[k % len(cols)], F, rot=(0, 0, RNG.uniform(0, 6.28))))
    return _one("env_deco_confetti", P)


def deco_tag():
    P = [
        shapes.rounded_box("tag", (0, 0, 0.004), (0.16, 0.24, 0.008), 0.01, 1, "sticker_white", T),
        shapes.cylinder("hole", (0, 0.09, 0.009), 0.014, None, 0.002, "Z", 10, 0.0, "rubber", F),
        shapes.rounded_box("line1", (0, 0.0, 0.0085), (0.1, 0.012, 0.001), 0.0, 1, "label_red", F),
        shapes.rounded_box("line2", (0, -0.04, 0.0085), (0.08, 0.012, 0.001), 0.0, 1, "label_red", F),
        shapes.capsule("string", (0, 0.09, 0.006), (0.12, 0.3, 0.004), 0.005, 4, 1, "tassel_red", T),
    ]
    return _one("env_deco_tag", lay(P, rot=(0, 0, deg(-15))))


def deco_balloon():
    b = shapes.quad_sphere("b", (0, 0, 0.03), (0.22, 0.16, 0.04), 3, "label_red")
    lumpy(b, 0.03, f=(6, 7, 3), center=(0, 0, 0.03))
    P = [b, shapes.cylinder("knot", (0.0, -0.17, 0.02), 0.025, 0.012, 0.04, "Y", 10, 0.004, "label_red", T),
         shapes.capsule("str", (0, -0.19, 0.01), (0.12, -0.45, 0.006), 0.005, 4, 1, "white", T)]
    return _one("env_deco_balloon", P)


DECOS = {
    "study": [deco_pen, deco_tape, deco_sharpener, deco_tack, deco_band, deco_notebook, deco_glue, deco_staples, deco_highlighter, deco_paper],
    "kitchen": [deco_spoon, deco_fork, deco_sugar, deco_cookie, deco_cereal, deco_pasta, deco_peas, deco_teabag, deco_match, deco_chopstick],
    "living": [deco_car, deco_puzzle, deco_card, deco_popcorn, deco_chip, deco_wrapper],
    "sofa": [deco_dust, deco_sock, deco_hairtie, deco_remote, deco_crumbs],
    "fridge": [deco_magnet, deco_ice, deco_grape, deco_puddle],
    "gift": [deco_ribbon, deco_bow, deco_confetti, deco_tag, deco_balloon],
}


def build(ctx):
    mods = [floor_tile_white(), floor_wood_dusty(), fridge(), cabinet(), sofa_skirt(), sofa_leg()]
    decos = []
    for fns in DECOS.values():
        decos += [f() for f in fns]
    rug = rug_party()
    allm = mods + decos + [rug]
    extras = [(r.name, [r]) for r in allm]

    def layout(_ctx):
        for i, r in enumerate(mods):
            r.location = Vector((i * 2.6, 3.0, 0))
        for i, r in enumerate(decos):
            r.location = Vector(((i % 8) * 1.1, -(i // 8) * 1.1, 0))
        rug.location = Vector((-4.0, 0.0, 0))

    ip = [("three_quarter", {"margin": 1.2, "res": 300})]
    pv = [("decos", "three_quarter", {"margin": 1.02, "res": 1400, "only": lambda o: any(o is d or o in d.children_recursive for d in decos)})]
    return ctx.Built([], previews=pv, outline=0.006, extra_exports=extras, after_export=layout, item_previews=ip)
