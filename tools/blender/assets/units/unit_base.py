"""鼠窝（基地）：纸箱搭的小屋 + 毛巾屋顶（队伍色条纹）+ 圆门洞 + 队伍色灯带 + 旗杆（flag 节点，代码摆动）
+ 门口棉花垫和瓜子堆。碰撞半径 1.1 米。节点：house / flag（含 muzzle_L、muzzle_R 两个炮口挂点，基地会交替开火）。"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg


def towel_roof(team_mat=True):
    """毛巾屋顶：两片带条纹的厚布，沿屋脊搭在纸箱上，边缘有流苏。"""
    P = []
    L = 2.2   # 沿 X（左右）
    W = 1.05  # 每片沿坡面
    th = 0.05
    for side in (-1, 1):
        cloth = shapes.rounded_box(f"towel{side}", (0, side * W * 0.42, 1.52 - 0.0), (L, W, th), 0.02, 2, "towel_cream", style.MAT_TOON, rot=(deg(-side * 30), 0, 0))
        P.append(cloth)
        for k in range(5):
            x = -0.88 + k * 0.44
            st = shapes.rounded_box(f"tstripe{side}{k}", (x, side * W * 0.42, 1.52), (0.16, W * 0.98, th * 1.15), 0.01, 1, "team_main", style.MAT_TEAM, rot=(deg(-side * 30), 0, 0))
            P.append(st)
        # 流苏
        for k in range(12):
            x = -1.0 + k * (2.0 / 11)
            fy = side * (W * 0.42 + math.cos(math.radians(30)) * W * 0.5)
            fz = 1.52 - math.sin(math.radians(30)) * W * 0.5
            P.append(shapes.capsule(f"fringe{side}{k}", (x, fy, fz), (x, fy + side * 0.02, fz - 0.07), 0.012, 6, 2, "towel_stripe", style.MAT_TOON))
    P.append(shapes.cylinder("ridge", (0, 0, 1.79), 0.05, None, 2.25, "X", 14, 0.01, "towel_stripe", style.MAT_TOON))
    return P


def build(ctx):
    P = []
    # 地基：木托盘
    P.append(shapes.rounded_box("pallet", (0, 0, 0.04), (2.3, 1.95, 0.08), 0.02, 2, "wood_dark", style.MAT_TOON))
    for k in range(5):
        P.append(shapes.rounded_box(f"plank{k}", (-0.92 + k * 0.46, 0, 0.09), (0.4, 1.95, 0.03), 0.01, 1, "wood", style.MAT_TOON))
    # 纸箱主体
    P.append(shapes.rounded_box("box", (0, 0, 0.66), (2.0, 1.6, 1.12), 0.03, 2, "cardboard", style.MAT_TOON))
    # 纸箱的封箱胶带和翻折口
    P.append(shapes.rounded_box("tape_v", (0, 0.805, 0.66), (0.22, 0.012, 1.12), 0.004, 1, "cardboard_light", style.MAT_TOON))
    P.append(shapes.rounded_box("tape_v2", (0, -0.805, 0.66), (0.22, 0.012, 1.12), 0.004, 1, "cardboard_light", style.MAT_TOON))
    for side in (-1, 1):
        P.append(shapes.rounded_box(f"flap{side}", (side * 1.0, 0, 1.24), (0.04, 1.5, 0.22), 0.01, 1, "cardboard_dark", style.MAT_TOON, rot=(0, deg(side * 25), 0)))
    # 侧面印刷（易碎/向上箭头）
    P.append(shapes.rounded_box("print1", (-0.55, -0.806, 0.75), (0.34, 0.006, 0.22), 0.0, 1, "label_red", style.MAT_FLAT))
    P.append(shapes.rounded_box("print2", (0.55, -0.806, 0.85), (0.2, 0.006, 0.3), 0.0, 1, "cardboard_dark", style.MAT_FLAT))
    # 门：朝敌方（+X），圆门洞 + 门框灯带
    door = shapes.cylinder("door", (1.005, 0, 0.5), 0.34, None, 0.02, "X", 32, 0, "seed_shell", style.MAT_FLAT)
    P.append(door)
    P.append(shapes.torus("doorglow", (1.02, 0, 0.5), 0.36, 0.03, "X", 32, 8, "team_glow", style.MAT_TEAM))
    # 窗户（发光）
    for y in (-0.5, 0.5):
        P.append(shapes.rounded_box(f"win{y}", (1.005, y, 0.92), (0.02, 0.26, 0.2), 0.01, 1, "bulb", style.MAT_EMISSIVE))
        P.append(shapes.rounded_box(f"winf{y}", (1.012, y, 0.92), (0.02, 0.3, 0.035), 0.005, 1, "wood_dark", style.MAT_TOON))
    # 灯带：箱顶边缘一圈
    for sy in (-1, 1):
        P.append(shapes.rounded_box(f"strip{sy}", (0, sy * 0.81, 1.2), (2.02, 0.04, 0.05), 0.012, 1, "team_glow", style.MAT_TEAM))
    P += towel_roof()
    # 门口：棉花垫 + 瓜子堆
    for k in range(7):
        a = k / 7 * math.tau
        P.append(shapes.quad_sphere(f"cotton{k}", (1.35 + math.cos(a) * 0.12, math.sin(a) * 0.3, 0.12), (0.14, 0.14, 0.08), 2, "white"))
    seeds = []
    for k in range(9):
        a = k * 2.4
        r = 0.08 + 0.03 * k
        sd = shapes.uv_sphere(f"seed{k}", (0, 0, 0), (0.025, 0.06, 0.018), 8, 6, "seed_shell")
        shapes.transform(sd, rot=(0, 0, a))
        shapes.transform(sd, loc=(-1.25 + math.cos(a) * r * 0.5, 0.55 + math.sin(a) * r, 0.1 + 0.02 * (k % 3)))
        seeds.append(sd)
    P += seeds
    house = shapes.join(P, "house")
    shapes.bake_outline_normals(house)
    # 旗杆 + 队伍旗
    pole = shapes.cylinder("pole", (-0.75, -0.55, 1.95), 0.025, None, 1.3, "Z", 10, 0.004, "white", style.MAT_TOON)
    ball = shapes.uv_sphere("poleball", (-0.75, -0.55, 2.62), (0.045, 0.045, 0.045), 10, 6, "sticker_yellow", style.MAT_METAL)
    poleobj = shapes.join([pole, ball], "pole")
    shapes.bake_outline_normals(poleobj)
    flag = shapes.rounded_box("flag", (0.22, 0, 0), (0.42, 0.012, 0.28), 0.006, 1, "team_main", style.MAT_TEAM)
    emblem = shapes.uv_sphere("emblem", (0.22, 0.008, 0), (0.07, 0.004, 0.07), 12, 4, "white", style.MAT_FLAT)
    flagobj = shapes.join([flag, emblem], "flag")
    shapes.bake_outline_normals(flagobj)
    flagobj.location = Vector((-0.75, -0.55, 2.4))
    root = bpy.data.objects.new("unit_base", None)
    bpy.context.scene.collection.objects.link(root)
    for o in (house, poleobj, flagobj):
        o.parent = root
    shapes.empty("muzzle_L", (1.0, -0.15, 0.96), parent=root)
    shapes.empty("muzzle_R", (1.0, 0.15, 0.96), parent=root)
    print(f"[unit_base] 三角面：{shapes.tri_count(house) + shapes.tri_count(poleobj) + shapes.tri_count(flagobj)}")

    def team(t):
        def f(_ctx):
            from lib import materials
            materials.PREVIEW["team"] = t
        return f

    pv = [("blue", "three_quarter", {"pre": team("blue"), "margin": 1.1}), ("red", "three_quarter", {"pre": team("red"), "margin": 1.1}), ("game", "game", {"pre": team("blue"), "margin": 1.2})]
    return ctx.Built([root], previews=pv, outline=0.012)
