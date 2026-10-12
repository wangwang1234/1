"""Q / E 双槽新道具模型（2026-10-12）。每个道具一个 glb：
Q 战术道具（场上部署物，带队伍色）：gad_cam 粘附摄像头（lens 挂点）、gad_trap 捕鼠夹（张开）/ gad_trap_shut（夹上）、
gad_cover 展开式掩体（半圆防弹板，半径 0.48 朝 +Y）、gad_regen 再生力场装置、gad_guardgun 哨戒炮（head 节点可转、muzzle）、
gad_reflector 榴弹反射器、gad_holo 全息投影器、gad_signal 信号弹发射筒。
E 强化道具（手持 / 图标用）：gad_adren 肾上腺素针、gad_bubble 护盾展开器、gad_warp 随机传送装置、gad_goggles 夜视仪、gad_sonar 声呐脉冲器。
坐标：+Y 朝前，+Z 向上，底部在 z=0（单位米，和 gadget_kit 一样）。
"""
import math

import bpy
from mathutils import Vector

from lib import shapes, style
from lib.anim import deg

T = style.MAT_TOON
M = style.MAT_METAL
E = style.MAT_EMISSIVE
G = style.MAT_GLASS
TM = style.MAT_TEAM


def _root(name, objs):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH":
            shapes.bake_outline_normals(o)
    return root


def _decal(name, center, size, color, rot=(0, 0, 0)):
    return shapes.rounded_box(name, center, size, 0.0, 1, color, style.MAT_FLAT, rot=rot)


def _ring_decal(name, z, r, h, color, segs=20):
    return shapes.cylinder(name, (0, 0, z), r + 0.0008, None, h, "Z", segs, 0.0, color, style.MAT_FLAT, caps=False)


def _team_base(prefix, r, h=0.012):
    """所有部署物共用的底座：深色圆盘 + 一圈队伍色灯带（俯视角下一眼分清敌我）。"""
    return [
        shapes.cylinder(prefix + "foot", (0, 0, h * 0.5), r, r * 1.06, h, "Z", 24, 0.003, "gun_darker", M),
        shapes.torus(prefix + "teamring", (0, 0, h + 0.001), r * 0.92, 0.0045, "Z", 28, 5, "team_glow", TM),
    ]


# =========================================================================== Q 战术道具

def cam():
    """粘附摄像头：粘胶底座（黄色胶圈）+ 队伍色外壳 + 大镜头 + 红色录像灯 + 小天线。"""
    P = [
        shapes.cylinder("pad", (0, 0, 0.004), 0.034, 0.036, 0.008, "Z", 20, 0.002, "rubber", T),
        shapes.torus("glue", (0, 0, 0.007), 0.033, 0.003, "Z", 20, 4, "sticker_yellow", T),
        shapes.cylinder("neck", (0, 0, 0.018), 0.012, None, 0.02, "Z", 12, 0.002, "gun_metal", M),
        shapes.rounded_box("body", (0, 0, 0.042), (0.05, 0.056, 0.034), 0.012, 2, "team_main", TM),
        shapes.rounded_box("hood", (0, 0.012, 0.062), (0.054, 0.05, 0.008), 0.004, 1, "team_dark", TM),
        shapes.cylinder("barrel", (0, 0.032, 0.042), 0.017, None, 0.014, "Y", 18, 0.003, "gun_darker", M),
        shapes.cylinder("lens", (0, 0.04, 0.042), 0.012, None, 0.004, "Y", 16, 0.0, "lens", G),
        shapes.uv_sphere("lensglint", (0.004, 0.0425, 0.046), (0.003, 0.002, 0.003), 8, 4, "white", E),
        shapes.uv_sphere("rec", (0.018, 0.026, 0.056), (0.004, 0.004, 0.004), 8, 6, "led_red", E),
        shapes.cylinder("antenna", (-0.016, -0.018, 0.075), 0.0016, None, 0.034, "Z", 6, 0.0, "gun_steel", M),
        shapes.uv_sphere("antennatip", (-0.016, -0.018, 0.093), (0.004, 0.004, 0.004), 8, 6, "team_glow", TM),
    ]
    for k in range(3):
        P.append(_decal(f"vent{k}", (0.0255, -0.012 + k * 0.008, 0.042), (0.0012, 0.004, 0.016), "gun_darker"))
    root = _root("gad_cam", [shapes.join(P, "cam")])
    shapes.empty("lens", (0, 0.045, 0.042), parent=root, size=0.01)
    return root


