class_name KillResolverService
extends Node
## KillResolver 自动加载入口。纯判定静态函数也可在无 SceneTree 的 headless sim 调用。


static func resolve(victim_team: String, fatal_id: int, fatal_method: String, stats: Dictionary,
		participants: Dictionary, support: DamageTracker, now: float, max_hp: float, config: KillConfig) -> Dictionary:
	var eligible: Dictionary = {}
	for pid in stats:
		if participants.has(pid) and String(participants[pid].team) != victim_team:
			eligible[pid] = stats[pid].duplicate(true)
	var killer_id := -1
	var method := fatal_method
	# 断线玩家的致命一击仍保留归属；其他补刀只从在线敌人的实际伤害中选。
	if participants.has(fatal_id) and String(participants[fatal_id].team) != victim_team:
		killer_id = fatal_id
	else:
		var best_damage := 0.0
		var best_time := -INF
		for pid in eligible:
			if not bool(participants[pid].connected):
				continue
			var row: Dictionary = eligible[pid]
			var damage := float(row.damage)
			var last := float(row.last_damage_time)
			var stable_id := int(participants[pid].actor_id)
			var best_stable := int(participants[killer_id].actor_id) if killer_id >= 0 else -1
			if damage > best_damage or (damage == best_damage and damage > 0.0 and (last > best_time or (last == best_time and stable_id < best_stable))):
				killer_id = int(pid)
				best_damage = damage
				best_time = last
		if killer_id >= 0:
			method = String(eligible[killer_id].method)
	if killer_id < 0:
		return {"killer_id": -1, "method": method, "assists": []}
	# 第一轮：只看伤害、控制、侦察。支援接收人集合在此冻结，不能传递。
	var killer_actor := int(participants[killer_id].actor_id)
	var direct: Dictionary = {killer_actor: true}
	for pid in eligible:
		if int(participants[pid].actor_id) != killer_actor and _qualifies(eligible[pid], config):
			direct[int(participants[pid].actor_id)] = true
	# 第二轮：对冻结集合的实际治疗/护盾吸收计入最终贡献。
	support.prune(now, config.assist_window)
	for row in support.records:
		var pid := int(row.player_id)
		var recipient := int(row.recipient_id)
		if float(row.time) > now or pid == recipient or not direct.has(recipient) or not participants.has(pid):
			continue
		if int(participants[pid].actor_id) == recipient or String(participants[pid].team) == victim_team:
			continue
		if not eligible.has(pid):
			eligible[pid] = {"damage": 0.0, "contribution": 0.0, "recon": false}
		eligible[pid].contribution += float(row.amount) / max_hp
	var assists: Array = []
	var ids: Array = eligible.keys()
	ids.sort()
	for pid in ids:
		var row: Dictionary = eligible[pid]
		if int(participants[pid].actor_id) != killer_actor and _qualifies(row, config):
			var info: Dictionary = participants[pid].duplicate(true)
			info.contribution = float(row.contribution)
			info.direct = direct.has(int(info.actor_id))
			assists.append(info)
	return {"killer_id": killer_id, "method": method, "assists": assists}


static func _qualifies(row: Dictionary, config: KillConfig) -> bool:
	return bool(row.recon) or float(row.contribution) + config.comparison_epsilon >= config.assist_min
