"""枪械通用零件（批次 2 的 15 把新枪共用）。坐标约定同 weapon_kit：原点 = 右手握把，+Y 枪口方向，+Z 向上，+X 右。

每个函数返回 Blender 物体（或物体列表），由武器脚本收集后交给 weapon_kit.finish 合并。
尺寸单位：米。仓鼠半径 0.16，原型里的“R”就是 0.16。
"""
from lib import shapes, style
from lib.anim import deg


def grip(name="grip", y=-0.006, z=-0.02, size=(0.026, 0.028, 0.05), angle=-18, color="gun_darker", mat=style.MAT_TOON, x=0.0):
    return shapes.rounded_box(name, (x, y, z), size, 0.006, 2, color, mat, rot=(deg(angle), 0, 0))


def guard(name="guard", y=0.018, z=-0.004, r=0.012, x=0.0):
    return [
        shapes.torus(name, (x, y, z), r, 0.003, "X", 18, 6, "gun_dark", style.MAT_METAL, scale=(1.0, 1.3, 1.0)),
        shapes.rounded_box(name + "_trig", (x, y - 0.004, z - 0.002), (0.006, 0.006, 0.013), 0.002, 1, "gun_darker", style.MAT_METAL, rot=(deg(15), 0, 0)),
    ]


def box(name, center, size, color="gun_metal", mat=style.MAT_METAL, bevel=0.005, rot=(0, 0, 0), seg=2):
    return shapes.rounded_box(name, center, size, bevel, seg, color, mat, rot=rot)


def barrel(name, y0, length, z=0.03, r=0.008, color="gun_dark", x=0.0, bore=True, segs=14):
    """沿 +Y 的圆管：从 y0 到 y0+length，末端加一个暗色枪口孔。"""
    out = [shapes.cylinder(name, (x, y0 + length * 0.5, z), r, None, length, "Y", segs, min(0.0015, r * 0.2), color, style.MAT_METAL)]
    if bore:
        out.append(shapes.cylinder(name + "_bore", (x, y0 + length + 0.0008, z), r * 0.55, None, 0.002, "Y", 10, 0, "rubber", style.MAT_FLAT))
    return out


def stock(name, y_front, length, z_top=0.034, drop=0.055, width=0.028, color="wood", mat=style.MAT_TOON):
    """枪托：梯形剖面沿 X 挤出。y_front = 贴着机匣的一端，向 -Y 延伸 length。"""
    y1 = y_front
    y0 = y_front - length
    pts = [(y1, z_top), (y1, z_top - 0.034), (y0 + 0.012, z_top - drop), (y0, z_top - drop + 0.006), (y0, z_top), (y0 + 0.01, z_top + 0.004)]
    return shapes.extrude_profile(name, pts, width, plane="YZ", bevel=0.005, color=color, mat=mat)


def scope(name, y, z, length=0.09, r=0.013, lens="lens", body="rubber", x=0.0):
    out = [
        shapes.cylinder(name, (x, y, z), r, None, length, "Y", 16, 0.002, body, style.MAT_METAL),
        shapes.cylinder(name + "_bellF", (x, y + length * 0.5, z), r * 1.25, r, 0.016, "Y", 16, 0.0015, body, style.MAT_METAL),
        shapes.cylinder(name + "_lens", (x, y + length * 0.5 + 0.0085, z), r * 1.05, None, 0.002, "Y", 16, 0, lens, style.MAT_GLASS),
        shapes.cylinder(name + "_lensR", (x, y - length * 0.5 - 0.001, z), r * 0.8, None, 0.002, "Y", 12, 0, lens, style.MAT_GLASS),
    ]
    for s in (-1, 1):
        out.append(box(name + f"_ring{s}", (x, y + s * length * 0.25, z - r - 0.004), (r * 1.2, 0.01, 0.01), "gun_darker", bevel=0.002, seg=1))
    return out


def mag(name, y, z, size=(0.022, 0.03, 0.06), angle=-8, color="gun_dark"):
    return [
        box(name, (0, y, z), size, color, style.MAT_METAL, 0.003, rot=(deg(angle), 0, 0)),
        box(name + "_base", (0, y + 0.003, z - size[2] * 0.5), (size[0] + 0.004, size[1] + 0.006, 0.008), "gun_darker", style.MAT_METAL, 0.002, rot=(deg(angle), 0, 0), seg=1),
    ]


def sight(name, y, z, w=0.006, h=0.008):
    return box(name, (0, y, z), (w, 0.008, h), "gun_darker", style.MAT_METAL, 0.0015, seg=1)


def rail_top(name, y, z, length, n=5):
    out = [box(name, (0, y, z), (0.012, length, 0.004), "gun_darker", style.MAT_METAL, 0.001, seg=1)]
    for k in range(n):
        out.append(box(f"{name}{k}", (0, y - length * 0.5 + (k + 0.5) * length / n, z + 0.003), (0.014, 0.004, 0.003), "gun_dark", style.MAT_METAL, 0.0, seg=1))
    return out


def bipod(name, y, z, length=0.07, spread=0.012):
    out = []
    for s in (-1, 1):
        out.append(shapes.capsule(f"{name}{s}", (s * 0.006, y, z), (s * (0.006 + spread), y - length, z - 0.012), 0.0035, 8, 2, "gun_darker", style.MAT_METAL))
    out.append(box(name + "_clamp", (0, y, z + 0.002), (0.02, 0.012, 0.01), "gun_dark", bevel=0.002, seg=1))
    return out