def _trap_parts(shut):
    P = [
        shapes.rounded_box("board", (0, 0, 0.008), (0.1, 0.17, 0.016), 0.004, 1, "wood", T),
        _decal("grain1", (0.02, 0.0, 0.0165), (0.003, 0.15, 0.0012), "wood_dark"),
        _decal("grain2", (-0.025, 0.01, 0.0165), (0.003, 0.12, 0.0012), "wood_dark"),
        # 队伍色边条（敌人看到时也知道是谁的）
        shapes.rounded_box("teamL", (0.051, 0, 0.008), (0.004, 0.17, 0.012), 0.001, 1, "team_main", TM),
        shapes.rounded_box("teamR", (-0.051, 0, 0.008), (0.004, 0.17, 0.012), 0.001, 1, "team_main", TM),
        # 弹簧
        shapes.torus("springL", (0.03, -0.01, 0.024), 0.008, 0.0022, "X", 12, 4, "gun_steel", M),
        shapes.torus("springR", (-0.03, -0.01, 0.024), 0.008, 0.0022, "X", 12, 4, "gun_steel", M),
        shapes.cylinder("axle", (0, -0.01, 0.024), 0.0018, None, 0.08, "X", 6, 0.0, "gun_chrome", M),
        # 踏板 + 奶酪诱饵
        shapes.rounded_box("pedal", (0, 0.035, 0.019), (0.04, 0.045, 0.004), 0.002, 1, "gun_light", M),
    ]
    cheese = shapes.extrude_profile("cheese", [(0, 0), (0.026, 0), (0.0, 0.018)], 0.022, center=(0, 0.04, 0.021), plane="XY", color="sticker_yellow", mat=T)
    P.append(cheese)
    for i, (u, v) in enumerate(((0.004, 0.046), (0.012, 0.042))):
        P.append(shapes.cylinder(f"hole{i}", (u, v, 0.0325), 0.0025, None, 0.0012, "Z", 8, 0, "grenade_yellow", style.MAT_FLAT))
    # 夹杆：张开时平放在后面，夹上时翻到前面
    if shut:
        bar = [
            shapes.cylinder("barA", (0.035, 0.035, 0.026), 0.0022, None, 0.09, "Y", 6, 0.0, "gun_chrome", M),
            shapes.cylinder("barB", (-0.035, 0.035, 0.026), 0.0022, None, 0.09, "Y", 6, 0.0, "gun_chrome", M),
            shapes.cylinder("barC", (0, 0.079, 0.026), 0.0022, None, 0.07, "X", 6, 0.0, "gun_chrome", M),
        ]
    else:
        bar = [
            shapes.cylinder("barA", (0.035, -0.055, 0.019), 0.0022, None, 0.09, "Y", 6, 0.0, "gun_chrome", M),
            shapes.cylinder("barB", (-0.035, -0.055, 0.019), 0.0022, None, 0.09, "Y", 6, 0.0, "gun_chrome", M),
            shapes.cylinder("barC", (0, -0.099, 0.019), 0.0022, None, 0.07, "X", 6, 0.0, "gun_chrome", M),
            shapes.rounded_box("latch", (0, 0.008, 0.02), (0.004, 0.05, 0.003), 0.001, 1, "gun_steel", M),
        ]
    return P + bar


def trap():
    return _root("gad_trap", [shapes.join(_trap_parts(False), "trap")])


def trap_shut():
    return _root("gad_trap_shut", [shapes.join(_trap_parts(True), "trap_shut")])


