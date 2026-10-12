class_name KillDebugPanel
extends CanvasLayer
## F8 调试面板；沙盒测试不会修改当前对局或通过 RPC 伪造奖励。

signal preview_requested(event: Dictionary)

var root: Control
var output: RichTextLabel
var preview: Label
var presets: OptionButton
var scenarios: OptionButton
var streak_input: SpinBox
var source_world: SimWorld
var preview_player_ids: Array[int] = []
var preview_owner: OptionButton
var preview_role: OptionButton
var preview_method: OptionButton
var preview_first: CheckBox
var preview_shutdown: CheckBox
var standalone_ui: KillPresentationUI
var _events: Array[Dictionary] = []


func _ready() -> void:
	layer = 50
	_build()
	if source_world != null:
		root.hide()
	else:
		_run_scenario(1)
		standalone_ui = KillPresentationUI.new()
		add_child(standalone_ui)
		standalone_ui.setup(_config())
		standalone_ui.attach(self, 1)
		preview_requested.connect(standalone_ui.preview)
		configure_preview_players([1])


func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.025, 0.05, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	root.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)
	var title := Label.new()
	title.text = "击败 / 助攻 / 赏金 · 第二阶段调试"
	title.add_theme_font_size_override("font_size", 28)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "沙盒测试不影响当前对局；预览占位播报后按 F8 返回。正式美术、动画和音效在后续阶段交付。"
	body.add_child(hint)
	var controls := HBoxContainer.new()
	body.add_child(controls)
	presets = OptionButton.new()
	for label in ["默认 CAP 300", "建议校准 CAP 120", "收入锚点候选 CAP 100"]:
		presets.add_item(label)
	controls.add_child(presets)
	scenarios = OptionButton.new()
	for label in KillDebugScenarios.NAMES:
		scenarios.add_item(label)
	scenarios.select(1)
	controls.add_child(scenarios)
	var run := Button.new()
	run.text = "运行沙盒算例"
	run.pressed.connect(func() -> void: _run_scenario(scenarios.selected))
	controls.add_child(run)
	var close := Button.new()
	close.text = "关闭（F8）"
	close.pressed.connect(toggle)
	controls.add_child(close)
	var row := HBoxContainer.new()
	body.add_child(row)
	var label := Label.new()
	label.text = "个人播报预览 · 连续击败"
	row.add_child(label)
	preview_owner = OptionButton.new()
	row.add_child(preview_owner)
	preview_role = OptionButton.new()
	for role in ["击败者", "助攻者", "受害者"]:
		preview_role.add_item(role)
	row.add_child(preview_role)
	streak_input = SpinBox.new()
	streak_input.min_value = 1
	streak_input.max_value = _config().debug_preview_streak_max
	streak_input.value = 7
	row.add_child(streak_input)
	var trigger := Button.new()
	trigger.text = "触发预览"
	trigger.pressed.connect(_preview)
	row.add_child(trigger)
	var clear := Button.new()
	clear.text = "阵亡清空"
	clear.pressed.connect(func() -> void: _preview(true))
	row.add_child(clear)
	var tags := HBoxContainer.new()
	body.add_child(tags)
	preview_first = CheckBox.new()
	preview_first.text = "首次击败"
	tags.add_child(preview_first)
	preview_shutdown = CheckBox.new()
	preview_shutdown.text = "终结（对方4连）"
	tags.add_child(preview_shutdown)
	preview_method = OptionButton.new()
	for method in ["普通", "爆炸", "灼烧", "刀斩", "弹反"]:
		preview_method.add_item(method)
	tags.add_child(preview_method)
	preview = Label.new()
	preview.text = "当前预览：占位瓜子排、文字、信息条和全场横幅。"
	body.add_child(preview)
	output = RichTextLabel.new()
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_font_size_override("normal_font_size", 20)
	output.scroll_following = true
	body.add_child(output)


func _config() -> KillConfig:
	var paths := ["res://data/kill_config.tres", "res://data/kill_config_calibrated.tres", "res://data/kill_config_income_candidate.tres"]
	return load(paths[0 if presets == null else presets.selected]) as KillConfig


