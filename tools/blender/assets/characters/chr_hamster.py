"""主角仓鼠：参数化皮肤（运行时按 M_skin 偏移）、队伍色毛线帽（M_team）、可切换表情、骨骼与全套基础动作。

坐标：米；+Z 上；+Y 为面朝方向。造型参照原型 n4.js 的 buildHamParts / poseHam，按 ART_BIBLE 第 5 节加强：
大头 Q 版、头身差不多大、大眼睛两点高光、圆腮帮、短手短脚小尾巴、队伍色毛线帽 + 绒球（顶视角面积最大）。
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

from lib import anim, rig, shapes, style
from lib.anim import deg

HEAD_C = Vector((0, 0.012, 0.212))
HEAD_R = Vector((0.135, 0.122, 0.118))
BODY_C = Vector((0, -0.008, 0.098))
BODY_R = Vector((0.104, 0.104, 0.09))


def _inside(c, r):
    c = Vector(c)
    r = Vector(r)
    return lambda p: ((p.x - c.x) / r.x) ** 2 + ((p.y - c.y) / r.y) ** 2 + ((p.z - c.z) / r.z) ** 2 <= 1.0


# ---------------------------------------------------------------------------
# 造型
# ---------------------------------------------------------------------------


def build_body():
    parts = [
        shapes.quad_sphere("head", HEAD_C, HEAD_R, subdiv=4),
        shapes.quad_sphere("body", BODY_C, BODY_R, subdiv=4),
        shapes.quad_sphere("neck", (0, 0.0, 0.155), (0.1, 0.095, 0.06), subdiv=3),
        shapes.quad_sphere("cheekbase_L", (-0.08, 0.055, 0.178), (0.055, 0.05, 0.046), subdiv=3),
        shapes.quad_sphere("cheekbase_R", (0.08, 0.055, 0.178), (0.055, 0.05, 0.046), subdiv=3),
        shapes.quad_sphere("snout", (0, 0.098, 0.192), (0.052, 0.04, 0.036), subdiv=3),
        shapes.quad_sphere("haunch_L", (-0.06, -0.035, 0.06), (0.05, 0.06, 0.05), subdiv=3),
        shapes.quad_sphere("haunch_R", (0.06, -0.035, 0.06), (0.05, 0.06, 0.05), subdiv=3),
    ]
    body = shapes.join(parts, "hamster_body")
    m = body.modifiers.new("remesh", "REMESH")
    m.mode = "VOXEL"
    m.voxel_size = 0.0045
    shapes.apply_modifiers(body)
    m = body.modifiers.new("smooth", "CORRECTIVE_SMOOTH") if False else body.modifiers.new("smooth", "SMOOTH")
    m.factor = 0.5
    m.iterations = 5
    shapes.apply_modifiers(body)
    # 先留一份高精度副本，减面后把它的平滑法线转移回来（三渲二明暗交界才不会锯齿）
    hi = bpy.data.objects.new("hamster_body_hi", body.data.copy())
    bpy.context.scene.collection.objects.link(hi)
    shapes.smooth(hi, 180)
    m = body.modifiers.new("dec", "DECIMATE")
    m.ratio = 0.05
    shapes.apply_modifiers(body)
    shapes.transfer_normals(body, hi)
    bpy.data.objects.remove(hi, do_unlink=True)
    shapes.set_material(body, style.MAT_SKIN)
    shapes.paint(body, style.SKIN_FUR)
    face = _inside((0, 0.112, 0.176), (0.09, 0.075, 0.06))
    belly = _inside((0, 0.07, 0.082), (0.078, 0.07, 0.078))
    stripe = _inside((0, -0.07, 0.17), (0.026, 0.13, 0.135))
    shapes.paint_where(body, style.SKIN_STRIPE, lambda c, n: stripe(c) and n.y < 0.35)
    shapes.paint_where(body, style.SKIN_CREAM, lambda c, n: (face(c) and n.y > -0.1) or (belly(c) and n.y > -0.3))
    return body


class Surface:
    """在身体网格上找前方表面点（用于贴眼睛、鼻子、嘴）。"""

    def __init__(self, obj):
        self.obj = obj
        dg = bpy.context.evaluated_depsgraph_get()
        self.bvh = BVHTree.FromObject(obj, dg)

    def front(self, x, z, y0=0.4):
        hit = self.bvh.ray_cast(Vector((x, y0, z)), Vector((0, -1, 0)))
        if hit[0] is None:
            return Vector((x, 0.12, z)), Vector((0, 1, 0))
        return hit[0], hit[1]

    def toward(self, origin, direction):
        hit = self.bvh.ray_cast(Vector(origin), Vector(direction).normalized())
        return hit[0], hit[1]


def _orient(obj, normal, up=Vector((0, 0, 1))):
    """把在原点、朝 +Y 建模的贴片转到表面法线方向。"""
    n = normal.normalized()
    q = Vector((0, 1, 0)).rotation_difference(n)
    # 保持“上”方向尽量朝上
    up2 = q @ Vector((0, 0, 1))
    tgt = (up - n * up.dot(n)).normalized()
    if tgt.length > 1e-6 and up2.length > 1e-6:
        ang = up2.angle(tgt)
        cr = up2.cross(tgt)
        sgn = 1.0 if cr.dot(n) >= 0 else -1.0
        q = Quaternion(n, sgn * ang) @ q
    obj.data.transform(q.to_matrix().to_4x4())


def tube(name, pts, radius, color, mat=style.MAT_FLAT, seg=6, caps=True):
    """沿折线扫出细管（用于表情线条）。"""
    import bmesh

    bm = bmesh.new()
    pts = [Vector(p) for p in pts]
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = t.orthogonal().normalized()
        b = t.cross(a).normalized()
        ring = []
        for k in range(seg):
            ang = k / seg * math.tau
            ring.append(bm.verts.new(p + (a * math.cos(ang) + b * math.sin(ang)) * radius))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(seg):
            j = (k + 1) % seg
            bm.faces.new((rings[i][k], rings[i][j], rings[i + 1][j], rings[i + 1][k]))
    # 端头封口（小圆球）
    if caps:
        for p in (pts[0], pts[-1]):
            bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius, matrix=Matrix.Translation(p))
    o = shapes.obj_from_bmesh(name, bm)
    shapes.set_material(o, mat)
    shapes.paint(o, color)
    shapes.smooth(o, 180)
    return o


def on_face(surf, x, z, lift=0.0015):
    p, n = surf.front(x, z)
    return p + n * lift, n


def eye_pair(surf, name, kind):
    """kind: open / squint / blink / hurt / dead / happy"""
    objs = []
    for s in (-1, 1):
        cx, cz = s * 0.052, 0.228
        p, n = on_face(surf, cx, cz, 0.002)
        if kind in ("open", "squint"):
            hz = 0.037 if kind == "open" else 0.016
            e = shapes.uv_sphere(f"{name}_e{s}", (0, 0, 0), (0.029, 0.013, hz), 12, 8, "eye_black", style.MAT_EYE)
            _orient(e, n)
            e.data.transform(Matrix.Translation(p))
            objs.append(e)
            # 两点高光
            hp, hn = on_face(surf, cx + s * 0.010, cz + (0.014 if kind == "open" else 0.004), 0.0125)
            h1 = shapes.uv_sphere(f"{name}_h1{s}", hp, (0.0095, 0.004, 0.0095 if kind == "open" else 0.006), 8, 5, "eye_white", style.MAT_EYE)
            objs.append(h1)
            if kind == "open":
                hp2, _ = on_face(surf, cx - s * 0.012, cz - 0.016, 0.012)
                objs.append(shapes.uv_sphere(f"{name}_h2{s}", hp2, (0.005, 0.003, 0.005), 6, 4, "eye_white", style.MAT_EYE))
        else:
            if kind == "blink":
                pts2 = [(cx - 0.024, cz + 0.002), (cx - 0.012, cz - 0.008), (cx, cz - 0.011), (cx + 0.012, cz - 0.008), (cx + 0.024, cz + 0.002)]
            elif kind == "happy":
                pts2 = [(cx - 0.024, cz - 0.01), (cx - 0.012, cz + 0.006), (cx, cz + 0.011), (cx + 0.012, cz + 0.006), (cx + 0.024, cz - 0.01)]
            elif kind == "hurt":
                # >  <：尖朝内
                tip = cx - s * 0.018
                back = cx + s * 0.018
                pts2 = [(back, cz + 0.02), (tip, cz), (back, cz - 0.02)]
            else:  # dead ×
                pts2 = [(cx - 0.02, cz + 0.02), (cx + 0.02, cz - 0.02)]
            line = [on_face(surf, x, z, 0.003)[0] for (x, z) in pts2]
            objs.append(tube(f"{name}_l{s}", line, 0.0042, "eye_black", style.MAT_EYE))
            if kind == "dead":
                line2 = [on_face(surf, x, z, 0.003)[0] for (x, z) in [(cx - 0.02, cz - 0.02), (cx + 0.02, cz + 0.02)]]
                objs.append(tube(f"{name}_m{s}", line2, 0.0042, "eye_black", style.MAT_EYE))
    return shapes.join(objs, name)


def mouth(surf, name, kind):
    cz = 0.178
    if kind == "idle":
        pts = [(-0.017, cz + 0.003), (-0.0085, cz - 0.004), (0.0, cz + 0.001), (0.0085, cz - 0.004), (0.017, cz + 0.003)]
        line = [on_face(surf, x, z, 0.0025)[0] for (x, z) in pts]
        return tube(name, line, 0.0028, "mouth")
    # 张嘴：深色椭圆 + 舌头
    p, n = on_face(surf, 0.0, cz - 0.004, 0.0015)
    m = shapes.uv_sphere(name + "_m", (0, 0, 0), (0.016, 0.004, 0.013), 12, 8, "mouth", style.MAT_FLAT)
    _orient(m, n)
    m.data.transform(Matrix.Translation(p))
    p2, n2 = on_face(surf, 0.0, cz - 0.01, 0.004)
    t = shapes.uv_sphere(name + "_t", (0, 0, 0), (0.009, 0.003, 0.0055), 10, 6, "tongue", style.MAT_FLAT)
    _orient(t, n2)
    t.data.transform(Matrix.Translation(p2))
    return shapes.join([m, t], name)


def build_face(surf):
    p, n = on_face(surf, 0.0, 0.196, 0.004)
    nose = shapes.uv_sphere("nose", (0, 0, 0), (0.0155, 0.011, 0.0115), 10, 6, "nose_pink", style.MAT_GLASS)
    _orient(nose, n)
    nose.data.transform(Matrix.Translation(p))
    exprs = {}
    for k in ("open", "squint", "blink", "hurt", "dead", "happy"):
        exprs["expr_eyes_" + k] = eye_pair(surf, "expr_eyes_" + k, k)
    for k in ("idle", "open"):
        exprs["expr_mouth_" + k] = mouth(surf, "expr_mouth_" + k, k)
    # 胡须：很细的短线（顶视角基本看不到，近景加细节）
    wh = []
    for s in (-1, 1):
        for k, dz in enumerate((0.006, -0.004)):
            a, _ = on_face(surf, s * 0.036, 0.19 + dz, 0.002)
            b = a + Vector((s * 0.045, 0.006, dz * 2.2 + 0.004 * (k - 0.5)))
            wh.append(tube(f"whisker{s}{k}", [a, a.lerp(b, 0.5) + Vector((0, 0.002, 0)), b], 0.0011, "whisker", seg=4, caps=False))
    whisk = shapes.join(wh, "whiskers")
    return nose, exprs, whisk


def build_ear(side):
    outer = shapes.quad_sphere(f"ear_o{side}", (0, 0, 0.022), (0.031, 0.011, 0.036), subdiv=2)
    shapes.set_material(outer, style.MAT_SKIN)
    shapes.paint(outer, style.SKIN_FUR)
    inner = shapes.quad_sphere(f"ear_i{side}", (0, 0.006, 0.022), (0.021, 0.006, 0.025), subdiv=2, color="ear_inner", mat=style.MAT_TOON)
    ear = shapes.join([outer, inner], f"ear_{'L' if side < 0 else 'R'}")
    # 向外、略向后倾
    shapes.transform(ear, rot=(deg(-12), deg(side * 28), deg(-side * 18)))
    shapes.transform(ear, loc=(side * 0.104, -0.02, 0.268))
    return ear


def build_cheek(side):
    c = shapes.quad_sphere(f"cheek{side}", (0, 0, 0), (0.038, 0.034, 0.032), subdiv=2)
    shapes.set_material(c, style.MAT_SKIN)
    shapes.paint(c, style.SKIN_CREAM)
    blush = shapes.uv_sphere(f"blush{side}", (side * 0.014, 0.024, 0.006), (0.015, 0.006, 0.009), 10, 6, "blush", style.MAT_FLAT)
    shapes.transform(blush, rot=(0, 0, deg(side * 30)))
    ck = shapes.join([c, blush], f"cheek_{'L' if side < 0 else 'R'}")
    shapes.transform(ck, loc=(side * 0.08, 0.082, 0.176))
    return ck


def _ribbed_lathe(name, profile, ribs, amp, color, mat):
    """毛线帽：带竖向罗纹的旋转体。"""
    import bmesh

    seg = ribs * 3
    bm = bmesh.new()
    rings = []
    for (r, z) in profile:
        ring = []
        for j in range(seg):
            a = j / seg * math.tau
            rr = r * (1 + amp * math.cos(a * ribs)) if r > 1e-6 else 0.0
            ring.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        rings.append(ring)
    for i in range(len(rings) - 1):
        A, B = rings[i], rings[i + 1]
        for j in range(seg):
            k = (j + 1) % seg
            try:
                bm.faces.new((A[j], A[k], B[k], B[j]))
            except ValueError:
                pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-7)
    bm.faces.new(list(reversed(rings[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    o = shapes.obj_from_bmesh(name, bm)
    shapes.set_material(o, mat)
    shapes.paint(o, color)
    shapes.smooth(o, 180)
    return o


def build_cap():
    z0 = 0.292
    dome = _ribbed_lathe(
        "cap_dome",
        [(0.096, z0), (0.097, z0 + 0.012), (0.094, z0 + 0.03), (0.084, z0 + 0.05), (0.066, z0 + 0.066), (0.042, z0 + 0.077), (0.018, z0 + 0.082), (0.0, z0 + 0.083)],
        ribs=12, amp=0.035, color="team_knit", mat=style.MAT_TEAM)
    brim = shapes.torus("cap_brim", (0, 0, z0 + 0.004), 0.097, 0.0165, "Z", 36, 6, "team_dark", style.MAT_TEAM, scale=(1, 1, 1.25))
    # 罗纹折边：沿圆周起伏
    for v in brim.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        k = 1 + 0.05 * math.cos(a * 18)
        v.co.x *= k
        v.co.y *= k
    pom = shapes.quad_sphere("cap_pom", (0, -0.004, z0 + 0.104), (0.033, 0.033, 0.03), subdiv=2, color="white", mat=style.MAT_TOON)
    # 绒球：用确定性的起伏做毛绒感
    for v in pom.data.vertices:
        d = v.co - Vector((0, -0.004, z0 + 0.104))
        n = d.normalized()
        bump = 0.004 * (math.sin(n.x * 17.0) * math.sin(n.y * 13.0 + 1.3) * math.sin(n.z * 15.0 + 0.7))
        v.co = v.co + n * bump
    # 帽子上的小布标（队伍浅色）
    tag = shapes.rounded_box("cap_tag", (0.0, 0.094, z0 + 0.018), (0.03, 0.006, 0.016), 0.002, 1, "team_light", style.MAT_TEAM, rot=(deg(-8), 0, 0))
    cap = shapes.join([dome, brim, pom, tag], "cap")
    return cap


def build_limbs():
    arms = []
    for s, sfx in ((-1, "L"), (1, "R")):
        sh = Vector(rig.HAMSTER_BONES[f"arm_{sfx}"][0])
        el = Vector(rig.HAMSTER_BONES[f"arm_{sfx}"][1])
        wr = Vector(rig.HAMSTER_BONES[f"forearm_{sfx}"][1])
        up = shapes.capsule(f"upper_{sfx}", sh, el, 0.0205, 10, 3, style.SKIN_FUR, style.MAT_SKIN, radius1=0.018)
        lo = shapes.capsule(f"lower_{sfx}", el, wr, 0.018, 10, 3, style.SKIN_FUR, style.MAT_SKIN, radius1=0.016)
        paw = shapes.uv_sphere(f"paw_{sfx}", wr + Vector((0, 0.006, -0.002)), (0.021, 0.022, 0.018), 10, 6, color="paw_light")
        arm = shapes.join([up, lo, paw], f"arm_{sfx}")
        arms.append((arm, sfx))
    legs = []
    for s, sfx in ((-1, "L"), (1, "R")):
        hip = Vector(rig.HAMSTER_BONES[f"leg_{sfx}"][0])
        kn = Vector(rig.HAMSTER_BONES[f"leg_{sfx}"][1])
        an = Vector(rig.HAMSTER_BONES[f"shin_{sfx}"][1])
        th = shapes.capsule(f"thigh_{sfx}", hip, kn, 0.024, 10, 3, style.SKIN_FUR, style.MAT_SKIN, radius1=0.02)
        foot = shapes.uv_sphere(f"foot_{sfx}", an + Vector((0, 0.014, 0.0)), (0.025, 0.037, 0.013), 12, 6, color="paw")
        beans = [shapes.uv_sphere(f"bean{sfx}{k}", an + Vector((dx, 0.047, 0.004)), (0.0062, 0.006, 0.0055), 6, 4, "paw_light") for k, dx in enumerate((-0.012, 0.0, 0.012))]
        leg = shapes.join([th, foot] + beans, f"leg_{sfx}")
        legs.append((leg, sfx))
    tail = shapes.capsule("tail", rig.HAMSTER_BONES["tail"][0], rig.HAMSTER_BONES["tail_tip"][1], 0.017, 10, 3, style.SKIN_FUR, style.MAT_SKIN, radius1=0.012)
    return arms, legs, tail


# ---------------------------------------------------------------------------
# 姿势工具：以骨架空间（= Blender 世界轴）描述旋转/位移，再换算成骨骼局部值
# ---------------------------------------------------------------------------


class Poser:
    def __init__(self, arm):
        self.arm = arm
        self.rest = {b.name: b.matrix_local.copy() for b in arm.data.bones}
        self.len = {b.name: b.length for b in arm.data.bones}

    def local_rot(self, bone, world_q, parent_world_q=Quaternion()):
        B = self.rest[bone].to_quaternion()
        q = B.inverted() @ parent_world_q.inverted() @ world_q @ B
        return q

    def wscale(self, bone, s):
        """骨架空间（世界轴）缩放 -> 骨骼局部缩放（静止姿势都是轴对齐的，按最接近的轴对应）。"""
        if s is None:
            return None
        if isinstance(s, (int, float)):
            return (s, s, s)
        B = self.rest[bone].to_3x3()
        out = []
        for i in range(3):
            col = B.col[i]
            j = max(range(3), key=lambda k: abs(col[k]))
            out.append(s[j])
        return tuple(out)

    def P(self, bone, loc=(0, 0, 0), rot=(0, 0, 0), scale=None, parent_q=Quaternion()):
        """rot：骨架空间欧拉（X 俯仰：负值前倾；Y 侧倾：正值向右；Z 偏航：正值左转）；scale：骨架空间轴向缩放"""
        from mathutils import Euler

        wq = Euler(rot, "XYZ").to_quaternion()
        q = self.local_rot(bone, wq, parent_q)
        B = self.rest[bone].to_quaternion()
        lloc = B.inverted() @ parent_q.inverted() @ Vector(loc)
        d = {"loc": tuple(lloc), "rot": tuple(q.to_euler("XYZ"))}
        if scale is not None:
            d["scale"] = self.wscale(bone, scale)
        return d

    def ik_arm(self, side, target, pole=Vector((0, 0, -1)), parent_q=Quaternion(), pivot=None):
        """两节手臂 IK：手腕落到 target（骨架空间）。够不着时前臂沿手臂方向平移（橡皮管风格，不用非等比缩放）。"""
        a = f"arm_{side}"
        f = f"forearm_{side}"
        if pivot is None:
            pivot = self.rest["spine"].translation
        S0 = self.rest[a].translation
        S = pivot + parent_q @ (S0 - pivot)
        L1, L2 = self.len[a], self.len[f]
        T = Vector(target)
        D = T - S
        d = max(D.length, 1e-6)
        dirT = D / d
        extra = 0.0
        if d >= (L1 + L2) * 0.998:
            extra = d - (L1 + L2) * 0.998
            A = math.acos(max(-1.0, min(1.0, ((L1 * L1) + ((L1 + L2) * 0.998) ** 2 - L2 * L2) / (2 * L1 * (L1 + L2) * 0.998))))
        else:
            cosA = (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)
            A = math.acos(max(-1.0, min(1.0, cosA)))
        pl = (pole - dirT * pole.dot(dirT))
        if pl.length < 1e-6:
            pl = Vector((0, 0, -1))
        pl.normalize()
        e_dir = (dirT * math.cos(A) + pl * math.sin(A)).normalized()
        E = S + e_dir * L1 + dirT * extra
        f_dir = (T - E).normalized()
        rest_a = (self.rest[a].to_quaternion() @ Vector((0, 1, 0))).normalized()
        rest_f = (self.rest[f].to_quaternion() @ Vector((0, 1, 0))).normalized()
        rest_a_now = parent_q @ rest_a
        qa = rest_a_now.rotation_difference(e_dir) @ parent_q
        qf = (qa @ rest_f).rotation_difference(f_dir) @ qa
        Ba = self.rest[a].to_quaternion()
        Bf = self.rest[f].to_quaternion()
        la = Ba.inverted() @ parent_q.inverted() @ qa @ Ba
        lf = Bf.inverted() @ qa.inverted() @ qf @ Bf
        floc = Bf.inverted() @ qa.inverted() @ (dirT * extra)
        return {
            a: {"loc": (0, 0, 0), "rot": tuple(la.to_euler("XYZ")), "scale": (1, 1, 1)},
            f: {"loc": tuple(floc), "rot": tuple(lf.to_euler("XYZ")), "scale": (1, 1, 1)},
        }


# 武器类别的持枪参数：socket 位移/旋转（骨架空间）、左右手相对握把偏移
HOLD = {
    "pistol": {"sock_loc": (0.0, 0.035, 0.022), "sock_rot": (0, 0, 0), "R": (0.012, -0.006, -0.006), "L": (-0.004, -0.004, -0.008)},
    "rifle": {"sock_loc": (0.018, 0.0, 0.0), "sock_rot": (0, 0, 0), "R": (0.014, -0.008, -0.01), "L": (-0.02, -0.006, -0.012)},
    "shotgun": {"sock_loc": (0.016, 0.0, 0.002), "sock_rot": (0, 0, 0), "R": (0.014, -0.008, -0.01), "L": (-0.02, -0.006, -0.014)},
    # 批次 2：重武器端在腰间、发射器扛高、刀斜向上举、喷火器略低、双枪两侧各一把、光束枪同步枪
    "heavy": {"sock_loc": (0.024, -0.012, -0.032), "sock_rot": (deg(2), 0, 0), "R": (0.014, -0.008, -0.01), "L": (-0.018, -0.006, -0.012)},
    "launcher": {"sock_loc": (0.03, -0.03, 0.045), "sock_rot": (deg(3), 0, 0), "R": (0.012, -0.008, -0.012), "L": (-0.016, -0.006, -0.016)},
    "melee": {"sock_loc": (0.024, 0.006, 0.006), "sock_rot": (deg(38), 0, deg(-12)), "R": (0.0, -0.004, -0.012), "L": (0.0, -0.004, -0.012)},
    "flame": {"sock_loc": (0.018, -0.004, -0.014), "sock_rot": (0, 0, 0), "R": (0.014, -0.008, -0.01), "L": (-0.018, -0.006, -0.012)},
    "dual": {"sock_loc": (0.066, 0.004, 0.0), "sock_rot": (0, 0, 0), "R": (0.012, -0.006, -0.006), "L": (-0.012, -0.006, -0.006)},
    "beam": {"sock_loc": (0.018, 0.0, 0.004), "sock_rot": (0, 0, 0), "R": (0.014, -0.008, -0.01), "L": (-0.02, -0.006, -0.012)},
}
CLASSES = ("pistol", "rifle", "shotgun", "heavy", "launcher", "melee", "flame", "dual", "beam")


def socket_world(P, sock_loc, sock_rot, spine_q=Quaternion()):
    from mathutils import Euler

    M = P.rest["weapon_socket"]
    q = spine_q @ Euler(sock_rot, "XYZ").to_quaternion()
    # 绕脊椎根部的旋转近似：socket 静止位置随脊椎旋转
    spine_head = P.rest["spine"].translation
    pos = spine_head + spine_q @ (M.translation - spine_head) + spine_q @ Vector(sock_loc)
    return pos, q


def hold_pose(P, cls, kick=0.0, kick_up=0.0, tilt=0.0, sock_extra=(0, 0, 0), hand_extra_L=(0, 0, 0), hand_extra_R=(0, 0, 0), spine_rot=(0, 0, 0), yaw=0.0):
    """生成某武器类别的上半身姿势（手 + weapon_socket），kick = 后坐位移（米），kick_up = 枪口上扬（弧度），tilt = 侧倾（换弹）。"""
    from mathutils import Euler

    h = HOLD[cls]
    spine_q = Euler(spine_rot, "XYZ").to_quaternion()
    sl = Vector(h["sock_loc"]) + Vector((0, -kick, 0)) + Vector(sock_extra)
    sr = (h["sock_rot"][0] + kick_up, h["sock_rot"][1] + tilt, h["sock_rot"][2] + yaw)
    pos, q = socket_world(P, sl, sr, spine_q)
    out = {}
    out["spine"] = P.P("spine", rot=spine_rot)
    # weapon_socket 是 spine 的子骨骼：局部值要扣除 spine 的旋转
    out["weapon_socket"] = P.P("weapon_socket", rot=sr)
    out["weapon_socket"]["loc"] = tuple(P.rest["weapon_socket"].to_quaternion().inverted() @ Vector(sl))
    gR = pos + q @ (Vector(style.GRIP[cls]["R"]) + Vector(h["R"])) + Vector(hand_extra_R)
    gL = pos + q @ (Vector(style.GRIP[cls]["L"]) + Vector(h["L"])) + Vector(hand_extra_L)
    out.update(P.ik_arm("R", gR, pole=Vector((0.6, -0.2, -1)), parent_q=spine_q))
    out.update(P.ik_arm("L", gL, pole=Vector((-0.6, -0.2, -1)), parent_q=spine_q))
    return out


UPPER = ["spine", "weapon_socket", "arm_L", "forearm_L", "arm_R", "forearm_R"]
LOWER = ["root", "pelvis", "head", "ear_L", "ear_R", "leg_L", "shin_L", "leg_R", "shin_R", "tail", "tail_tip"]
ALL = UPPER + LOWER


def make_animations(arm):
    P = Poser(arm)
    A = anim.Action

    # ---------------- idle ----------------
    a = A(arm, "idle", loop=True, bones=LOWER)
    for f, br, tw in ((0, 0.0, 0.0), (15, 1.0, 0.0), (30, 0.0, 0.0), (40, 0.4, 1.0), (45, 0.5, 0.0), (60, 0.0, 0.0)):
        a.key(f, {
            "pelvis": P.P("pelvis", loc=(0, 0, 0.002 * br), scale=(1 + 0.012 * br, 1 + 0.012 * br, 1 + 0.025 * br)),
            "head": P.P("head", rot=(deg(-2 * br), deg(3 * math.sin(f / 60 * math.tau)), deg(4 * math.sin(f / 60 * math.tau)))),
            "ear_L": P.P("ear_L", rot=(0, deg(-14 * tw), 0)),
            "ear_R": P.P("ear_R", rot=(0, deg(6 * tw), 0)),
            "tail": P.P("tail", rot=(0, 0, deg(18 * math.sin(f / 60 * math.tau * 2)))),
        })
    a.finish()

    # ---------------- run（4 方向，10 帧一圈：两次蹦跳） ----------------
    def run(name, lean_x, lean_y, leg_axis):
        a = A(arm, name, loop=True, bones=LOWER)
        for f in range(0, 11):
            ph = f / 10.0 * math.tau
            s = math.sin(ph)
            bob = abs(math.sin(ph)) * 0.014
            sw = deg(38) * s
            legL = (-sw, 0, 0) if leg_axis == "x" else (0, sw * 0.7, 0)
            legR = (sw, 0, 0) if leg_axis == "x" else (0, -sw * 0.7, 0)
            if leg_axis == "back":
                legL, legR = (sw, 0, 0), (-sw, 0, 0)
            sq = 1.0 + 0.05 * (abs(math.cos(ph)) - 0.5)
            a.key(f, {
                "root": P.P("root", scale=(1 / math.sqrt(sq), 1 / math.sqrt(sq), sq)),
                "pelvis": P.P("pelvis", loc=(0, 0, bob), rot=(lean_x, lean_y + deg(4) * s, deg(5) * s)),
                "head": P.P("head", rot=(deg(3) * math.cos(2 * ph), 0, deg(-3) * s)),
                "ear_L": P.P("ear_L", rot=(deg(16) + deg(10) * abs(math.cos(ph)), deg(-8), 0)),
                "ear_R": P.P("ear_R", rot=(deg(16) + deg(10) * abs(math.sin(ph)), deg(8), 0)),
                "leg_L": P.P("leg_L", rot=legL),
                "shin_L": P.P("shin_L", rot=(deg(-25) * max(0, math.cos(ph)), 0, 0)),
                "leg_R": P.P("leg_R", rot=legR),
                "shin_R": P.P("shin_R", rot=(deg(-25) * max(0, -math.cos(ph)), 0, 0)),
                "tail": P.P("tail", rot=(deg(20) + deg(10) * s, 0, deg(25) * s)),
                "tail_tip": P.P("tail_tip", rot=(deg(15) * s, 0, 0)),
            }, interp="LINEAR")
        a.finish()

    run("run_fwd", deg(-9), 0, "x")
    run("run_back", deg(7), 0, "back")
    run("run_left", 0, deg(-9), "y")
    run("run_right", 0, deg(9), "y")

    # ---------------- dash_roll（0.3 秒，向前翻滚一圈） ----------------
    a = A(arm, "dash_roll", bones=ALL)
    c = Vector((0, 0, 0.15))
    from mathutils import Euler

    for f, k in ((0, 0.0), (2, 0.15), (4, 0.4), (6, 0.65), (8, 0.88), (9, 1.0)):
        ang = -k * math.tau
        q = Euler((ang, 0, 0), "XYZ").to_quaternion()
        off = c - q @ c
        curl = math.sin(min(1.0, k * 1.15) * math.pi)
        sq = 1 - 0.22 * curl
        pose = {
            "root": {"loc": tuple(P.rest["root"].to_quaternion().inverted() @ (off + Vector((0, 0, 0.03 * curl)))), "rot": tuple(P.local_rot("root", q).to_euler("XYZ")), "scale": (1 + 0.1 * curl, 1 + 0.1 * curl, sq)},
            "head": P.P("head", rot=(deg(28) * -curl, 0, 0)),
            "pelvis": P.P("pelvis", rot=(deg(-20) * curl, 0, 0)),
            "leg_L": P.P("leg_L", rot=(deg(-70) * curl, 0, 0)),
            "leg_R": P.P("leg_R", rot=(deg(-70) * curl, 0, 0)),
            "shin_L": P.P("shin_L", rot=(deg(40) * curl, 0, 0)),
            "shin_R": P.P("shin_R", rot=(deg(40) * curl, 0, 0)),
            "ear_L": P.P("ear_L", rot=(deg(40) * curl, 0, 0)),
            "ear_R": P.P("ear_R", rot=(deg(40) * curl, 0, 0)),
            "spine": P.P("spine", rot=(deg(-25) * curl, 0, 0)),
        }
        pose.update(P.ik_arm("L", Vector((-0.04, 0.1, 0.11 - 0.03 * curl)), parent_q=Euler((deg(-25) * curl, 0, 0), "XYZ").to_quaternion()))
        pose.update(P.ik_arm("R", Vector((0.04, 0.1, 0.11 - 0.03 * curl)), parent_q=Euler((deg(-25) * curl, 0, 0), "XYZ").to_quaternion()))
        pose["weapon_socket"] = P.P("weapon_socket", loc=(0, -0.02, -0.03 * curl), scale=(1 - curl * 0.999,) * 3)
        a.key(f, pose, interp="LINEAR")
    a.finish()

    # ---------------- hurt（0.3 秒） ----------------
    a = A(arm, "hurt", bones=LOWER)
    for f, k in ((0, 0.0), (2, 1.0), (5, 0.55), (9, 0.0)):
        a.key(f, {
            "root": P.P("root", scale=(1 + 0.12 * k, 1 + 0.12 * k, 1 - 0.14 * k)),
            "pelvis": P.P("pelvis", rot=(deg(10) * k, 0, 0)),
            "head": P.P("head", rot=(deg(16) * k, deg(-6) * k, deg(8) * k)),
            "ear_L": P.P("ear_L", rot=(deg(25) * k, deg(-20) * k, 0)),
            "ear_R": P.P("ear_R", rot=(deg(25) * k, deg(20) * k, 0)),
        })
    a.finish()

    # ---------------- death（0.8 秒，向后仰倒四脚朝天，停在最后一帧） ----------------
    a = A(arm, "death", bones=ALL)
    keys = ((0, 0.0, 0.0), (5, 0.25, 1.0), (12, 0.75, 0.6), (16, 1.0, 0.0), (20, 1.0, 0.25), (24, 1.0, 0.0))
    for f, k, hop in keys:
        q = Euler((deg(95) * k, 0, deg(20) * k), "XYZ").to_quaternion()
        off = c - q @ c + Vector((0, -0.05 * k, 0.04 * hop - 0.06 * k))
        pose = {
            "root": {"loc": tuple(P.rest["root"].to_quaternion().inverted() @ off), "rot": tuple(P.local_rot("root", q).to_euler("XYZ")), "scale": (1, 1, 1)},
            "head": P.P("head", rot=(deg(20) * k, 0, deg(15) * k)),
            "leg_L": P.P("leg_L", rot=(deg(-60) * k + deg(20) * hop, deg(-10), 0)),
            "leg_R": P.P("leg_R", rot=(deg(-45) * k - deg(20) * hop, deg(10), 0)),
            "ear_L": P.P("ear_L", rot=(deg(40) * k, 0, 0)),
            "ear_R": P.P("ear_R", rot=(deg(40) * k, 0, 0)),
            "tail": P.P("tail", rot=(deg(-30) * k, 0, 0)),
        }
        pose.update(P.ik_arm("L", Vector((-0.13 - 0.02 * k, 0.07, 0.17 + 0.04 * k))))
        pose.update(P.ik_arm("R", Vector((0.13 + 0.02 * k, 0.07, 0.17 + 0.04 * k))))
        pose["spine"] = P.P("spine")
        pose["weapon_socket"] = P.P("weapon_socket", loc=(0, -0.02, 0), scale=(max(0.001, 1 - k),) * 3)
        a.key(f, pose)
    a.finish()

    # ---------------- respawn_pop（0.5 秒） ----------------
    a = A(arm, "respawn_pop", bones=["root", "pelvis", "head", "ear_L", "ear_R"])
    for f, s, sz, sp in ((0, 0.05, 0.05, -0.6), (5, 1.25, 1.3, 0.0), (9, 0.9, 0.85, 0.1), (12, 1.05, 1.06, 0.0), (15, 1.0, 1.0, 0.0)):
        a.key(f, {
            "root": {"loc": (0, 0, 0), "rot": tuple(P.local_rot("root", Euler((0, 0, sp), "XYZ").to_quaternion()).to_euler("XYZ")), "scale": (s, s, sz)},
            "pelvis": P.P("pelvis"),
            "head": P.P("head", rot=(deg(-8) * (1 - s), 0, 0)),
            "ear_L": P.P("ear_L", rot=(deg(30) * (1.1 - s), 0, 0)),
            "ear_R": P.P("ear_R", rot=(deg(30) * (1.1 - s), 0, 0)),
        })
    a.finish()

    # ---------------- victory（循环蹦跳 + 举手） ----------------
    a = A(arm, "victory", loop=True, bones=ALL)
    for f in range(0, 21, 2):
        ph = f / 20.0 * math.tau
        jump = max(0.0, math.sin(ph)) * 0.06
        land = max(0.0, -math.sin(ph))
        pose = {
            "root": P.P("root", loc=(0, 0, jump), scale=(1 + 0.08 * land, 1 + 0.08 * land, 1 - 0.12 * land)),
            "pelvis": P.P("pelvis", rot=(deg(-4), 0, deg(8) * math.sin(ph))),
            "head": P.P("head", rot=(deg(-10), deg(10) * math.sin(ph), 0)),
            "ear_L": P.P("ear_L", rot=(deg(-20) * jump / 0.06 + deg(15) * land, 0, 0)),
            "ear_R": P.P("ear_R", rot=(deg(-20) * jump / 0.06 + deg(15) * land, 0, 0)),
            "leg_L": P.P("leg_L", rot=(deg(-25) * jump / 0.06, 0, 0)),
            "leg_R": P.P("leg_R", rot=(deg(-25) * jump / 0.06, 0, 0)),
            "tail": P.P("tail", rot=(0, 0, deg(30) * math.sin(ph * 2))),
            "spine": P.P("spine"),
            "weapon_socket": P.P("weapon_socket", loc=(0.0, -0.02, 0.17), rot=(deg(70), 0, 0)),
        }
        wave = deg(15) * math.sin(ph * 2)
        pose.update(P.ik_arm("L", Vector((-0.06, 0.07, 0.29 + 0.02 * math.sin(ph * 2)))))
        pose.update(P.ik_arm("R", Vector((0.06, 0.07, 0.29 - 0.02 * math.sin(ph * 2)))))
        a.key(f, pose)
    a.finish()

    # ---------------- 持枪姿势 / 开火 / 换弹（按武器类别） ----------------
    for cls in CLASSES:
        a = A(arm, f"hold_{cls}", loop=True, bones=UPPER)
        for f, br in ((0, 0.0), (30, 1.0), (60, 0.0)):
            a.key(f, hold_pose(P, cls, sock_extra=(0, 0, 0.002 * br), spine_rot=(deg(-1.5) * br, 0, 0)))
        a.finish()

    # 开火：枪向后坐、枪口上扬，手跟着走
    fire = {
        "pistol": ((0, 0, 0), (1, 0.018, deg(16)), (3, 0.006, deg(6)), (6, 0, 0)),
        "rifle": ((0, 0, 0), (1, 0.014, deg(5)), (2, 0.006, deg(2)), (4, 0, 0)),
        "shotgun": ((0, 0, 0), (1, 0.03, deg(14)), (4, 0.012, deg(5)), (8, 0, 0)),
        "heavy": ((0, 0, 0), (1, 0.008, deg(2)), (2, 0.003, deg(1)), (3, 0, 0)),
        "launcher": ((0, 0, 0), (1, 0.04, deg(10)), (5, 0.015, deg(4)), (10, 0, 0)),
        "flame": ((0, 0, 0), (1, 0.004, deg(1)), (2, 0, 0)),
        "dual": ((0, 0, 0), (1, 0.014, deg(10)), (4, 0, 0)),
        "beam": ((0, 0, 0), (1, 0.012, deg(4)), (3, 0.004, deg(1)), (6, 0, 0)),
    }
    for cls, keys in fire.items():
        a = A(arm, f"fire_{cls}", bones=UPPER)
        for (f, kick, up) in keys:
            a.key(f, hold_pose(P, cls, kick=kick, kick_up=up, spine_rot=(deg(4) * (kick / 0.03), 0, 0)))
        if cls == "shotgun":
            # 泵动：左手前后拉一次（0.3～0.55 秒）
            for (f, pump) in ((9, 0.0), (12, -0.035), (14, -0.035), (17, 0.0)):
                a.key(f, hold_pose(P, cls, hand_extra_L=(0, pump, 0)))
        a.finish()

    # 换弹（统一 30 帧 = 1 秒，Godot 按实际换弹时间缩放播放速度）
    a = A(arm, "reload_pistol", bones=UPPER)
    for f, tilt, down, hand in ((0, 0, 0, 0), (6, deg(-35), 0.02, 0), (12, deg(-40), 0.025, 1), (18, deg(-40), 0.025, 0.2), (24, deg(-10), 0.005, 0), (30, 0, 0, 0)):
        a.key(f, hold_pose(P, "pistol", tilt=tilt, sock_extra=(0, 0, -down), hand_extra_L=(0, -0.01 * hand, -0.05 * hand)))
    a.finish()
    a = A(arm, "reload_rifle", bones=UPPER)
    for f, tilt, up, hand in ((0, 0, 0, 0), (5, deg(-25), deg(10), 0), (10, deg(-30), deg(12), 1.0), (15, deg(-30), deg(12), 1.0), (20, deg(-28), deg(10), 0.0), (25, deg(-5), deg(-4), 0), (30, 0, 0, 0)):
        a.key(f, hold_pose(P, "rifle", tilt=tilt, kick_up=up, hand_extra_L=(0.0, -0.05 * hand, -0.06 * hand)))
    a.finish()
    # 批次 2 新类别的换弹：按相近的老类别做（重武器 / 光束 / 喷火 = 步枪式；双枪 = 手枪式；发射器 = 往后装填）
    for cls in ("heavy", "flame", "beam"):
        a = A(arm, f"reload_{cls}", bones=UPPER)
        for f, tilt, up, hand in ((0, 0, 0, 0), (5, deg(-25), deg(10), 0), (10, deg(-30), deg(12), 1.0), (15, deg(-30), deg(12), 1.0), (20, deg(-28), deg(10), 0.0), (25, deg(-5), deg(-4), 0), (30, 0, 0, 0)):
            a.key(f, hold_pose(P, cls, tilt=tilt, kick_up=up, hand_extra_L=(0.0, -0.05 * hand, -0.06 * hand)))
        a.finish()
    a = A(arm, "reload_dual", bones=UPPER)
    for f, down, hand in ((0, 0, 0), (6, 0.03, 0), (12, 0.035, 1), (18, 0.035, 1), (24, 0.008, 0), (30, 0, 0)):
        a.key(f, hold_pose(P, "dual", kick_up=deg(-30) * (down / 0.035), sock_extra=(0, 0, -down), hand_extra_L=(0.01 * hand, 0, -0.03 * hand), hand_extra_R=(-0.01 * hand, 0, -0.03 * hand)))
    a.finish()
    a = A(arm, "reload_launcher", bones=UPPER)
    for f, up, hand in ((0, 0, 0), (6, deg(-12), 0), (12, deg(-15), 1.0), (20, deg(-15), 1.0), (26, deg(-5), 0.3), (30, 0, 0)):
        a.key(f, hold_pose(P, "launcher", kick_up=up, hand_extra_L=(0.0, -0.09 * hand, 0.02 * hand)))
    a.finish()
    # 刀没有弹匣：换弹动作做成一个挽刀花（备用，正常不会触发）
    a = A(arm, "reload_melee", bones=UPPER)
    for f, sp in ((0, 0), (8, 1), (16, 2), (24, 3), (30, 4)):
        a.key(f, hold_pose(P, "melee", tilt=deg(90) * sp))
    a.finish()
    # 武士刀两向挥砍（8 帧 ≈ 0.27 秒）：举到一侧 → 向前横扫 → 甩到另一侧 → 收回
    for name, sgn in (("slash_a", 1.0), ("slash_b", -1.0)):
        a = A(arm, name, bones=UPPER)
        for f, yw, up, tw in ((0, 0, 0, 0), (1, 55, 15, 1), (3, 0, -40, 0), (5, -65, -45, -1), (8, 0, 0, 0)):
            a.key(f, hold_pose(P, "melee", kick_up=deg(up), yaw=deg(yw) * sgn, sock_extra=(0.015 * sgn * tw, 0.02 if f == 3 else 0.0, 0), spine_rot=(0, 0, deg(14) * sgn * tw)))
        a.finish()
    # 扔道具：左手后摆再甩出去（右手照常持枪）
    a = A(arm, "throw", bones=UPPER)
    for f, k in ((0, 0.0), (3, -1.0), (6, 1.0), (9, 0.3), (12, 0.0)):
        pose = hold_pose(P, "pistol")
        if k != 0.0:
            tgt = Vector((-0.07, 0.02 + 0.09 * k, 0.2 + 0.05 * max(0.0, -k) + 0.03 * max(0.0, k)))
            pose.update(P.ik_arm("L", tgt, pole=Vector((-0.6, -0.2, -1))))
        a.key(f, pose)
    a.finish()

    a = A(arm, "reload_shotgun", bones=UPPER)
    fr = [(0, 0.0, 0.0)]
    for i in range(3):
        b = 4 + i * 8
        fr += [(b, 1.0, 0.0), (b + 3, 1.0, 1.0), (b + 6, 1.0, 0.0)]
    fr += [(30, 0.0, 0.0)]
    for f, roll, push in fr:
        a.key(f, hold_pose(P, "shotgun", tilt=deg(25) * roll, hand_extra_L=(0.0, -0.03 + 0.03 * push - 0.03 * (1 - roll), -0.03 * roll)))
    a.finish()


# ---------------------------------------------------------------------------


def build(ctx):
    body = build_body()
    surf = Surface(body)
    nose, exprs, whisk = build_face(surf)
    earL = build_ear(-1)
    earR = build_ear(1)
    ckL = build_cheek(-1)
    ckR = build_cheek(1)
    cap = build_cap()
    arms, legs, tail = build_limbs()

    arm = rig.build_armature("hamster_rig", rig.HAMSTER_BONES)

    def body_w(co):
        z = co.z
        sm = lambda a, b, x: max(0.0, min(1.0, (x - a) / (b - a))) ** 2 * (3 - 2 * max(0.0, min(1.0, (x - a) / (b - a))))
        wh = sm(0.15, 0.19, z)
        ws = sm(0.075, 0.14, z) * (1 - wh)
        wp = max(0.0, 1 - wh - ws)
        w = {"head": wh, "spine": ws, "pelvis": wp}
        # 尾根附近一点点
        if co.y < -0.08 and z < 0.1:
            w["tail"] = 0.15
        return w

    rig.bind(body, arm, body_w)
    for o in [nose, whisk, cap] + list(exprs.values()):
        rig.bind(o, arm, {"head": 1.0})
    rig.bind(earL, arm, {"ear_L": 1.0})
    rig.bind(earR, arm, {"ear_R": 1.0})
    rig.bind(ckL, arm, {"cheek_L": 1.0})
    rig.bind(ckR, arm, {"cheek_R": 1.0})
    for (o, sfx) in arms:
        B = rig.HAMSTER_BONES
        rig.bind(o, arm, rig.envelope_weights({f"arm_{sfx}": (B[f"arm_{sfx}"][0], B[f"arm_{sfx}"][1]), f"forearm_{sfx}": (B[f"forearm_{sfx}"][0], B[f"forearm_{sfx}"][1])}, 0.012, 4.0))
    for (o, sfx) in legs:
        B = rig.HAMSTER_BONES
        rig.bind(o, arm, rig.envelope_weights({f"leg_{sfx}": (B[f"leg_{sfx}"][0], B[f"leg_{sfx}"][1]), f"shin_{sfx}": (B[f"shin_{sfx}"][0], B[f"shin_{sfx}"][1])}, 0.012, 4.0))
    B = rig.HAMSTER_BONES
    rig.bind(tail, arm, rig.envelope_weights({"tail": (B["tail"][0], B["tail"][1]), "tail_tip": (B["tail_tip"][0], B["tail_tip"][1])}, 0.01, 4.0))

    meshes = [body, nose, whisk, cap, earL, earR, ckL, ckR, tail] + [o for o, _ in arms] + [o for o, _ in legs] + list(exprs.values())
    for o in meshes:
        shapes.bake_outline_normals(o)
    shown = [o for o in meshes if not o.name.startswith("expr_") or o.name in ("expr_eyes_open", "expr_mouth_idle")]
    tris = sum(shapes.tri_count(o) for o in shown)
    print(f"[chr_hamster] 三角面（显示中的部件）：{tris}  " + ", ".join(f"{o.name}={shapes.tri_count(o)}" for o in shown))

    make_animations(arm)

    # 预览：带上武器（若已生成），多皮肤 / 两队 / 动作关键帧
    from lib import materials

    def attach_weapon(wid):
        p = os.path.join(ctx.root, "game", "assets", "models", "weapons", f"wpn_{wid}.glb")
        for o in list(bpy.data.objects):
            if o.get("preview_weapon"):
                bpy.data.objects.remove(o, do_unlink=True)
        if not os.path.exists(p):
            return None
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=p)
        new = [o for o in bpy.data.objects if o not in before]
        roots = [o for o in new if o.parent is None]
        for o in new:
            o["preview_weapon"] = True
        for r in roots:
            r.parent = arm
            r.parent_type = "BONE"
            r.parent_bone = "weapon_socket"
            bm = arm.data.bones["weapon_socket"].matrix_local
            # 骨骼父子关系以骨尾为原点；回到骨头位置并对齐骨架轴
            r.matrix_parent_inverse = (Matrix.Translation(Vector((0, arm.data.bones["weapon_socket"].length, 0)))).inverted() @ bm.to_quaternion().to_matrix().to_4x4().inverted()
            r.location = (0, 0, 0)
            r.rotation_mode = "QUATERNION"
            r.rotation_quaternion = (1, 0, 0, 0)
        materials.setup_preview_materials()
        materials.add_preview_outlines([o for o in new if o.type == "MESH"], 0.0024)
        return new

    def set_action(name, frame):
        act = bpy.data.actions.get(name)
        arm.animation_data.action = act
        bpy.context.scene.frame_set(frame)

    def show_expr(eyes="open", mouth="idle"):
        for k, o in exprs.items():
            o.hide_render = not (k == f"expr_eyes_{eyes}" or k == f"expr_mouth_{mouth}")

    def pre_factory(weapon=None, action=None, frame=0, skin=0, team="blue", eyes="open", mouth="idle"):
        def f(_ctx):
            materials.PREVIEW["skin"] = skin
            materials.PREVIEW["team"] = team
            if weapon is not None:
                attach_weapon(weapon)
            if action:
                set_action(action, frame)
            show_expr(eyes, mouth)
        return f

    def visible(o):
        if o.name.startswith("expr_"):
            return not o.hide_render
        return True

    pv = []
    pv.append(("game", "game", {"pre": pre_factory("pistol", "hold_pistol", 0), "only": visible, "margin": 1.6}))
    pv.append(("game_night", "game", {"pre": pre_factory("pistol", "hold_pistol", 0), "only": visible, "margin": 1.6, "light": "night"}))
    pv.append(("front", "front", {"pre": pre_factory(None, "hold_pistol", 0), "only": visible}))
    pv.append(("side", "side", {"pre": pre_factory(None, "hold_pistol", 0), "only": visible}))
    for i, yaw in enumerate(range(0, 360, 45)):
        pv.append((f"turn_{i}", "turntable", {"yaw_deg": yaw, "pre": pre_factory(None, "hold_pistol", 0), "only": visible, "res": 420}))
    for si, sk in enumerate(style.SKINS):
        pv.append((f"skin_{sk}", "three_quarter", {"pre": pre_factory(None, "idle", 0, si, "blue"), "only": visible, "res": 420}))
    pv.append(("team_red", "three_quarter", {"pre": pre_factory(None, "idle", 0, 0, "red"), "only": visible, "res": 420}))
    for e in ("open", "squint", "blink", "hurt", "dead", "happy"):
        pv.append((f"expr_{e}", "front", {"pre": pre_factory(None, "idle", 0, 0, "blue", e, "open" if e in ("hurt", "happy") else "idle"), "only": visible, "res": 360, "margin": 0.8}))
    for wid, cls in (("pistol", "pistol"), ("ak47", "rifle"), ("shotgun", "shotgun"), ("lmg", "heavy"), ("rocket", "launcher"), ("katana", "melee"), ("flame", "flame"), ("dual", "dual"), ("rail", "beam")):
        pv.append((f"hold_{wid}", "three_quarter", {"pre": pre_factory(wid, f"hold_{cls}", 0), "only": visible, "res": 420, "margin": 1.5}))
        pv.append((f"hold_{wid}_game", "game", {"pre": pre_factory(wid, f"hold_{cls}", 0), "only": visible, "res": 420, "margin": 1.8}))
    seqs = [("run_fwd", [0, 2, 5, 7], "side"), ("dash_roll", [0, 3, 5, 7], "side"), ("death", [0, 8, 16, 24], "three_quarter"), ("victory", [0, 5, 10, 15], "three_quarter"), ("reload_rifle", [0, 8, 14, 25], "three_quarter"), ("fire_shotgun", [0, 1, 4, 12], "side"), ("hurt", [0, 2, 5, 9], "front"), ("respawn_pop", [0, 3, 5, 9], "front")]
    for (act, frames, view) in seqs:
        wid = {"reload_rifle": "ak47", "fire_shotgun": "shotgun"}.get(act, "pistol")
        for fr in frames:
            e = "dead" if act == "death" and fr > 8 else "happy" if act == "victory" else "hurt" if act == "hurt" and 0 < fr < 9 else "squint" if act.startswith("fire") and fr in (1, 4) else "open"
            pv.append((f"anim_{act}_{fr:02d}", view, {"pre": pre_factory(wid, act, fr, 0, "blue", e, "open" if e in ("happy", "hurt", "dead") else "idle"), "only": visible, "res": 300, "margin": 1.7}))

    return ctx.Built([arm], animations=True, previews=pv, outline=0.0028)
