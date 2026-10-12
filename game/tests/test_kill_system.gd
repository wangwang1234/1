extends "res://tests/test_case.gd"
## 判定/赏金验收：测试真实死亡、经验发放及持久来源，覆盖规则边界。


func _config() -> KillConfig:
	return load("res://data/kill_config.tres") as KillConfig


func _world() -> SimWorld:
	var w := KillDebugScenarios.world(_config())
	_worlds.append(w)
	return w


func _hit(w: SimWorld, owner: SimHamster, n: float, method: String = "normal", contributor: int = 0) -> void:
	w.deal_dmg(w.hams[3], n, {"owner": owner, "method": method, "contributor_id": contributor}, true)


func _finish(w: SimWorld, owner: SimHamster, method: String = "normal", contributor: int = 0) -> Dictionary:
	for i in 3:
		_hit(w, owner, 1000.0, method, contributor)
		if not w.hams[3].alive:
			break
	return w.kill_system.history.back()


func test_1v1_reward_and_no_other_recipients() -> void:
	var w := _world()
	var before := w.hams[0].seed_total
	var event := _finish(w, w.hams[0])
	eq(event.killer_reward, 72, "同量 P120，击败者60%=72")
	eq(event.assists.size(), 0, "没有助攻者")
	near(w.hams[0].seed_total - before, 72.0, 0.00001, "经验倍率2也只到账72")
	near(w.hams[1].seed_total, 1000.0, 0.00001, "其他人不得")
	near(w.hams[3].seed_total, 1000.0, 0.00001, "受害者不扣瓜子")
	eq(w.items.size(), 0, "不另掉可拾取的额外PvP经验")


func test_default_and_calibrated_example() -> void:
	for path in ["res://data/kill_config.tres", "res://data/kill_config_calibrated.tres"]:
		var result := KillDebugScenarios.run(1, load(path) as KillConfig)
		var event: Dictionary = result[0]
		eq(event.assists[0].reward, 18, "甲贡献30%得18")
		eq(event.assists[1].reward, 9, "乙贡献10%且D封顶得9")
		near(event.debug.P, 120.0, 0.00001, "两配置在算例P都为120")
		eq(event.killer_reward, 81, "导演确认D先保留两位，击败者81")
		var expected := BountyCalculator.reward(72.0 * BountyCalculator.difference(1000.0, 800.0, load(path) as KillConfig), load(path) as KillConfig)
		eq(event.killer_reward, expected, "击败者符合确定的D舍入规则")


func test_five_percent_and_sonar() -> void:
	var low := KillDebugScenarios.run(2, _config())[0]
	eq(low.assists.size(), 0, "5%伤害不足助攻门槛")
	var recon := KillDebugScenarios.run(3, _config())[0]
	eq(recon.assists.size(), 1, "侦察直接助攻")
	eq(recon.assists[0].reward, 24, "单助攻领取完整20%")


func test_environment_last_hit_and_no_participation() -> void:
	var event := KillDebugScenarios.run(4, _config())[0]
	var w := _world()
	eq(event.killer_id, w.hams[0].id, "最高伤害归属")
	eq(event.method, "slash", "塔补刀取击败者最后命中方式")
	var none := KillDebugScenarios.run(5, _config())[0]
	eq(none.killer_id, -1, "无人参与无击败者")
	eq(none.killer_reward, 0, "无人参与不发赏金")
	check(not none.is_first_kill, "环境死亡不消费首次击败")
	w = _world()
	w.record_recon(w.hams[1], w.hams[3], "sonar")
	w.begin_assist_control(w.hams[2], w.hams[3], "hamster_ball")
	w.t = 2.5
	var control_only := _finish(w, null)
	eq(control_only.killer_id, -1, "导演确认：只有控制侦察且环境补刀时无击败者")
	eq(control_only.assists.size(), 0, "无击败者也不结算控制侦察助攻")
	eq(control_only.killer_reward, 0, "无实际生命伤害时不发赏金")


