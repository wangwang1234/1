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
	var winner := String(stats.get("winner", ""))
	var won := winner == local_team
	var locals: Array = stats.get("locals", [])
	var versus := locals.size() > 1 and String(locals[0].team) != String(locals[1].team)
	var title_text := "胜利！" if won else "惜败…"
	if versus:
		for lp in locals:
			if String(lp.team) == winner:
				title_text = "%s 赢了！" % lp.name
		won = true
	elif locals.size() > 1:
		won = String(locals[0].team) == winner
		title_text = "胜利！" if won else "惜败…"
	_title = UiTheme.label(title_text, 140, UiTheme.GOLD if won else Color("#b9b0c9"), true, 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.pivot_offset = Vector2(300, 80)
	v.add_child(_title)
	var t := float(stats.get("time", 0.0))
	var sub_t := ("零食全归我们了" if won else "对面的鼠窝笑到了最后")
	if versus:
		sub_t = "%s打爆了对方的仓鼠窝" % ("蓝队" if winner == "blue" else "红队")
	var sub := UiTheme.label(sub_t + "   ·   用时 %d:%02d" % [int(t) / 60, int(t) % 60], 26, UiTheme.CREAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var panel := PanelContainer.new()
	v.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(grid)
	var players: Array = stats.get("players", [])
	# MVP：赢的一方里表现最好的
	var mvp := ""
	var best := -1.0
	for p: Dictionary in players:
		if String(p.team) != winner:
			continue
		var score := int(p.kills) * 2.0 + float(p.dmg) / 500.0 + float(p.bdmg) / 300.0 - int(p.deaths) * 0.5
		if score > best:
			best = score
			mvp = String(p.name)
	var first_team := local_team
	for team in [first_team, "red" if first_team == "blue" else "blue"]:
		var tc := UiTheme.BLUE if team == "blue" else UiTheme.RED
		var tk := 0
		var tb := 0
		for p: Dictionary in players:
			if p.team == team:
				tk += int(p.kills)
				tb += int(p.bdmg)
		var head := UiTheme.label(("蓝队" if team == "blue" else "红队") + ("（胜）" if team == winner else ""), 26, tc, true, 5)
		grid.add_child(head)
		for hd: String in ["武器", "等级", "击倒", "倒下", "伤害", "拆塔", ""]:
			grid.add_child(UiTheme.label(hd, 18, UiTheme.SUB, false, 4))
		var rows := players.filter(func(p): return p.team == team)
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.kills) > int(b.kills))
		for p: Dictionary in rows:
			var nm := String(p.name)
			if bool(p.get("local", false)) and nm != "你" and not nm.begins_with("玩家"):
				nm += "（你）"
			grid.add_child(UiTheme.label(nm, 23, tc.lightened(0.25) if bool(p.get("local", false)) else tc, false, 5))
			var wn := String(Data.weapon(String(p.get("weapon", "pistol"))).get("name", ""))
			var evo: Array = p.get("evo", [0, 0, 0])
			var evs := ""
			for i in 3:
				if int(evo[i]) > 0:
					evs += " %s%d" % [["A", "B", "C"][i], int(evo[i])]
			grid.add_child(UiTheme.label(wn + evs, 18, UiTheme.CREAM, false, 4))
			for k: String in ["lvl", "kills", "deaths", "dmg", "bdmg"]:
				grid.add_child(UiTheme.label(str(p.get(k, 0)), 23, UiTheme.GOLD if k == "kills" else UiTheme.CREAM, false, 5))
			grid.add_child(UiTheme.label("MVP" if String(p.name) == mvp else "", 20, UiTheme.GOLD, true, 5))
		if team == first_team:
			for i in 8:
				var gap := Control.new()
				gap.custom_minimum_size = Vector2(0, 10)
				grid.add_child(gap)
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