def cover():
    """展开式掩体：七块弧形防弹板围成半圆（半径 0.48，朝 +Y），队伍色上沿、观察缝、撑脚。"""
    R = 0.48
    H = 0.24
    n = 7
    P = []
    for i in range(n):
        a = -math.pi * 0.5 + (i + 0.5) / n * math.pi        # 从 -90° 到 +90°，以 +Y 为中线
        x = math.sin(a) * R
        y = math.cos(a) * R
        w = 2 * R * math.sin(math.pi / n * 0.5) * 1.02
        rot = (0, 0, -a)
        P.append(shapes.rounded_box(f"plate{i}", (x, y, H * 0.5 + 0.01), (w, 0.03, H), 0.008, 2, "gun_steel", M, rot=rot))
        P.append(shapes.rounded_box(f"rim{i}", (x, y, H + 0.012), (w * 0.98, 0.034, 0.02), 0.005, 1, "team_main", TM, rot=rot))
        P.append(shapes.rounded_box(f"band{i}", (math.sin(a) * (R + 0.016), math.cos(a) * (R + 0.016), H * 0.32), (w * 0.9, 0.003, 0.018), 0.0, 1, "sticker_yellow" if i % 2 == 0 else "rubber", style.MAT_FLAT, rot=rot))
        if i in (2, 4):
            P.append(_decal(f"slit{i}", (math.sin(a) * (R + 0.016), math.cos(a) * (R + 0.016), H * 0.72), (w * 0.5, 0.003, 0.012), "gun_darker", rot=rot))
        # 背后的撑脚
        bx = math.sin(a) * (R - 0.06)
        by = math.cos(a) * (R - 0.06)
        P.append(shapes.capsule(f"strut{i}", (bx, by, 0.004), (math.sin(a) * (R - 0.012), math.cos(a) * (R - 0.012), H * 0.6), 0.006, 6, 2, "gun_dark", M))
    for s in (-1, 1):
        P.append(shapes.rounded_box(f"hinge{s}", (s * R * 0.98, 0.02, H * 0.5), (0.03, 0.04, H * 0.9), 0.006, 1, "gun_dark", M))
    # 中间的展开基座（放下的位置）
    P += _team_base("b", 0.05)
    P.append(shapes.cylinder("core", (0, 0, 0.03), 0.026, None, 0.03, "Z", 16, 0.004, "gun_metal", M))
    P.append(shapes.uv_sphere("corelight", (0, 0, 0.05), (0.012, 0.012, 0.01), 10, 6, "team_glow", TM))
    return _root("gad_cover", [shapes.join(P, "cover")])


def regen():
    """再生力场装置：三脚底座 + 立柱 + 绿色发光十字 + 顶部发射环。"""
    P = _team_base("b", 0.07) + [
        shapes.cylinder("body", (0, 0, 0.05), 0.038, 0.046, 0.07, "Z", 20, 0.006, "white", T),
        _ring_decal("band", 0.06, 0.038, 0.012, "regen_green", 20),
        shapes.cylinder("neck", (0, 0, 0.1), 0.02, None, 0.03, "Z", 14, 0.003, "gun_metal", M),
        shapes.torus("emitter", (0, 0, 0.122), 0.03, 0.006, "Z", 22, 6, "regen_green", E),
        shapes.uv_sphere("orb", (0, 0, 0.13), (0.016, 0.016, 0.016), 12, 8, "regen_green", E),
    ]
    for s in (0, 1):
        rot = (0, 0, deg(90) * s)
        P.append(shapes.rounded_box(f"crossv{s}", (0, 0, 0.05), (0.012, 0.094, 0.034), 0.002, 1, "regen_green", style.MAT_FLAT, rot=rot))
        P.append(shapes.rounded_box(f"crossh{s}", (0, 0, 0.05), (0.034, 0.094, 0.012), 0.002, 1, "regen_green", style.MAT_FLAT, rot=rot))
    for i in range(3):
        a = i / 3 * math.tau
        P.append(shapes.capsule(f"leg{i}", (math.cos(a) * 0.03, math.sin(a) * 0.03, 0.03), (math.cos(a) * 0.068, math.sin(a) * 0.068, 0.006), 0.006, 6, 2, "gun_dark", M))
    return _root("gad_regen", [shapes.join(P, "regen")])


