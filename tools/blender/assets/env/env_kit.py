"""地图模块（Godot 里的地图生成器按 map_layout 摆放 / 拉伸 / 平铺这些模块）。

主题：夜里熄了灯的屋子，仓鼠视角（ART_BIBLE 第 1 节）。物件约为真实尺寸的 2.5 倍。
- 地面：floor_wood（书房木地板 2×2 米）、floor_carpet（客厅地毯 2×2 米）、floor_tile（厨房瓷砖 2×2 米）、rug_edge（地毯流苏边 1 米）
- 边界：wall（墙 + 踢脚线 2 米段）、shelf（靠墙矮书架 2 米段，带书）
- 障碍：counter（木抽屉柜 1 米段，按长度平铺）、counter_end、book_<色>（单本立书，排成书墙）、
  can（笔筒罐头 + 铅笔）、pot（多肉盆栽）、bottles（墨水瓶托盘）
- 装饰（无碰撞，密度担当）：pencil、eraser、paperball、sticky、coin、button、block、marble、dice、clip、cap、crayon、ruler、shells、cable
"""
import math
import random

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg

RNG = random.Random(7)


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


# --------------------------------------------------------------------------- 地面

def floor_wood():
    P = [shapes.rounded_box("sub", (0, 0, -0.03), (2.0, 2.0, 0.04), 0.0, 1, "floor_wood_dark", style.MAT_TOON)]
    cols = ["floor_wood", "floor_wood_light", "floor_wood", "floor_wood_dark"]
    w = 0.25
    for i in range(8):
        x = -1.0 + w * (i + 0.5)
        off = RNG.uniform(-0.9, 0.9)
        y = -1.0
        segs = []
        cut = off
        edges = sorted([-1.0, 1.0] + [c for c in (cut - 1.2, cut, cut + 1.2) if -0.95 < c < 0.95])
        for a, b in zip(edges[:-1], edges[1:]):
            c = cols[RNG.randrange(len(cols))]
            P.append(shapes.rounded_box(f"pl{i}_{a:.2f}", (x, (a + b) / 2, -0.005), (w - 0.012, (b - a) - 0.012, 0.012), 0.004, 1, c, style.MAT_TOON))
            if RNG.random() < 0.3:
                P.append(shapes.uv_sphere(f"knot{i}{a:.2f}", (x + RNG.uniform(-0.06, 0.06), (a + b) / 2 + RNG.uniform(-0.3, 0.3), 0.0015), (0.02, 0.035, 0.001), 8, 3, "floor_wood_dark", style.MAT_FLAT))
    return _one("env_floor_wood", P)


def floor_carpet():
    P = [shapes.rounded_box("c", (0, 0, -0.01), (2.0, 2.0, 0.02), 0.0, 1, "carpet", style.MAT_TOON)]
    # 菱形花纹
    for i in range(4):
        for j in range(4):
            if (i + j) % 2 == 0:
                d = shapes.rounded_box(f"d{i}{j}", (-0.75 + i * 0.5, -0.75 + j * 0.5, 0.0015), (0.16, 0.16, 0.004), 0.0, 1, "carpet_light", style.MAT_FLAT, rot=(0, 0, deg(45)))
                P.append(d)
    return _one("env_floor_carpet", P)


def floor_tile():
    P = [shapes.rounded_box("grout", (0, 0, -0.02), (2.0, 2.0, 0.03), 0.0, 1, "wood_dark", style.MAT_TOON)]
    n = 4
    s = 2.0 / n
    for i in range(n):
        for j in range(n):
            c = "tile_cream" if (i + j) % 2 == 0 else "tile_terracotta"   # 暖色：冷灰瓷砖在夜光下发蓝，会和蓝队色混
            P.append(shapes.rounded_box(f"t{i}{j}", (-1 + s * (i + 0.5), -1 + s * (j + 0.5), -0.004), (s - 0.02, s - 0.02, 0.012), 0.004, 1, c, style.MAT_TOON))
    return _one("env_floor_tile", P)


def rug_edge():
    P = [shapes.rounded_box("band", (0, 0, 0.004), (1.0, 0.1, 0.012), 0.004, 1, "carpet_light", style.MAT_TOON)]
    for k in range(10):
        x = -0.45 + k * 0.1
        P.append(shapes.capsule(f"f{k}", (x, 0.05, 0.004), (x + RNG.uniform(-0.01, 0.01), 0.12, 0.003), 0.008, 6, 2, "towel_cream", style.MAT_TOON))
    return _one("env_rug_edge", P)


# --------------------------------------------------------------------------- 边界

