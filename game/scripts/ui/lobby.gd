class_name Lobby
extends PanelContainer
## 开局大厅（GDD 第 16 节）：模式（单人 / 双人同屏）、地图、玩家队伍和形象、2P 操作方式、两队 AI 补位人数、初始武器（测试用）。
## 选择记在 Settings.lobby 里，下次打开保持上次的设置。

signal start_requested(opts: Dictionary)
signal closed
signal skin_changed(skin: String)

const DEFAULTS := {"duo": false, "mode": "full", "p1_team": "blue", "p2_team": "red", "p2_input": "pad", "skin": "gold", "skin2": "pudding",
	"ai_blue": 4, "ai_red": 5, "ai_auto": true, "weapon": "pistol"}
## AI 自动配平时每队凑满几只（完整地图 5 对 5，中路小图 3 对 3）
const TEAM_SIZE := {"full": 5, "slice": 3}

var o := {}
var rows := {}
var ai_labels := {}
var help: Label
var weapon_pick: OptionButton
var seg_btns: Array = []      # [[key, value, Button]]
var auto_btn: Button


func _ready() -> void:
	theme = UiTheme.theme()
	o = DEFAULTS.duplicate()
	o.merge(Settings.lobby, true)
	custom_minimum_size = Vector2(820, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var title := UiTheme.label("开局设置", 46, UiTheme.GOLD, true, 8)
	v.add_child(title)
	rows.mode = _seg(v, "模式", "duo", [[false, "单人"], [true, "双人同屏"]])
	rows.map = _seg(v, "地图", "mode", [["full", "完整地图（三条兵线）"], ["slice", "中路小图"]])
	rows.p1_team = _seg(v, "玩家1 队伍" if bool(o.duo) else "队伍", "p1_team", [["blue", "蓝队"], ["red", "红队"]])
	rows.skin = _seg(v, "玩家1 形象" if bool(o.duo) else "形象", "skin", _skin_opts())
	rows.p2_team = _seg(v, "玩家2 队伍", "p2_team", [["blue", "蓝队"], ["red", "红队"]])
	rows.p2_input = _seg(v, "玩家2 操作", "p2_input", [["pad", "手柄"], ["keys2", "方向键"]])
	rows.skin2 = _seg(v, "玩家2 形象", "skin2", _skin_opts())
	# AI 补位
	var ar := _row(v, "AI 补位")
	for team in ["blue", "red"]:
		var tc := UiTheme.BLUE if team == "blue" else UiTheme.RED
		ar.add_child(UiTheme.label("蓝队" if team == "blue" else "红队", 22, tc, true, 4))
		var minus := _small_btn("−")
		var plus := _small_btn("+")
		var lab := UiTheme.label(str(int(o["ai_" + team])), 28, UiTheme.CREAM, true, 4)
		lab.custom_minimum_size = Vector2(36, 0)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ai_labels[team] = lab
		var key: String = "ai_" + team
		minus.pressed.connect(func() -> void: _ai(key, -1))
		plus.pressed.connect(func() -> void: _ai(key, 1))
		ar.add_child(minus)
		ar.add_child(lab)
		ar.add_child(plus)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(18, 0)
		ar.add_child(gap)
	# 自动配平：按队伍里的真人数补满（手动按 +/− 后关掉，按这个按钮再打开）
	auto_btn = Button.new()
	auto_btn.theme_type_variation = "GhostButton"
	auto_btn.toggle_mode = true
	auto_btn.text = "自动配平"
	auto_btn.add_theme_font_size_override("font_size", 18)
	auto_btn.toggled.connect(func(on: bool) -> void:
		o.ai_auto = on
		Audio.play2d("ui_click", -8.0)
		_refresh())
	ar.add_child(auto_btn)
	# 初始武器（测试用）
	var wr := _row(v, "初始武器")
	weapon_pick = OptionButton.new()
	weapon_pick.theme_type_variation = "GhostButton"
	weapon_pick.add_theme_font_size_override("font_size", 20)
	var ids: Array = Data.weapons().keys()
	for i in ids.size():
		weapon_pick.add_item(String(Data.weapon(ids[i]).name), i)
		var ip := "res://assets/icons/wpn_%s.png" % ids[i]
		if ResourceLoader.exists(ip):
			weapon_pick.set_item_icon(i, load(ip))
		if ids[i] == o.weapon:
			weapon_pick.select(i)
	weapon_pick.add_theme_constant_override("icon_max_width", 48)
	weapon_pick.item_selected.connect(func(i: int) -> void:
		o.weapon = ids[i]
		Audio.play2d("ui_click", -8.0))
	wr.add_child(weapon_pick)
	wr.add_child(UiTheme.label("测试用：正式规则是手枪起步", 17, UiTheme.SUB, false, 0))
	help = UiTheme.label("", 18, UiTheme.SUB, false, 0)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(760, 0)
	v.add_child(help)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 16)
	v.add_child(btns)
	var go := Button.new()
	go.text = "开始对局"
	go.custom_minimum_size = Vector2(280, 0)
	go.pressed.connect(_start)
	btns.add_child(go)
	var back := Button.new()
	back.theme_type_variation = "GhostButton"
	back.text = "返回"
	back.pressed.connect(_close)
	btns.add_child(back)
	_refresh()
	go.call_deferred("grab_focus")


