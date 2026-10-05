"""glTF 导出设置（GLB，+Y 向上，应用修改器，带骨骼和全部动作）。兼容 Blender 4.0～4.x 的参数差异。"""
import os

import bpy


def _supported(props):
    rna = bpy.ops.export_scene.gltf.get_rna_type()
    names = {p.identifier for p in rna.properties}
    return {k: v for k, v in props.items() if k in names}


def export_glb(path, objects, animations=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objects:
        o.select_set(True)
        for c in o.children_recursive:
            c.select_set(True)
    props = {
        "filepath": path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": True,
        "export_yup": True,
        "export_texcoords": True,
        "export_normals": True,
        "export_tangents": False,
        "export_materials": "EXPORT",
        "export_image_format": "NONE",
        "export_colors": True,
        "export_vertex_color": "ACTIVE",
        "export_attributes": False,
        "export_cameras": False,
        "export_lights": False,
        "export_extras": False,
        "export_skins": True,
        "export_all_influences": False,
        "export_def_bones": False,
        "export_animations": animations,
        "export_animation_mode": "ACTIONS",
        "export_force_sampling": True,
        "export_frame_range": False,
        "export_anim_single_armature": True,
        "export_reset_pose_bones": True,
        "export_optimize_animation_size": False,
        "export_morph": False,
        "export_rest_position_armature": True,
        "export_hierarchy_flatten_bones": False,
        "will_save_settings": False,
    }
    bpy.ops.export_scene.gltf(**_supported(props))
    return path
