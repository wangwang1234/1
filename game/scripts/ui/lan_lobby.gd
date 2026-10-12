class_name LanLobby
extends PanelContainer

signal closed

var nickname: LineEdit
var address: LineEdit
var port: SpinBox
var team: OptionButton
var skin: OptionButton
var weapon: OptionButton
var gadget_picks := {}     # 开局道具：开局池里有 2 个以上道具的槽才有（q / e -> OptionButton）
var map_pick: OptionButton
var roster_label: Label
var team_lists: = {}
var search_rows: Array[Control] = []
var team_box: HBoxContainer
var status_label: Label
var host_btn: Button
var join_btn: Button
var ready_btn: Button
var start_btn: Button
var leave_btn: Button
var room_pick: OptionButton
var room_join: Button
var _refreshing: = false


func _ready() -> void :
	theme = UiTheme.theme().duplicate()
	theme.set_color("font_color", "OptionButton", UiTheme.CREAM)
	theme.set_color("font_color", "LineEdit", UiTheme.CREAM)
	theme.set_color("font_placeholder_color", "LineEdit", Color("#a89bb8"))
	custom_minimum_size = Vector2(850, 0)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(UiTheme.label("局域网联机", 46, UiTheme.GOLD, true, 8))
	v.add_child(UiTheme.label("最多 %d 台电脑连接同一 Wi-Fi / 路由器 · 各自独立画面 · 自由分队，空位由 AI 补齐" % int(Data.load_json("network").maxPlayers), 18, Color("#c4bbd2")))
	var name_row: = _row(v, "你的昵称")
	nickname = LineEdit.new()
	nickname.text = "玩家"
	nickname.max_length = 16
	nickname.custom_minimum_size.x = 260
	name_row.add_child(nickname)
	nickname.text_submitted.connect( func(_t: String) -> void : _profile_changed())
	nickname.focus_exited.connect(_profile_changed)
	team = _pick(_row(v, "队伍"), [["blue", "蓝队"], ["red", "红队"]])
	var skins: Array = []
	for id in Data.skin_ids():
		skins.append([id, Data.skins()[id].name])
	skin = _pick(_row(v, "形象"), skins)
	var weapons: Array = []
	for id in Data.active_weapons():
		weapons.append([id, Data.weapon(id).name])
	weapon = _pick(_row(v, "初始武器"), weapons)
	for slot: String in ["q", "e"]:
		var pool := Data.gadget_pool(slot, "start")
		if pool.size() >= 2:
			var gl: Array = []
			for id in pool:
				gl.append([id, Data.gadget(id).name])
			gadget_picks[slot] = _pick(_row(v, "开局%s（%s）" % [Data.gadgets().slots[slot].name, slot.to_upper()]), gl)
	map_pick = _pick(_row(v, "房主地图"), [["full", "完整地图（三条兵线）"], ["slice", "中路小图"]])
	var ip_row: = _row(v, "房主 IP")
	address = LineEdit.new()
	address.placeholder_text = "例如 192.168.1.23"
	address.custom_minimum_size.x = 290
	ip_row.add_child(address)
	ip_row.add_child(UiTheme.label("端口", 20, UiTheme.SUB))
	port = SpinBox.new()
	port.min_value = 1024
	port.max_value = 65535
	port.value = int(Data.load_json("network").port)
	port.custom_minimum_size.x = 140
	ip_row.add_child(port)
	search_rows.append(ip_row)
	var found_row := _row(v, "附近房间")
	room_pick = OptionButton.new()
	room_pick.theme_type_variation = "GhostButton"
	room_pick.custom_minimum_size.x = 440
	room_pick.add_theme_font_size_override("font_size", 18)
	found_row.add_child(room_pick)
	search_rows.append(found_row)
	room_join = _button(found_row, "直接加入", _join_found)
	room_pick.item_selected.connect(func(_i: int) -> void: _select_found())
	LanSession.discovery.changed.connect(_refresh_rooms)
	LanSession.scan_rooms()
	_refresh_rooms()
	var ips: = LanSession.addresses()
	var ip_label: = UiTheme.label("本机 IP：" + ("、".join(ips) if not ips.is_empty() else "未检测到局域网 IPv4") + "\n可直接选择附近房间；搜索不到时，填写房主 IP 和端口加入。", 18, Color("#c4bbd2"))
	ip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ip_label.custom_minimum_size.x = 790
	v.add_child(ip_label)
	search_rows.append(ip_label)
	var connection: = HBoxContainer.new()
	connection.add_theme_constant_override("separation", 12)
	v.add_child(connection)
	search_rows.append(connection)
	host_btn = _button(connection, "创建房间", func() -> void : LanSession.host(_profile(), {"mode": _value(map_pick)}, int(port.value)))
	join_btn = _button(connection, "加入房间", func() -> void : LanSession.join(address.text, _profile(), int(port.value)))
	roster_label = UiTheme.label("", 20, Color("#d8cfe3"))
	v.add_child(roster_label)
	var teams: = HBoxContainer.new()
	teams.add_theme_constant_override("separation", 24)
	v.add_child(teams)
	team_box = teams
	for t in [["blue", "蓝队", Color("#8fc4ff")], ["red", "红队", Color("#ff9a8a")]]:
		var col: = VBoxContainer.new()
		col.custom_minimum_size.x = 383
		col.add_theme_constant_override("separation", 2)
		teams.add_child(col)
		var head: = UiTheme.label(String(t[1]), 22, t[2], true, 4)
		col.add_child(head)
		var body: = UiTheme.label("", 18, UiTheme.CREAM)
		body.custom_minimum_size.y = 5 * 26
		col.add_child(body)
		team_lists[t[0]] = [head, body, String(t[1])]
	status_label = UiTheme.label(LanSession.status, 20, UiTheme.GOLD)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.x = 790
	v.add_child(status_label)
	var actions: = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	v.add_child(actions)
	ready_btn = _button(actions, "准备", func() -> void :
		var p: Dictionary = LanSession.roster.get(LanSession.local_id(), {})
		LanSession.set_ready( not bool(p.get("ready", false))))
	start_btn = _button(actions, "开始对局", func() -> void : LanSession.start_game())
	leave_btn = _button(actions, "离开房间", func() -> void :
		LanSession.leave()
		LanSession.status = "已离开房间，可以重新创建或加入"
		_refresh())
	_button(actions, "返回", _close)
	LanSession.room_changed.connect(_refresh)
	LanSession.status_changed.connect( func(message: String) -> void : status_label.text = message)
	if LanSession.roster.has(LanSession.local_id()):
		var p: Dictionary = LanSession.roster[LanSession.local_id()]
		nickname.text = String(p.name)
		_select(team, String(p.team))
		_select(skin, String(p.skin))
		_select(weapon, String(p.weapon))
		for slot in gadget_picks:
			if p.has("g" + slot):
				_select(gadget_picks[slot], String(p["g" + slot]))
	_select(map_pick, String(LanSession.room_options.mode))
	_refresh()


