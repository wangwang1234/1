class_name StreakBannerUI
extends Control
## 一个视口对应一名本地玩家。占位阶段只更新静态状态和停留，不实现第四阶段重动画。

var config: KillConfig
var player_id: int = -1
var event: Dictionary = {}
var current_streak: int = 0
var remaining: float = 0.0
var assist_text: String = ""
var assist_remaining: float = 0.0
var death_text: String = ""
var death_method: String = "normal"
var has_death: bool = false
var death_snapshot_target: int = -1
var seed_center: Vector2 = Vector2.ZERO
var bottom_exclusion: float = 0.0 # 触控按钮/摇杆最上边界，以视口坐标传入。
var title_label: Label
var number_label: Label
var subtitle_label: Label


func setup(settings: KillConfig, owner: int) -> void:
	config = settings
	player_id = owner
	UiTheme.fonts()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_label = _label(UiTheme.display_font)
	number_label = _label(UiTheme.display_font)
	subtitle_label = _label(UiTheme.body_font)
	resized.connect(_layout)
	_layout()


func _label(font: Font) -> Label:
	var result := Label.new()
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font)
	result.add_theme_color_override("font_outline_color", config.title_ink)
	result.add_theme_color_override("font_color", config.white_title)
	result.hide()
	add_child(result)
	return result


func receive(packet: Dictionary) -> void:
	if int(packet.get("victim_id", -1)) == player_id:
		defeated()
		var killer := int(packet.get("killer_id", -1))
		death_text = "你被击败" if killer < 0 else "被 %s 击败" % KillUIStyle.name_of(packet, killer)
		death_method = String(packet.get("method", "normal"))
		has_death = true
		death_snapshot_target = int(packet.get("victim_death_count", -1))
	if int(packet.get("killer_id", -1)) == player_id and bool(packet.get("killer_connected", false)):
		event = packet.duplicate(true)
		current_streak = int(packet.killer_streak)
		remaining = config.five_stay if current_streak == config.five_streak else (config.unstoppable_stay if current_streak >= config.unstoppable_streak else config.ordinary_stay)
		_layout() # 连续收到击败直接更新瓜子与文字，停留重新计时。
	for row: Dictionary in packet.get("assists", []):
		if int(row.player_id) == player_id and bool(row.get("connected", true)):
			assist_text = "助攻 +%d" % int(row.reward)
			assist_remaining = config.assist_stay
	queue_redraw()


func defeated() -> void:
	remaining = 0.0
	current_streak = 0
	event.clear()
	assist_text = ""
	assist_remaining = 0.0
	_layout()
	queue_redraw()


func respawned() -> void:
	has_death = false
	death_snapshot_target = -1
	death_text = ""
	queue_redraw()


