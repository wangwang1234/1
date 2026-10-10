"""调色板贴图 + 预览用的三渲二材质节点（只用于 Blender 里渲染预览图）。

导出 glTF 时材质只保留名字和默认参数；进 Godot 后由 toon_materials.gd 按名字换成 toon 着色器。
"""
import os

import bpy

from . import style

_PALETTE_IMG = "palette"


_PALETTE_PATH = None


def palette_image(save_path=None):
    """调色板贴图：先用标准库写成 PNG，再让 Blender 从文件加载（生成图像的像素写入在后台模式下不可靠）。"""
    global _PALETTE_PATH
    if save_path:
        _PALETTE_PATH = save_path
    img = bpy.data.images.get(_PALETTE_IMG)
    if img is None:
        path = _PALETTE_PATH or os.path.join(bpy.app.tempdir or "/tmp", "palette_preview.png")
        style.write_palette_png(path)
        img = bpy.data.images.load(path)
        img.name = _PALETTE_IMG
        img.colorspace_settings.name = "sRGB"
    return img


def reset_for_export():
    """导出前：把所有材质恢复成不带贴图的默认材质（只保留名字）。"""
    for mat in bpy.data.materials:
        mat.use_nodes = False
        mat.diffuse_color = (1, 1, 1, 1)


# 预览参数：皮肤 / 队伍 / 进化路线色偏移
PREVIEW = {"skin": 0, "team": "blue", "path": 0, "glow": 0.0}


def _toon_tree(mat, kind):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    N = nt.nodes
    L = nt.links
    img = palette_image()

    uvn = N.new("ShaderNodeUVMap")
    mapping = N.new("ShaderNodeMapping")
    mapping.vector_type = "POINT"
    du = 0.0
    dv = 0.0
    if kind == style.MAT_SKIN:
        du = PREVIEW["skin"] / style.CELLS
    if kind == style.MAT_TEAM and PREVIEW["team"] == "red":
        dv = -1.0 / (2 * style.ROWS)
    if kind == "M_path":
        du = PREVIEW["path"] / style.CELLS
    mapping.inputs["Location"].default_value = (du, dv, 0)
    L.new(uvn.outputs["UV"], mapping.inputs["Vector"])

    tex = N.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    L.new(mapping.outputs["Vector"], tex.inputs["Vector"])

    # 自发光：同列下半张
    m2 = N.new("ShaderNodeMapping")
    m2.inputs["Location"].default_value = (0, -0.5, 0)
    L.new(mapping.outputs["Vector"], m2.inputs["Vector"])
    etex = N.new("ShaderNodeTexImage")
    etex.image = img
    etex.interpolation = "Closest"
    L.new(m2.outputs["Vector"], etex.inputs["Vector"])

    diff = N.new("ShaderNodeBsdfDiffuse")
    diff.inputs["Color"].default_value = (1, 1, 1, 1)
    s2r = N.new("ShaderNodeShaderToRGB")
    L.new(diff.outputs["BSDF"], s2r.inputs["Shader"])
    bw = N.new("ShaderNodeRGBToBW")
    L.new(s2r.outputs["Color"], bw.inputs["Color"])
    ramp = N.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "LINEAR"
    ramp.color_ramp.elements[0].position = 0.30
    ramp.color_ramp.elements[0].color = (0, 0, 0, 1)
    ramp.color_ramp.elements[1].position = 0.34
    ramp.color_ramp.elements[1].color = (1, 1, 1, 1)
    L.new(bw.outputs["Val"], ramp.inputs["Fac"])

    # 冷紫阴影
    shadow = N.new("ShaderNodeMixRGB")
    shadow.blend_type = "MULTIPLY"
    shadow.inputs["Fac"].default_value = 1.0
    shadow.inputs["Color2"].default_value = (0.42, 0.36, 0.62, 1)
    L.new(tex.outputs["Color"], shadow.inputs["Color1"])
    mix = N.new("ShaderNodeMixRGB")
    L.new(ramp.outputs["Color"], mix.inputs["Fac"])
    L.new(shadow.outputs["Color"], mix.inputs["Color1"])
    L.new(tex.outputs["Color"], mix.inputs["Color2"])

    # 边缘光
    lw = N.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.35
    rr = N.new("ShaderNodeValToRGB")
    rr.color_ramp.elements[0].position = 0.72
    rr.color_ramp.elements[0].color = (0, 0, 0, 1)
    rr.color_ramp.elements[1].position = 0.74
    rr.color_ramp.elements[1].color = (0.22, 0.2, 0.18, 1)
    L.new(lw.outputs["Facing"], rr.inputs["Fac"])
    add_rim = N.new("ShaderNodeMixRGB")
    add_rim.blend_type = "ADD"
    add_rim.inputs["Fac"].default_value = 1.0
    L.new(mix.outputs["Color"], add_rim.inputs["Color1"])
    L.new(rr.outputs["Color"], add_rim.inputs["Color2"])

    last = add_rim
    if kind in (style.MAT_METAL, style.MAT_GLASS, style.MAT_EYE):
        gl = N.new("ShaderNodeBsdfGlossy")
        gl.inputs["Roughness"].default_value = 0.25
        s2 = N.new("ShaderNodeShaderToRGB")
        L.new(gl.outputs["BSDF"], s2.inputs["Shader"])
        b2 = N.new("ShaderNodeRGBToBW")
        L.new(s2.outputs["Color"], b2.inputs["Color"])
        r2 = N.new("ShaderNodeValToRGB")
        r2.color_ramp.elements[0].position = 0.55
        r2.color_ramp.elements[0].color = (0, 0, 0, 1)
        r2.color_ramp.elements[1].position = 0.57
        r2.color_ramp.elements[1].color = (0.6, 0.6, 0.6, 1)
        L.new(b2.outputs["Val"], r2.inputs["Fac"])
        a2 = N.new("ShaderNodeMixRGB")
        a2.blend_type = "ADD"
        a2.inputs["Fac"].default_value = 1.0
        L.new(last.outputs["Color"], a2.inputs["Color1"])
        L.new(r2.outputs["Color"], a2.inputs["Color2"])
        last = a2

    emit = N.new("ShaderNodeEmission")
    L.new(last.outputs["Color"], emit.inputs["Color"])
    glow = N.new("ShaderNodeEmission")
    L.new(etex.outputs["Color"], glow.inputs["Color"])
    strength = 1.5
    if kind == style.MAT_EMISSIVE:
        strength = 3.0
    if kind == "M_path":
        strength = PREVIEW["glow"] * 3.0
    glow.inputs["Strength"].default_value = strength
    add = N.new("ShaderNodeAddShader")
    L.new(emit.outputs["Emission"], add.inputs[0])
    L.new(glow.outputs["Emission"], add.inputs[1])
    out = N.new("ShaderNodeOutputMaterial")
    L.new(add.outputs["Shader"], out.inputs["Surface"])


