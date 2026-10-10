class_name ToonMaterials
extends RefCounted
## 按 Blender 材质名和配置选择连续环境 / 柔化阶调角色材质（见 tools/blender/lib/style.py）。
## 材质按（种类, 描边宽度）缓存共享；皮肤 / 队伍 / 进化路线 / 受击闪白等差异全部走 instance uniform。

const PALETTE := preload("res://assets/textures/palette.png")
const TOON := preload("res://shaders/toon.gdshader")
const SURFACE := preload("res://shaders/surface.gdshader")
const OUTLINE := preload("res://shaders/toon_outline.gdshader")

const KINDS := {
	"M_toon": 0, "M_skin": 1, "M_team": 2, "M_metal": 3, "M_glass": 4,
	"M_emissive": 5, "M_eye": 6, "M_flat": 7, "M_path": 8,
}
const NO_OUTLINE := [6, 7]

static var _cache: Dictionary = {}
static var review_neutral := false


static func kind_of(mat_name: String) -> int:
	for k in KINDS:
		if mat_name.begins_with(k):
			return KINDS[k]
	return 0


static func material(kind: int, outline_px: float = 1.5, surface: String = "object") -> ShaderMaterial:
	var key := "%d_%.2f_%s" % [kind, outline_px, surface]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	var profiles := VisualStyle.section("materials")
	var p: Dictionary = profiles.get(surface, profiles["object"])
	m.shader = TOON if String(p.get("shading", "surface")) == "toon" else SURFACE
	m.set_shader_parameter("palette", PALETTE)
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("neutral_amount", 1.0 if review_neutral else 0.0)
	m.set_shader_parameter("surface_mode", int(p.surfaceMode))
	m.set_shader_parameter("skin_blend", bool(p.get("skinBlend", false)))
	m.set_shader_parameter("detail_strength", float(p.get("detailStrength", 0.0)))
	m.set_shader_parameter("rim_strength", float(p.rim))
	m.set_shader_parameter("material_roughness", float(p.roughness))
	m.set_shader_parameter("material_specular", float(p.get("specular", 0.5)))
	m.set_shader_parameter("metal_roughness", float(p.get("metalRoughness", 0.32)))
	m.set_shader_parameter("emission_energy", float(p.get("emissionEnergy", 1.0)))
	m.set_shader_parameter("bump_strength", float(p.get("bumpStrength", 0.0)))
	m.set_shader_parameter("surface_saturation", float(p.get("saturation", 1.0)))
	m.set_shader_parameter("vertex_tint_strength", float(p.get("vertexTint", 0.0)))
	if m.shader == TOON:
		m.set_shader_parameter("toon_weight", float(p.get("toonWeight", 0.38)))
	m.set_shader_parameter("surface_color", Color(String(p.get("color", "#ffffff"))))
	m.set_shader_parameter("surface_color_blend", float(p.get("colorBlend", 0.0)))
	outline_px *= float(p.outlineScale)
	if kind == 3:
		m.set_shader_parameter("spec_strength", 0.5)
	if kind == 4:
		m.set_shader_parameter("spec_strength", 0.8)
		m.set_shader_parameter("spec_threshold", 0.86)
	if kind == 6:
		m.set_shader_parameter("rim_strength", 0.0)
	if outline_px > 0.0 and not NO_OUTLINE.has(kind):
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("palette", PALETTE)
		o.set_shader_parameter("kind", kind)
		o.set_shader_parameter("width_px", outline_px)
		m.next_pass = o
	_cache[key] = m
	return m


static func apply(root: Node, outline_px: float = 1.5, surface: String = "object") -> void:
	## 遍历子树，把所有 MeshInstance3D 的表面材质换成 toon。
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s)
			var nm := src.resource_name if src != null else "M_toon_base"
			m.set_surface_override_material(s, material(kind_of(nm), outline_px, surface_for_material(nm, surface)))


static func surface_for_material(mat_name: String, fallback: String) -> String:
	if fallback == "shelf" and mat_name.begins_with("M_toon_base"):
		return "books"
	if mat_name.begins_with("M_skin_blend"):
		return "fur"
	if mat_name.begins_with("M_team_knit"):
		return "knit"
	if mat_name.begins_with("M_toon_wood"):
		return "furniture_wood"
	if mat_name.begins_with("M_toon_cloth"):
		return "gear"
	if mat_name.begins_with("M_toon_ceramic"):
		return "ceramic"
	return fallback


static func set_param(root: Node, param: StringName, value: Variant) -> void:
	for mi in root.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).set_instance_shader_parameter(param, value)
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).set_instance_shader_parameter(param, value)


static func instance(path: String, outline_px: float = 1.5) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		push_error("ToonMaterials: 无法加载 %s" % path)
		return Node3D.new()
	var n: Node3D = ps.instantiate()
	apply(n, outline_px, VisualStyle.surface_for(path))
	return n


static var _mesh_cache: Dictionary = {}


static func merged_mesh(path: String, outline_px: float = 1.5) -> ArrayMesh:
	## 把一个模块的所有网格合并成一个多表面 ArrayMesh（按材质种类分表面，已套 toon 材质），给 MultiMesh 批量摆放用。
	var key := "%s_%.2f" % [path, outline_px]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var ps: PackedScene = load(path)
	var root: Node3D = ps.instantiate()
	var tools := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var n: Node = m
		while n != null and n != root:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s)
			var k := kind_of(src.resource_name if src != null else "M_toon")
			var surface := surface_for_material(src.resource_name if src != null else "M_toon", VisualStyle.surface_for(path))
			var group := "%d_%s" % [k, surface]
			if not tools.has(group):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[group] = {"tool": st, "kind": k, "surface": surface}
			(tools[group].tool as SurfaceTool).append_from(m.mesh, s, xf)
	var out := ArrayMesh.new()
	for k in tools:
		var st: SurfaceTool = tools[k].tool
		st.commit(out)
		out.surface_set_material(out.get_surface_count() - 1, material(int(tools[k].kind), outline_px, String(tools[k].surface)))
	root.free()
	_mesh_cache[key] = out
	return out
