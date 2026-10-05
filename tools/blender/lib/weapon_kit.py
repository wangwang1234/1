"""武器通用：挂点空节点、根物体、预览参数。

武器坐标约定（style.GRIP）：原点 = 右手握把；+Y 枪口方向；+Z 向上；+X 向右。
挂点（PIPELINE 第 5 节）：att_scope、att_muzzle、att_drum、att_tank、att_coil、att_radar、att_torch、muzzle、grip_L、grip_R。
"""
import bpy
from mathutils import Vector

from . import shapes, style

SOCKETS = ["att_scope", "att_muzzle", "att_drum", "att_tank", "att_coil", "att_radar", "att_torch", "muzzle", "grip_L", "grip_R"]


def finish(name, parts, cls, sockets):
    """合并网格、烘焙描边法线、创建根空节点并挂上所有挂点。返回根物体。"""
    mesh = shapes.join([p for p in parts if p is not None], name + "_mesh")
    shapes.bake_outline_normals(mesh)
    root = bpy.data.objects.new(name, None)
    root.empty_display_size = 0.05
    bpy.context.scene.collection.objects.link(root)
    mesh.parent = root
    g = style.GRIP[cls]
    sockets = dict(sockets)
    sockets.setdefault("grip_R", g["R"])
    sockets.setdefault("grip_L", g["L"])
    for s in SOCKETS:
        if s not in sockets:
            raise ValueError(f"{name} 缺少挂点 {s}")
        shapes.empty(s, sockets[s], parent=root, size=0.01)
    print(f"[{name}] 三角面：{shapes.tri_count(mesh)}")
    return root


def previews(name=None):
    import os
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    extra = []
    if name:
        extra.append(("icon", "icon_side", {"transparent": True, "res": 256, "margin": 1.04, "out": os.path.join(root, "game", "assets", "icons", name + ".png")}))
    return extra + [
        ("game", "game", {"margin": 1.3}),
        ("side", "side", {"margin": 1.15}),
        ("top", "top", {"margin": 1.15}),
        ("three_quarter", "three_quarter", {"margin": 1.2}),
    ]
