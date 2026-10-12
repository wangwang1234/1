class_name DamageTracker
extends RefCounted
## 只接受服务器已确认的实际贡献。控制保存区间，在结算时裁剪、按人取并集。
## 不保存实体引用，避免陷阱主人阵亡及网络序列化导致归属丢失。

var records: Array[Dictionary] = []
var _control_seq: int = 0


func damage(player_id: int, actual: float, now: float, method: String) -> void:
	if actual > 0.0:
		records.append({"player_id": player_id, "amount": actual, "time": now, "method": method, "type": "damage"})


func recon(player_id: int, now: float, source: String) -> void:
	records.append({"player_id": player_id, "time": now, "type": "recon", "source": source})


func begin_control(player_id: int, now: float, source: String) -> int:
	_control_seq += 1
	records.append({"player_id": player_id, "time": now, "end": INF, "type": "control", "source": source, "token": _control_seq})
	return _control_seq


func end_control(token: int, now: float) -> void:
	for row in records:
		if row.type == "control" and int(row.token) == token:
			row.end = maxf(float(row.time), minf(float(row.end), now))
			return


func support(player_id: int, recipient_id: int, actual: float, now: float, source: String) -> void:
	if player_id != recipient_id and actual > 0.0:
		records.append({"player_id": player_id, "recipient_id": recipient_id, "amount": actual, "time": now, "type": "support", "source": source})


func prune(now: float, window: float) -> void:
	var cutoff := now - window
	records = records.filter(func(row: Dictionary) -> bool:
		return float(row.get("end", row.time)) >= cutoff)


func aggregate(now: float, max_hp: float, config: KillConfig) -> Dictionary:
	prune(now, config.assist_window)
	var out: Dictionary = {}
	var intervals: Dictionary = {}
	for row in records:
		if float(row.time) > now or row.type == "support":
			continue
		var pid := int(row.player_id)
		if not out.has(pid):
			out[pid] = {"damage": 0.0, "contribution": 0.0, "recon": false, "last_damage_time": -INF, "method": "normal", "control_seconds": 0.0}
		var stats: Dictionary = out[pid]
		match String(row.type):
			"damage":
				stats.damage += float(row.amount)
				stats.contribution += float(row.amount) / max_hp
				if float(row.time) >= float(stats.last_damage_time):
					stats.last_damage_time = row.time
					stats.method = row.method
			"recon":
				stats.recon = true
				stats.contribution += config.recon_contribution
			"control":
				var start := maxf(float(row.time), now - config.assist_window)
				var end := minf(float(row.end), now)
				if end > start:
					if not intervals.has(pid):
						intervals[pid] = []
					intervals[pid].append([start, end]) # Array float 为64位，避免长局时间戳被Vector2截成32位。
	for pid in intervals:
		var list: Array = intervals[pid]
		list.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var start: float = list[0][0]
		var end: float = list[0][1]
		var seconds := 0.0
		for i in range(1, list.size()):
			var interval: Array = list[i]
			if float(interval[0]) <= end:
				end = maxf(end, float(interval[1]))
			else:
				seconds += end - start
				start = float(interval[0])
				end = float(interval[1])
		seconds += end - start
		out[pid].control_seconds = seconds
		out[pid].contribution += seconds * config.control_per_second
	return out


func clear() -> void:
	records.clear()
