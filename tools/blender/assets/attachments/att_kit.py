"""进化配件 8 类（瞄准镜、枪口装置、弹鼓、侧挂罐、线圈、雷达盘、战术手电、刀身光）+ 强化外观的枪上小件（金环、大手电）。

每类单独导出 att_<类>.glb，原点 = 武器上的对应挂点。路线色件用 M_path 材质（运行时按路线横向偏移 U：A 橙 / B 蓝 / C 紫），
第 9 级发光由 Godot 端调自发光强度。审阅图里把 8 类排成一排，分别渲染三种路线色和发光状态。
"""
import math

import bpy
from mathutils import Vector

from lib import materials, shapes, style
from lib.anim import deg

PATH = "M_path"


def scope():
    P = [
        shapes.cylinder("sc_body", (0, 0.004, 0.026), 0.0115, None, 0.072, "Y", 16, 0.002, "rubber", style.MAT_METAL),
        shapes.cylinder("sc_front", (0, 0.045, 0.026), 0.0145, 0.0115, 0.014, "Y", 16, 0.002, "rubber", style.MAT_METAL),
        shapes.cylinder("sc_lens", (0, 0.0525, 0.026), 0.0118, None, 0.002, "Y", 16, 0, "lens", style.MAT_GLASS),
        shapes.cylinder("sc_eye", (0, -0.036, 0.026), 0.0125, 0.0115, 0.012, "Y", 16, 0.002, "rubber", style.MAT_METAL),
        shapes.cylinder("sc_turret", (0, 0.004, 0.041), 0.006, None, 0.01, "Z", 12, 0.0015, "path_a", PATH),
        shapes.cylinder("sc_turret2", (0.0145, 0.004, 0.026), 0.0055, None, 0.008, "X", 12, 0.0015, "path_a", PATH),
    ]
    for y in (-0.018, 0.022):
        P.append(shapes.rounded_box(f"sc_mount{y}", (0, y, 0.007), (0.014, 0.008, 0.014), 0.002, 1, "gun_dark", style.MAT_METAL))
        P.append(shapes.torus(f"sc_ring{y}", (0, y, 0.026), 0.0125, 0.0028, "Y", 18, 6, "path_a", PATH))
    return shapes.join(P, "att_scope")


def muzzle():
    P = [
        shapes.cylinder("mz_body", (0, 0.016, 0), 0.0125, None, 0.032, "Y", 16, 0.002, "gun_dark", style.MAT_METAL),
        shapes.cylinder("mz_tip", (0, 0.034, 0), 0.0105, 0.0125, 0.006, "Y", 16, 0.0015, "gun_darker", style.MAT_METAL),
        shapes.torus("mz_band", (0, 0.006, 0), 0.0128, 0.003, "Y", 18, 6, "path_a", PATH),
        shapes.cylinder("mz_bore", (0, 0.0375, 0), 0.006, None, 0.0015, "Y", 10, 0, "rubber", style.MAT_FLAT),
    ]
    for k, ang in enumerate((0, math.pi)):
        for i in range(3):
            P.append(shapes.rounded_box(f"mz_vent{k}{i}", (0, 0.016 + i * 0.006, 0.0115 * math.cos(ang)), (0.009, 0.0025, 0.004), 0.0006, 1, "rubber", style.MAT_FLAT))
    return shapes.join(P, "att_muzzle")


def drum():
    P = [
        shapes.cylinder("dr_body", (0, 0, -0.03), 0.03, None, 0.024, "X", 24, 0.004, "path_a", PATH),
        shapes.cylinder("dr_cap", (0, 0, -0.03), 0.012, None, 0.0265, "X", 16, 0.002, "gun_dark", style.MAT_METAL),
        shapes.rounded_box("dr_neck", (0, 0, -0.004), (0.016, 0.02, 0.012), 0.003, 1, "gun_dark", style.MAT_METAL),
        shapes.torus("dr_rim1", (0.0122, 0, -0.03), 0.026, 0.0022, "X", 24, 6, "gun_darker", style.MAT_METAL),
        shapes.torus("dr_rim2", (-0.0122, 0, -0.03), 0.026, 0.0022, "X", 24, 6, "gun_darker", style.MAT_METAL),
    ]
    return shapes.join(P, "att_drum")


def tank():
    P = [
        shapes.cylinder("tk_body", (0, 0, 0), 0.0125, None, 0.056, "Y", 16, 0.004, "path_a", PATH),
        shapes.cylinder("tk_cap1", (0, 0.03, 0), 0.0105, None, 0.008, "Y", 14, 0.002, "gun_dark", style.MAT_METAL),
        shapes.cylinder("tk_cap2", (0, -0.03, 0), 0.0105, None, 0.008, "Y", 14, 0.002, "gun_dark", style.MAT_METAL),
        shapes.cylinder("tk_valve", (0, 0.037, 0.0), 0.004, None, 0.008, "Y", 10, 0.001, "brass", style.MAT_METAL),
        shapes.cylinder("tk_gauge", (0, 0.0, 0.0128), 0.0055, None, 0.003, "Z", 12, 0.0008, "white", style.MAT_GLASS),
        shapes.rounded_box("tk_strap1", (0, 0.016, 0), (0.0265, 0.004, 0.0265), 0.002, 1, "gun_darker", style.MAT_METAL),
        shapes.rounded_box("tk_strap2", (0, -0.016, 0), (0.0265, 0.004, 0.0265), 0.002, 1, "gun_darker", style.MAT_METAL),
    ]
    return shapes.join(P, "att_tank")