func test_tie_latest_damage_then_stable_id() -> void:
	var w := _world()
	_hit(w, w.hams[1], 20.0, "burn")
	w.t = 1.0
	_hit(w, w.hams[0], 20.0, "slash")
	var first := _finish(w, null)
	eq(first.killer_id, w.hams[0].id, "同伤害时最近造成伤害者优先")
	w = _world()
	_hit(w, w.hams[1], 20.0)
	_hit(w, w.hams[0], 20.0)
	eq(_finish(w, null).killer_id, w.hams[0].id, "同时间同伤害按ID升序")
	w = _world()
	w.hand_to_ai(w.hams[0])
	_hit(w, w.hams[1], 20.0)
	_hit(w, w.hams[0], 20.0)
	eq(_finish(w, null).killer_id, w.hams[0].id, "AI贡献身份改变后仍按稳定仓鼠ID平手排序")


func test_actual_hp_only_shield_and_overkill_excluded() -> void:
	var w := _world()
	var v := w.hams[3]
	v.eshield = 50.0
	v.eshield_t = 10.0
	_hit(w, w.hams[1], 40.0)
	eq(w.kill_system.tracker(v.id).records.size(), 0, "全护盾伤害不记录")
	_hit(w, w.hams[1], 15.0)
	near(w.kill_system.tracker(v.id).aggregate(w.t, 100.0, _config())[w.hams[1].id].damage, 5.0, 0.00001, "只记录穿盾后5HP")
	_finish(w, w.hams[0])
	eq(w.kill_system.history.back().assists.size(), 0, "穿盾后5%不助攻")
	w = _world()
	w.hams[3].hp = 3.0
	var event := _finish(w, w.hams[0])
	var direct: Array = event.debug.direct_assists
	eq(direct.size(), 0, "溢出伤害没有产生助攻")
	eq(w.kill_system.tracker(w.hams[3].id).records.size(), 0, "死亡清空队列")


func test_assist_window_inclusive_and_expired() -> void:
	var w := _world()
	_hit(w, w.hams[1], 20.0)
	w.t = _config().assist_window
	eq(_finish(w, w.hams[0]).assists.size(), 1, "正好10秒保留")
	w = _world()
	_hit(w, w.hams[1], 20.0)
	w.t = _config().assist_window + 0.001
	eq(_finish(w, w.hams[0]).assists.size(), 0, "超过10秒丢弃")


func test_control_union_window_and_early_end() -> void:
	var w := _world()
	var a := w.hams[1]
	var v := w.hams[3]
	var first := w.begin_assist_control(a, v, "hamster_ball")
	w.t = 1.0
	var second := w.begin_assist_control(a, v, "mousetrap")
	w.t = 2.0
	w.end_assist_control(v.id, first)
	w.t = 3.0
	w.end_assist_control(v.id, second)
	var row: Dictionary = w.kill_system.tracker(v.id).aggregate(w.t, v.max_hp, _config())[a.id]
	near(row.control_seconds, 3.0, 0.00001, "不同控制类型重叠取并集0至3秒")
	near(row.contribution, 0.3, 0.00001, "控制3秒=30%")
	w.t = 12.0
	row = w.kill_system.tracker(v.id).aggregate(w.t, v.max_hp, _config())[a.id]
	near(row.control_seconds, 1.0, 0.00001, "只取窗口2至12中的2至3秒")
	w = _world()
	first = w.begin_assist_control(w.hams[1], w.hams[3], "hamster_ball")
	w.t = 0.5
	w.end_assist_control(w.hams[3].id, first)
	eq(_finish(w, w.hams[0]).assists.size(), 0, "提前结束0.5秒不足门槛")


func test_current_ongoing_control_only_counts_elapsed() -> void:
	var w := _world()
	w.begin_assist_control(w.hams[1], w.hams[3], "hamster_ball")
	w.t = 0.2
	eq(_finish(w, w.hams[0]).assists.size(), 0, "持续控制只计已经发生的0.2秒")
	w = _world()
	w.t = 1000.0
	var token := w.begin_assist_control(w.hams[1], w.hams[3], "mousetrap")
	for frame in 60:
		w.t += 1.0 / 60.0
	w.end_assist_control(w.hams[3].id, token)
	eq(_finish(w, w.hams[0]).assists.size(), 1, "60帧1秒控制不会因长局浮点误差漏掉10%助攻")


