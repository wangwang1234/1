"""骨架模板与蒙皮工具。

仓鼠骨架（PIPELINE 第 5 节）：root、pelvis、spine、head、ear_L/R、arm_L/R + forearm_L/R、leg_L/R + shin_L/R、
tail + tail_tip，另加 cheek_L/R（腮帮子鼓起）；挂点 weapon_socket、hat_socket、back_socket、face_socket（不参与蒙皮）。
"""
import bpy
from mathutils import Vector

# 名字: (head, tail, parent, deform)
HAMSTER_BONES = {
    "root": ((0, 0, 0), (0, 0.06, 0), None, False),
    "pelvis": ((0, 0, 0.065), (0, 0, 0.115), "root", True),
    "spine": ((0, 0, 0.115), (0, 0, 0.165), "pelvis", True),
    "head": ((0, 0.01, 0.165), (0, 0.01, 0.30), "spine", True),
    "ear_L": ((-0.104, -0.02, 0.268), (-0.126, -0.026, 0.312), "head", True),
    "ear_R": ((0.104, -0.02, 0.268), (0.126, -0.026, 0.312), "head", True),
    "cheek_L": ((-0.078, 0.082, 0.178), (-0.078, 0.112, 0.178), "head", True),
    "cheek_R": ((0.078, 0.082, 0.178), (0.078, 0.112, 0.178), "head", True),
    "arm_L": ((-0.062, 0.058, 0.13), (-0.082, 0.1, 0.115), "spine", True),
    "forearm_L": ((-0.082, 0.1, 0.115), (-0.066, 0.145, 0.108), "arm_L", True),
    "arm_R": ((0.062, 0.058, 0.13), (0.082, 0.1, 0.115), "spine", True),
    "forearm_R": ((0.082, 0.1, 0.115), (0.066, 0.145, 0.108), "arm_R", True),
    "leg_L": ((-0.05, 0.0, 0.065), (-0.054, 0.018, 0.032), "pelvis", True),
    "shin_L": ((-0.054, 0.018, 0.032), (-0.055, 0.032, 0.012), "leg_L", True),
    "leg_R": ((0.05, 0.0, 0.065), (0.054, 0.018, 0.032), "pelvis", True),
    "shin_R": ((0.054, 0.018, 0.032), (0.055, 0.032, 0.012), "leg_R", True),
    "tail": ((0, -0.092, 0.072), (0, -0.112, 0.068), "pelvis", True),
    "tail_tip": ((0, -0.112, 0.068), (0, -0.13, 0.066), "tail", True),
    "weapon_socket": ((0.0, 0.11, 0.105), (0.0, 0.15, 0.105), "spine", False),
    "hat_socket": ((0, 0.005, 0.33), (0, 0.005, 0.36), "head", False),
    "back_socket": ((0, -0.095, 0.13), (0, -0.125, 0.13), "spine", False),
    "face_socket": ((0, 0.14, 0.22), (0, 0.17, 0.22), "head", False),
}


def build_armature(name, bones, rolls=None):
    arm_data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    with bpy.context.temp_override(active_object=arm, object=arm):
        bpy.ops.object.mode_set(mode="EDIT")
        eb = arm_data.edit_bones
        for bname, (h, t, parent, deform) in bones.items():
            b = eb.new(bname)
            b.head = Vector(h)
            b.tail = Vector(t)
            b.use_deform = deform
            if rolls and bname in rolls:
                b.roll = rolls[bname]
        for bname, (h, t, parent, deform) in bones.items():
            if parent:
                eb[bname].parent = eb[parent]
                eb[bname].use_connect = False
        bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
    return arm


def bind(obj, arm, weights):
    """weights: {bone_name: weight} 刚性/固定权重；或 callable(co)->{bone: w} 按顶点计算。"""
    obj.parent = arm
    groups = {}
    if callable(weights):
        for v in obj.data.vertices:
            w = weights(v.co)
            tot = sum(w.values()) or 1.0
            for b, x in w.items():
                if x <= 1e-4:
                    continue
                g = groups.get(b) or obj.vertex_groups.new(name=b)
                groups[b] = g
                g.add([v.index], x / tot, "REPLACE")
    else:
        idx = [v.index for v in obj.data.vertices]
        for b, x in weights.items():
            g = obj.vertex_groups.new(name=b)
            g.add(idx, x, "REPLACE")
    m = obj.modifiers.new("armature", "ARMATURE")
    m.object = arm
    return obj


def seg_dist(p, a, b):
    a = Vector(a)
    b = Vector(b)
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-12)))
    return (p - (a + ab * t)).length


def envelope_weights(bones, falloff=0.03, sharp=4.0):
    """按到骨段距离的平滑权重：w = 1/(d+falloff)^sharp。bones: {name: (head, tail)}"""

    def fn(co):
        out = {}
        for n, (h, t) in bones.items():
            d = seg_dist(Vector(co), h, t)
            out[n] = 1.0 / (d + falloff) ** sharp
        tot = sum(out.values())
        # 去掉很小的影响，保留最多 3 根
        items = sorted(out.items(), key=lambda kv: -kv[1])[:3]
        return {k: v / tot for k, v in items if v / tot > 0.02}

    return fn
