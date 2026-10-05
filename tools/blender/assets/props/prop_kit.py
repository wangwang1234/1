"""场景互动物件（每件单独导出 prop_<名>.glb，原点在地面中心）：
纸箱掩体 box、台灯 lamp（灯泡节点 bulb）、爆炸罐 barrel（红色喷漆罐）、弹簧板 pad（顶板节点 top，弹起动画由代码驱动）、
零食箱 crate、大礼箱 gift、经验瓜子 seed / seed_big、奶酪 cheese。
尺寸按 map_layout / rules 的碰撞尺寸（1 单位 = 1 厘米）。"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg


def _root(name, objs):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH":
            shapes.bake_outline_normals(o)
    return root


def box():
    """纸箱 70×70×60：胶带十字 + 翻边 + 印刷图案 + 磨损。"""
    P = [shapes.rounded_box("b", (0, 0, 0.3), (0.7, 0.7, 0.6), 0.02, 2, "cardboard", style.MAT_TOON)]
    P.append(shapes.rounded_box("tape1", (0, 0, 0.601), (0.7, 0.12, 0.008), 0.003, 1, "cardboard_light", style.MAT_TOON))
    P.append(shapes.rounded_box("tape2", (0, 0.352, 0.45), (0.12, 0.008, 0.3), 0.003, 1, "cardboard_light", style.MAT_TOON))
    P.append(shapes.rounded_box("tape3", (0, -0.352, 0.45), (0.12, 0.008, 0.3), 0.003, 1, "cardboard_light", style.MAT_TOON))
    P.append(shapes.rounded_box("seam", (0, 0, 0.6005), (0.004, 0.7, 0.004), 0, 1, "cardboard_dark", style.MAT_FLAT))
    # 印刷：易碎玻璃杯 / 向上箭头
    P.append(shapes.rounded_box("print", (0.352, -0.12, 0.33), (0.006, 0.18, 0.16), 0.0, 1, "label_red", style.MAT_FLAT))
    for k in (-1, 1):
        P.append(shapes.rounded_box(f"arrow{k}", (-0.352, 0.1 + k * 0.05, 0.36), (0.006, 0.02, 0.12), 0.0, 1, "cardboard_dark", style.MAT_FLAT))
        P.append(shapes.rounded_box(f"arrowh{k}", (-0.352, 0.1 + k * 0.05, 0.43), (0.006, 0.05, 0.02), 0.0, 1, "cardboard_dark", style.MAT_FLAT, rot=(deg(k * 35), 0, 0)))
    # 角上的压痕
    P.append(shapes.rounded_box("dent", (0.25, 0.352, 0.12), (0.12, 0.006, 0.08), 0.0, 1, "cardboard_dark", style.MAT_FLAT))
    return _root("prop_box", [shapes.join(P, "prop_box_mesh")])


def lamp():
    """小夜灯 / 台灯：圆底座 + 弯杆 + 灯罩 + 发光灯泡（bulb 节点）。高 0.7。"""
    P = [
        shapes.cylinder("base", (0, 0, 0.025), 0.14, 0.15, 0.05, "Z", 28, 0.012, "lamp_dark", style.MAT_METAL),
        shapes.cylinder("switch", (0.08, 0.04, 0.055), 0.016, None, 0.012, "Z", 12, 0.003, "white", style.MAT_TOON),
        shapes.cylinder("pole", (0, 0, 0.32), 0.016, None, 0.56, "Z", 12, 0.003, "lamp_pole", style.MAT_METAL),
        shapes.torus("joint", (0, 0, 0.6), 0.02, 0.008, "X", 12, 6, "lamp_dark", style.MAT_METAL),
    ]
    shade = shapes.lathe("shade", [(0.17, 0.0), (0.165, 0.01), (0.1, 0.12), (0.06, 0.15), (0.035, 0.16)], 32, "Z", (0, 0, 0.53), "lamp_shade", style.MAT_TOON, cap_bottom=False)
    P.append(shade)
    P.append(shapes.torus("shaderim", (0, 0, 0.53), 0.17, 0.006, "Z", 32, 6, "lamp_dark", style.MAT_METAL))
    mesh = shapes.join(P, "prop_lamp_mesh")
    bulb = shapes.uv_sphere("bulb", (0, 0, 0.56), (0.06, 0.06, 0.055), 14, 8, "bulb", style.MAT_EMISSIVE)
    shapes.bake_outline_normals(bulb)
    r = _root("prop_lamp", [mesh, bulb])
    shapes.empty("light", (0, 0, 0.5), parent=r)
    return r


def barrel():
    """爆炸罐：红色喷漆罐（直径 0.36，高 0.44）+ 黄色警示带 + 喷嘴 + 骷髅标签。"""
    P = [
        shapes.cylinder("can", (0, 0, 0.19), 0.17, None, 0.38, "Z", 28, 0.02, "spray_red", style.MAT_METAL),
        shapes.cylinder("band", (0, 0, 0.21), 0.1725, None, 0.08, "Z", 28, 0, "spray_yellow", style.MAT_TOON),
        shapes.lathe("dome", [(0.17, 0.38), (0.15, 0.41), (0.09, 0.435), (0.04, 0.44), (0.0, 0.44)], 28, "Z", (0, 0, 0), "spray_red", style.MAT_METAL),
        shapes.cylinder("valve", (0, 0, 0.455), 0.03, None, 0.03, "Z", 14, 0.006, "white", style.MAT_TOON),
        shapes.rounded_box("nozzle", (0, 0.025, 0.47), (0.03, 0.03, 0.02), 0.006, 1, "white", style.MAT_TOON),
        shapes.torus("rimtop", (0, 0, 0.38), 0.168, 0.008, "Z", 28, 6, "gun_steel", style.MAT_METAL),
        shapes.torus("rimbot", (0, 0, 0.01), 0.168, 0.008, "Z", 28, 6, "gun_steel", style.MAT_METAL),
    ]
    # 警示标签：黑色三角 + 火焰
    lab = shapes.extrude_profile("warn", [(-0.05, 0.13), (0.05, 0.13), (0.0, 0.21)], 0.004, center=(0, 0.172, 0.0), plane="XZ", color="seed_shell")
    shapes.transform(lab, rot=(0, 0, 0))
    P.append(lab)
    return _root("prop_barrel", [shapes.join(P, "prop_barrel_mesh")])


def pad():
    """弹簧板 56×56：底座 + 黄色弹簧 + 顶板（top 节点，代码让它弹起）+ 箭头贴纸。"""
    base = [
        shapes.rounded_box("base", (0, 0, 0.03), (0.56, 0.56, 0.06), 0.02, 2, "lamp_dark", style.MAT_METAL),
        shapes.rounded_box("basestripe", (0, 0.28, 0.03), (0.5, 0.006, 0.03), 0.0, 1, "spring_yellow", style.MAT_FLAT),
    ]
    for k in range(4):
        base.append(shapes.torus(f"spring{k}", (0, 0, 0.09 + k * 0.045), 0.13, 0.018, "Z", 24, 6, "spring_yellow", style.MAT_METAL))
    base_mesh = shapes.join(base, "pad_base")
    top = [
        shapes.rounded_box("top", (0, 0, 0.0), (0.46, 0.46, 0.04), 0.015, 2, "lamp_pole", style.MAT_METAL),
        shapes.rounded_box("arrow", (0.02, 0, 0.0205), (0.26, 0.07, 0.006), 0.0, 1, "spring_yellow", style.MAT_EMISSIVE),
    ]
    for k in (-1, 1):
        top.append(shapes.rounded_box(f"ah{k}", (0.14, k * 0.05, 0.0205), (0.12, 0.03, 0.006), 0.0, 1, "spring_yellow", style.MAT_EMISSIVE, rot=(0, 0, deg(-k * 40))))
    top_mesh = shapes.join(top, "top")
    top_mesh.location = Vector((0, 0, 0.27))
    return _root("prop_pad", [base_mesh, top_mesh])


def crate():
    """零食箱（半径 0.22）：薯片包装盒 + 橙色封口 + 卡通商标 + 撕开口。"""
    P = [
        shapes.rounded_box("box", (0, 0, 0.17), (0.4, 0.4, 0.34), 0.03, 2, "snack_orange", style.MAT_TOON),
        shapes.rounded_box("band", (0, 0, 0.17), (0.405, 0.405, 0.08), 0.03, 2, "label_red", style.MAT_TOON),
        shapes.rounded_box("lid", (0, 0, 0.345), (0.41, 0.41, 0.03), 0.012, 2, "sticker_yellow", style.MAT_TOON),
        shapes.uv_sphere("logo", (0, 0.205, 0.24), (0.07, 0.006, 0.05), 14, 4, "white", style.MAT_FLAT),
        shapes.uv_sphere("logo2", (0, 0.209, 0.24), (0.045, 0.006, 0.03), 12, 4, "snack_purple", style.MAT_FLAT),
        shapes.rounded_box("tab", (0.12, -0.12, 0.365), (0.08, 0.05, 0.012), 0.004, 1, "white", style.MAT_TOON, rot=(0, 0, deg(20))),
    ]
    for k in range(3):
        P.append(shapes.uv_sphere(f"chip{k}", (-0.08 + k * 0.06, 0.05, 0.385), (0.05, 0.035, 0.012), 10, 4, "sticker_yellow", style.MAT_TOON))
    return _root("prop_crate", [shapes.join(P, "prop_crate_mesh")])


def gift():
    """大礼箱（半径 0.32）：金色礼盒 + 红丝带十字 + 蝴蝶结。"""
    P = [
        shapes.rounded_box("box", (0, 0, 0.25), (0.6, 0.6, 0.5), 0.03, 2, "sticker_yellow", style.MAT_TOON),
        shapes.rounded_box("lid", (0, 0, 0.49), (0.64, 0.64, 0.08), 0.02, 2, "sticker_yellow", style.MAT_TOON),
        shapes.rounded_box("rib1", (0, 0, 0.27), (0.655, 0.09, 0.545), 0.01, 1, "label_red", style.MAT_TOON),
        shapes.rounded_box("rib2", (0, 0, 0.27), (0.09, 0.655, 0.545), 0.01, 1, "label_red", style.MAT_TOON),
    ]
    for s in (-1, 1):
        loop = shapes.torus(f"bow{s}", (s * 0.08, 0, 0.59), 0.07, 0.022, "Y", 18, 6, "label_red", style.MAT_TOON, scale=(1.0, 1.0, 0.7))
        P.append(loop)
        tail = shapes.rounded_box(f"tail{s}", (s * 0.07, 0.07, 0.54), (0.04, 0.12, 0.012), 0.004, 1, "label_red", style.MAT_TOON, rot=(deg(20), 0, deg(s * 25)))
        P.append(tail)
    P.append(shapes.uv_sphere("knot", (0, 0, 0.59), (0.035, 0.035, 0.03), 10, 6, "label_red"))
    # 金点花纹
    for k in range(8):
        a = k / 8 * math.tau
        P.append(shapes.uv_sphere(f"dot{k}", (0.301 * (1 if k < 4 else -1), -0.2 + (k % 4) * 0.13, 0.12 + (k % 2) * 0.2), (0.004, 0.025, 0.025), 8, 4, "white", style.MAT_FLAT))
    return _root("prop_gift", [shapes.join(P, "prop_gift_mesh")])


def seed(big=False):
    """经验瓜子：黑白条纹葵花籽（big = 金色大瓜子）。"""
    k = 1.4 if big else 1.0
    body = shapes.quad_sphere("s", (0, 0, 0), (0.026 * k, 0.05 * k, 0.016 * k), 2, "sticker_yellow" if big else "seed_shell", style.MAT_EMISSIVE if big else style.MAT_TOON)
    # 收尖：前端变细
    for v in body.data.vertices:
        t = (v.co.y / (0.05 * k) + 1) * 0.5
        v.co.x *= 0.55 + 0.45 * max(0.0, math.sin(min(max(t, 0.0), 1.0) * math.pi)) ** 0.6
        v.co.z *= 0.6 + 0.4 * max(0.0, math.sin(min(max(t, 0.0), 1.0) * math.pi)) ** 0.6
    stripes = []
    for s in (-1, 0, 1):
        st = shapes.uv_sphere(f"st{s}", (s * 0.011 * k, 0, 0.0115 * k), (0.0035 * k, 0.04 * k, 0.004 * k), 8, 4, "white" if big else "seed_stripe", style.MAT_FLAT)
        stripes.append(st)
    return _root("prop_seed_big" if big else "prop_seed", [shapes.join([body] + stripes, "seed_mesh")])


def cheese():
    """奶酪（回血）：楔形 + 孔洞。"""
    w = shapes.extrude_profile("wedge", [(-0.09, 0.0), (0.09, 0.0), (0.0, 0.11)], 0.1, plane="XY", bevel=0.008, color="sticker_yellow")
    shapes.transform(w, loc=(0, -0.03, 0.05))
    holes = [shapes.uv_sphere(f"h{k}", (x, y, 0.1), (0.015, 0.015, 0.006), 10, 4, "book_yellow", style.MAT_FLAT) for k, (x, y) in enumerate([(-0.03, -0.0), (0.03, 0.02), (0.0, 0.05)])]
    return _root("prop_cheese", [shapes.join([w] + holes, "cheese_mesh")])


def frag():
    """手雷：墨绿卵形 + 黄色环 + 握片 + 拉环。"""
    P = [
        shapes.quad_sphere("body", (0, 0, 0.055), (0.046, 0.046, 0.056), 2, "polymer_olive", style.MAT_TOON),
        shapes.torus("band", (0, 0, 0.055), 0.046, 0.006, "Z", 20, 6, "sticker_yellow", style.MAT_TOON),
        shapes.cylinder("top", (0, 0, 0.118), 0.016, None, 0.022, "Z", 12, 0.003, "gun_steel", style.MAT_METAL),
        shapes.rounded_box("lever", (0.012, 0, 0.1), (0.012, 0.018, 0.07), 0.003, 1, "gun_steel", style.MAT_METAL, rot=(0, deg(-18), 0)),
        shapes.torus("ring", (-0.016, 0, 0.13), 0.012, 0.0025, "Y", 14, 4, "gun_chrome", style.MAT_METAL),
    ]
    return _root("prop_frag", [shapes.join(P, "frag_mesh")])


def build(ctx):
    items = [box(), lamp(), barrel(), pad(), crate(), gift(), seed(False), seed(True), cheese(), frag()]
    extras = [(r.name, [r]) for r in items]

    def layout(_ctx):
        for i, r in enumerate(items):
            r.location = Vector(((i % 3) * 0.95, -(i // 3) * 0.95, 0))

    pv = [("all", "three_quarter", {"margin": 1.02, "res": 900}), ("all_game", "game", {"margin": 1.05, "res": 900}), ("all_night", "three_quarter", {"margin": 1.02, "res": 900, "light": "night"})]
    return ctx.Built([], previews=pv, outline=0.004, extra_exports=extras, after_export=layout)