def wall():
    P = [
        shapes.rounded_box("wall", (0, 0.1, 0.8), (2.0, 0.2, 1.6), 0.0, 1, "wall_plaster", style.MAT_TOON),
        shapes.rounded_box("base", (0, -0.005, 0.09), (2.0, 0.03, 0.18), 0.008, 1, "floor_wood_dark", style.MAT_TOON),
        shapes.rounded_box("trim", (0, -0.004, 0.6), (2.0, 0.025, 0.04), 0.008, 1, "wall_trim", style.MAT_TOON),
        shapes.rounded_box("panel", (0, -0.002, 0.35), (1.8, 0.012, 0.4), 0.004, 1, "wall_trim", style.MAT_FLAT),
    ]
    if RNG.random() < 1.0:
        P.append(shapes.rounded_box("socket", (0.5, -0.02, 0.3), (0.14, 0.02, 0.1), 0.01, 1, "white", style.MAT_TOON))
        for k in (-1, 1):
            P.append(shapes.rounded_box(f"hole{k}", (0.5 + k * 0.03, -0.031, 0.3), (0.012, 0.004, 0.03), 0.0, 1, "rubber", style.MAT_FLAT))
    return _one("env_wall", P)


def book(color, h=0.62, t=0.12, d=0.44):
    P = [
        shapes.rounded_box("cover", (0, 0, h / 2), (t, d, h), 0.008, 1, color, style.MAT_TOON),
        shapes.rounded_box("pages", (0, 0.006, h / 2), (t - 0.02, d - 0.004, h - 0.03), 0.004, 1, "paper", style.MAT_TOON),
        shapes.rounded_box("spine1", (0, -d / 2 - 0.001, h * 0.82), (t * 0.9, 0.004, 0.025), 0.0, 1, "sticker_yellow", style.MAT_FLAT),
        shapes.rounded_box("spine2", (0, -d / 2 - 0.001, h * 0.2), (t * 0.9, 0.004, 0.025), 0.0, 1, "sticker_yellow", style.MAT_FLAT),
        shapes.rounded_box("label", (0, -d / 2 - 0.001, h * 0.55), (t * 0.6, 0.004, 0.09), 0.0, 1, "paper", style.MAT_FLAT),
    ]
    return P


def books_modules():
    out = []
    for c in ("book_blue", "book_red", "book_green", "book_yellow", "book_purple", "book_orange"):
        out.append(_one("env_" + c, book(c)))
    return out


def shelf():
    P = [
        shapes.rounded_box("back", (0, 0.18, 0.5), (2.0, 0.06, 1.0), 0.01, 1, "wood_dark", style.MAT_TOON),
        shapes.rounded_box("board", (0, 0.0, 0.03), (2.0, 0.42, 0.06), 0.01, 1, "wood", style.MAT_TOON),
        shapes.rounded_box("top", (0, 0.0, 0.98), (2.04, 0.44, 0.05), 0.01, 1, "wood", style.MAT_TOON),
    ]
    x = -0.95
    cols = ["book_blue", "book_red", "book_green", "book_yellow", "book_purple", "book_orange"]
    while x < 0.9:
        t = RNG.uniform(0.09, 0.15)
        h = RNG.uniform(0.6, 0.86)
        c = cols[RNG.randrange(len(cols))]
        lean = deg(RNG.choice([0, 0, 0, 6]))
        for p in book(c, h, t, 0.36):
            shapes.transform(p, rot=(0, lean, 0))
            shapes.transform(p, loc=(x + t / 2, -0.02, 0.06))
            P.append(p)
        x += t + 0.006
    return _one("env_shelf", P)


# --------------------------------------------------------------------------- 障碍

def counter():
    P = [
        shapes.rounded_box("body", (0, 0, 0.3), (1.0, 0.68, 0.56), 0.02, 2, "wood", style.MAT_TOON),
        shapes.rounded_box("top", (0, 0, 0.6), (1.04, 0.72, 0.06), 0.015, 2, "floor_wood_light", style.MAT_TOON),
        shapes.rounded_box("plinth", (0, 0, 0.03), (0.96, 0.64, 0.06), 0.01, 1, "wood_dark", style.MAT_TOON),
    ]
    for sy in (-1, 1):
        P.append(shapes.rounded_box(f"drawer{sy}", (0, sy * 0.342, 0.32), (0.9, 0.012, 0.44), 0.008, 1, "floor_wood_light", style.MAT_TOON))
        P.append(shapes.uv_sphere(f"knob{sy}", (0, sy * 0.36, 0.34), (0.035, 0.03, 0.035), 10, 6, "paper", style.MAT_TOON))
    return _one("env_counter", P)


