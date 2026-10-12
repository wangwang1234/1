class_name GlobalBannerUI
extends RefCounted
## 一个客户端共享全场横幅队列。每个分屏视口分别按高度布局。

var config: KillConfig
var queue: Array[String] = []
var current: String = ""
var age: float = 0.0
var canvases: Array[Control] = []


func _init(settings: KillConfig) -> void:
	config = settings
	UiTheme.fonts()


func attach(parent: Node) -> GlobalCanvas:
	var canvas := GlobalCanvas.new()
	canvas.model = self
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvases.append(canvas)
	return canvas


func receive(event: Dictionary) -> void:
	var labels := PackedStringArray()
	var count := int(event.get("killer_streak", 0))
	if bool(event.get("killer_connected", false)):
		if count == config.five_streak:
			labels.append("五重击败")
		elif count == config.unstoppable_streak:
			labels.append("鼠向披靡 %d" % count)
	labels.append_array(KillUIStyle.tags(event))
	if labels.is_empty():
		return
	queue.append(KillUIStyle.name_of(event, int(event.killer_id)) + " · " + " · ".join(labels))
	if current.is_empty():
		_next()


func _next() -> void:
	current = "" if queue.is_empty() else queue.pop_front()
	age = 0.0


func tick(delta: float) -> void:
	age += delta
	if not current.is_empty() and age >= config.banner_stay:
		_next()
	for canvas in canvases:
		if is_instance_valid(canvas):
			canvas.queue_redraw()


func clear() -> void:
	queue.clear()
	current = ""
	age = 0.0


class GlobalCanvas:
	extends Control
	var model: GlobalBannerUI

	func _draw() -> void:
		if model == null or model.current.is_empty():
			return
		var cfg := model.config
		var scale := size.y / cfg.reference_height
		var font_size := maxi(1, roundi(cfg.banner_size * scale))
		var width := size.x - cfg.viewport_margin * scale * 2.0
		var text := KillUIStyle.elide(model.current, UiTheme.display_font, font_size, width)
		var actual := UiTheme.display_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		KillUIStyle.text(self, Vector2((size.x - actual) * 0.5, size.y * cfg.banner_top_ratio + UiTheme.display_font.get_ascent(font_size)), text, UiTheme.display_font, font_size, cfg.gold_top, cfg, roundi(cfg.title_outline * scale))
