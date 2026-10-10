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
    # ---- 分阶段破损（Godot 按血量显示）：dmg1 胶带补丁、凹痕、屋顶掀角 / dmg2 破洞、纸片翘起、毛巾滑落、窗户破 / wreck 塌成一堆
    def tape_x(name, c, axis, size=0.36):
        out = []
        for i, a in enumerate((35, -35)):
            if axis == "Y":
                out.append(shapes.rounded_box(f"{name}{i}", c, (size, 0.012, 0.09), 0.0, 1, "cardboard_light", style.MAT_FLAT, rot=(0, deg(a), 0)))
            else:
                out.append(shapes.rounded_box(f"{name}{i}", c, (0.012, size, 0.09), 0.0, 1, "cardboard_light", style.MAT_FLAT, rot=(deg(a), 0, 0)))
        return out

    D1 = []
    D1 += tape_x("tapeA", (-0.4, -0.818, 0.45), "Y")
    D1 += tape_x("tapeB", (0.35, 0.818, 0.9), "Y", 0.3)
    D1 += tape_x("tapeC", (-1.013, 0.3, 0.6), "X", 0.32)
    for i, (x, y, z) in enumerate(((0.6, -0.81, 0.4), (-0.7, 0.81, 0.85), (0.2, -0.81, 1.0))):
        D1.append(shapes.uv_sphere(f"dent{i}", (x, y, z), (0.12, 0.03, 0.09), 10, 6, "cardboard_dark", style.MAT_TOON))
    # 屋顶掀起一角 + 散落的瓜子壳
    D1.append(shapes.rounded_box("roofcorner", (0.95, 0.75, 1.42), (0.35, 0.3, 0.05), 0.015, 1, "towel_cream", style.MAT_TOON, rot=(deg(-50), deg(-20), 0)))
    for k in range(6):
        a = k * 1.9
        D1.append(shapes.transform(shapes.uv_sphere(f"shell{k}", (0, 0, 0), (0.025, 0.055, 0.012), 8, 4, "seed_shell"), loc=(1.3 + math.cos(a) * 0.4, math.sin(a) * 0.7, 0.012), rot=(0, 0, a)))
    dmg1 = shapes.join(D1, "dmg1")
    D2 = []
    for i, (c, ax, r) in enumerate((((0.5, -0.812, 0.5), "Y", 0.22), ((-0.55, 0.812, 0.7), "Y", 0.18), ((-1.012, -0.35, 0.8), "X", 0.2))):
        D2.append(shapes.cylinder(f"hole{i}", c, r, None, 0.01, ax, 12, 0, "rubber", style.MAT_FLAT))
        for j in range(5):
            b = j / 5 * math.tau
            off = (math.cos(b) * r * 0.95, 0, math.sin(b) * r * 0.95) if ax == "Y" else (0, math.cos(b) * r * 0.95, math.sin(b) * r * 0.95)
            sgn = -1 if c[1 if ax == "Y" else 0] < 0 else 1
            sh = shapes.rounded_box(f"shard{i}{j}", (0, 0, 0), (0.12, 0.012, 0.09) if ax == "Y" else (0.012, 0.12, 0.09), 0.004, 1, "cardboard", style.MAT_TOON,
                                    rot=((deg(40 * sgn), 0, b) if ax == "Y" else (0, deg(-40 * sgn), b)))
            D2.append(shapes.transform(sh, loc=(c[0] + off[0] + (0 if ax == "Y" else sgn * 0.05), c[1] + off[1] + (sgn * 0.05 if ax == "Y" else 0), c[2] + off[2])))
    # 屋顶破洞（看得见里面）+ 滑落的毛巾片 + 翘起的纸板
    # 屋顶：毛巾撕开一块，露出下面的破纸板和黑洞，撕开的毛巾片往上翻
    rx = lambda o: shapes.transform(o, loc=(-0.4, -0.44, 1.545), rot=(deg(30), 0, 0))
    D2.append(rx(shapes.rounded_box("roofunder", (0, 0, 0.0), (0.56, 0.46, 0.02), 0.01, 1, "cardboard_dark", style.MAT_TOON)))
    D2.append(rx(shapes.cylinder("roofhole", (0.04, -0.02, 0.012), 0.13, None, 0.01, "Z", 9, 0, "rubber", style.MAT_FLAT)))
    for j, (x, y, a, tilt) in enumerate(((0.0, 0.26, 0, 55), (-0.3, 0.0, 90, 50), (0.3, 0.05, -90, 45))):
        D2.append(rx(shapes.rounded_box(f"rflap{j}", (x, y, 0.06), (0.26 if j == 0 else 0.06, 0.06 if j == 0 else 0.22, 0.04), 0.01, 1, "towel_cream", style.MAT_TOON, rot=(deg(tilt) if j == 0 else 0, deg(tilt) * (-1 if j == 1 else 1) if j else 0, 0))))

    D2.append(shapes.rounded_box("slip", (0.0, -1.05, 0.55), (0.9, 0.06, 0.7), 0.02, 2, "towel_cream", style.MAT_TOON, rot=(deg(8), 0, deg(4))))
    for k in range(3):
        D2.append(shapes.rounded_box(f"slipst{k}", (-0.3 + k * 0.3, -1.087, 0.55), (0.1, 0.012, 0.66), 0.0, 1, "team_main", style.MAT_TEAM, rot=(deg(8), 0, deg(4))))
    D2.append(shapes.rounded_box("flaptorn", (-1.08, 0.5, 1.0), (0.04, 0.5, 0.3), 0.01, 1, "cardboard_dark", style.MAT_TOON, rot=(deg(20), deg(-60), 0)))
    for y in (-0.5,):
        D2.append(shapes.rounded_box(f"brokenwin{y}", (1.018, y, 0.92), (0.01, 0.26, 0.2), 0.0, 1, "rubber", style.MAT_FLAT))
    dmg2 = shapes.join(D2, "dmg2")
    # 废墟：压扁的纸箱片 + 毛巾堆 + 倒下的旗杆和旗
    W = [shapes.rounded_box("wpallet", (0, 0, 0.04), (2.3, 1.95, 0.08), 0.02, 2, "wood_dark", style.MAT_TOON)]
    for k, (x, y, w_, d_, a, tilt) in enumerate(((-0.5, -0.3, 1.2, 0.9, 10, 8), (0.5, 0.35, 1.1, 0.8, -15, -10), (0.2, -0.45, 0.8, 0.6, 35, 14), (-0.4, 0.5, 0.9, 0.5, -30, 6), (0.75, -0.2, 0.5, 0.7, 60, 20))):
        W.append(shapes.rounded_box(f"wpiece{k}", (x, y, 0.14 + k * 0.05), (w_, d_, 0.04), 0.01, 1, "cardboard" if k % 2 == 0 else "cardboard_dark", style.MAT_TOON, rot=(deg(tilt), deg(-tilt * 0.5), deg(a))))
    W.append(shapes.quad_sphere("wtowel", (-0.1, 0.0, 0.4), (0.8, 0.6, 0.2), 2, "towel_cream", style.MAT_TOON))
    for k in range(4):
        W.append(shapes.quad_sphere(f"wtowelst{k}", (-0.5 + k * 0.28, 0.0, 0.42), (0.07, 0.58, 0.19), 2, "team_main", style.MAT_TEAM))
    W.append(shapes.cylinder("wpole", (0, 0, 0), 0.025, None, 1.3, "Z", 10, 0.004, "white", style.MAT_TOON))
    shapes.transform(W[-1], loc=(0.3, 0.9, 0.12), rot=(deg(85), 0, deg(-20)))
    W.append(shapes.rounded_box("wflag", (0.75, 1.45, 0.06), (0.42, 0.28, 0.012), 0.006, 1, "team_main", style.MAT_TEAM, rot=(0, 0, deg(-20))))
    for k in range(8):
        a = k * 0.8
        W.append(shapes.transform(shapes.uv_sphere(f"wseed{k}", (0, 0, 0), (0.025, 0.06, 0.018), 8, 6, "seed_shell"), loc=(math.cos(a) * 1.1, math.sin(a) * 0.9, 0.1), rot=(0, 0, a)))
    W.append(shapes.cylinder("wsoot", (0, 0, 0.081), 1.2, None, 0.002, "Z", 24, 0, "rubber", style.MAT_FLAT))
    wreck = shapes.join(W, "wreck")
    for o in (dmg1, dmg2, wreck):
        shapes.bake_outline_normals(o)
    root = bpy.data.objects.new("unit_base", None)
    bpy.context.scene.collection.objects.link(root)
    for o in (house, poleobj, flagobj, dmg1, dmg2, wreck):
        o.parent = root
    shapes.empty("muzzle_L", (1.0, -0.15, 0.96), parent=root)
    shapes.empty("muzzle_R", (1.0, 0.15, 0.96), parent=root)
    print(f"[unit_base] 三角面：{shapes.tri_count(house) + shapes.tri_count(poleobj) + shapes.tri_count(flagobj)}")

    def team(t):
        def f(_ctx):
            from lib import materials
            materials.PREVIEW["team"] = t
        return f

    intact = lambda o: o.name not in ("dmg1", "dmg2", "wreck")
    stage1 = lambda o: o.name not in ("dmg2", "wreck")
    stage2 = lambda o: o.name != "wreck"
    dead = lambda o: o.name == "wreck"
    pv = [("blue", "three_quarter", {"pre": team("blue"), "margin": 1.1, "only": intact}), ("red", "three_quarter", {"pre": team("red"), "margin": 1.1, "only": intact}),
          ("game", "game", {"pre": team("blue"), "margin": 1.2, "only": intact}),
          ("dmg1", "three_quarter", {"pre": team("blue"), "margin": 1.1, "only": stage1}), ("dmg2", "three_quarter", {"pre": team("blue"), "margin": 1.1, "only": stage2}),
          ("dmg2_game", "game", {"pre": team("blue"), "margin": 1.2, "only": stage2}), ("wreck", "three_quarter", {"pre": team("blue"), "margin": 1.1, "only": dead})]
    return ctx.Built([root], previews=pv, outline=0.012)