def can():
    """笔筒罐头（半径 0.4 基准）+ 铅笔、尺子插在里面。"""
    r = 0.4
    P = [
        shapes.cylinder("can", (0, 0, 0.26), r, None, 0.52, "Z", 36, 0.02, "gun_chrome", style.MAT_METAL),
        shapes.cylinder("label", (0, 0, 0.26), r + 0.004, None, 0.3, "Z", 36, 0, "book_blue", style.MAT_TOON),
        shapes.cylinder("stripe", (0, 0, 0.3), r + 0.006, None, 0.06, "Z", 36, 0, "sticker_yellow", style.MAT_TOON),
        shapes.torus("lip", (0, 0, 0.52), r - 0.005, 0.016, "Z", 36, 6, "gun_chrome", style.MAT_METAL),
    ]
    for k in range(5):
        a = k / 5 * math.tau + 0.3
        pr = r * 0.5
        tilt = deg(RNG.uniform(6, 16))
        P += pencil_parts(f"p{k}", 1.0)
        for p in P[-4:]:
            shapes.transform(p, rot=(0, -tilt, 0))
            shapes.transform(p, rot=(0, 0, a))
            shapes.transform(p, loc=(math.cos(a) * pr, math.sin(a) * pr, 0.08))
    return _one("env_can", P)


def pot():
    r = 0.44
    P = [
        shapes.lathe("pot", [(r * 0.7, 0.0), (r * 0.8, 0.04), (r * 0.98, 0.4), (r, 0.42), (r * 1.06, 0.44), (r * 1.06, 0.5), (r * 0.98, 0.52)], 32, "Z", (0, 0, 0), "spray_red", style.MAT_TOON),
        shapes.cylinder("soil", (0, 0, 0.49), r * 0.95, None, 0.02, "Z", 32, 0, "wood_dark", style.MAT_TOON),
    ]
    # 多肉：一圈圈胖叶子
    for ring, (n, rr, h, sz) in enumerate([(8, 0.28, 0.55, 0.13), (6, 0.17, 0.62, 0.11), (4, 0.07, 0.7, 0.09)]):
        for k in range(n):
            a = k / n * math.tau + ring * 0.4
            lf = shapes.quad_sphere(f"leaf{ring}{k}", (0, 0, 0), (sz * 0.55, sz, sz * 0.35), 2, "clover" if ring < 2 else "regen_green")
            shapes.transform(lf, rot=(deg(-40 + ring * 15), 0, 0))
            shapes.transform(lf, loc=(0, rr * 0.6, 0))
            shapes.transform(lf, rot=(0, 0, a))
            shapes.transform(lf, loc=(0, 0, h))
            P.append(lf)
    return _one("env_pot", P)


def bottles():
    """墨水 / 胶水瓶托盘（1 米见方基准）。"""
    P = [shapes.rounded_box("tray", (0, 0, 0.04), (1.0, 1.0, 0.08), 0.02, 2, "cardboard", style.MAT_TOON)]
    cols = ["book_blue", "label_red", "book_green", "seed_shell"]
    k = 0
    for i in range(3):
        for j in range(3):
            x = -0.33 + i * 0.33
            y = -0.33 + j * 0.33
            h = RNG.uniform(0.5, 0.68)
            c = cols[k % len(cols)]
            P.append(shapes.cylinder(f"b{k}", (x, y, 0.08 + h / 2), 0.13, None, h, "Z", 18, 0.03, "lens", style.MAT_GLASS))
            P.append(shapes.cylinder(f"ink{k}", (x, y, 0.08 + h * 0.3), 0.125, None, h * 0.55, "Z", 18, 0.0, c, style.MAT_TOON))
            P.append(shapes.cylinder(f"cap{k}", (x, y, 0.08 + h + 0.04), 0.07, None, 0.08, "Z", 14, 0.01, "rubber", style.MAT_TOON))
            P.append(shapes.cylinder(f"lab{k}", (x, y, 0.08 + h * 0.62), 0.132, None, 0.1, "Z", 18, 0.0, "paper", style.MAT_FLAT))
            k += 1
    return _one("env_bottles", P)


# --------------------------------------------------------------------------- 装饰

