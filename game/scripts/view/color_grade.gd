class_name ColorGrade
extends RefCounted
## 全局调色：运行时按 visual_style.json 的 grade 段生成 3D 查找表，接到 Environment 的颜色校正上。
## 分离色调——暗部往冷紫偏并轻微抬起（夜色不是死黑），亮部往暖偏；高饱和的颜色（队伍色、特效、曳光）按饱和度少受影响，
## 保证“队伍色永远最醒目”。只是一次查表，所有画质档都开，手机也一样。

static var _cache_key := ""
static var _cache: ImageTexture3D


static func luma(c: Color) -> float:
	return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722


static func prepare(g: Dictionary) -> Dictionary:
	## 把 grade 段解析成查表循环里直接用的数值（只解析一次）
	var shadow_tint := Color(String(g.get("shadowTint", "#5b46a8")))
	var high_tint := Color(String(g.get("highlightTint", "#ffd7a3")))
	return {
		"st": Vector3(shadow_tint.r, shadow_tint.g, shadow_tint.b),
		"stn": Vector3(shadow_tint.r, shadow_tint.g, shadow_tint.b) / maxf(luma(shadow_tint), 0.001),
		"htn": Vector3(high_tint.r, high_tint.g, high_tint.b) / maxf(luma(high_tint), 0.001),
		"protect": float(g.get("saturationProtect", 0.7)),
		"shadowRange": float(g.get("shadowRange", 0.42)),
		"highlightStart": float(g.get("highlightStart", 0.55)),
		"shadowAmount": float(g.get("shadowAmount", 0.4)),
		"highlightAmount": float(g.get("highlightAmount", 0.15)),
		"shadowLift": float(g.get("shadowLift", 0.025)),
		"vibrance": float(g.get("vibrance", 0.2)),
	}


static func grade(c: Color, p: Dictionary) -> Color:
	## 单个颜色的调色结果（显示空间 0～1）；p 来自 prepare()。查找表和测试共用
	var l := luma(c)
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	var sat := 0.0 if mx <= 0.0001 else (mx - mn) / mx
	var keep := 1.0 - clampf(sat * float(p.protect), 0.0, 1.0)
	var ws := (1.0 - smoothstep(0.0, float(p.shadowRange), l)) * keep
	var wh := smoothstep(float(p.highlightStart), 1.0, l) * keep
	var out := Vector3(c.r, c.g, c.b)
	# 保持亮度的着色：往同亮度的色调色上混
	out = out.lerp((p.stn as Vector3) * l, ws * float(p.shadowAmount))
	out = out.lerp((p.htn as Vector3) * l, wh * float(p.highlightAmount))
	# 暗部抬一点紫：越暗越明显，纯黑变成深靛紫
	out += (p.st as Vector3) * float(p.shadowLift) * (1.0 - smoothstep(0.0, 0.25, l))
	# 自然饱和度：灰的颜色加得多，已经很艳的几乎不动
	var vib := float(p.vibrance) * (1.0 - sat)
	var l2 := out.x * 0.2126 + out.y * 0.7152 + out.z * 0.0722
	out = Vector3(l2, l2, l2).lerp(out, 1.0 + vib)
	return Color(clampf(out.x, 0.0, 1.0), clampf(out.y, 0.0, 1.0), clampf(out.z, 0.0, 1.0))


static func texture(g: Dictionary = {}) -> ImageTexture3D:
	if g.is_empty():
		g = VisualStyle.section("grade")
	if not bool(g.get("enabled", true)):
		return null
	var key := JSON.stringify(g)
	if key == _cache_key and _cache != null:
		return _cache
	var n := int(g.get("lutSize", 32))
	var p := prepare(g)
	var layers: Array[Image] = []
	for b in n:
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for gg in n:
			for r in n:
				var c := Color(float(r) / (n - 1), float(gg) / (n - 1), float(b) / (n - 1))
				img.set_pixel(r, gg, grade(c, p))
		layers.append(img)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, n, n, n, false, layers)
	_cache_key = key
	_cache = tex
	return tex


static func apply(e: Environment) -> void:
	var tex := texture()
	if tex != null:
		e.adjustment_enabled = true
		e.adjustment_color_correction = tex
