class_name ResultScreen
extends CanvasLayer
## 结算：胜利 / 失败大字 + 双方战绩表（等级、击倒、倒下、伤害、拆塔伤害）+ 再来一局 / 返回主菜单。

signal again_requested
signal menu_requested

var root: Control
var _t := 0.0
var _title: Label


func show_result(local_team: String, stats: Dictionary) -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.025, 0.07, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	cc.add_child(v)
	var won := String(stats.get("winner", "")) == local_team
	_title = UiTheme.label("胜利！" if won else "惜败…", 140, UiTheme.GOLD if won else Color("#b9b0c9"), true, 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.pivot_offset = Vector2(300, 80)
	v.add_child(_title)
	var t := float(stats.get("time", 0.0))
	var sub := UiTheme.label(("零食全归我们了" if won else "对面的鼠窝笑到了最后") + "   ·   用时 %d:%02d" % [int(t) / 60, int(t) % 60], 26, UiTheme.CREAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var panel := PanelContainer.new()
	v.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)
	for hd: String in ["仓鼠", "等级", "击倒", "倒下", "伤害", "拆塔"]:
		grid.add_child(UiTheme.label(hd, 20, UiTheme.SUB, false, 4))
	var players: Array = stats.get("players", [])
	players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.team != b.team:
			return String(a.team) == local_team
		return int(a.kills) > int(b.kills))
	for p: Dictionary in players:
		var col := UiTheme.BLUE if p.team == "blue" else UiTheme.RED
		var nm := String(p.name) + ("（你）" if bool(p.get("local", false)) else "")
		grid.add_child(UiTheme.label(nm, 24, col.lightened(0.25) if bool(p.get("local", false)) else col, false, 5))
		for k: String in ["lvl", "kills", "deaths", "dmg", "bdmg"]:
			grid.add_child(UiTheme.label(str(p.get(k, 0)), 24, UiTheme.CREAM, k == "kills", 5))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 22)
	v.add_child(hb)
	var again := Button.new()
	again.text = "再来一局"
	again.pressed.connect(func() -> void:
		Audio.play2d("ui_click", -6.0)
		again_requested.emit())
	hb.add_child(again)
	var menu := Button.new()
	menu.text = "返回主菜单"
	menu.theme_type_variation = "GhostButton"
	menu.pressed.connect(func() -> void:
		Audio.play2d("ui_click", -6.0)
		menu_requested.emit())
	hb.add_child(menu)
	again.call_deferred("grab_focus")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	root.modulate.a = 0.0


func _process(delta: float) -> void:
	if root == null:
		return
	_t += delta
	root.modulate.a = minf(1.0, _t * 3.0)
	var k := minf(1.0, _t * 2.2)
	var s := 1.0 + 0.6 * pow(1.0 - k, 3.0) + sin(_t * 2.0) * 0.015
	_title.scale = Vector2(s, s)