def guardgun():
    """哨戒炮：低矮的四脚底座 + 防护挡板 + 队伍色双管炮头（head 节点可转）。"""
    base = _team_base("b", 0.075) + [
        shapes.cylinder("hub", (0, 0, 0.05), 0.03, 0.034, 0.05, "Z", 16, 0.004, "gun_dark", M),
        shapes.cylinder("turntable", (0, 0, 0.08), 0.034, None, 0.01, "Z", 20, 0.003, "gun_darker", M),
        _ring_decal("hubband", 0.045, 0.03, 0.008, "sticker_yellow", 16),
    ]
    for i in range(4):
        a = i / 4 * math.tau + math.pi / 4
        base.append(shapes.capsule(f"leg{i}", (0, 0, 0.05), (math.cos(a) * 0.085, math.sin(a) * 0.085, 0.004), 0.007, 8, 2, "gun_dark", M))
        base.append(shapes.uv_sphere(f"foot{i}", (math.cos(a) * 0.085, math.sin(a) * 0.085, 0.006), (0.012, 0.012, 0.007), 10, 6, "rubber", T))
    bm = shapes.join(base, "base")
    head = [
        shapes.rounded_box("box", (0, 0, 0), (0.08, 0.07, 0.05), 0.014, 2, "team_main", TM),
        shapes.rounded_box("shield", (0, 0.04, 0.0), (0.1, 0.014, 0.07), 0.006, 2, "gun_steel", M),
        shapes.rounded_box("shieldband", (0, 0.048, 0.022), (0.1, 0.003, 0.012), 0.0, 1, "team_dark", style.MAT_FLAT),
        shapes.rounded_box("visor", (0, 0.049, -0.008), (0.03, 0.003, 0.008), 0.001, 1, "team_glow", TM),
        shapes.rounded_box("ammo", (0, -0.042, -0.004), (0.06, 0.022, 0.034), 0.004, 1, "polymer_olive", T),
    ]
    for s in (-1, 1):
        head.append(shapes.cylinder(f"barrel{s}", (s * 0.018, 0.08, -0.004), 0.0065, None, 0.07, "Y", 12, 0.002, "gun_darker", M))
        head.append(shapes.cylinder(f"brake{s}", (s * 0.018, 0.114, -0.004), 0.009, None, 0.01, "Y", 12, 0.002, "gun_dark", M))
    hm = shapes.join(head, "head")
    hm.location = (0, 0, 0.115)
    root = _root("gad_guardgun", [bm, hm])
    shapes.empty("muzzle", (0, 0.125, 0.11), parent=root, size=0.015)
    return root


def reflector():
    """榴弹反射器：底座 + 立柱 + 三块倾斜的镜面挡板（青色发光边）+ 顶部雷达碟。"""
    P = _team_base("b", 0.07) + [
        shapes.cylinder("post", (0, 0, 0.06), 0.014, None, 0.1, "Z", 12, 0.002, "gun_metal", M),
        shapes.cylinder("collar", (0, 0, 0.03), 0.03, None, 0.03, "Z", 18, 0.004, "gun_dark", M),
        _ring_decal("collarband", 0.03, 0.03, 0.008, "team_main", 18),
        shapes.cylinder("dish", (0, 0, 0.12), 0.028, 0.012, 0.012, "Z", 18, 0.002, "gun_steel", M),
        shapes.uv_sphere("dishcore", (0, 0, 0.13), (0.008, 0.008, 0.008), 10, 6, "rail_cyan", E),
    ]
    for i in range(3):
        a = i / 3 * math.tau
        x = math.cos(a) * 0.05
        y = math.sin(a) * 0.05
        rot = (deg(-20), 0, a + math.pi / 2)
        P.append(shapes.transform(shapes.rounded_box(f"mirror{i}", (0, 0, 0), (0.06, 0.008, 0.07), 0.004, 1, "ice", G), loc=(x, y, 0.07), rot=rot))
        P.append(shapes.transform(shapes.rounded_box(f"mirroredge{i}", (0, 0, 0.037), (0.062, 0.01, 0.006), 0.002, 1, "rail_cyan", E), loc=(x, y, 0.07), rot=rot))
        P.append(shapes.capsule(f"arm{i}", (0, 0, 0.06), (x * 0.8, y * 0.8, 0.07), 0.004, 6, 2, "gun_dark", M))
    return _root("gad_reflector", [shapes.join(P, "reflector")])