def _outline_tree(mat):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    N = nt.nodes
    L = nt.links
    img = palette_image()
    uvn = N.new("ShaderNodeUVMap")
    tex = N.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    L.new(uvn.outputs["UV"], tex.inputs["Vector"])
    dark = N.new("ShaderNodeMixRGB")
    dark.blend_type = "MULTIPLY"
    dark.inputs["Fac"].default_value = 1.0
    dark.inputs["Color2"].default_value = (style.OUTLINE_LIGHTNESS * 0.75, style.OUTLINE_LIGHTNESS * 0.7, style.OUTLINE_LIGHTNESS * 0.9, 1)
    L.new(tex.outputs["Color"], dark.inputs["Color1"])
    emit = N.new("ShaderNodeEmission")
    L.new(dark.outputs["Color"], emit.inputs["Color"])
    out = N.new("ShaderNodeOutputMaterial")
    L.new(emit.outputs["Emission"], out.inputs["Surface"])
    mat.use_backface_culling = True


def setup_preview_materials():
    for mat in list(bpy.data.materials):
        if mat.name.startswith("OUTLINE"):
            continue
        kind = mat.name
        for k in style.MATERIALS + ["M_path"]:
            if mat.name.startswith(k):
                kind = k
        _toon_tree(mat, kind)


def add_preview_outlines(objs, thickness=0.0035):
    """预览用反向外壳描边（不导出）。"""
    ol = bpy.data.materials.get("OUTLINE")
    if ol is None:
        ol = bpy.data.materials.new("OUTLINE")
        _outline_tree(ol)
    for o in objs:
        if o.type != "MESH":
            continue
        if any(m and (m.name.startswith(style.MAT_EYE) or m.name.startswith(style.MAT_FLAT)) for m in o.data.materials):
            continue
        if not any(m.name == "OUTLINE" for m in o.data.materials if m):
            o.data.materials.append(ol)
        idx = [m.name for m in o.data.materials].index("OUTLINE")
        sm = o.modifiers.new("outline", "SOLIDIFY")
        sm.thickness = thickness
        sm.offset = 1.0
        sm.use_flip_normals = True
        sm.use_rim = False
        sm.material_offset = idx
        sm.use_even_offset = False