def coil():
    P = []
    for i in range(3):
        P.append(shapes.torus(f"cl_ring{i}", (0, -0.012 + i * 0.012, 0), 0.0165, 0.0036, "Y", 20, 6, "path_a", PATH))
    P.append(shapes.rounded_box("cl_rail", (0, 0.0, -0.0185), (0.006, 0.036, 0.004), 0.0015, 1, "gun_dark", style.MAT_METAL))
    return shapes.join(P, "att_coil")


def radar():
    dish = shapes.lathe("rd_dish", [(0.0, 0.0), (0.012, 0.0035), (0.021, 0.0095), (0.0225, 0.0115), (0.019, 0.0105), (0.011, 0.0045), (0.0, 0.0028)], 20, "Z", (0, 0, 0), "path_a", PATH)
    shapes.transform(dish, rot=(deg(-35), 0, 0))
    shapes.transform(dish, loc=(0, 0.0, 0.024))
    P = [
        dish,
        shapes.cylinder("rd_post", (0, 0, 0.011), 0.0028, None, 0.022, "Z", 8, 0, "gun_dark", style.MAT_METAL),
        shapes.cylinder("rd_base", (0, 0, 0.002), 0.008, None, 0.004, "Z", 12, 0.001, "gun_dark", style.MAT_METAL),
        shapes.uv_sphere("rd_tip", (0, 0.009, 0.036), (0.003, 0.003, 0.003), 8, 6, "path_a", PATH),
    ]
    return shapes.join(P, "att_radar")


def torch(big=False, colored=True):
    k = 1.35 if big else 1.0
    c = "path_a" if colored else "gun_steel"
    mat = PATH if colored else style.MAT_METAL
    P = [
        shapes.cylinder("tr_body", (0, 0.0, 0), 0.0085 * k, None, 0.036 * k, "Y", 14, 0.0015, "rubber", style.MAT_METAL),
        shapes.cylinder("tr_head", (0, 0.022 * k, 0), 0.012 * k, 0.0095 * k, 0.012 * k, "Y", 16, 0.0015, "gun_dark", style.MAT_METAL),
        shapes.cylinder("tr_lens", (0, 0.0285 * k, 0), 0.0105 * k, None, 0.0015, "Y", 16, 0, "torch_glass", style.MAT_EMISSIVE),
        shapes.torus("tr_band", (0, 0.008 * k, 0), 0.0088 * k, 0.0022, "Y", 16, 6, c, mat),
        shapes.rounded_box("tr_mount", (0, 0.0, 0.0095 * k), (0.008, 0.02, 0.006), 0.0015, 1, "gun_dark", style.MAT_METAL),
    ]
    return shapes.join(P, "att_torch_big" if big else "att_torch")


def blade():
    b = shapes.rounded_box("bl_glow", (0, 0.13, 0), (0.004, 0.2, 0.016), 0.0015, 1, "path_a", PATH)
    return shapes.join([b], "att_blade")


def gold_ring():
    return shapes.join([shapes.torus("rg", (0, 0, 0), 0.0135, 0.0032, "Y", 20, 6, "gold_ring", style.MAT_METAL)], "att_ring")


BUILDERS = [("scope", scope), ("muzzle", muzzle), ("drum", drum), ("tank", tank), ("coil", coil), ("radar", radar), ("torch", lambda: torch(False)), ("blade", blade), ("ring", gold_ring), ("torch_big", lambda: torch(True, False))]


def build(ctx):
    roots = []
    extras = []
    for i, (name, fn) in enumerate(BUILDERS):
        obj = fn()
        shapes.bake_outline_normals(obj)
        root = bpy.data.objects.new("att_" + name, None)
        bpy.context.scene.collection.objects.link(root)
        obj.parent = root
        obj.name = "att_" + name + "_mesh"
        extras.append(("att_" + name, [root]))
        roots.append(root)
        print(f"[att_{name}] 三角面：{shapes.tri_count(obj)}")
    # 预览：排成一排（不影响各自导出时的原点——导出在摆放之前完成）
    def layout(_ctx):
        for i, r in enumerate(roots):
            r.location = Vector(((i % 5) * 0.11 - 0.22, -(i // 5) * 0.13, 0))

    def path(p, glow=0.0):
        def f(_ctx):
            materials.PREVIEW["path"] = p
            materials.PREVIEW["glow"] = glow
        return f

    pv = [
        ("path_a", "three_quarter", {"pre": path(0), "margin": 1.05, "res": 720}),
        ("path_b", "three_quarter", {"pre": path(1), "margin": 1.05, "res": 720}),
        ("path_c", "three_quarter", {"pre": path(2), "margin": 1.05, "res": 720}),
        ("path_a_glow", "three_quarter", {"pre": path(0, 1.0), "margin": 1.05, "res": 720, "light": "night"}),
    ]
    b = ctx.Built([], previews=pv, outline=0.0012, extra_exports=extras, after_export=layout)
    return b