def pencil_parts(name, L=1.2, col="pencil_yellow"):
    return [
        shapes.cylinder(name + "b", (0, 0, L * 0.45), 0.035, None, L * 0.8, "Z", 6, 0.0, col, style.MAT_TOON),
        shapes.cylinder(name + "w", (0, 0, L * 0.9), 0.0, 0.035, L * 0.12, "Z", 6, 0.0, "floor_wood_light", style.MAT_TOON),
        shapes.cylinder(name + "t", (0, 0, L * 0.97), 0.0, 0.012, L * 0.04, "Z", 6, 0.0, "seed_shell", style.MAT_TOON),
        shapes.cylinder(name + "e", (0, 0, L * 0.03), 0.036, None, L * 0.06, "Z", 8, 0.004, "eraser_pink", style.MAT_TOON),
    ]


def deco_pencil():
    P = pencil_parts("p", 1.3)
    for p in P:
        shapes.transform(p, rot=(0, deg(90), 0))
        shapes.transform(p, loc=(-0.65, 0, 0.036))
    return _one("env_deco_pencil", P)


def deco_eraser():
    return _one("env_deco_eraser", [
        shapes.rounded_box("e", (0, 0, 0.06), (0.35, 0.2, 0.12), 0.03, 2, "eraser_pink", style.MAT_TOON),
        shapes.rounded_box("sleeve", (0.06, 0, 0.06), (0.2, 0.205, 0.125), 0.01, 1, "book_blue", style.MAT_TOON),
    ])


def deco_paperball():
    b = shapes.quad_sphere("pb", (0, 0, 0.16), (0.17, 0.16, 0.15), 2, "paper")
    for v in b.data.vertices:
        n = (v.co - Vector((0, 0, 0.16))).normalized()
        v.co += n * 0.025 * math.sin(n.x * 9 + 1) * math.sin(n.y * 7) * math.sin(n.z * 8 + 2)
    shapes.flat(b)
    return _one("env_deco_paperball", [b])


def deco_sticky():
    s = shapes.rounded_box("s", (0, 0, 0.003), (0.38, 0.38, 0.006), 0.002, 1, "sticker_yellow", style.MAT_TOON)
    lines = [shapes.rounded_box(f"l{k}", (-0.02, -0.1 + k * 0.08, 0.0065), (0.26, 0.012, 0.002), 0.0, 1, "book_blue", style.MAT_FLAT) for k in range(3)]
    return _one("env_deco_sticky", [s] + lines)


def deco_coin():
    return _one("env_deco_coin", [
        shapes.cylinder("c", (0, 0, 0.012), 0.24, None, 0.024, "Z", 28, 0.006, "brass", style.MAT_METAL),
        shapes.torus("r", (0, 0, 0.024), 0.2, 0.008, "Z", 28, 4, "gold_ring", style.MAT_METAL),
    ])


def deco_button():
    P = [shapes.cylinder("b", (0, 0, 0.02), 0.16, None, 0.04, "Z", 24, 0.01, "label_red", style.MAT_TOON)]
    for k in range(4):
        a = k / 4 * math.tau + 0.78
        P.append(shapes.cylinder(f"h{k}", (math.cos(a) * 0.05, math.sin(a) * 0.05, 0.041), 0.02, None, 0.004, "Z", 10, 0, "seed_shell", style.MAT_FLAT))
    return _one("env_deco_button", P)


def deco_block():
    P = [shapes.rounded_box("b", (0, 0, 0.12), (0.48, 0.24, 0.24), 0.012, 2, "book_red", style.MAT_TOON)]
    for i in range(2):
        for j in range(4):
            P.append(shapes.cylinder(f"s{i}{j}", (-0.18 + j * 0.12, -0.06 + i * 0.12, 0.26), 0.04, None, 0.04, "Z", 12, 0.008, "book_red", style.MAT_TOON))
    return _one("env_deco_block", P)


def deco_marble():
    return _one("env_deco_marble", [
        shapes.uv_sphere("m", (0, 0, 0.1), (0.1, 0.1, 0.1), 16, 10, "lens", style.MAT_GLASS),
        shapes.uv_sphere("sw", (0.0, 0.0, 0.1), (0.03, 0.08, 0.03), 10, 6, "path_c", style.MAT_TOON),
    ])


def deco_dice():
    P = [shapes.rounded_box("d", (0, 0, 0.14), (0.28, 0.28, 0.28), 0.04, 3, "white", style.MAT_TOON)]
    for (x, y) in [(-0.07, -0.07), (0.07, 0.07), (0, 0)]:
        P.append(shapes.uv_sphere(f"p{x}{y}", (x, y, 0.281), (0.026, 0.026, 0.006), 10, 4, "seed_shell", style.MAT_FLAT))
    P.append(shapes.uv_sphere("p1", (0.141, 0, 0.14), (0.006, 0.03, 0.03), 10, 4, "label_red", style.MAT_FLAT))
    return _one("env_deco_dice", P)