def holo():
    """全息投影器（图标 / 放下时的底座）：小圆盘 + 青色光锥 + 半透明仓鼠头像。"""
    P = [
        shapes.cylinder("puck", (0, 0, 0.01), 0.04, 0.044, 0.02, "Z", 22, 0.004, "gun_darker", M),
        shapes.torus("ring", (0, 0, 0.021), 0.032, 0.004, "Z", 22, 5, "rail_cyan", E),
        shapes.cylinder("lens", (0, 0, 0.022), 0.014, None, 0.004, "Z", 14, 0.0, "rail_cyan", E),
        shapes.cylinder("cone", (0, 0, 0.06), 0.004, 0.036, 0.07, "Z", 18, 0.0, "rail_cyan", G, caps=False),
        shapes.uv_sphere("head", (0, 0, 0.12), (0.036, 0.032, 0.03), 14, 10, "rail_cyan", E),
    ]
    for s in (-1, 1):
        P.append(shapes.uv_sphere(f"ear{s}", (s * 0.026, -0.004, 0.146), (0.012, 0.006, 0.012), 10, 6, "rail_cyan", E))
        P.append(shapes.uv_sphere(f"eye{s}", (s * 0.012, 0.03, 0.124), (0.005, 0.003, 0.006), 8, 4, "gun_darker", style.MAT_FLAT))
    for k in range(3):
        P.append(shapes.torus(f"scan{k}", (0, 0, 0.1 + k * 0.016), 0.034 - k * 0.002, 0.0012, "Z", 18, 3, "white", E))
    return _root("gad_holo", [shapes.join(P, "holo")])


def signal():
    """信号弹发射筒：橙色粗筒 + 握把 + 顶部红色信号弹头（升空时由特效画）。"""
    P = [
        shapes.cylinder("tube", (0, 0, 0.07), 0.022, None, 0.12, "Z", 18, 0.004, "snack_orange", T),
        _ring_decal("band", 0.11, 0.022, 0.01, "white", 18),
        _ring_decal("band2", 0.035, 0.022, 0.01, "white", 18),
        shapes.cylinder("cap", (0, 0, 0.134), 0.024, None, 0.012, "Z", 18, 0.003, "gun_dark", M),
        shapes.uv_sphere("head", (0, 0, 0.15), (0.016, 0.016, 0.02), 12, 8, "flare_red", E),
        shapes.rounded_box("grip", (0, -0.03, 0.03), (0.022, 0.03, 0.05), 0.006, 2, "rubber", T, rot=(deg(-15), 0, 0)),
        shapes.cylinder("butt", (0, 0, 0.007), 0.023, None, 0.014, "Z", 18, 0.003, "gun_dark", M),
        _decal("label", (0, 0.0228, 0.072), (0.02, 0.0012, 0.036), "paper"),
        _decal("labelstar", (0, 0.0236, 0.076), (0.01, 0.0012, 0.01), "flare_red", rot=(0, deg(45), 0)),
    ]
    return _root("gad_signal", [shapes.join(P, "signal")])


# =========================================================================== E 强化道具

