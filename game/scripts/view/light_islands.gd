class_name LightIslands
extends Node3D
## 光岛：每个区域一个看得出来源的光——客厅月光透过龟背竹窗、路灯透过百叶窗、厨房月光从餐桌椅下穿过、冰箱门缝的冷光、
## 沙发底掉落的手机（屏幕定期亮起）、礼物区地上的彩灯串。投影贴图投出画面外巨大家具的影子，交代仓鼠有多小。
## 参数在 visual_style.json 的 lightIslands；只影响表现，不提供视野，不碰战斗随机数。只在完整地图建。

const QUALITY_RANK := {"low": 0, "medium": 1, "high": 2}

var placements: Array[Dictionary] = []    # 地上的实物（手机、灯泡），厘米坐标 + 半径；MapView 用来让装饰避开，测试检查净空
var lights: Array[Light3D] = []
var _phone_light: OmniLight3D
var _phone_screen: ShaderMaterial
var _phone_cfg: Dictionary = {}
var _t := 0.0


static func quality_allows(min_quality: String) -> bool:
	return int(QUALITY_RANK.get(VisualStyle.quality, 2)) >= int(QUALITY_RANK.get(min_quality, 0))


static func build(parent: Node3D, map: SimMap) -> LightIslands:
	var node := LightIslands.new()
	node.name = "LightIslands"
	parent.add_child(node)
	if not RoomArchitecture.has_study_wall(map):
		return node
	var cfg := VisualStyle.section("lightIslands")
	for item: Dictionary in cfg.get("lights", []):
		node._add_light(item, map)
	if cfg.has("phone"):
		node._build_phone(cfg.phone)
	if cfg.has("fairy"):
		node._build_fairy(cfg.fairy)
	return node


func _add_light(item: Dictionary, map: SimMap) -> void:
	if not quality_allows(String(item.get("minQuality", "low"))):
		return
	var target := RoomLighting.vector(item.target)
	if not RoomLighting.inside_map(target, map):
		return
	var pos := RoomLighting.vector(item.position)
	var spot := SpotLight3D.new()
	spot.name = String(item.name)
	spot.spot_range = float(item.range)
	spot.spot_angle = float(item.angle)
	spot.spot_attenuation = float(item.attenuation)
	spot.spot_angle_attenuation = float(item.coneAttenuation)
	if item.has("projector"):
		spot.light_projector = load(String(item.projector)) as Texture2D
	spot.light_color = Color(String(item.color))
	spot.light_energy = float(item.energy)
	spot.light_specular = float(item.get("specular", 0.3))
	spot.light_size = float(item.get("size", 0.2))
	# Godot 4.7 的聚光投影贴图依赖阴影矩阵：不开阴影就投不出形状，所以带投影贴图的灯所有画质档都开阴影（光锥窄，开销小）
	spot.shadow_enabled = spot.light_projector != null
	spot.shadow_bias = 0.03
	spot.shadow_normal_bias = 0.2
	add_child(spot)
	spot.position = pos
	var dir := target - pos
	var up := Vector3.UP if absf(dir.normalized().y) < 0.98 else Vector3.FORWARD
	spot.basis = Basis.looking_at(dir, up).rotated(dir.normalized(), deg_to_rad(float(item.get("rollDeg", 0.0))))
	lights.append(spot)


static func _w(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x * 0.01, h, p.y * 0.01)


func _build_phone(c: Dictionary) -> void:
	## 屏幕朝上掉在沙发底的手机（真实 15 cm → 仓鼠尺度 67 cm），充电线从画面外的沙发底拖过来
	_phone_cfg = c
	var center := Vector2(float(c.position[0]), float(c.position[1]))
	var a := deg_to_rad(float(c.angleDeg))
	var root := Node3D.new()
	root.name = "Phone"
	add_child(root)
	root.position = _w(center)
	root.basis = Basis(Vector3.UP, -a)
	var b := RoomArchitecture.new()
	b.box("phone_body", Vector3(0, 0.018, 0), Vector3(0.67, 0.036, 0.32), 0.03)
	b.box("phone_screen", Vector3(-0.005, 0.037, 0), Vector3(0.6, 0.004, 0.28), 0.002)
	b.box("phone_card", Vector3(-0.17, 0.0395, 0), Vector3(0.11, 0.003, 0.24), 0.008)
	b.flush(root)
	var screen := root.get_node("phone_screen") as MeshInstance3D
	_phone_screen = screen.material_override as ShaderMaterial
	var card := root.get_node("phone_card") as MeshInstance3D
	for n: MeshInstance3D in [screen, card]:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_phone_light = OmniLight3D.new()
	_phone_light.name = "phone_glow"
	_phone_light.light_color = Color(String(c.color))
	_phone_light.omni_range = float(c.lightRange)
	_phone_light.omni_attenuation = 1.1
	_phone_light.light_specular = 0.3
	_phone_light.shadow_enabled = false
	root.add_child(_phone_light)
	_phone_light.position = Vector3(0, float(c.lightHeight), 0)
	lights.append(_phone_light)
	placements.append({"module": "phone", "position": center, "radius": 38.0})
	# 充电线：从手机底部的接口出发，按数据点弯到画面外
	var port := center + Vector2(cos(a), sin(a)) * 33.5
	var pts: Array[Vector2] = [port]
	for p: Array in c.get("cable", []):
		pts.append(Vector2(float(p[0]), float(p[1])))
	var r := float(c.get("cableRadiusCm", 1.6)) * 0.01
	var cable := MeshInstance3D.new()
	cable.name = "phone_cable"
	cable.mesh = tube_mesh(smooth_path(pts, 10), r, 7)
	cable.material_override = RoomArchitecture.material("cable")
	add_child(cable)
	_update_phone(0.0)