def deco_clip():
    P = []
    pts = [(-0.15, -0.05), (0.15, -0.05), (0.15, 0.05), (-0.12, 0.05), (-0.12, -0.025), (0.1, -0.025)]
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        P.append(shapes.capsule(f"c{i}", (a[0], a[1], 0.012), (b[0], b[1], 0.012), 0.01, 6, 2, "gun_chrome", style.MAT_METAL))
    return _one("env_deco_clip", P)


def deco_cap():
    P = [shapes.cylinder("c", (0, 0, 0.035), 0.14, None, 0.07, "Z", 24, 0.01, "label_red", style.MAT_METAL)]
    for k in range(18):
        a = k / 18 * math.tau
        P.append(shapes.rounded_box(f"r{k}", (math.cos(a) * 0.142, math.sin(a) * 0.142, 0.035), (0.02, 0.02, 0.07), 0.004, 1, "label_red", style.MAT_METAL, rot=(0, 0, a)))
    P.append(shapes.cylinder("logo", (0, 0, 0.071), 0.07, None, 0.003, "Z", 18, 0, "white", style.MAT_FLAT))
    return _one("env_deco_cap", P)


def deco_crayon():
    P = [
        shapes.cylinder("b", (0, 0, 0.4), 0.06, None, 0.7, "Z", 10, 0.01, "path_b", style.MAT_TOON),
        shapes.cylinder("w", (0, 0, 0.4), 0.062, None, 0.5, "Z", 10, 0.0, "paper", style.MAT_TOON),
        shapes.cylinder("t", (0, 0, 0.8), 0.015, 0.06, 0.1, "Z", 10, 0.0, "path_b", style.MAT_TOON),
    ]
    for p in P:
        shapes.transform(p, rot=(0, deg(90), deg(20)))
        shapes.transform(p, loc=(-0.3, 0, 0.06))
    return _one("env_deco_crayon", P)


def deco_ruler():
    P = [shapes.rounded_box("r", (0, 0, 0.012), (2.2, 0.32, 0.024), 0.006, 1, "sticker_yellow", style.MAT_TOON)]
    for k in range(21):
        P.append(shapes.rounded_box(f"t{k}", (-1.0 + k * 0.1, -0.12 + (0.02 if k % 5 else 0.0), 0.0245), (0.008, 0.06 if k % 5 else 0.1, 0.002), 0.0, 1, "seed_shell", style.MAT_FLAT))
    return _one("env_deco_ruler", P)


def deco_shells():
    P = []
    for k in range(6):
        s = shapes.uv_sphere(f"s{k}", (0, 0, 0), (0.03, 0.06, 0.012), 8, 4, "seed_shell")
        shapes.transform(s, rot=(deg(RNG.uniform(-30, 30)), 0, RNG.uniform(0, 6.28)))
        shapes.transform(s, loc=(RNG.uniform(-0.18, 0.18), RNG.uniform(-0.18, 0.18), 0.012))
        P.append(s)
    return _one("env_deco_shells", P)


def deco_cable():
    pts = []
    for k in range(12):
        t = k / 11
        pts.append(Vector((-1.2 + 2.4 * t, 0.25 * math.sin(t * 6.0), 0.03)))
    P = []
    for i in range(len(pts) - 1):
        P.append(shapes.capsule(f"c{i}", pts[i], pts[i + 1], 0.03, 8, 2, "white", style.MAT_TOON))
    P.append(shapes.rounded_box("plug", (1.28, 0.25 * math.sin(6.0), 0.05), (0.18, 0.12, 0.09), 0.02, 2, "white", style.MAT_TOON))
    return _one("env_deco_cable", P)


def build(ctx):
    mods = [floor_wood(), floor_carpet(), floor_tile(), rug_edge(), wall(), shelf(), counter(), can(), pot(), bottles()]
    mods += books_modules()
    mods += [deco_pencil(), deco_eraser(), deco_paperball(), deco_sticky(), deco_coin(), deco_button(), deco_block(), deco_marble(), deco_dice(), deco_clip(), deco_cap(), deco_crayon(), deco_ruler(), deco_shells(), deco_cable()]
    extras = [(r.name, [r]) for r in mods]

    def layout(_ctx):
        cols = 6
        for i, r in enumerate(mods):
            r.location = Vector(((i % cols) * 2.6, -(i // cols) * 2.6, 0))

    pv = [("all", "three_quarter", {"margin": 1.0, "res": 1200}), ("all_game", "game", {"margin": 1.0, "res": 1200})]
    return ctx.Built([], previews=pv, outline=0.008, extra_exports=extras, after_export=layout)