func _row(v: VBoxContainer, title: String) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label: = UiTheme.label(title, 22, Color("#d8cfe3"))
	label.custom_minimum_size.x = 145
	row.add_child(label)
	v.add_child(row)
	return row


func _pick(row: HBoxContainer, values: Array) -> OptionButton:
	var pick: = OptionButton.new()
	pick.theme_type_variation = "GhostButton"
	pick.add_theme_font_size_override("font_size", 20)
	for value in values:
		pick.add_item(String(value[1]))
		pick.set_item_metadata(pick.item_count - 1, value[0])
	row.add_child(pick)
	pick.item_selected.connect( func(_i: int) -> void : _profile_changed())
	return pick


func _value(pick: OptionButton) -> String:
	return String(pick.get_item_metadata(pick.selected))


func _select(pick: OptionButton, value: String) -> void :
	for i in pick.item_count:
		if pick.get_item_metadata(i) == value:
			pick.select(i)


func _button(row: HBoxContainer, title: String, cb: Callable) -> Button:
	var b: = Button.new()
	b.text = title
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect( func() -> void :
		Audio.play2d("ui_click", -6)
		cb.call())
	row.add_child(b)
	return b


func _profile() -> Dictionary:
	var out := {"name": nickname.text, "team": _value(team), "skin": _value(skin), "weapon": _value(weapon)}
	for slot in gadget_picks:
		out["g" + slot] = _value(gadget_picks[slot])
	return out


func _profile_changed() -> void :
	if not _refreshing:
		LanSession.update_profile(_profile())


