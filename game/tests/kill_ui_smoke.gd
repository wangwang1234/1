extends Node
## 场景模式验证真实Control/CanvasLayer/SubViewport与事件路由；不模拟奖励公式。

var checks: int = 0
var failures: Array[String] = []
var config: KillConfig
var ui: KillPresentationUI
var sequence: int = 0


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func _packet(killer: int = 1, victim: int = 3, streak: int = 1) -> Dictionary:
	sequence += 1
	var event := KillEvent.new()
	event.event_id = sequence
	event.killer_id = killer
	event.victim_id = victim
	event.killer_streak = streak
	event.killer_reward = 81
	event.killer_connected = true
	event.identities = {1: {"name": "蓝方", "team": "blue", "connected": true}, 2: {"name": "助攻", "team": "blue", "connected": true}, 3: {"name": "红方", "team": "red", "connected": true}}
	return event.to_dict()


func _ready() -> void:
	config = load("res://data/kill_config_calibrated.tres")
	ui = KillPresentationUI.new()
	add_child(ui)
	ui.setup(config)
	ui.set_process(false)
	for id in [1, 2, 3]:
		var vp := SubViewport.new()
		vp.size = Vector2i(960, 1080)
		add_child(vp)
		ui.attach(vp, id)
	await get_tree().process_frame
	var own: StreakBannerUI = ui.views[0].banner
	var ally: StreakBannerUI = ui.views[1].banner
	var victim: StreakBannerUI = ui.views[2].banner
	var first := _packet()
	first.is_first_kill = true
	first.is_shutdown = true
	first.victim_streak_before = 7
	first.assists = [{"player_id": 2, "reward": 18, "connected": true}]
	ui.receive(first)
	_check(own.title_label.text == "击败", "击败者显示主文字")
	_check(own.current_streak == 1 and ally.current_streak == 0 and victim.current_streak == 0, "私人瓜子排仅在击败者视口")
	_check(ally.assist_text == "助攻 +18" and own.assist_text.is_empty(), "助攻提示仅在助攻视口，金额等于事件")
	_check(victim.has_death and victim.death_text == "被 蓝方 击败", "受害者显示名字及被击败提示")
	_check(own.subtitle_label.text.contains("首次击败") and own.subtitle_label.text.contains("终结 · 对方 7 连击败"), "两种标签可以同时显示")
	_check(ui.global_banner.current.contains("首次击败") and ui.global_banner.current.contains("终结"), "首次击败与终结触发全场横幅")
	_check(ui.feed.canvases.size() == 3 and ui.global_banner.canvases.size() == 3, "共享信息条及横幅覆盖每个视口")
	ui.receive(first)
	_check(ui.feed.rows.size() == 1, "重复可靠事件不重复展示")
	ui._process(config.ordinary_stay * 0.5)
	ui.receive(_packet(1, 3, 2))
	_check(own.title_label.text == "双重击败" and is_equal_approx(own.remaining, config.ordinary_stay), "显示期间再次击败直接追加并重置停留")
	ui.global_banner.clear()
	ui.receive(_packet(1, 3, 5))
	_check(own.title_label.text == "五重击败" and KillUIStyle.gold_counts(5, config).visible == 1, "五重击败显示一颗金瓜子")
	_check(ui.global_banner.current.contains("五重击败"), "第五次触发全场横幅")
	ui.global_banner.clear()
	ui.receive(_packet(1, 3, 6))
	_check(own.title_label.text == "鼠向披靡" and own.number_label.text == "6", "第六次显示鼠向披靡及数字")
	_check(ui.global_banner.current.contains("鼠向披靡 6"), "每一段第六次触发横幅")
	ui.global_banner.clear()
	ui.receive(_packet(1, 3, 7))
	_check(ui.global_banner.current.is_empty(), "同一段第七次不重复触发横幅")
	ui.receive(_packet(1, 3, 10))
	_check(KillUIStyle.gold_counts(10, config).visible == 2 and KillUIStyle.gold_counts(10, config).normal == 0, "第十次显示两颗金瓜子")
	ui.receive(_packet(1, 3, 20))
	_check(KillUIStyle.gold_counts(20, config).visible == 4 and KillUIStyle.gold_counts(20, config).multiplier == 0, "四颗金瓜子逐颗显示")
	ui.receive(_packet(1, 3, 25))
	var counts := KillUIStyle.gold_counts(25, config)
	_check(counts.visible == 1 and counts.multiplier == 5 and counts.normal == 0, "25连显示一颗金瓜子×5")
	ui.receive(_packet(1, 3, 27))
	counts = KillUIStyle.gold_counts(27, config)
	_check(counts.visible == 1 and counts.multiplier == 5 and counts.normal == 2, "27连显示金瓜子×5加两颗普通瓜子")
	ui.receive(_packet(3, 1, 1))
	_check(own.current_streak == 0 and not own.title_label.visible and own.remaining == 0.0, "阵亡当次事件立即隐藏、清空私人瓜子排")
	ui.global_banner.clear()
	ui.receive(_packet(1, 3, 1))
	_check(own.current_streak == 1, "新一段击败从一颗开始")
	ui.receive(_packet(1, 3, 6))
	_check(ui.global_banner.current.contains("鼠向披靡 6"), "阵亡后再次达到六连仍触发横幅")
	ui.respawned(3)
	_check(not victim.has_death, "复活清除受害者提示")
	var none := _packet(-1, 3, 0)
	none.killer_connected = false
	ui.receive(none)
	_check(victim.death_text == "你被击败", "无击败者提示不虚构名字")
	var disconnected := _packet(1, 3, 27)
	disconnected.killer_connected = false
	disconnected.identities[1].connected = false
	var before := own.current_streak
	ui.receive(disconnected)
	_check(own.current_streak == before, "断线击败者不播放个人播报")
	_check(KillUIStyle.color_of(disconnected, 1, config) == config.disconnected_color, "断线名字置灰")
	for i in config.feed_max_rows + 2:
		ui.receive(_packet())
	_check(ui.feed.rows.size() == config.feed_max_rows, "信息条最多五条")
	ui.feed.tick(config.feed_stay)
	_check(ui.feed.rows.size() == config.feed_max_rows, "五秒后开始淡出，未提前删除")
	ui.feed.tick(config.feed_fade)
	_check(ui.feed.rows.is_empty(), "淡出结束删除信息条")
	own.bottom_exclusion = 760.0
	own.tick(0.0)
	_check(own.seed_center.y + config.gold_seed_height * 0.5 + config.mobile_clearance <= own.bottom_exclusion, "瓜子排位于触控占用区上方")
	own.size = Vector2(800, 600)
	own.bottom_exclusion = 0.0
	own.tick(0.0)
	_check(is_equal_approx(own.seed_center.y, 600.0 * (1.0 - config.seed_bottom_ratio)), "按各视口高度独立等比布局")
	_check(is_equal_approx(Engine.time_scale, 1.0), "占位播报不改变游戏时间倍率")
	await _real_match_check()
	var result := {"checks": checks, "failures": failures, "ok": failures.is_empty()}
	print("KILL_UI_RESULT ", JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)