def adren():
    """肾上腺素针：玻璃针管 + 红色药液 + 推杆 + 针头 + 黄色警示标。"""
    P = [
        shapes.cylinder("barrel", (0, 0, 0.07), 0.014, None, 0.08, "Z", 16, 0.002, "glass_green", G),
        shapes.cylinder("liquid", (0, 0, 0.058), 0.0125, None, 0.054, "Z", 16, 0.0, "label_red", E),
        shapes.cylinder("flange", (0, 0, 0.112), 0.022, None, 0.006, "Z", 16, 0.002, "white", T),
        shapes.cylinder("rod", (0, 0, 0.13), 0.004, None, 0.034, "Z", 8, 0.0, "gun_steel", M),
        shapes.cylinder("thumb", (0, 0, 0.15), 0.014, None, 0.006, "Z", 14, 0.002, "white", T),
        shapes.cylinder("hub", (0, 0, 0.026), 0.009, 0.006, 0.012, "Z", 12, 0.0, "sticker_yellow", T),
        shapes.cylinder("needle", (0, 0, 0.006), 0.0012, None, 0.03, "Z", 6, 0.0, "gun_chrome", M),
        _decal("tag", (0, 0.0145, 0.075), (0.016, 0.0012, 0.03), "sticker_yellow"),
        _decal("tagbolt", (0, 0.0153, 0.075), (0.004, 0.0012, 0.018), "label_red", rot=(0, deg(20), 0)),
    ]
    for k in range(4):
        P.append(_ring_decal(f"tick{k}", 0.045 + k * 0.014, 0.014, 0.0015, "white", 16))
    return _root("gad_adren", [shapes.join(P, "adren")])


def bubble():
    """护盾展开器：手掌大小的圆盘发生器 + 六边形发射口 + 半个青色护罩（图标里看得出“护盾”）。"""
    P = [
        shapes.cylinder("puck", (0, 0, 0.012), 0.04, 0.044, 0.024, "Z", 6, 0.004, "gun_metal", M),
        shapes.cylinder("top", (0, 0, 0.026), 0.03, None, 0.006, "Z", 6, 0.002, "gun_darker", M),
        shapes.cylinder("lens", (0, 0, 0.03), 0.02, None, 0.003, "Z", 6, 0.0, "rail_cyan", E),
        shapes.torus("band", (0, 0, 0.012), 0.044, 0.003, "Z", 6, 4, "sticker_yellow", T),
    ]
    dome = shapes.uv_sphere("dome", (0, 0, 0.03), (0.07, 0.07, 0.07), 18, 10, "ice", G)
    # 只留上半球
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(dome.data)
    for v in [v for v in bm.verts if v.co.z < -0.002]:
        bm.verts.remove(v)
    bm.to_mesh(dome.data)
    bm.free()
    P.append(dome)
    for i in range(6):
        a = i / 6 * math.tau
        P.append(shapes.torus(f"hex{i}", (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.085 - 0.02 * (i % 2)), 0.012, 0.0015, "Z", 6, 3, "rail_cyan", E))
    return _root("gad_bubble", [shapes.join(P, "bubble")])


def warp():
    """随机传送装置：握把 + 两根叉形电极 + 中间旋涡（青紫发光环）。"""
    P = [
        shapes.rounded_box("grip", (0, 0, 0.03), (0.026, 0.03, 0.06), 0.008, 2, "gun_dark", M),
        shapes.rounded_box("body", (0, 0, 0.07), (0.05, 0.034, 0.03), 0.008, 2, "pilot_blue", T),
        _decal("screen", (0, 0.0175, 0.07), (0.026, 0.0012, 0.014), "screen_dark"),
        _decal("screenbar", (-0.004, 0.0183, 0.07), (0.014, 0.0012, 0.004), "rail_cyan"),
        shapes.torus("vortex", (0, 0, 0.13), 0.03, 0.005, "Y", 22, 6, "laser_pink", E),
        shapes.torus("vortex2", (0, 0, 0.13), 0.019, 0.004, "Y", 20, 6, "rail_cyan", E),
        shapes.uv_sphere("core", (0, 0, 0.13), (0.009, 0.006, 0.009), 10, 6, "white", E),
    ]
    for s in (-1, 1):
        P.append(shapes.capsule(f"prong{s}", (s * 0.018, 0, 0.082), (s * 0.034, 0, 0.13), 0.004, 6, 2, "gun_chrome", M))
    return _root("gad_warp", [shapes.join(P, "warp")])


