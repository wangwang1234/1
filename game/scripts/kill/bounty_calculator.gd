class_name BountyCalculator
extends RefCounted


static func difference(victim_seeds: float, recipient_seeds: float, config: KillConfig) -> float:
	if victim_seeds == 0.0 and recipient_seeds == 0.0:
		return 1.0
	if recipient_seeds == 0.0:
		return config.d_max
	if victim_seeds == 0.0:
		return config.d_min
	var exact := clampf(sqrt(victim_seeds / recipient_seeds), config.d_min, config.d_max)
	var precision := pow(10.0, config.d_round_decimals)
	return clampf(roundf(exact * precision) / precision, config.d_min, config.d_max)


static func pool(seeds: float, previous_deaths: int, victim_streak: int, config: KillConfig) -> Dictionary:
	var fade := maxf(pow(config.decay, previous_deaths), config.fade_min)
	var shutdown := 1.0
	if victim_streak >= config.shutdown_min:
		shutdown = minf(1.0 + config.shutdown_step * (victim_streak - config.shutdown_min + 1), config.shutdown_max)
	var capped := minf(config.base + seeds * config.ratio, config.cap)
	return {"P": capped * fade * shutdown, "F": fade, "M": shutdown, "uncapped": config.base + seeds * config.ratio, "capped": capped}


static func reward(raw: float, config: KillConfig) -> int:
	return maxi(config.reward_min, roundi(raw))


static func calculate(victim: Dictionary, killer: Dictionary, assists: Array, config: KillConfig) -> Dictionary:
	var out := pool(float(victim.seeds), int(victim.deaths), int(victim.streak), config)
	out.killer_reward = 0
	out.assists = []
	out.recipients = []
	if killer.is_empty():
		return out
	var total := 0.0
	for a: Dictionary in assists:
		total += float(a.contribution) # 断线者也保留分母；份额不重新分配。
	out.assist_total = total
	var kd := difference(float(victim.seeds), float(killer.seeds), config)
	var raw := config.kill_share * float(out.P) * kd
	out.killer_reward = reward(raw, config) if bool(killer.connected) else 0
	out.recipients.append({"player_id": killer.player_id, "D": kd, "contribution": 0.0, "raw": raw, "reward": out.killer_reward, "connected": killer.connected, "role": "killer"})
	for a: Dictionary in assists:
		var d := difference(float(victim.seeds), float(a.seeds), config)
		var amount := config.assist_share * float(out.P) * float(a.contribution) / total * d
		var awarded := reward(amount, config) if bool(a.connected) else 0
		out.assists.append({"player_id": a.player_id, "reward": awarded, "connected": a.connected, "contribution": a.contribution})
		out.recipients.append({"player_id": a.player_id, "D": d, "contribution": a.contribution, "raw": amount, "reward": awarded, "connected": a.connected, "role": "assist"})
	return out