func _refresh() -> void :
	_refreshing = true
	var connected: = LanSession.active()
	host_btn.disabled = connected
	join_btn.disabled = connected
	address.editable = not connected
	port.editable = not connected
	map_pick.disabled = connected
	if connected:
		_select(map_pick, String(LanSession.room_options.mode))
	ready_btn.disabled = not LanSession.roster.has(LanSession.local_id())
	start_btn.disabled = not LanSession.can_start()
	start_btn.visible = not connected or LanSession.is_host()
	leave_btn.visible = connected
	# Inside a room the search / IP rows are noise; hiding them keeps ten seats on screen.
	for row in search_rows:
		row.visible = not connected
	team_box.visible = connected
	var mode: = String(LanSession.room_options.mode) if connected else _value(map_pick)
	var per: = LanSession.team_size(mode)
	var ids: Array = LanSession.roster.keys()
	ids.sort()
	for t in team_lists:
		var rows: = PackedStringArray()
		for id in ids:
			var p: Dictionary = LanSession.roster[id]
			if p.team == t:
				rows.append("%s %s%s%s · %s" % ["✔" if p.ready else "○", p.name, "（房主）" if id == 1 else "", "（你）" if id == LanSession.local_id() and connected else "",
					Data.weapon(p.weapon).name])
		var row: Array = team_lists[t]
		(row[0] as Label).text = "%s  %d/%d" % [row[2], rows.size(), per]
		(row[1] as Label).text = "\n".join(rows) if not rows.is_empty() else "（空位由 AI 补齐）"
	# A full team cannot be picked; your own seat does not count against it.
	for i in team.item_count:
		team.set_item_disabled(i, connected and not LanSession.team_has_room(String(team.get_item_metadata(i)), LanSession.local_id()))
	if connected and LanSession.roster.has(LanSession.local_id()):
		_select(team, String(LanSession.roster[LanSession.local_id()].team))
	roster_label.text = ("房间 %d/%d 人 · 至少 %d 人、全部准备后房主可开始" % [LanSession.roster.size(), LanSession.capacity(), int(Data.load_json("network").get("minPlayers", 2))]) if connected \
		else "创建或加入房间（%s最多 %d 人）" % ["完整地图" if mode == "full" else "中路小图", LanSession.capacity(mode)]
	var local: Dictionary = LanSession.roster.get(LanSession.local_id(), {})
	ready_btn.text = "取消准备" if bool(local.get("ready", false)) else "准备"
	status_label.text = LanSession.status
	_refreshing = false
	if not connected:
		LanSession.scan_rooms()
	_refresh_rooms()


func _refresh_rooms() -> void:
	var selected: Variant = room_pick.get_item_metadata(room_pick.selected) if room_pick.selected >= 0 else null
	room_pick.clear()
	var keys: Array = LanSession.discovery.rooms.keys()
	keys.sort()
	for key in keys:
		var row: Dictionary = LanSession.discovery.rooms[key]
		var state := "可加入" if row.state == "open" else ("对局中" if row.state == "playing" else "已满")
		if row.signature != LanSession.signature():
			state = "版本不同"
		room_pick.add_item("%s · %s · %d/%d · %s" % [row.name, "完整地图" if row.mode == "full" else "中路小图", row.count, int(row.get("capacity", LanSession.capacity(String(row.mode)))), state])
		room_pick.set_item_metadata(room_pick.item_count - 1, key)
		if selected == key:
			room_pick.select(room_pick.item_count - 1)
	if keys.is_empty():
		room_pick.add_item("正在搜索… 找不到时可用 IP 加入")
		room_pick.set_item_metadata(0, null)
	room_pick.disabled = LanSession.active() or keys.is_empty()
	_select_found()


func _select_found() -> void:
	var key: Variant = room_pick.get_item_metadata(room_pick.selected) if room_pick.selected >= 0 else null
	var row: Dictionary = LanSession.discovery.rooms.get(key, {})
	room_join.disabled = LanSession.active() or row.is_empty() or row.get("state") != "open" or row.get("signature") != LanSession.signature()


func _join_found() -> void:
	var key: Variant = room_pick.get_item_metadata(room_pick.selected) if room_pick.selected >= 0 else null
	var row: Dictionary = LanSession.discovery.rooms.get(key, {})
	if row.is_empty() or row.state != "open" or row.signature != LanSession.signature():
		_refresh_rooms()
		return
	address.text = row.address
	port.value = row.port
	LanSession.join(row.address, _profile(), int(row.port))


func _close() -> void :
	LanSession.leave()
	closed.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void :
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