func test_support_actual_healing_and_no_propagation() -> void:
	var event := KillDebugScenarios.run(12, _config())[0]
	eq(event.assists.size(), 1, "只助攻治疗击败者的甲，治疗甲的乙不得")
	near(event.assists[0].contribution, 0.1, 0.00001, "甲实际治疗10点=10%")
	var w := _world()
	w.hams[0].hp = 95.0
	near(w.heal_player(w.hams[1], w.hams[0], 100.0), 5.0, 0.00001, "溢出治疗不记录")
	w.heal_player(w.hams[0], w.hams[0], 100.0)
	eq(_finish(w, w.hams[0]).assists.size(), 0, "5点溢出治疗/自疗都不足助攻")


func test_support_to_direct_assistant_and_shield_absorbed() -> void:
	var w := _world()
	_hit(w, w.hams[1], 15.0)
	w.record_support(w.hams[2], w.hams[1], 10.0, "shield")
	var event := _finish(w, w.hams[0])
	eq(event.assists.size(), 2, "为直接助攻者吸收10点护盾也有资格")
	w = _world()
	_hit(w, w.hams[1], 5.0)
	w.record_support(w.hams[2], w.hams[1], 100.0, "shield")
	eq(_finish(w, w.hams[0]).assists.size(), 0, "支援非直接助攻者不递归产生资格")


func test_zero_seed_and_difference_limits() -> void:
	var c := _config()
	near(BountyCalculator.difference(0.0, 0.0, c), 1.0, 0.00001, "双方0瓜子D1")
	near(BountyCalculator.difference(10.0, 0.0, c), c.d_max, 0.00001, "仅领取人0取上限")
	near(BountyCalculator.difference(0.0, 10.0, c), c.d_min, 0.00001, "仅受害者0取下限")
	near(BountyCalculator.difference(10000.0, 1.0, c), c.d_max, 0.00001, "差距上限")


func test_decay_first_three_and_survival_reset() -> void:
	var events := KillDebugScenarios.run(7, _config())
	for i in 3:
		near(events[i].debug.F, pow(0.7, i), 0.00001, "前三次F=1/.7/.49")
	var reset := KillDebugScenarios.run(8, _config())
	near(reset.back().debug.F, 1.0, 0.00001, "存活90秒恢复100%")
	near(BountyCalculator.pool(1000.0, 100, 0, _config()).F, 0.3, 0.00001, "衰减有下限")


func test_killing_resets_death_chain_but_assist_does_not() -> void:
	var w := _world()
	w.hams[0].consecutive_deaths = 3
	w.hams[1].consecutive_deaths = 3
	_hit(w, w.hams[1], 20.0)
	_finish(w, w.hams[0])
	eq(w.hams[0].consecutive_deaths, 0, "击败重置连续阵亡")
	eq(w.hams[1].consecutive_deaths, 3, "助攻不重置连续阵亡")


func test_shutdown_and_cap_before_modifiers() -> void:
	var shutdown := KillDebugScenarios.run(9, _config())[0]
	check(shutdown.is_shutdown, "受害者4连触发终结")
	near(shutdown.debug.M, 1.25, 0.00001, "4连M1.25")
	check(not KillDebugScenarios.run(10, _config())[0].is_shutdown, "3连不触发")
	var c := load("res://data/kill_config_calibrated.tres") as KillConfig
	near(BountyCalculator.pool(10000.0, 0, 100, c).P, 240.0, 0.00001, "CAP120先封顶再乘M2")


func test_reflected_rocket_credits_reflector() -> void:
	var event := KillDebugScenarios.run(6, _config())[0]
	eq(event.method, "reflect", "反射优先于爆炸")
	var w := _world()
	eq(event.killer_id, w.hams[0].id, "击败归反射者")


func test_dead_contributor_retains_reward_and_streak_starts_one() -> void:
	var w := _world()
	w.hams[0].alive = false
	w.hams[0].kill_streak = 0
	var event := _finish(w, w.hams[0], "explosion")
	eq(event.killer_reward, 72, "阵亡主人仍到账")
	eq(event.killer_streak, 1, "阵亡后从当前0开始+1")
	check(not w.hams[0].alive, "到账不使阵亡玩家复活")


