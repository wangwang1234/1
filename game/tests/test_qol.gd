extends "res://tests/test_case.gd"

func test_spectator_delay_cycle_target_loss_and_respawn() -> void:
	var w := make_world("slice", 7, 2, 1, [{"team": "blue", "ctl": "player", "name": "你"}])
	var owner: SimHamster = w.hams[0]
	var state := SpectatorState.new()
	eq(state.update(w, owner, 0.0, 1.2), owner, "存活跟随自身")
	owner.alive = false
	owner.dead = true
	eq(state.update(w, owner, 0.5, 1.2), null, "死亡后短暂停留")
	var first := state.update(w, owner, 0.8, 1.2)
	check(first != null and first.team == owner.team and first != owner, "自动选择己方")
	state.cycle(w, owner, 1)
	var next := state.update(w, owner, 0.0, 1.2)
	check(next != first, "切换另一队友")
	next.alive = false
	var fallback := state.update(w, owner, 0.0, 1.2)
	eq(fallback, first, "目标死亡自动接续")
	eq(state.update(w, owner, 0.0, 1.2, func(_id: int) -> bool: return false), null, "全部断线回到等待")
	eq(state.target_id, -1, "无效目标清除")
	owner.alive = true
	owner.dead = false
	eq(state.update(w, owner, 0.0, 1.2), owner, "复活立即回到自己")
	eq(state.target_id, -1, "复活清除观战目标")

func test_split_spectators_and_enemy_exclusion() -> void:
	var w := make_world("slice", 8, 1, 1, [{"team": "blue", "ctl": "player"}, {"team": "red", "ctl": "player"}])
	var blue: SimHamster = w.hams[0]
	var red: SimHamster = w.hams[1]
	blue.alive = false
	var a := SpectatorState.new()
	var b := SpectatorState.new()
	var target := a.update(w, blue, 2.0, 1.2)
	check(target != null and target.team == "blue", "红蓝对战不能观战敌人")
	eq(b.update(w, red, 2.0, 1.2), red, "分屏另一位仍跟随自己")
	w.over = true
	eq(a.update(w, blue, 1.0, 1.2), null, "结算停止切换观战")

func test_death_source_survives_network_snapshot() -> void:
	var w := make_world("slice", 9, 0, 1, [{"team": "blue", "ctl": "player", "name": "你"}])
	var victim: SimHamster = w.hams[0]
	var killer: SimHamster = w.hams[1]
	w.kill_ent(victim, {"owner": killer})
	eq(victim.death_source, killer.name, "记录真实击杀者")
	w.tick = 1
	var copy := make_world("slice", 9, 0, 1, [{"team": "blue", "ctl": "player", "name": "你"}])
	check(NetSnapshot.apply(copy, NetSnapshot.capture(w)), "死亡状态可同步")
	eq(copy.hams[0].death_source, killer.name, "漏事件或重连后仍有来源")
