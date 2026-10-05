"""动作工具：关键姿势、缓动插值、循环。

用法：
    a = Action(arm, "run_fwd", fps=30, loop=True)
    a.key(0, {"pelvis": dict(loc=(0,0,0.01), rot=(0.1,0,0))})
    a.key(6, {...})
    a.finish()
姿势值是相对静止姿势（rest）的局部偏移：loc 米、rot 弧度（XYZ 欧拉，骨骼局部轴）、scale 倍数。
"""
import math

import bpy

FPS = 30
ALL_CHANNELS = ("loc", "rot", "scale")


class Action:
    def __init__(self, arm, name, fps=FPS, loop=False, bones=None):
        self.arm = arm
        self.name = name
        self.fps = fps
        self.loop = loop
        old = bpy.data.actions.get(name)
        if old:
            bpy.data.actions.remove(old)
        self.action = bpy.data.actions.new(name)
        self.action.use_fake_user = True
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = self.action
        self.bones = bones  # 只给这些骨骼打关键帧（None = 姿势里出现的骨骼）
        self.keyed = set()
        self.last_frame = 0
        self.interp = {}

    def key(self, frame, pose, interp="BEZIER", ease="AUTO"):
        """pose: {bone: {loc, rot, scale}}；未写的通道 = 静止值。"""
        bones = self.bones or list(pose.keys())
        for bn in bones:
            pb = self.arm.pose.bones[bn]
            p = pose.get(bn, {})
            pb.location = p.get("loc", (0, 0, 0))
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = p.get("rot", (0, 0, 0))
            s = p.get("scale", (1, 1, 1))
            if isinstance(s, (int, float)):
                s = (s, s, s)
            pb.scale = s
            pb.keyframe_insert("location", frame=frame)
            pb.keyframe_insert("rotation_euler", frame=frame)
            pb.keyframe_insert("scale", frame=frame)
            self.keyed.add(bn)
        self.interp[frame] = (interp, ease)
        self.last_frame = max(self.last_frame, frame)

    def finish(self):
        for fc in self.action.fcurves:
            for kp in fc.keyframe_points:
                it, ea = self.interp.get(int(round(kp.co.x)), ("BEZIER", "AUTO"))
                kp.interpolation = it
                if it == "BEZIER":
                    kp.handle_left_type = "AUTO_CLAMPED"
                    kp.handle_right_type = "AUTO_CLAMPED"
                if ea != "AUTO":
                    kp.easing = ea
            if self.loop:
                m = fc.modifiers.new("CYCLES")
        self.action.frame_range = (0, self.last_frame)
        try:
            self.action.use_frame_range = True
            self.action.use_cyclic = self.loop
        except Exception:
            pass
        # 让导出器把它当作独立动作
        self.arm.animation_data.action = None
        tr = self.arm.animation_data.nla_tracks.new()
        tr.name = self.name
        st = tr.strips.new(self.name, 0, self.action)
        tr.mute = True
        reset_pose(self.arm)
        return self.action


def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
        pb.scale = (1, 1, 1)


def deg(x):
    return math.radians(x)