func _real_match_check() -> void:
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "slice", "seed": 15, "players": [{"team": "blue", "ctl": "player", "name": "一屏"}, {"team": "red", "ctl": "player", "name": "二屏", "input": "keys2"}], "ai": {"blue": 0, "red": 0}})
	mv.set_physics_process(false)
	mv.set_process(false)
	mv.kill_ui.set_process(false)
	await get_tree().process_frame
	_check(mv.split and mv.kill_ui.views.size() == 2, "真实MatchView分屏创建两套私人播报")
	var k: SimHamster = mv.players[0].ham
	var v: SimHamster = mv.players[1].ham
	var before_seeds: float = k.seed_total
	var event := _packet(k.id, v.id, 7)
	event.identities = {k.id: {"name": k.name, "team": k.team}, v.id: {"name": v.name, "team": v.team}}
	event.victim_death_count = v.deaths + 1
	mv._dispatch([event])
	var kb: StreakBannerUI = mv.kill_ui.views[0].banner
	var vb: StreakBannerUI = mv.kill_ui.views[1].banner
	_check(kb.current_streak == 7 and vb.current_streak == 0, "真实事件只路由到击败者对应SubViewport")
	_check(kb.get_viewport() == mv.players[0].vp and vb.get_viewport() == mv.players[1].vp, "私人CanvasLayer绑定独立视口")
	mv.kill_ui._process(0.0)
	_check(vb.has_death, "可靠事件先到、旧alive快照后到时保留死亡提示")
	v.deaths += 1
	v.alive = false
	mv.kill_ui._process(0.0)
	_check(vb.has_death, "死亡快照不隐藏死亡提示")
	v.alive = true
	mv.kill_ui._process(0.0)
	_check(not vb.has_death, "复活特效丢包时由对应死亡次数的alive快照清除提示")
	_check(is_equal_approx(k.seed_total, before_seeds) and k.kill_streak == 0, "客户端展示不修改实际奖励或连续次数")
	mv.kill_debug.streak_input.value = 27
	mv.kill_debug._preview()
	_check(kb.current_streak == 27, "F8任意连续次数入口接入占位播报")
	_check(is_equal_approx(k.seed_total, before_seeds), "开发预览不发放真实瓜子")
	mv.players[0].hud.touch_mode = true
	mv.kill_ui._process(0.0)
	var touch_top: float = mv.players[0].hud.touch_exclusion_top()
	_check(kb.bottom_exclusion == touch_top and kb.seed_center.y > kb.size.y * 0.5, "切换触控立即使用当前按钮几何，不把瓜子排误推到顶部")
	mv.queue_free()
	await get_tree().process_frame
