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


# ---------------------------------------------------------------------------
# 批次 3：细节零件（螺丝、抛壳窗、贴花、警示条纹、爪印贴纸、背带环、散热孔）
# 贴花用 MAT_FLAT（不描边），离表面 0.0008 米避免闪烁。
# ---------------------------------------------------------------------------
D = 0.0008


def screw(name, pos, axis="X", r=0.0024, color="gun_steel"):
    return shapes.cylinder(name, pos, r, None, 0.0016, axis, 8, 0.0004, color, style.MAT_METAL)


def screws(name, y, z, half_w, r=0.0024, color="gun_steel"):
    """左右两侧对称各一颗螺丝（half_w = 表面到中心的距离）。"""
    return [screw(f"{name}{s}", (s * (half_w + 0.0006), y, z), "X", r, color) for s in (-1, 1)]


def decal(name, center, size, color="sticker_yellow", rot=(0, 0, 0)):
    """平面贴花（薄片）：size 里最薄的那一维是厚度。"""
    return shapes.rounded_box(name, center, size, 0.0, 1, color, style.MAT_FLAT, rot=rot)


def top_decal(name, y, z_top, length, width, color, x=0.0):
    """贴在顶面的识别色条（顶视角最先看到）。z_top = 表面高度。"""
    return decal(name, (x, y, z_top + D), (width, length, 0.0012), color)


def side_decal(name, y, z, length, height, color, half_w, both=True):
    out = [decal(f"{name}R", (half_w + D, y, z), (0.0012, length, height), color)]
    if both:
        out.append(decal(f"{name}L", (-half_w - D, y, z), (0.0012, length, height), color))
    return out


def eject_port(name, y, z, half_w, length=0.028, height=0.012, shell=True):
    """右侧抛壳窗：深色凹口 + 一截黄铜弹壳。"""
    out = [decal(name, (half_w + D, y, z), (0.0014, length, height), "rubber")]
    if shell:
        out.append(shapes.cylinder(name + "_shell", (half_w - 0.001, y, z), height * 0.32, None, length * 0.55, "Y", 8, 0.0004, "brass", style.MAT_METAL))
    return out


def stripes(name, y0, y1, z, width, n=6, c1="sticker_yellow", c2="rubber", x=0.0, top=True, half_w=0.0):
    """警示条纹：沿 Y 交替的两色斜条（顶面或两侧）。"""
    out = []
    step = (y1 - y0) / n
    for k in range(n):
        c = c1 if k % 2 == 0 else c2
        yc = y0 + (k + 0.5) * step
        if top:
            out.append(decal(f"{name}{k}", (x, yc, z + D), (width, step * 0.98, 0.0012), c, rot=(0, 0, deg(0))))
        else:
            for s in (-1, 1):
                out.append(decal(f"{name}{k}_{s}", (s * (half_w + D), yc, z), (0.0012, step * 0.98, width), c))
    return out


def paw(name, center, normal="X", size=0.012, color="sticker_white"):
    """仓鼠爪印贴纸：一个大肉垫 + 四个小趾印。normal = 贴的面朝向（X 侧面 / Z 顶面）。"""
    cx, cy, cz = center
    out = []
    pads = [((0.0, -0.1), 0.42), ((-0.36, 0.32), 0.17), ((-0.12, 0.48), 0.17), ((0.12, 0.48), 0.17), ((0.36, 0.32), 0.17)]
    for i, ((u, v), r) in enumerate(pads):
        rr = r * size
        if normal == "X":
            pos = (cx, cy + u * size, cz + v * size)
        else:
            pos = (cx + u * size, cy + v * size, cz)
        out.append(shapes.cylinder(f"{name}{i}", pos, rr * (1.25 if i == 0 else 1.0), None, 0.0012, normal, 12, 0, color, style.MAT_FLAT))
    return out


def sling_loop(name, pos, axis="X", r=0.006):
    return shapes.torus(name, pos, r, 0.0016, axis, 12, 4, "gun_darker", style.MAT_METAL)


def vents(name, y0, z, n, pitch, half_w, w=0.003, h=0.01, both=True):
    """侧面竖向散热槽。"""
    out = []
    for k in range(n):
        y = y0 + k * pitch
        out.append(decal(f"{name}{k}R", (half_w + D, y, z), (0.0012, w, h), "rubber"))
        if both:
            out.append(decal(f"{name}{k}L", (-half_w - D, y, z), (0.0012, w, h), "rubber"))
    return out


def holes(name, y0, x_or_z, n, pitch, r, axis="X", z=0.0, surface=0.0, color="rubber"):
    """一排圆孔（散热护罩）：axis = 孔的朝向；X 时 surface 是 x 位置，Z 时 surface 是 z 位置。"""
    out = []
    for k in range(n):
        y = y0 + k * pitch
        pos = (surface, y, z) if axis == "X" else (x_or_z, y, surface)
        out.append(shapes.cylinder(f"{name}{k}", pos, r, None, 0.0014, axis, 8, 0, color, style.MAT_FLAT))
    return out


def knob(name, pos, r=0.0045, color="gun_steel"):
    return shapes.uv_sphere(name, pos, (r, r, r), 10, 6, color, style.MAT_METAL)
