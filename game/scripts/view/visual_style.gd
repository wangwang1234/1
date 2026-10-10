class_name VisualStyle
extends RefCounted
## 集中管理画面参数；与战斗逻辑、视野和随机数完全分离。

## 当前画质档（Settings.apply 写入：low / medium / high）
static var quality := "high"


static func q() -> Dictionary:
	## 当前画质档的开关（visual_style.json 的 quality）
	var Q: Dictionary = section("quality")
	return Q.get(quality, Q.get("high", {}))


static func apply_quality() -> void:
	## 立即生效的全局渲染设置；环境、相机效果、房间灯在下一局开始时按档位创建
	var Q := q()
	RenderingServer.directional_soft_shadow_filter_set_quality(int(Q.get("softShadow", 4)))
	RenderingServer.positional_soft_shadow_filter_set_quality(int(Q.get("softShadow", 4)))
	RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_HIGH if quality == "high" else RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		bool(Q.get("ssaoHalf", false)), 0.5, 2, 50.0, 300.0)


static func config() -> Dictionary:
	return Data.load_json("visual_style")


static func section(key: String) -> Dictionary:
	return config().get(key, {})


static func surface_for(path: String) -> String:
	if path.contains("prop_lamp"):
		return "lamp"
	if path.contains("floor_wood"):
		return "wood"
	if path.contains("floor_tile"):
		return "tile"
	if path.contains("floor_carpet") or path.contains("rug_"):
		return "fabric"
	if path.contains("deco_"):
		return "decor"
	if path.contains("env_book_"):
		return "books"
	if path.contains("env_shelf"):
		return "shelf"
	if path.contains("chr_hamster"):
		return "character"
	return "object"


static func environment() -> Environment:
	var v := section("environment")
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#121928")
	var sky_cfg: Dictionary = v.sky
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(String(sky_cfg.topColor))
	sky_material.sky_horizon_color = Color(String(sky_cfg.horizonColor))
	sky_material.ground_bottom_color = Color(String(sky_cfg.groundColor))
	sky_material.ground_horizon_color = Color(String(sky_cfg.groundHorizonColor))
	sky_material.sky_energy_multiplier = float(sky_cfg.energy)
	sky_material.ground_energy_multiplier = float(sky_cfg.energy)
	sky_material.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.ambient_light_color = Color(String(v.ambientColor))
	e.ambient_light_energy = float(v.ambientEnergy)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = float(v.exposure)
	e.glow_enabled = true
	e.glow_intensity = float(v.glowIntensity)
	e.glow_hdr_threshold = float(v.glowThreshold)
	e.glow_bloom = 0.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var Q := q()
	e.ssao_enabled = bool(Q.get("ssao", true))
	e.ssao_radius = float(v.aoRadius)
	e.ssao_intensity = float(v.aoIntensity)
	e.ssao_power = 1.35
	e.ssao_detail = 0.5
	e.ssao_light_affect = float(v.get("aoLightAffect", 0.2))
	e.ssil_enabled = bool(Q.get("ssil", true))
	e.ssil_radius = float(v.get("indirectRadius", 0.6))
	e.ssil_intensity = float(v.indirectIntensity)
	e.adjustment_enabled = true
	e.adjustment_saturation = float(v.saturation)
	e.adjustment_contrast = float(v.contrast)
	return e


static func moon() -> DirectionalLight3D:
	var v := section("environment")
	var l := DirectionalLight3D.new()
	l.name = "Moon"
	l.light_color = Color(String(v.moonColor))
	l.light_energy = float(v.moonEnergy)
	var a: Array = v.moonRotation
	l.rotation_degrees = Vector3(float(a[0]), float(a[1]), float(a[2]))
	l.light_specular = float(v.moonSpecular)
	l.shadow_enabled = true
	l.light_angular_distance = float(v.shadowSoftness)
	var splits := int(q().get("shadowSplits", 4))
	l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if splits >= 4 else (DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if splits >= 2 else DirectionalLight3D.SHADOW_ORTHOGONAL)
	l.directional_shadow_max_distance = float(v.shadowDistance)
	l.directional_shadow_blend_splits = true
	l.shadow_bias = 0.025
	l.shadow_normal_bias = 0.5
	return l
