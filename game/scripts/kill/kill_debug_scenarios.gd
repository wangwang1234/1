class_name KillDebugScenarios
extends RefCounted
## 可复用、无动画的沙盒输入：面板和验收测试驱动同一真实服务器链路。

const NAMES := ["1v1 无助攻", "算例 81 / 18 / 9", "5% 伤害无助攻", "声呐直接助攻", "炮台补刀", "无人参与", "反射火箭弹", "连续阵亡三次", "存活90秒重置", "终结4连", "3连不终结", "重叠控制取并集", "治疗助攻不传递", "断线助攻保留分母", "断线致命一击", "阵亡后地雷"]


static func world(config: KillConfig) -> SimWorld:
	var w := SimWorld.new()
	w.setup({"mode": "slice", "ai": {"blue": 0, "red": 0}, "players": [
		{"team": "blue", "name": "击败者", "ctl": "player"}, {"team": "blue", "name": "甲", "ctl": "player"},
		{"team": "blue", "name": "乙", "ctl": "player"}, {"team": "red", "name": "受害者", "ctl": "player"}]})
	w.kill_system = KillSystem.new(config)
	for h in w.hams:
		h.seed_total = 1000.0
		h.max_hp = 100.0
		h.hp = 100.0
		h.iframes = 0.0
		h.st.crit = 0.0
		h.st.armor = 0.0
		h.st.vamp = 0.0
		h.st.xpK = 2.0 # 特意验证赏金跳过倍率。
	w.events.clear()
	return w


static func hit(w: SimWorld, attacker: SimHamster, amount: float, method: String = "normal") -> void:
	w.deal_dmg(w.hams[3], amount, {"owner": attacker, "team": attacker.team if attacker != null else "neutral", "method": method}, true)


static func run(index: int, config: KillConfig) -> Array[Dictionary]:
	var w := world(config)
	var k := w.hams[0]
	var a := w.hams[1]
	var b := w.hams[2]
	var v := w.hams[3]
	match index:
		1, 13:
			k.seed_total = 800.0
			b.seed_total = 400.0
			hit(w, a, 30.0)
			hit(w, b, 10.0)
			if index == 13:
				b.bounty_connected = false
		2:
			hit(w, a, 5.0)
		3:
			w.record_recon(a, v, "sonar")
		4:
			hit(w, k, 50.0, "slash")
			hit(w, a, 20.0)
			hit(w, null, 1000.0)
		5:
			hit(w, null, 1000.0)
		6:
			k.weapon_id = "rocket"
			v.hp = 50.0
			var bl := SimBullet.new()
			bl.owner = k
			bl.by = k
			bl.team = k.team
			bl.reflected = true
			bl.aoe = 100.0
			bl.dmg = 1000.0
			bl.x = v.x
			bl.y = v.y
			w._hash_all()
			SimWeaponModes.explode_rocket(w, bl)
		7, 8:
			for i in 3:
				for shot in 3:
					hit(w, k, 1000.0)
					if not v.alive:
						break
				v.alive = true
				v.hp = v.max_hp
				v.alive_since = w.t
			if index == 8:
				w.t += config.fade_reset_time
				w.kill_system.tick(w)
				for shot in 3:
					hit(w, k, 1000.0)
					if not v.alive:
						break
		9:
			v.kill_streak = config.shutdown_min
		10:
			v.kill_streak = config.shutdown_min - 1
		11:
			var one := w.begin_assist_control(a, v, "hamster_ball")
			w.t = 1.0
			var two := w.begin_assist_control(a, v, "mousetrap")
			w.t = 2.0
			w.end_assist_control(v.id, one)
			w.t = 3.0
			w.end_assist_control(v.id, two)
		12:
			k.hp = 50.0
			a.hp = 50.0
			w.heal_player(a, k, 10.0)
			w.heal_player(b, a, 20.0)
		14:
			k.bounty_connected = false
			v.kill_streak = config.shutdown_min
			hit(w, a, 30.0)
		15:
			k.alive = false
			k.kill_streak = 0
	if v.alive and not index in [4, 5, 6, 7, 8]:
		for i in 3:
			hit(w, k, 1000.0, "explosion" if index == 15 else "normal")
			if not v.alive:
				break
	var result: Array[Dictionary] = w.kill_system.history.duplicate(true)
	w.dispose()
	return result
