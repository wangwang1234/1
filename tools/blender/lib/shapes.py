"""形体工具：圆角盒、胶囊、椭球（四边面球）、圆柱、圆环、metaball 有机形体、上色、法线、合并。

所有函数都在当前场景里创建对象并返回 Object。坐标单位为米，Blender 坐标系（+Z 向上，+Y 为角色/武器前方）。
颜色一律通过调色板 UV 指定（style.uv），材质只决定着色方式。
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

from . import style

# ---------------------------------------------------------------------------
# 基础
# ---------------------------------------------------------------------------


def _link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def obj_from_bmesh(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.update()
    return _link(bpy.data.objects.new(name, me))


def ensure_material(name):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    return mat


def set_material(obj, mat_name):
    mat = ensure_material(mat_name)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.material_index = 0
    return obj


def _uv_layer(me):
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    return me.uv_layers.active


def paint(obj, color_name):
    """整个物体涂成一种调色板颜色。"""
    me = obj.data
    layer = _uv_layer(me)
    u, v = style.uv(color_name)
    for loop in layer.data:
        loop.uv = (u, v)
    return obj


def paint_where(obj, color_name, pred):
    """按面中心/法线（物体局部坐标）有条件上色。pred(center: Vector, normal: Vector) -> bool"""
    me = obj.data
    layer = _uv_layer(me)
    u, v = style.uv(color_name)
    n = 0
    for p in me.polygons:
        if pred(Vector(p.center), Vector(p.normal)):
            for li in p.loop_indices:
                layer.data[li].uv = (u, v)
            n += 1
    return n


def transform(obj, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    """把变换直接烘进网格（保持物体本身为单位变换）。rot 为欧拉角（弧度，XYZ）。"""
    from mathutils import Euler

    m = Matrix.Translation(Vector(loc)) @ Euler(rot, "XYZ").to_matrix().to_4x4() @ Matrix.Diagonal(Vector(scale).to_4d())
    obj.data.transform(m)
    obj.data.update()
    return obj


def apply_modifiers(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    old = obj.data
    obj.modifiers.clear()
    obj.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)
    return obj


def join(objs, name=None):
    """合并多个网格物体（保留材质槽与 UV）。返回合并后的物体。"""
    objs = [o for o in objs if o is not None]
    if not objs:
        return None
    target = objs[0]
    if len(objs) > 1:
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = target
        with bpy.context.temp_override(active_object=target, object=target, selected_objects=objs, selected_editable_objects=objs):
            bpy.ops.object.join()
    if name:
        target.name = name
        target.data.name = name
    return target


def smooth(obj, angle_deg=40.0):
    """平滑着色 + 按角度保留硬边（兼容 Blender 4.0 与 4.1+）。"""
    me = obj.data
    for p in me.polygons:
        p.use_smooth = True
    if hasattr(me, "use_auto_smooth"):
        me.use_auto_smooth = True
        me.auto_smooth_angle = math.radians(angle_deg)
    else:  # 4.1+
        try:
            bpy.context.view_layer.objects.active = obj
            with bpy.context.temp_override(active_object=obj, object=obj, selected_editable_objects=[obj]):
                bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle_deg))
        except Exception:
            pass
    return obj


def flat(obj):
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def weighted_normals(obj, angle_deg=35.0):
    """硬表面：倒角 + 加权法线，让大面平、倒角处圆润。"""
    smooth(obj, angle_deg)
    m = obj.modifiers.new("wn", "WEIGHTED_NORMAL")
    m.keep_sharp = True
    m.weight = 50
    apply_modifiers(obj)
    return obj


# ---------------------------------------------------------------------------
# 基本形体
# ---------------------------------------------------------------------------


def quad_sphere(name, center=(0, 0, 0), radii=(0.1, 0.1, 0.1), subdiv=3, color="white", mat=style.MAT_TOON):
    """四边面球（立方体细分投影），拓扑均匀，适合有机形体。"""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=2.0)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2 ** subdiv - 1, use_grid_fill=True)
    for v in bm.verts:
        v.co = v.co.normalized()
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0] + center[0], v.co.y * radii[1] + center[1], v.co.z * radii[2] + center[2]))
    obj = obj_from_bmesh(name, bm)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 180)
    return obj


def uv_sphere(name, center=(0, 0, 0), radii=(0.1, 0.1, 0.1), segments=16, rings=10, color="white", mat=style.MAT_TOON):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0] + center[0], v.co.y * radii[1] + center[1], v.co.z * radii[2] + center[2]))
    obj = obj_from_bmesh(name, bm)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 180)
    return obj


def rounded_box(name, center=(0, 0, 0), size=(0.1, 0.1, 0.1), bevel=0.01, segments=2, color="white", mat=style.MAT_TOON, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    b = min(bevel, min(size) * 0.49)
    if b > 1e-5:
        bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=b, segments=segments, profile=0.5, affect="EDGES", clamp_overlap=True)
    obj = obj_from_bmesh(name, bm)
    transform(obj, loc=center, rot=rot)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 35)
    return obj


def cylinder(name, center=(0, 0, 0), r_top=0.02, r_bottom=None, depth=0.1, axis="Z", segments=16, bevel=0.0, color="white", mat=style.MAT_TOON, caps=True):
    """圆柱/圆台。axis：'X' / 'Y' / 'Z'，为圆柱轴向。"""
    if r_bottom is None:
        r_bottom = r_top
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segments, radius1=r_bottom, radius2=r_top, depth=depth)
    if bevel > 1e-5 and caps:
        edges = [e for e in bm.edges if all(abs(abs(v.co.z) - depth / 2) < 1e-6 for v in e.verts) and len(e.link_faces) == 2 and any(len(f.verts) > 4 for f in e.link_faces)]
        if edges:
            bmesh.ops.bevel(bm, geom=edges, offset=min(bevel, min(r_top, r_bottom) * 0.45, depth * 0.45), segments=2, profile=0.5, affect="EDGES", clamp_overlap=True)
    obj = obj_from_bmesh(name, bm)
    rot = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}[axis]
    transform(obj, loc=center, rot=rot)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 40)
    return obj


def torus(name, center=(0, 0, 0), major=0.05, minor=0.01, axis="Z", seg_major=24, seg_minor=8, color="white", mat=style.MAT_TOON, scale=(1, 1, 1)):
    bm = bmesh.new()
    verts = []
    for i in range(seg_major):
        a = i / seg_major * math.tau
        ring = []
        for j in range(seg_minor):
            b = j / seg_minor * math.tau
            x = (major + minor * math.cos(b)) * math.cos(a)
            y = (major + minor * math.cos(b)) * math.sin(a)
            z = minor * math.sin(b)
            ring.append(bm.verts.new((x, y, z)))
        verts.append(ring)
    for i in range(seg_major):
        for j in range(seg_minor):
            a = verts[i][j]
            b = verts[(i + 1) % seg_major][j]
            c = verts[(i + 1) % seg_major][(j + 1) % seg_minor]
            d = verts[i][(j + 1) % seg_minor]
            bm.faces.new((a, b, c, d))
    obj = obj_from_bmesh(name, bm)
    rot = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}[axis]
    transform(obj, scale=scale)
    transform(obj, loc=center, rot=rot)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 180)
    return obj


def capsule(name, p0, p1, radius, segments=12, rings=4, color="white", mat=style.MAT_TOON, radius1=None):
    """两点之间的胶囊（可两端不同半径）。"""
    p0 = Vector(p0)
    p1 = Vector(p1)
    r0 = radius
    r1 = radius if radius1 is None else radius1
    L = (p1 - p0).length
    bm = bmesh.new()
    rows = []
    # 下半球
    for i in range(rings + 1):
        t = -math.pi / 2 + (i / rings) * (math.pi / 2)
        rows.append((r0 * math.cos(t), r0 * math.sin(t)))
    # 上半球
    for i in range(rings + 1):
        t = (i / rings) * (math.pi / 2)
        rows.append((r1 * math.cos(t), L + r1 * math.sin(t)))
    ring_verts = []
    for (rr, z) in rows:
        ring = []
        for j in range(segments):
            a = j / segments * math.tau
            ring.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        ring_verts.append(ring)
    for i in range(len(ring_verts) - 1):
        A = ring_verts[i]
        B = ring_verts[i + 1]
        for j in range(segments):
            k = (j + 1) % segments
            try:
                bm.faces.new((A[j], A[k], B[k], B[j]))
            except ValueError:
                pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-6)
    obj = obj_from_bmesh(name, bm)
    d = (p1 - p0)
    if d.length < 1e-9:
        d = Vector((0, 0, 1))
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    obj.data.transform(q.to_matrix().to_4x4())
    obj.data.transform(Matrix.Translation(p0))
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 180)
    return obj


def lathe(name, profile, segments=24, axis="Z", center=(0, 0, 0), color="white", mat=style.MAT_TOON, cap_top=True, cap_bottom=True):
    """旋转体。profile = [(半径, 高度), ...] 自下而上。"""
    bm = bmesh.new()
    rings = []
    for (r, z) in profile:
        ring = []
        for j in range(segments):
            a = j / segments * math.tau
            ring.append(bm.verts.new((max(r, 0.0) * math.cos(a), max(r, 0.0) * math.sin(a), z)))
        rings.append(ring)
    for i in range(len(rings) - 1):
        A, B = rings[i], rings[i + 1]
        for j in range(segments):
            k = (j + 1) % segments
            try:
                bm.faces.new((A[j], A[k], B[k], B[j]))
            except ValueError:
                pass
    if cap_bottom and profile[0][0] > 1e-6:
        bm.faces.new(list(reversed(rings[0])))
    if cap_top and profile[-1][0] > 1e-6:
        bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-7)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = obj_from_bmesh(name, bm)
    rot = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (-math.pi / 2, 0, 0)}[axis]
    transform(obj, loc=center, rot=rot)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 50)
    return obj


def extrude_profile(name, pts2d, depth, center=(0, 0, 0), plane="YZ", bevel=0.0, color="white", mat=style.MAT_TOON):
    """把 2D 轮廓（逆时针）挤出成厚片。plane='YZ' 表示轮廓在 YZ 平面、沿 X 挤出（适合枪身侧面剪影）。"""
    bm = bmesh.new()
    h = depth / 2
    if plane == "YZ":
        mk = lambda p, s: (s, p[0], p[1])
    elif plane == "XY":
        mk = lambda p, s: (p[0], p[1], s)
    else:  # XZ
        mk = lambda p, s: (p[0], s, p[1])
    A = [bm.verts.new(mk(p, -h)) for p in pts2d]
    B = [bm.verts.new(mk(p, h)) for p in pts2d]
    n = len(pts2d)
    bm.faces.new(list(reversed(A)))
    bm.faces.new(B)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((A[i], A[j], B[j], B[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    if bevel > 1e-5:
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, profile=0.5, affect="EDGES", clamp_overlap=True)
    obj = obj_from_bmesh(name, bm)
    transform(obj, loc=center)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 35)
    return obj


def metaball_mesh(name, balls, resolution=0.012, threshold=0.6, color="white", mat=style.MAT_TOON, remesh_voxel=None, decimate_ratio=None):
    """metaball 融合有机形体 -> 网格。balls = [(center, radius, (sx, sy, sz)), ...]"""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    mb.threshold = threshold
    for (c, r, s) in balls:
        e = mb.elements.new()
        e.type = "ELLIPSOID"
        e.co = Vector(c)
        e.radius = r
        e.size_x, e.size_y, e.size_z = s
        e.stiffness = 2.0
    mobj = _link(bpy.data.objects.new(name + "_mbobj", mb))
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(mobj.evaluated_get(dg))
    bpy.data.objects.remove(mobj, do_unlink=True)
    bpy.data.metaballs.remove(mb)
    obj = _link(bpy.data.objects.new(name, me))
    if remesh_voxel:
        m = obj.modifiers.new("remesh", "REMESH")
        m.mode = "VOXEL"
        m.voxel_size = remesh_voxel
        apply_modifiers(obj)
    m = obj.modifiers.new("smooth", "SMOOTH")
    m.factor = 0.6
    m.iterations = 6
    apply_modifiers(obj)
    if decimate_ratio:
        m = obj.modifiers.new("dec", "DECIMATE")
        m.ratio = decimate_ratio
        apply_modifiers(obj)
    set_material(obj, mat)
    paint(obj, color)
    smooth(obj, 180)
    return obj


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# ---------------------------------------------------------------------------
# 描边法线：把位置焊接后的平均法线写进顶点色，供 Godot 反向外壳描边使用
# ---------------------------------------------------------------------------


def bake_outline_normals(obj):
    me = obj.data
    me.update()
    acc = {}
    key = lambda co: (round(co.x, 5), round(co.y, 5), round(co.z, 5))
    for p in me.polygons:
        n = p.normal * p.area
        for vi in p.vertices:
            k = key(me.vertices[vi].co)
            acc[k] = acc.get(k, Vector((0, 0, 0))) + n
    name = "outline"
    if name in me.color_attributes:
        me.color_attributes.remove(me.color_attributes[name])
    attr = me.color_attributes.new(name=name, type="BYTE_COLOR", domain="CORNER")
    for p in me.polygons:
        for li, vi in zip(p.loop_indices, p.vertices):
            n = acc[key(me.vertices[vi].co)]
            if n.length < 1e-12:
                n = Vector(me.vertices[vi].normal)
            n = n.normalized()
            attr.data[li].color = (n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0)
    me.color_attributes.active_color = attr
    try:
        me.color_attributes.render_color_index = me.color_attributes.find(name)
    except Exception:
        pass
    return obj


def mirror_x(obj):
    """返回一个沿 X 镜像的副本（网格已烘焙）。"""
    me = obj.data.copy()
    o = _link(bpy.data.objects.new(obj.name + "_mx", me))
    o.data.transform(Matrix.Scale(-1, 4, Vector((1, 0, 0))))
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    bm.to_mesh(o.data)
    bm.free()
    return o


def empty(name, loc=(0, 0, 0), parent=None, size=0.02):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = size
    e.empty_display_type = "PLAIN_AXES"
    e.location = Vector(loc)
    _link(e)
    if parent is not None:
        e.parent = parent
    return e


def transfer_normals(obj, src):
    """把 src 的平滑法线以自定义法线形式转移到 obj（减面后保持圆润明暗）。"""
    smooth(obj, 180)
    m = obj.modifiers.new("nt", "DATA_TRANSFER")
    m.object = src
    m.use_loop_data = True
    m.data_types_loops = {"CUSTOM_NORMAL"}
    m.loop_mapping = "POLYINTERP_NEAREST"
    m.mix_mode = "REPLACE"
    m.mix_factor = 1.0
    apply_modifiers(obj)
    return obj
