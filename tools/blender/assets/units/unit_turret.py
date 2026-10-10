"""炮台：罐头改造的炮塔。底座 = 大号罐头 + 队伍色灯带；炮塔头（head 节点，可旋转）= 小罐头 + 吸管炮管 + 瓶盖装甲 + 灯。
碰撞半径 0.34 米。节点：base / head（含 muzzle 挂点）。"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg


def build(ctx):
    # 底座：罐头（金属）+ 纸标签 + 罐口卷边 + 队伍色灯带
    B = []
    B.append(shapes.cylinder("can", (0, 0, 0.21), 0.3, None, 0.42, "Z", 40, 0.02, "can_grey", style.MAT_METAL))
    for z in (0.06, 0.12, 0.30, 0.36):
        B.append(shapes.torus(f"rib{z}", (0, 0, z), 0.302, 0.006, "Z", 40, 6, "can_grey_dark", style.MAT_METAL))
    B.append(shapes.cylinder("label", (0, 0, 0.21), 0.3035, None, 0.12, "Z", 40, 0, "paper", style.MAT_TOON))
    B.append(shapes.cylinder("labelstripe", (0, 0, 0.21), 0.305, None, 0.04, "Z", 40, 0, "label_red", style.MAT_TOON))
    B.append(shapes.torus("lip", (0, 0, 0.42), 0.296, 0.014, "Z", 40, 8, "can_grey", style.MAT_METAL))
    B.append(shapes.torus("glow", (0, 0, 0.2), 0.31, 0.012, "Z", 40, 6, "team_glow", style.MAT_TEAM))
    B.append(shapes.cylinder("lid", (0, 0, 0.43), 0.27, None, 0.02, "Z", 36, 0.006, "can_grey_dark", style.MAT_METAL))
    # 铆钉（瓶盖）点缀
    for k in range(6):
        a = k / 6 * math.tau
        B.append(shapes.cylinder(f"cap{k}", (0.304, 0, 0.33), 0.03, None, 0.012, "X", 16, 0.003, "team_dark", style.MAT_TEAM))
        shapes.transform(B[-1], rot=(0, 0, a))
    base = shapes.join(B, "base")
    # 让瓶盖朝外：重新按角度放
    shapes.bake_outline_normals(base)
    # 炮塔头：小罐头横放 + 吸管炮管 + 瞄准灯
    H = []
    H.append(shapes.cylinder("hcan", (0, -0.02, 0.0), 0.15, None, 0.26, "X", 28, 0.012, "team_main", style.MAT_TEAM))
    H.append(shapes.torus("hrim1", (0.13, -0.02, 0.0), 0.15, 0.008, "X", 28, 6, "can_grey", style.MAT_METAL))
    H.append(shapes.torus("hrim2", (-0.13, -0.02, 0.0), 0.15, 0.008, "X", 28, 6, "can_grey", style.MAT_METAL))
    H.append(shapes.cylinder("barrel", (0, 0.24, 0.02), 0.045, 0.05, 0.3, "Y", 18, 0.006, "gun_dark", style.MAT_METAL))
    H.append(shapes.torus("bring", (0, 0.38, 0.02), 0.05, 0.012, "Y", 18, 6, "team_glow", style.MAT_TEAM))
    H.append(shapes.cylinder("bstripe", (0, 0.16, 0.02), 0.052, None, 0.03, "Y", 18, 0.004, "team_light", style.MAT_TEAM))
    H.append(shapes.rounded_box("visor", (0, 0.1, 0.1), (0.18, 0.06, 0.05), 0.015, 2, "gun_dark", style.MAT_METAL))
    H.append(shapes.rounded_box("eye", (0, 0.13, 0.1), (0.12, 0.012, 0.022), 0.006, 1, "bulb", style.MAT_EMISSIVE))
    H.append(shapes.cylinder("antenna", (0.09, -0.08, 0.2), 0.006, None, 0.18, "Z", 8, 0, "gun_steel", style.MAT_METAL))
    H.append(shapes.uv_sphere("antball", (0.09, -0.08, 0.295), (0.018, 0.018, 0.018), 10, 6, "team_glow", style.MAT_TEAM))
    head = shapes.join(H, "head")
    shapes.bake_outline_normals(head)
    head.location = Vector((0, 0, 0.6))
    shapes.empty("muzzle", (0, 0.4, 0.02), parent=head)
    # ---- 分阶段破损（Godot 按血量显示）：dmg1 轻损（凹痕、撕开的标签、胶带补丁）/ dmg2 重损（破洞、翘起的铁皮、露出的电线）/ wreck 废墟（压扁的罐头）
    def on_can(name, a, z, size, color, mat=style.MAT_FLAT, r=0.3045):
        o = shapes.rounded_box(name, (r, 0, z), size, 0.0, 1, color, mat)
        return shapes.transform(o, rot=(0, 0, a))

    D1 = []
    for i, (a, z) in enumerate(((0.6, 0.27), (2.3, 0.16), (4.1, 0.31), (5.4, 0.1))):
        D1.append(shapes.transform(shapes.uv_sphere(f"dent{i}", (0.296, 0, 0), (0.012, 0.05, 0.04), 10, 6, "can_grey_dark", style.MAT_TOON), loc=(0, 0, z), rot=(0, 0, a)))
    D1.append(on_can("tear0", 1.2, 0.19, (0.004, 0.08, 0.05), "can_grey", style.MAT_METAL))
    D1.append(on_can("tear1", 3.5, 0.23, (0.004, 0.06, 0.035), "can_grey", style.MAT_METAL))
    for i, a in enumerate((2.9, 2.9)):
        D1.append(shapes.transform(shapes.rounded_box(f"tape{i}", (0.307, 0, 0), (0.004, 0.13, 0.035), 0.0, 1, "cardboard_light", style.MAT_FLAT, rot=((-1) ** i * deg(35), 0, 0)), loc=(0, 0, 0.27), rot=(0, 0, a)))
    # 顶盖：焦痕 + 交叉胶带（俯视角主要看这里）
    for i, (x, y, r) in enumerate(((0.12, 0.08, 0.07), (-0.1, -0.12, 0.05), (0.05, -0.18, 0.04))):
        D1.append(shapes.cylinder(f"scorch{i}", (x, y, 0.4415), r, None, 0.002, "Z", 12, 0, "seed_shell", style.MAT_FLAT))
    for i in range(2):
        D1.append(shapes.rounded_box(f"ltape{i}", (-0.13, 0.1, 0.443), (0.2, 0.045, 0.003), 0.0, 1, "cardboard_light", style.MAT_FLAT, rot=(0, 0, deg(40 if i == 0 else -40))))
    dmg1 = shapes.join(D1, "dmg1")
    HD1 = [shapes.rounded_box(f"htape{i}", (0, 0, 0), (0.12, 0.034, 0.003), 0.0, 1, "cardboard_light", style.MAT_FLAT, rot=(0, 0, deg(35 if i == 0 else -35))) for i in range(2)]
    for o in HD1:
        shapes.transform(o, loc=(-0.05, -0.04, 0.152))
    HD1.append(shapes.cylinder("hscorch", (0.06, 0.02, 0.1515), 0.035, None, 0.002, "Z", 10, 0, "seed_shell", style.MAT_FLAT))
    hdmg1 = shapes.join(HD1, "hdmg1")
    D2 = []
    for i, (a, z, r) in enumerate(((0.2, 0.25, 0.05), (1.9, 0.12, 0.04), (3.3, 0.3, 0.06), (4.8, 0.2, 0.045))):
        D2.append(shapes.transform(shapes.cylinder(f"hole{i}", (0.3055, 0, 0), r, None, 0.004, "X", 12, 0, "rubber", style.MAT_FLAT), loc=(0, 0, z), rot=(0, 0, a)))
        for j in range(3):
            b = j / 3 * math.tau
            petal = shapes.rounded_box(f"petal{i}{j}", (0.31 + 0.02, 0, 0), (0.004, r * 0.7, r * 0.5), 0.0, 1, "can_grey", style.MAT_METAL, rot=(b, deg(-40), 0))
            shapes.transform(petal, loc=(0, math.cos(b) * r * 0.9, math.sin(b) * r * 0.9))
            D2.append(shapes.transform(petal, loc=(0, 0, z), rot=(0, 0, a)))
    for i, (a, c) in enumerate(((0.25, "copper"), (3.35, "headband_red"), (3.3, "copper"))):
        D2.append(shapes.transform(shapes.capsule(f"wire{i}", (0.3, 0.0, 0.0), (0.38, 0.03 * (i - 1), -0.06), 0.006, 6, 2, c, style.MAT_TOON), loc=(0, 0, 0.27 if i == 0 else 0.3), rot=(0, 0, a)))
    D2.append(shapes.transform(shapes.rounded_box("liftlid", (0.2, 0, 0.0), (0.14, 0.2, 0.012), 0.004, 1, "can_grey_dark", style.MAT_METAL, rot=(0, deg(-28), 0)), loc=(0, 0, 0.47), rot=(0, 0, 1.0)))
    # 顶盖破洞（翘起的铁皮）+ 露出的电线
    D2.append(shapes.cylinder("lidhole", (-0.12, 0.12, 0.442), 0.08, None, 0.003, "Z", 14, 0, "rubber", style.MAT_FLAT))
    for j in range(5):
        b = j / 5 * math.tau
        D2.append(shapes.transform(shapes.rounded_box(f"lidpetal{j}", (0.085, 0, 0.0), (0.05, 0.04, 0.006), 0.002, 1, "can_grey", style.MAT_METAL, rot=(0, deg(-35), 0)), loc=(-0.12, 0.12, 0.45), rot=(0, 0, b)))
    for i, c in enumerate(("copper", "headband_red", "sticker_yellow")):
        D2.append(shapes.capsule(f"lwire{i}", (-0.12 + 0.02 * (i - 1), 0.12, 0.44), (-0.16 + 0.05 * i, 0.2 - 0.03 * i, 0.53 - 0.02 * i), 0.008, 6, 2, c, style.MAT_TOON))
    D2.append(shapes.cylinder("bigscorch", (0.1, -0.06, 0.4418), 0.12, None, 0.002, "Z", 14, 0, "rubber", style.MAT_FLAT))
    dmg2 = shapes.join(D2, "dmg2")
    HD2 = [shapes.cylinder("hhole", (0, 0, 0), 0.04, None, 0.004, "Z", 12, 0, "rubber", style.MAT_FLAT)]
    shapes.transform(HD2[0], loc=(0.05, -0.06, 0.151))
    for j in range(4):
        b = j / 4 * math.tau + 0.4
        HD2.append(shapes.transform(shapes.rounded_box(f"hpetal{j}", (0.045, 0, 0), (0.03, 0.026, 0.004), 0.0, 1, "team_dark", style.MAT_TEAM, rot=(0, deg(-35), 0)), loc=(0.05, -0.06, 0.156), rot=(0, 0, b)))
    HD2.append(shapes.capsule("hspring", (0.05, -0.06, 0.15), (0.07, -0.08, 0.2), 0.006, 6, 2, "gun_steel", style.MAT_METAL))
    hdmg2 = shapes.join(HD2, "hdmg2")
    W = [
        shapes.cylinder("wcan", (0, 0, 0.09), 0.33, 0.31, 0.18, "Z", 32, 0.02, "can_grey", style.MAT_METAL),
        shapes.cylinder("wlabel", (0, 0, 0.09), 0.333, 0.313, 0.06, "Z", 32, 0, "paper", style.MAT_TOON, caps=False),
        shapes.cylinder("wtop", (0, 0, 0.185), 0.3, None, 0.016, "Z", 32, 0.004, "can_grey_dark", style.MAT_METAL),
        shapes.cylinder("wburn", (0, 0, 0.195), 0.18, None, 0.004, "Z", 20, 0, "rubber", style.MAT_FLAT),
    ]
    for i in range(7):
        a = i / 7 * math.tau + 0.3
        W.append(shapes.transform(shapes.rounded_box(f"wshard{i}", (0.3, 0, 0.2), (0.012, 0.08, 0.12 + 0.03 * (i % 3)), 0.004, 1, "can_grey", style.MAT_METAL, rot=(0, deg(-25 + 15 * (i % 2)), 0)), rot=(0, 0, a)))
    W.append(shapes.transform(shapes.cylinder("whead", (0, 0, 0), 0.15, None, 0.24, "X", 24, 0.012, "team_main", style.MAT_TEAM), loc=(0.42, 0.25, 0.14), rot=(0, deg(10), deg(35))))
    W.append(shapes.transform(shapes.cylinder("wbarrel", (0, 0, 0), 0.045, None, 0.3, "Y", 14, 0.006, "gun_dark", style.MAT_METAL), loc=(-0.35, 0.3, 0.05), rot=(0, 0, deg(70))))
    for i in range(5):
        a = i * 1.3 + 0.5
        W.append(shapes.cylinder(f"wcap{i}", (math.cos(a) * (0.45 + 0.05 * i), math.sin(a) * (0.45 + 0.05 * i), 0.008), 0.03, None, 0.014, "Z", 14, 0.003, "team_dark", style.MAT_TEAM))
    wreck = shapes.join(W, "wreck")
    for o in (dmg1, dmg2, wreck, hdmg1, hdmg2):
        shapes.bake_outline_normals(o)
    # 炮塔头上的破损跟着炮塔头转
    for o in (hdmg1, hdmg2):
        o.parent = head
    root = bpy.data.objects.new("unit_turret", None)
    bpy.context.scene.collection.objects.link(root)
    base.parent = root
    head.parent = root
    for o in (dmg1, dmg2, wreck):
        o.parent = root
    print(f"[unit_turret] 三角面：{shapes.tri_count(base) + shapes.tri_count(head)}")

    def team(t):
        def f(_ctx):
            from lib import materials
            materials.PREVIEW["team"] = t
        return f

    intact = lambda o: o.name not in ("dmg1", "dmg2", "wreck", "hdmg1", "hdmg2")
    stage1 = lambda o: o.name not in ("dmg2", "wreck", "hdmg2")
    stage2 = lambda o: o.name != "wreck"
    dead = lambda o: o.name == "wreck"
    pv_extra = [("dmg2_game", "game", {"pre": team("blue"), "margin": 1.4, "only": stage2})]
    pv = [("blue", "three_quarter", {"pre": team("blue"), "margin": 1.2, "only": intact}), ("red", "three_quarter", {"pre": team("red"), "margin": 1.2, "only": intact}),
          ("game", "game", {"pre": team("blue"), "margin": 1.4, "only": intact}),
          ("dmg1", "three_quarter", {"pre": team("blue"), "margin": 1.2, "only": stage1}), ("dmg2", "three_quarter", {"pre": team("blue"), "margin": 1.2, "only": stage2}),
          ("wreck", "three_quarter", {"pre": team("blue"), "margin": 1.2, "only": dead})] + pv_extra
    return ctx.Built([root], previews=pv, outline=0.006)