func _skin_opts() -> Array:
	var out: Array = []
	for id in Data.skin_ids():
		out.append([id, String(Data.skins()[id].name)])
	return out


func _row(v: VBoxContainer, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := UiTheme.label(text, 22, UiTheme.SUB, false, 0)
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	h.set_meta("label", l)
	v.add_child(h)
	return h


func _seg(v: VBoxContainer, text: String, key: String, opts: Array) -> HBoxContainer:
	var h := _row(v, text)
	var grp := ButtonGroup.new()
	for op in opts:
		var b := Button.new()
		b.theme_type_variation = "GhostButton"
		b.toggle_mode = true
		b.button_group = grp
		b.text = String(op[1])
		b.button_pressed = o.get(key) == op[0]
		var val: Variant = op[0]
		seg_btns.append([key, val, b])
		b.pressed.connect(func() -> void:
			o[key] = val
			Audio.play2d("ui_click", -8.0)
			if key == "skin":
				skin_changed.emit(String(val))
			_refresh())
		h.add_child(b)
	return h


func _small_btn(t: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.text = t
	b.custom_minimum_size = Vector2(46, 0)
	return b


func _ai(key: String, d: int) -> void:
	o.ai_auto = false
	o[key] = clampi(int(o[key]) + d, 0, 6)
	Audio.play2d("ui_click", -8.0)
	_refresh()


func _refresh() -> void:
	for sb in seg_btns:
		(sb[2] as Button).set_pressed_no_signal(o.get(sb[0]) == sb[1])
	var duo := bool(o.duo)
	for k in ["p2_team", "p2_input", "skin2"]:
		(rows[k] as Control).visible = duo
	((rows.p1_team as HBoxContainer).get_meta("label") as Label).text = "玩家1 队伍" if duo else "队伍"
	((rows.skin as HBoxContainer).get_meta("label") as Label).text = "玩家1 形象" if duo else "形象"
	var humans := {"blue": 0, "red": 0}
	humans[String(o.p1_team)] += 1
	if duo:
		humans[String(o.p2_team)] += 1
	if bool(o.get("ai_auto", true)):
		var per := int(TEAM_SIZE.get(String(o.mode), 5))
		for team in ["blue", "red"]:
			o["ai_" + team] = maxi(0, per - int(humans[team]))
	auto_btn.set_pressed_no_signal(bool(o.get("ai_auto", true)))
	for team in ["blue", "red"]:
		(ai_labels[team] as Label).text = str(int(o["ai_" + team]))
	var t := ""
	if not duo:
		t = "WASD 移动 · 鼠标瞄准、左键射击 · 空格翻滚 · R 换弹 · Q 道具 · 1/2/3 选卡 · Esc 暂停\n接上手柄按一下就能切换到手柄操作"
	else:
		t = "玩家1：WASD 移动 · 鼠标瞄准射击 · 空格翻滚 · R 换弹 · Q 道具 · 1/2/3 选卡\n"
		if String(o.p2_input) == "pad":
			t += "玩家2（手柄）：左摇杆移动 · 右摇杆瞄准（不推时自动瞄准）· RT 射击 · A 翻滚 · X 换弹 · LB 道具 · X/Y/B 选卡"
			if Input.get_connected_joypads().is_empty():
				t += "\n还没检测到手柄：开局后先用方向键操作，接上手柄会自动切换"
		else:
			t += "玩家2（方向键）：方向键移动（自动瞄准）· 回车射击 · 右 Shift 翻滚 · / 换弹 · . 道具 · 8/9/0 选卡"
	var nb := int(o.ai_blue) + (1 if String(o.p1_team) == "blue" else 0) + (1 if duo and String(o.p2_team) == "blue" else 0)
	var nr := int(o.ai_red) + (1 if String(o.p1_team) == "red" else 0) + (1 if duo and String(o.p2_team) == "red" else 0)
	help.text = "%s\n本局：蓝队 %d 只 vs 红队 %d 只" % [t, nb, nr]


func _start() -> void:
	Settings.lobby = o.duplicate()
	Settings.save_cfg()
	Audio.play2d("ui_click", -6.0)
	start_requested.emit(o.duplicate())


func _close() -> void:
	Audio.play2d("ui_click", -6.0)
	closed.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