def goggles():
    """夜视仪：两个绿色镜筒 + 中间电池盒 + 头带。"""
    P = [
        shapes.rounded_box("bridge", (0, 0, 0.04), (0.07, 0.03, 0.03), 0.01, 2, "gun_darker", M),
        shapes.rounded_box("battery", (0, -0.01, 0.064), (0.03, 0.03, 0.018), 0.005, 1, "polymer_olive", T),
        shapes.torus("strap", (0, -0.03, 0.04), 0.05, 0.005, "Z", 24, 4, "rubber", T, scale=(1.0, 0.7, 1.0)),
    ]
    for s in (-1, 1):
        P.append(shapes.cylinder(f"tube{s}", (s * 0.022, 0.03, 0.04), 0.015, 0.017, 0.04, "Y", 16, 0.003, "gun_dark", M))
        P.append(shapes.cylinder(f"lens{s}", (s * 0.022, 0.0505, 0.04), 0.012, None, 0.003, "Y", 14, 0.0, "led_green", E))
        P.append(shapes.torus(f"rim{s}", (s * 0.022, 0.05, 0.04), 0.014, 0.0022, "Y", 16, 4, "gun_steel", M))
    return _root("gad_goggles", [shapes.join(P, "goggles")])


def sonar():
    """声呐脉冲器：圆盘底座 + 雷达屏（同心圆 + 扫描扇）+ 天线。"""
    P = [
        shapes.cylinder("puck", (0, 0, 0.014), 0.046, 0.05, 0.028, "Z", 22, 0.005, "gun_metal", M),
        shapes.cylinder("screen", (0, 0, 0.029), 0.038, None, 0.004, "Z", 22, 0.0, "screen_dark", E),
        shapes.uv_sphere("ping", (0.014, 0.012, 0.032), (0.004, 0.004, 0.002), 8, 4, "led_red", E),
        shapes.cylinder("mast", (0, -0.03, 0.05), 0.003, None, 0.05, "Z", 6, 0.0, "gun_steel", M),
        shapes.uv_sphere("masttip", (0, -0.03, 0.076), (0.006, 0.006, 0.006), 8, 6, "rail_cyan", E),
    ]
    for k in range(3):
        P.append(shapes.torus(f"ring{k}", (0, 0, 0.0315), 0.01 + k * 0.011, 0.0012, "Z", 22, 3, "led_green", E))
    P.append(shapes.transform(_decal("sweep", (0.016, 0, 0.0318), (0.032, 0.004, 0.0012), "led_green"), rot=(0, 0, deg(35))))
    for i in range(3):
        a = i / 3 * math.tau + 0.4
        P.append(shapes.torus(f"wave{i}", (0, 0, 0.06 + i * 0.02), 0.03 + i * 0.012, 0.0016, "Z", 24, 3, "rail_cyan", E))
    return _root("gad_sonar", [shapes.join(P, "sonar")])


def build(ctx):
    items = [cam(), trap(), trap_shut(), cover(), regen(), guardgun(), reflector(), holo(), signal(), adren(), bubble(), warp(), goggles(), sonar()]
    extras = [(r.name, [r]) for r in items]

    def layout(_ctx):
        for i, r in enumerate(items):
            r.location = Vector(((i % 5) * 0.62, -(i // 5) * 0.62, 0))

    pv = [("all", "three_quarter", {"margin": 1.02, "res": 1200}), ("all_game", "game", {"margin": 1.05, "res": 1200})]
    ip = [("three_quarter", {"margin": 1.15, "res": 360}), ("game", {"margin": 1.3, "res": 360})]
    return ctx.Built([], previews=pv, outline=0.003, extra_exports=extras, after_export=layout, item_previews=ip)