func _build_fairy(c: Dictionary) -> void:
	var colors: Array = c.colors
	var r := float(c.bulbRadiusCm) * 0.01
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var sphere := SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 2.3
	sphere.radial_segments = 10
	sphere.rings = 5
	mm.mesh = sphere
	var bulbs: Array[Vector2] = []
	var strand_i := 0
	for strand: Array in c.strands:
		var pts: Array[Vector2] = []
		for p: Array in strand:
			pts.append(Vector2(float(p[0]), float(p[1])))
		var path := smooth_path(pts, 12)
		var wire := MeshInstance3D.new()
		wire.name = "fairy_wire_%d" % strand_i
		wire.mesh = tube_mesh(path, 0.006, 5)
		wire.material_override = RoomArchitecture.material("fairy_wire")
		add_child(wire)
		for p in resample(path, int(c.bulbsPerStrand)):
			bulbs.append(p)
		strand_i += 1
	mm.instance_count = bulbs.size()
	for i in bulbs.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, _w(bulbs[i], r * 1.05)))
		mm.set_instance_color(i, Color(String(colors[i % colors.size()])))
		mm.set_instance_custom_data(i, Color(fposmod(float(i) * 0.37, 1.0), 0, 0, 0))
		placements.append({"module": "fairy_bulb", "position": bulbs[i], "radius": 8.0})
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "fairy_bulbs"
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/fairy_bulb.gdshader")
	mat.set_shader_parameter("emission_energy", float(c.emission))
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# 少量暖色补光，让灯串在地上留一圈光晕（中档以上）
	var lc: Dictionary = c.lights
	if quality_allows(String(lc.get("minQuality", "medium"))):
		var step := maxi(1, bulbs.size() / 4)
		var k := step / 2
		while k < bulbs.size():
			var l := OmniLight3D.new()
			l.name = "fairy_glow_%d" % k
			l.light_color = Color(String(lc.color))
			l.light_energy = float(lc.energy)
			l.omni_range = float(lc.range)
			l.omni_attenuation = 1.3
			l.light_specular = 0.2
			l.shadow_enabled = false
			add_child(l)
			l.position = _w(bulbs[k], 0.25)
			lights.append(l)
			k += step


func _process(delta: float) -> void:
	if _phone_light == null:
		return
	_t += delta
	_update_phone(_t)


func phone_level(t: float) -> float:
	## 手机屏幕亮度 0～1：每 period 秒亮一次（来通知），亮 onSeconds 秒后渐暗，暗的时候留一点待机微光
	var period := float(_phone_cfg.get("period", 13.0))
	var on := float(_phone_cfg.get("onSeconds", 5.0))
	var u := fposmod(t + period * 0.6, period)
	var level := smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(on, on + 1.2, u))
	return 0.12 + 0.88 * level


func _update_phone(t: float) -> void:
	var k := phone_level(t)
	_phone_light.light_energy = float(_phone_cfg.lightEnergy) * k
	_phone_screen.set_shader_parameter("emission", float(_phone_cfg.screenEmission) * k)
	var card := _phone_light.get_parent().get_node_or_null("phone_card") as MeshInstance3D
	if card:
		# 通知卡片只在亮屏时出现
		(card.material_override as ShaderMaterial).set_shader_parameter("emission", float(_phone_cfg.screenEmission) * 1.3 * maxf(k - 0.12, 0.0))


# --- 几何工具 ---------------------------------------------------------------

static func smooth_path(pts: Array[Vector2], per_segment: int) -> Array[Vector2]:
	## Catmull-Rom 平滑（厘米坐标）
	var out: Array[Vector2] = []
	if pts.size() < 2:
		return pts.duplicate()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for s in per_segment:
			var t := float(s) / per_segment
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


static func resample(path: Array[Vector2], count: int) -> Array[Vector2]:
	## 沿折线等弧长取 count 个点（两端各留半个间距）
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	var out: Array[Vector2] = []
	for k in count:
		var want := total * (float(k) + 0.5) / count
		var acc := 0.0
		for i in path.size() - 1:
			var seg := path[i].distance_to(path[i + 1])
			if acc + seg >= want:
				out.append(path[i].lerp(path[i + 1], (want - acc) / maxf(seg, 0.0001)))
				break
			acc += seg
	return out


static func tube_mesh(path: Array[Vector2], radius: float, sides: int) -> ArrayMesh:
	## 贴地的圆管（电线、灯串线）：path 厘米坐标，radius 米
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in path.size():
		var p := _w(path[i], radius)
		var fwd := (_w(path[mini(i + 1, path.size() - 1)]) - _w(path[maxi(i - 1, 0)])).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var ring: Array = []
		for s in sides:
			var a := TAU * float(s) / sides
			var n := (side * cos(a) + Vector3.UP * sin(a)).normalized()
			ring.append([p + n * radius, n])
		rings.append(ring)
	for i in rings.size() - 1:
		for s in sides:
			var s2 := (s + 1) % sides
			var quad := [rings[i][s], rings[i + 1][s], rings[i + 1][s2], rings[i][s], rings[i + 1][s2], rings[i][s2]]
			for v: Array in quad:
				st.set_normal(v[1])
				st.add_vertex(v[0])
	return st.commit()