func test_disconnected_assist_share_not_redistributed() -> void:
	var event := KillDebugScenarios.run(13, _config())[0]
	eq(event.assists[0].reward, 18, "在线甲仍拿18，不能拿断线乙份额")
	eq(event.assists[1].reward, 0, "断线乙不发放")
	near(event.debug.assist_total, 0.4, 0.00001, "分母仍含断线乙")


func test_disconnected_fatal_owner_keeps_attribution_and_shutdown() -> void:
	var event := KillDebugScenarios.run(14, _config())[0]
	var w := _world()
	eq(event.killer_id, w.hams[0].id, "断线致命一击归属保留")
	eq(event.killer_reward, 0, "断线击败者60%不发")
	eq(event.killer_streak, 0, "断线不+1")
	check(not event.killer_connected, "个人播报禁用标记")
	near(event.debug.M, 1.25, 0.00001, "终结加成仍有效")
	eq(event.assists[0].reward, 30, "在线助攻拿满20%含终结")


func test_ai_takeover_preserves_body_but_old_projectile_unpaid() -> void:
	var w := _world()
	var k := w.hams[0]
	k.kill_streak = 3
	var projectile := w.new_bullet("trc", k, 0.0, 0.0, 10.0, 0.0, 100.0, 1000.0, 100.0)
	var old_identity := projectile.contributor_id
	w.kill_system.mark_disconnected(k)
	w.hand_to_ai(k)
	check(k.contributor_id != old_identity, "新AI贡献身份")
	eq(k.kill_streak, 3, "接管不清空连续击败")
	var event := _finish(w, k, "normal", old_identity)
	eq(event.killer_reward, 0, "旧断线投射物仍不发放")
	eq(k.kill_streak, 3, "旧断线击败不增加连续击败")
	w.hams[3].alive = true
	w.hams[3].hp = 100.0
	event = _finish(w, k)
	eq(event.killer_streak, 4, "AI从仓鼠已有3连继续+1")
	check(event.killer_reward > 0, "AI赏金记入仓鼠S")


func test_persistent_recon_support_control_keep_old_identity() -> void:
	var w := _world()
	var provider := w.hams[1]
	var old_identity := w.kill_system.identity(provider)
	w.kill_system.mark_disconnected(provider)
	w.hand_to_ai(provider)
	w.record_recon(provider, w.hams[3], "camera", old_identity)
	var token := w.begin_assist_control(provider, w.hams[3], "mousetrap", old_identity)
	w.t = 2.0
	w.end_assist_control(w.hams[3].id, token)
	w.hams[0].hp = 50.0
	w.heal_player(provider, w.hams[0], 10.0, old_identity)
	w.record_support(provider, w.hams[0], 10.0, "shield", old_identity)
	var event := _finish(w, w.hams[0])
	eq(event.assists.size(), 1, "旧摄像头/控制/支援合并为原来源")
	eq(event.assists[0].reward, 0, "不让接管AI领取断线玩家留下的贡献")
	check(not event.assists[0].connected, "旧来源仍为断线")


func test_reconnect_inherits_and_ai_sources_become_player() -> void:
	var w := _world()
	var k := w.hams[0]
	w.kill_system.mark_disconnected(k)
	w.hand_to_ai(k)
	var ai_identity := k.contributor_id
	k.kill_streak = 5
	var before := k.seed_total
	w.resume_player(k)
	eq(k.ctl, "player", "重连恢复玩家控制")
	eq(k.kill_streak, 5, "重连保留5连")
	near(k.seed_total, before, 0.00001, "重连保留S")
	var event := _finish(w, k, "explosion", ai_identity)
	check(event.killer_connected, "AI遗留陷阱按玩家身份结算")
	eq(event.killer_streak, 6, "AI遗留击败使玩家继续6连")
	check(event.killer_reward > 0, "AI来源归并后发放")


func test_streak_first_death_and_nonplayer_targets() -> void:
	var w := _world()
	w.hams[3].kill_streak = 7
	var none := _finish(w, null)
	eq(w.hams[3].kill_streak, 0, "无归属死亡也清空受害者连续")
	check(not none.is_first_kill, "环境死亡不消费首次击败")
	w.hams[3].alive = true
	w.hams[3].hp = 100.0
	var first := _finish(w, w.hams[0])
	check(first.is_first_kill, "下一次玩家击败仍是首次")
	var minion := w.spawn_minion("red", "mid")
	w.deal_dmg(minion, 10000.0, {"owner": w.hams[0]})
	eq(w.hams[0].kill_streak, 1, "小兵击败不算连续")


