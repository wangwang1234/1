"""兵线小兵：队伍色头盔的小号仓鼠兵，比玩家小一圈。为批量渲染做成分件（无骨骼），动作在 Godot 里程序驱动：
节点 body / head / leg_L / leg_R / gun（含 muzzle 挂点）。碰撞半径 0.12 米。"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg


def build(ctx):
    S = 0.78  # 相对主角的造型比例
    # 身体 + 头合成一个圆团
    parts = [
        shapes.quad_sphere("m_body", (0, -0.004 * S, 0.085 * S), (0.09 * S, 0.088 * S, 0.08 * S), 3),
        shapes.quad_sphere("m_head", (0, 0.012 * S, 0.19 * S), (0.112 * S, 0.1 * S, 0.098 * S), 3),
        shapes.quad_sphere("m_cheeks", (0, 0.05 * S, 0.16 * S), (0.1 * S, 0.06 * S, 0.05 * S), 2),
    ]
    blob = shapes.join(parts, "m_blob")
    m = blob.modifiers.new("remesh", "REMESH")
    m.mode = "VOXEL"
    m.voxel_size = 0.005
    shapes.apply_modifiers(blob)
    m = blob.modifiers.new("smooth", "SMOOTH")
    m.factor = 0.5
    m.iterations = 4
    shapes.apply_modifiers(blob)
    hi = bpy.data.objects.new("m_hi", blob.data.copy())
    bpy.context.scene.collection.objects.link(hi)
    shapes.smooth(hi, 180)
    m = blob.modifiers.new("dec", "DECIMATE")
    m.ratio = 0.06
    shapes.apply_modifiers(blob)
    shapes.transfer_normals(blob, hi)
    bpy.data.objects.remove(hi, do_unlink=True)
    shapes.set_material(blob, style.MAT_TOON)
    shapes.paint(blob, "minion_fur")
    face = lambda c: ((c.x / (0.075 * S)) ** 2 + ((c.y - 0.09 * S) / (0.06 * S)) ** 2 + ((c.z - 0.155 * S) / (0.05 * S)) ** 2) <= 1
    belly = lambda c: ((c.x / (0.065 * S)) ** 2 + ((c.y - 0.06 * S) / (0.06 * S)) ** 2 + ((c.z - 0.075 * S) / (0.065 * S)) ** 2) <= 1
    shapes.paint_where(blob, "minion_cream", lambda c, n: (face(c) and n.y > -0.1) or (belly(c) and n.y > -0.2))
    # 头盔（队伍色）+ 帽檐 + 头灯
    helm = shapes.lathe("m_helm", [(0.104 * S, 0.215 * S), (0.106 * S, 0.235 * S), (0.098 * S, 0.262 * S), (0.078 * S, 0.287 * S), (0.045 * S, 0.302 * S), (0.0, 0.307 * S)], 24, "Z", (0, 0.004 * S, 0), "team_main", style.MAT_TEAM)
    rim = shapes.torus("m_rim", (0, 0.004 * S, 0.216 * S), 0.106 * S, 0.008 * S, "Z", 28, 6, "team_dark", style.MAT_TEAM, scale=(1, 1.08, 0.7))
    lamp = shapes.cylinder("m_lamp", (0, 0.098 * S, 0.25 * S), 0.012 * S, None, 0.012 * S, "Y", 12, 0.002, "bulb", style.MAT_EMISSIVE)
    lampbase = shapes.rounded_box("m_lampb", (0, 0.092 * S, 0.25 * S), (0.03 * S, 0.012 * S, 0.026 * S), 0.003, 1, "gear_navy", style.MAT_TOON)
    # 眼睛 + 鼻子
    eyes = []
    for s in (-1, 1):
        eyes.append(shapes.uv_sphere(f"m_eye{s}", (s * 0.04 * S, 0.098 * S, 0.19 * S), (0.017 * S, 0.008 * S, 0.022 * S), 10, 6, "eye_black", style.MAT_EYE))
        eyes.append(shapes.uv_sphere(f"m_hl{s}", (s * 0.044 * S, 0.104 * S, 0.197 * S), (0.006 * S, 0.003 * S, 0.006 * S), 6, 4, "eye_white", style.MAT_EYE))
    nose = shapes.uv_sphere("m_nose", (0, 0.112 * S, 0.165 * S), (0.012 * S, 0.008 * S, 0.009 * S), 8, 6, "nose_pink", style.MAT_GLASS)
    ears = []
    for s in (-1, 1):
        e = shapes.quad_sphere(f"m_ear{s}", (0, 0, 0.018 * S), (0.024 * S, 0.009 * S, 0.026 * S), 2, "minion_fur")
        shapes.transform(e, rot=(0, deg(s * 30), deg(-s * 15)))
        shapes.transform(e, loc=(s * 0.095 * S, -0.01 * S, 0.215 * S))
        ears.append(e)
    # 小背包
    pack = shapes.rounded_box("m_pack", (0, -0.085 * S, 0.11 * S), (0.09 * S, 0.04 * S, 0.08 * S), 0.012, 2, "gear_navy", style.MAT_TOON)
    strap = shapes.rounded_box("m_strap", (0, -0.062 * S, 0.135 * S), (0.1 * S, 0.012 * S, 0.012 * S), 0.003, 1, "gear_navy_light", style.MAT_TOON)
    # 头盔顶：浅色十字条纹 + 中心铆钉（俯视角一眼看出是兵）+ 两侧小铆钉 + 下巴带
    hdeco = []
    prof = [(0.0, 0.311), (0.047, 0.306), (0.081, 0.29), (0.102, 0.264)]
    for k in range(4):
        a = k * math.pi / 2
        for j in range(len(prof) - 1):
            (r0, z0), (r1, z1) = prof[j], prof[j + 1]
            hdeco.append(shapes.capsule(f"m_hs{k}{j}", (math.cos(a) * r0 * S, 0.004 * S + math.sin(a) * r0 * S, z0 * S), (math.cos(a) * r1 * S, 0.004 * S + math.sin(a) * r1 * S, z1 * S), 0.008 * S, 6, 2, "team_light", style.MAT_TEAM))
    hdeco.append(shapes.uv_sphere("m_hbolt", (0, 0.004 * S, 0.312 * S), (0.016 * S, 0.016 * S, 0.008 * S), 10, 6, "gun_steel", style.MAT_METAL))
    for sgn in (-1, 1):
        hdeco.append(shapes.uv_sphere(f"m_hrivet{sgn}", (sgn * 0.104 * S, 0.004 * S, 0.232 * S), (0.008 * S, 0.008 * S, 0.008 * S), 8, 4, "gun_steel", style.MAT_METAL))
        hdeco.append(shapes.capsule(f"m_chin{sgn}", (sgn * 0.1 * S, 0.01 * S, 0.22 * S), (sgn * 0.06 * S, 0.07 * S, 0.135 * S), 0.0045 * S, 6, 2, "gear_navy_light", style.MAT_TOON))
    # 背包上的队伍色灯 + 天线、腰带
    hdeco.append(shapes.rounded_box("m_packlight", (0, -0.106 * S, 0.12 * S), (0.03 * S, 0.004 * S, 0.012 * S), 0.0, 1, "team_glow", style.MAT_TEAM))
    hdeco.append(shapes.cylinder("m_antenna", (0.03 * S, -0.09 * S, 0.19 * S), 0.0025 * S, None, 0.08 * S, "Z", 6, 0.0, "gun_steel", style.MAT_METAL))
    hdeco.append(shapes.uv_sphere("m_anttip", (0.03 * S, -0.09 * S, 0.232 * S), (0.007 * S, 0.007 * S, 0.007 * S), 6, 4, "team_glow", style.MAT_TEAM))
    hdeco.append(shapes.torus("m_belt", (0, -0.004 * S, 0.06 * S), 0.086 * S, 0.008 * S, "Z", 22, 4, "gear_navy", style.MAT_TOON, scale=(1, 0.98, 0.8)))
    hdeco.append(shapes.rounded_box("m_buckle", (0, 0.083 * S, 0.06 * S), (0.022 * S, 0.006 * S, 0.016 * S), 0.002, 1, "brass", style.MAT_METAL))
    body = shapes.join([blob, helm, rim, lamp, lampbase, nose, pack, strap] + eyes + ears + hdeco, "body")
    shapes.bake_outline_normals(body)
    # 腿（脚掌）
    legs = []
    for s, nm in ((-1, "leg_L"), (1, "leg_R")):
        f = shapes.uv_sphere(nm, (0, 0.012 * S, 0.0), (0.022 * S, 0.032 * S, 0.012 * S), 10, 6, "paw")
        th = shapes.capsule(nm + "_th", (0, 0, 0.0), (0, 0.0, 0.045 * S), 0.02 * S, 8, 3, "minion_fur", style.MAT_TOON)
        leg = shapes.join([f, th], nm)
        shapes.bake_outline_normals(leg)
        leg.location = Vector((s * 0.045 * S, 0.01 * S, 0.012 * S))
        legs.append(leg)
    # 豌豆枪（爪子握着）
    gparts = [
        shapes.rounded_box("g_body", (0, 0.03, 0.0), (0.03, 0.07, 0.03), 0.008, 2, "gear_navy", style.MAT_TOON),
        shapes.cylinder("g_barrel", (0, 0.078, 0.004), 0.009, 0.011, 0.03, "Y", 12, 0.002, "team_main", style.MAT_TEAM),
        shapes.uv_sphere("g_tankball", (0, 0.012, 0.02), (0.014, 0.014, 0.014), 10, 6, "team_light", style.MAT_TEAM),
    ]
    for s in (-1, 1):
        gparts.append(shapes.uv_sphere(f"g_paw{s}", (s * 0.018, 0.012, -0.006), (0.014, 0.014, 0.012), 8, 6, "paw_light"))
    gun = shapes.join(gparts, "gun")
    shapes.bake_outline_normals(gun)
    gun.location = Vector((0.0, 0.08 * S, 0.11 * S))
    muzzle = shapes.empty("muzzle", (0, 0.095, 0.004), parent=gun)
    root = bpy.data.objects.new("unit_minion", None)
    bpy.context.scene.collection.objects.link(root)
    for o in [body, gun] + legs:
        o.parent = root
    tri = sum(shapes.tri_count(o) for o in [body, gun] + legs)
    print(f"[unit_minion] 三角面：{tri}")

    def team(t):
        def f(_ctx):
            from lib import materials
            materials.PREVIEW["team"] = t
        return f

    pv = [("blue", "three_quarter", {"pre": team("blue"), "margin": 1.4}), ("red", "three_quarter", {"pre": team("red"), "margin": 1.4}), ("game", "game", {"pre": team("blue"), "margin": 2.0}), ("front", "front", {"pre": team("blue"), "margin": 1.3})]
    return ctx.Built([root], previews=pv, outline=0.0022)
