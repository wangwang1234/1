class_name RoomArchitecture
extends RefCounted
## Boundary-only room shell. All geometry stays inside the existing wall strip
## or outside it; no simulation solids, visibility rules or RNG are changed.

var _groups: Dictionary = {}


static func has_study_wall(map: SimMap) -> bool:
	return map.min_y == 0.0 and map.min_x == 0.0


static func build(parent: Node3D, map: SimMap) -> void:
	if not has_study_wall(map):
		return
	var builder := RoomArchitecture.new()
	var root := Node3D.new()
	root.name = "StudyArchitecture"
	parent.add_child(root)
	# Back wall, with a real opening above the low shelf. The pane sits behind
	# the opening and does not cast a shadow across its own window key light.
	var end_x := minf(13.0, map.max_x * 0.01)
	var left := 4.2
	var right := 8.4
	var bottom := 1.52
	var top := 3.5
	builder.box("plaster", Vector3(end_x * 0.5, 0.72, -0.02), Vector3(end_x, 1.44, 0.20), 0.02)
	builder.box("plaster", Vector3(left * 0.5, 2.52, -0.02), Vector3(left, 2.16, 0.20), 0.02)
	builder.box("plaster", Vector3((right + end_x) * 0.5, 2.52, -0.02), Vector3(end_x - right, 2.16, 0.20), 0.02)
	builder.box("plaster", Vector3((left + right) * 0.5, 3.64, -0.02), Vector3(right - left, 0.28, 0.20), 0.02)
	builder.box("glass", Vector3(6.3, (bottom + top) * 0.5, -0.13), Vector3(4.02, top - bottom - 0.12, 0.025), 0.003)
	for x in [left, right]:
		builder.box("painted_wood", Vector3(x, (bottom + top) * 0.5, 0.12), Vector3(0.14, top - bottom + 0.24, 0.20), 0.018)
	for y in [bottom, top]:
		builder.box("painted_wood", Vector3(6.3, y, 0.12), Vector3(right - left + 0.24, 0.14, 0.20), 0.018)
	for x in [5.6, 7.0]:
		builder.box("painted_wood", Vector3(x, 2.51, 0.14), Vector3(0.055, 1.88, 0.11), 0.008)
	builder.box("painted_wood", Vector3(6.3, 2.55, 0.14), Vector3(4.1, 0.055, 0.11), 0.008)
	builder.box("wood", Vector3(6.3, 1.46, 0.16), Vector3(4.55, 0.13, 0.30), 0.025)
	# Low wall panels unify the shelf and floor. The western shell is kept at
	# the existing low boundary height, so it cannot hide the playable lane.
	builder.box("plaster", Vector3(-0.02, 0.62, 7.0), Vector3(0.20, 1.24, 14.0), 0.02)
	for x in range(13):
		builder.box("panel", Vector3(float(x) + 0.5, 0.56, 0.095), Vector3(0.94, 0.92, 0.04), 0.012)
	builder.box("wood", Vector3(end_x * 0.5, 1.08, 0.15), Vector3(end_x, 0.07, 0.12), 0.015)
	builder.box("wood", Vector3(end_x * 0.5, 0.10, 0.17), Vector3(end_x, 0.19, 0.15), 0.018)
	builder.box("wood", Vector3(0.13, 0.10, 7.0), Vector3(0.15, 0.19, 14.0), 0.018)
	builder.box("wood", Vector3(0.13, 1.21, 7.0), Vector3(0.15, 0.07, 14.0), 0.012)
	# Folded drapes occupy only the boundary wall; deliberately broad folds.
	for side: float in [-1.0, 1.0]:
		for i in 5:
			var x := 6.3 + side * (2.25 + float(i) * 0.13)
			builder.box("cloth", Vector3(x, 2.45, 0.13 + sin(float(i) * 1.7) * 0.025), Vector3(0.15, 2.32, 0.09), 0.042)
	builder.box("wood", Vector3(6.3, 3.7, 0.16), Vector3(5.9, 0.06, 0.06), 0.024)
	builder.flush(root)


func box(surface: String, center: Vector3, size: Vector3, radius: float) -> void:
	if not _groups.has(surface):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_groups[surface] = st
	var tool: SurfaceTool = _groups[surface]
	var half := size * 0.5
	var r := minf(radius, minf(half.x, minf(half.y, half.z)) * 0.95)
	var inner := half - Vector3.ONE * r
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		var au := [-half[u], -half[u] + r * 0.293, -half[u] + r, half[u] - r, half[u] - r * 0.293, half[u]]
		var av := [-half[v], -half[v] + r * 0.293, -half[v] + r, half[v] - r, half[v] - r * 0.293, half[v]]
		for sign_: float in [-1.0, 1.0]:
			for i in 5:
				for j in 5:
					# Godot's front faces are clockwise when viewed from outside.
					var order := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]
					if sign_ < 0.0:
						order.reverse()
					for corner: Vector2i in order:
						var p := Vector3.ZERO
						p[axis] = half[axis] * sign_
						p[u] = au[i + corner.x]
						p[v] = av[j + corner.y]
						var q := p.clamp(-inner, inner)
						var normal := (p - q).normalized()
						tool.set_normal(normal)
						tool.set_uv(Vector2(p[u], p[v]))
						tool.add_vertex(center + q + normal * r)


func flush(parent: Node3D) -> void:
	for surface: String in _groups:
		var mesh := MeshInstance3D.new()
		mesh.name = surface
		mesh.mesh = (_groups[surface] as SurfaceTool).commit()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/architecture.gdshader")
		var style: Dictionary = VisualStyle.section("architecture")[surface]
		mat.set_shader_parameter("base_color", Color(String(style.color)))
		mat.set_shader_parameter("roughness", float(style.roughness))
		mat.set_shader_parameter("grain", float(style.get("grain", 0.0)))
		mat.set_shader_parameter("emission", float(style.get("emission", 0.0)))
		mat.set_shader_parameter("neutral_amount", 1.0 if ToonMaterials.review_neutral else 0.0)
		mesh.material_override = mat
		if surface == "glass":
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mesh)
	_groups.clear()
