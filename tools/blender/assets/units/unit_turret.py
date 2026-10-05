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
    root = bpy.data.objects.new("unit_turret", None)
    bpy.context.scene.collection.objects.link(root)
    base.parent = root
    head.parent = root
    print(f"[unit_turret] 三角面：{shapes.tri_count(base) + shapes.tri_count(head)}")

    def team(t):
        def f(_ctx):
            from lib import materials
            materials.PREVIEW["team"] = t
        return f

    pv = [("blue", "three_quarter", {"pre": team("blue"), "margin": 1.2}), ("red", "three_quarter", {"pre": team("red"), "margin": 1.2}), ("game", "game", {"pre": team("blue"), "margin": 1.4})]
    return ctx.Built([root], previews=pv, outline=0.006)