func toggle() -> void:
	root.visible = not root.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if root.visible else (Input.MOUSE_MODE_HIDDEN if source_world != null else Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		toggle()
		get_viewport().set_input_as_handled()


func _run_scenario(index: int) -> void:
	var config := _config()
	output.append_text("\n【沙盒】%s（BASE=%.3f / RATIO=%.3f / CAP=%.3f）\n" % [KillDebugScenarios.NAMES[index], config.base, config.ratio, config.cap])
	for event in KillDebugScenarios.run(index, _config()):
		observe(event)


func observe(event: Dictionary) -> void:
	_events.append(event.duplicate(true))
	while _events.size() > _config().debug_history_limit:
		_events.pop_front()
	var d: Dictionary = event.debug
	var text := "事件 #%d   击败者 %d → 受害者 %d   方式 %s   连续击败 %d\n" % [event.event_id, event.killer_id, event.victim_id, event.method, event.killer_streak]
	if not d.has("victim_seeds"):
		output.append_text(text + "展示预览：没有服务器赏金调试快照。\n")
		return
	text += "S_v=%.1f  n=%d  P=%.4f  F=%.4f  M=%.4f   首次=%s  终结=%s\n" % [d.victim_seeds, d.previous_deaths, d.P, d.F, d.M, event.is_first_kill, event.is_shutdown]
	if int(event.killer_id) < 0:
		text += "无人归属：本次不发放赏金\n"
	for person: Dictionary in d.recipients:
		var info: Dictionary = person.identity
		text += "%s（%s） S=%.1f  c=%.2f%%  D=%.4f  原值=%.4f → 到账 +%d%s\n" % [info.name, "击败者" if person.role == "killer" else "助攻者", info.seeds, person.contribution * 100.0, person.D, person.raw, person.reward, "（断线，取消到账）" if not person.connected else ""]
	output.append_text(text)
	if output.get_line_count() > _config().debug_history_limit * 10:
		output.text = text


func configure_preview_players(ids: Array) -> void:
	preview_player_ids.assign(ids)
	preview_owner.clear()
	for id in preview_player_ids:
		var h := source_world.ham_by_id(id) if source_world != null else null
		preview_owner.add_item(h.name if h != null else "本地预览", id)
	if preview_player_ids.is_empty():
		preview_player_ids.append(1)
		preview_owner.add_item("旁观预览", 1)


func _preview(force_death: bool = false) -> void:
	var count := int(streak_input.value)
	var config := _config()
	preview.text = "%s %d（占位预览不发放赏金）" % [KillUIStyle.title(count, config), count]
	var event := KillEvent.new()
	var owner := preview_player_ids[preview_owner.selected]
	var role := 2 if force_death else preview_role.selected
	event.killer_id = owner if role == 0 else -10
	event.victim_id = owner if role == 2 else -11
	event.method = ["normal", "explosion", "burn", "slash", "reflect"][preview_method.selected]
	var sample: Dictionary = KillDebugScenarios.run(1, config)[0]
	event.killer_reward = int(sample.killer_reward)
	event.victim_death_count = -1 # 展示沙盒没有真实死亡快照。
	event.killer_streak = count
	event.killer_connected = true
	event.is_first_kill = preview_first.button_pressed
	event.is_shutdown = preview_shutdown.button_pressed
	event.victim_streak_before = config.shutdown_min if event.is_shutdown else 0
	if role == 1:
		event.assists = [{"player_id": owner, "reward": int(sample.assists[0].reward), "connected": true}]
	event.identities = {owner: {"name": "本地预览", "team": "blue", "connected": true}, -10: {"name": "对手", "team": "red", "connected": true}, -11: {"name": "受害者", "team": "red", "connected": true}}
	if source_world != null:
		var hamster := source_world.ham_by_id(owner)
		if hamster != null:
			event.identities[owner] = {"name": hamster.name, "team": hamster.team, "connected": true}
	# 虚拟角色必须是有效玩家ID；负ID仅用于不显示的开发身份。
	if event.killer_id == -10:
		event.killer_id = config.debug_preview_streak_max + 1
		event.identities[event.killer_id] = event.identities[-10]
	if event.victim_id == -11:
		event.victim_id = config.debug_preview_streak_max + 2
		event.identities[event.victim_id] = event.identities[-11]
	var packet := event.to_dict()
	packet.debug_preview = true
	preview_requested.emit(packet)
	root.hide()