func tick(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	assist_remaining = maxf(0.0, assist_remaining - delta)
	_layout()
	queue_redraw()


func _layout() -> void:
	if config == null or title_label == null:
		return
	var scale := size.y / config.reference_height
	seed_center = Vector2(size.x * 0.5, size.y * (1.0 - config.seed_bottom_ratio))
	if bottom_exclusion > 0.0:
		seed_center.y = minf(seed_center.y, bottom_exclusion - (config.gold_seed_height * 0.5 + config.mobile_clearance) * scale)
	var showing := remaining > 0.0 and current_streak > 0
	title_label.visible = showing
	number_label.visible = showing and current_streak >= config.unstoppable_streak
	subtitle_label.visible = showing and not KillUIStyle.tags(event).is_empty()
	if not showing:
		return
	var highlight := current_streak >= config.five_streak
	var font_size := maxi(1, roundi((config.highlight_title_size if highlight else config.title_size) * scale))
	title_label.text = KillUIStyle.title(current_streak, config)
	title_label.add_theme_font_size_override("font_size", font_size)
	title_label.add_theme_constant_override("outline_size", roundi(config.title_outline * scale))
	number_label.text = str(current_streak)
	number_label.add_theme_font_size_override("font_size", font_size)
	number_label.add_theme_constant_override("outline_size", roundi(config.title_outline * scale))
	subtitle_label.text = " · ".join(KillUIStyle.tags(event))
	subtitle_label.add_theme_font_size_override("font_size", maxi(1, roundi(config.subtitle_size * scale)))
	subtitle_label.add_theme_color_override("font_color", config.subtitle_color)
	subtitle_label.add_theme_constant_override("outline_size", roundi(config.subtitle_outline * scale))
	var title_width := UiTheme.display_font.get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var number_width := UiTheme.display_font.get_string_size(number_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if number_label.visible else 0.0
	var icons_width := KillUIStyle.tags(event).size() * (config.tag_icon_size + config.seed_gap) * scale
	var total_width := title_width + icons_width + (number_width + config.seed_gap * scale if number_label.visible else 0.0)
	var title_height := title_label.get_minimum_size().y
	var subtitle_height := subtitle_label.get_minimum_size().y if subtitle_label.visible else 0.0
	var top := seed_center.y - config.gold_seed_height * scale * 0.5 - config.title_gap * scale - subtitle_height - title_height
	title_label.position = Vector2(seed_center.x - total_width * 0.5 + icons_width, top)
	title_label.size = Vector2(title_width, title_height)
	number_label.position = Vector2(title_label.position.x + title_width + config.seed_gap * scale, top)
	number_label.size = Vector2(number_width, title_height)
	subtitle_label.size = subtitle_label.get_minimum_size()
	subtitle_label.position = Vector2(seed_center.x - subtitle_label.size.x * 0.5, top + title_height)
	for label in [title_label, number_label]:
		if highlight:
			if label.material == null:
				var mat := ShaderMaterial.new()
				mat.shader = load("res://shaders/kill_title_gradient.gdshader")
				label.material = mat
			label.material.set_shader_parameter("top_color", config.gold_top)
			label.material.set_shader_parameter("bottom_color", config.gold_bottom)
			label.material.set_shader_parameter("gradient_height", maxf(1.0, title_height))
		else:
			label.material = null


func _draw() -> void:
	if config == null:
		return
	var scale := size.y / config.reference_height
	if remaining > 0.0 and current_streak > 0:
		var counts := KillUIStyle.gold_counts(current_streak, config)
		var normal_size := Vector2(config.seed_height * config.seed_width_ratio, config.seed_height) * scale
		var gold_size := Vector2(config.gold_seed_height * config.seed_width_ratio, config.gold_seed_height) * scale
		var gap := config.seed_gap * scale
		var total: float = int(counts.visible) * gold_size.x + int(counts.normal) * normal_size.x + maxi(0, int(counts.visible) + int(counts.normal) - 1) * gap
		var x: float = seed_center.x - total * 0.5
		for i in int(counts.visible):
			KillUIStyle.icon(self, Rect2(Vector2(x, seed_center.y - gold_size.y * 0.5), gold_size), "gold", config)
			if int(counts.multiplier) > 0:
				KillUIStyle.text(self, Vector2(x + gold_size.x * 0.6, seed_center.y - gold_size.y * 0.3), "×%d" % counts.multiplier, UiTheme.body_font, maxi(1, roundi(config.subtitle_size * scale)), config.gold_top, config, roundi(config.subtitle_outline * scale))
			x += gold_size.x + gap
		for i in int(counts.normal):
			KillUIStyle.icon(self, Rect2(Vector2(x, seed_center.y - normal_size.y * 0.5), normal_size), "seed", config)
			x += normal_size.x + gap
		var icon_x := title_label.position.x - KillUIStyle.tags(event).size() * (config.tag_icon_size + config.seed_gap) * scale
		for icon in ["first", "shutdown"]:
			if bool(event.get("is_first_kill" if icon == "first" else "is_shutdown", false)):
				var icon_size := config.tag_icon_size * scale
				KillUIStyle.icon(self, Rect2(icon_x, title_label.position.y + (title_label.size.y - icon_size) * 0.5, icon_size, icon_size), icon, config)
				icon_x += (config.tag_icon_size + config.seed_gap) * scale
	if assist_remaining > 0.0:
		var font_size := maxi(1, roundi(config.toast_font_size * scale))
		var width := UiTheme.body_font.get_string_size(assist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		KillUIStyle.text(self, Vector2(seed_center.x - width * 0.5, seed_center.y), assist_text, UiTheme.body_font, font_size, config.subtitle_color, config, roundi(config.subtitle_outline * scale))
	if has_death:
		var font_size := maxi(1, roundi(config.title_size * scale))
		var text := KillUIStyle.elide(death_text, UiTheme.display_font, font_size, size.x - (config.method_icon_size + config.viewport_margin * 2.0) * scale)
		var width := UiTheme.display_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var icon_size := config.method_icon_size * scale
		var start := Vector2((size.x - width - icon_size - config.seed_gap * scale) * 0.5, size.y * config.death_top_ratio)
		KillUIStyle.icon(self, Rect2(start, Vector2.ONE * icon_size), death_method, config)
		KillUIStyle.text(self, start + Vector2(icon_size + config.seed_gap * scale, UiTheme.display_font.get_ascent(font_size)), text, UiTheme.display_font, font_size, config.white_title, config, roundi(config.title_outline * scale))