func test_same_death_cannot_award_twice() -> void:
	var w := _world()
	_finish(w, w.hams[0])
	var before := w.hams[0].seed_total
	w.kill_ent(w.hams[3], {"owner": w.hams[0]})
	eq(w.kill_system.history.size(), 1, "重复回调不再结算")
	near(w.hams[0].seed_total, before, 0.00001, "重复死亡不重复到账")


func test_kill_blast_reentrancy_and_first_event_order() -> void:
	var w := _world()
	var k := w.hams[0]
	var victim := w.hams[3]
	var secondary := w.hams[2]
	k.weapon_id = "deagle"
	k.evo.a = 7
	k.evo_key = ""
	secondary.team = "red"
	secondary.hp = 1.0
	secondary.x = victim.x + 10.0
	secondary.y = victim.y
	w._hash_all()
	_finish(w, k)
	eq(w.kill_system.history.size(), 2, "一次致命攻击和一次连锁爆炸，共两次结算")
	eq(w.kill_system.history[0].victim_id, victim.id, "首先结算原始死亡")
	check(w.kill_system.history[0].is_first_kill, "原始致命攻击获得首次击败标签")
	check(not w.kill_system.history[1].is_first_kill, "后续爆炸不是首次")
	eq(victim.deaths, 1, "击败爆炸不重入同一主体")
	eq(k.kill_streak, 2, "恰好2连击败")


func test_client_cannot_damage_record_or_award() -> void:
	var w := _world()
	w.authoritative = false
	_hit(w, w.hams[0], 1000.0)
	SimHamsterLogic.give_xp(w, w.hams[0], 100.0)
	w.record_recon(w.hams[1], w.hams[3], "sonar")
	w.heal_player(w.hams[1], w.hams[0], 100.0)
	check(w.kill_system.settle(w, w.hams[3], {"owner": w.hams[0]}).is_empty(), "客户端不能直接结算")
	near(w.hams[0].seed_total, 1000.0, 0.00001, "客户端不能发放")
	eq(w.kill_system.history.size(), 0, "客户端无服务器事件")
	near(w.hams[3].hp, 100.0, 0.00001, "客户端不能扣HP")


func test_50_levels_at_exact_thresholds_and_seeds_after_max() -> void:
	var w := _world()
	var h := w.hams[0]
	h.seed_total = 0.0
	h.st.xpK = 1.0
	var thresholds: Array = Data.progression().cumulativeThresholds
	for level in range(2, 51):
		SimHamsterLogic.give_xp(w, h, float(thresholds[level - 1]) - h.seed_total, false)
		eq(h.lvl, level, "精确累计门槛达到指定成长档")
	near(h.seed_total, 1560.0, 0.00001, "满级累计1560")
	SimHamsterLogic.give_xp(w, h, 77.0, false)
	eq(h.lvl, 50, "满级不再升级")
	near(h.seed_total, 1637.0, 0.00001, "满级瓜子继续累计")


func test_event_same_frame_and_snapshot_seed_totals() -> void:
	var w := _world()
	var event := _finish(w, w.hams[0])
	check(w.events.any(func(row: Dictionary) -> bool: return row.get("t") == "kill_event" and row.event_id == event.event_id), "发放同帧出现KillEvent")
	var copy := _world()
	w.tick = 1
	check(NetSnapshot.apply(copy, NetSnapshot.capture(w)), "可应用快照")
	near(copy.hams[0].seed_total, w.hams[0].seed_total, 0.00001, "累计S进入网络快照")
	eq(copy.hams[0].kill_streak, 1, "连续状态进入快照")


func test_minimum_reward_and_config_validation() -> void:
	var c := _config().duplicate() as KillConfig
	c.base = 0.0001
	c.ratio = 0.0
	eq(BountyCalculator.reward(0.000001, c), 1, "每个有资格领取人最低1颗")
	check(c.validation_errors().is_empty(), "低正值配置有效")
	c.kill_share = 1.0
	c.assist_share = 0.5
	check(not c.validation_errors().is_empty(), "拒绝份额和超过1的配置")
