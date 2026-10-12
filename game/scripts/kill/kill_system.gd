class_name KillSystem
extends RefCounted
## 每局服务器状态。客户端不会调用贡献、结算及发放入口。

var config: KillConfig
var trackers: Dictionary = {}
var support := DamageTracker.new()
var streak := StreakTracker.new()
var history: Array[Dictionary] = []
var sequence: int = 0
var identities: Dictionary = {}
var aliases: Dictionary = {}


func _init(settings: KillConfig = null) -> void:
	config = settings if settings != null else load("res://data/kill_config_calibrated.tres") as KillConfig
	assert(config != null and config.validation_errors().is_empty(), "击败配置无效")


func tracker(victim_id: int) -> DamageTracker:
	if not trackers.has(victim_id):
		trackers[victim_id] = DamageTracker.new()
	return trackers[victim_id]


func identity(h: SimHamster) -> int:
	if h == null:
		return -1
	if h.contributor_id == 0:
		h.contributor_id = h.id
		h.player_contributor_id = h.id
	if not identities.has(h.contributor_id):
		identities[h.contributor_id] = {"actor_id": h.id, "connected": h.bounty_connected, "source": h.ctl}
	return h.contributor_id


func canonical(id: int) -> int:
	while aliases.has(id):
		id = int(aliases[id])
	return id


func mark_disconnected(h: SimHamster) -> void:
	var id := identity(h)
	identities[id].connected = false
	h.bounty_connected = false


func takeover(w: SimWorld, h: SimHamster) -> void:
	mark_disconnected(h)
	h.contributor_id = w.new_uid()
	h.bounty_connected = true
	identity(h)
	identities[h.contributor_id].source = "ai"


func resume_player(h: SimHamster) -> void:
	var current := identity(h)
	if current != h.player_contributor_id:
		aliases[current] = h.player_contributor_id
	h.contributor_id = h.player_contributor_id
	h.bounty_connected = true
	identity(h)
	identities[h.contributor_id].connected = true
	identities[h.contributor_id].source = "player"


func _participants(w: SimWorld) -> Dictionary:
	for h in w.hams:
		var id := identity(h)
		identities[id].connected = h.bounty_connected
	var result: Dictionary = {}
	for id in identities:
		if canonical(int(id)) != int(id):
			continue
		var h := w.ham_by_id(int(identities[id].actor_id))
		if h != null:
			result[id] = {"player_id": id, "actor_id": h.id, "seeds": h.seed_total, "team": h.team, "name": h.name,
				"connected": identities[id].connected, "source": identities[id].source}
	return result


func _canonical_tracker(original: DamageTracker) -> DamageTracker:
	var result := DamageTracker.new()
	for row in original.records:
		var copy: Dictionary = row.duplicate(true)
		copy.player_id = canonical(int(copy.player_id))
		result.records.append(copy)
	return result


func tick(w: SimWorld) -> void:
	if not w.authoritative:
		return
	for h in w.hams:
		StreakTracker.refresh_survival(h, w.t, config)
	for item: DamageTracker in trackers.values():
		item.prune(w.t, config.assist_window)
	support.prune(w.t, config.assist_window)


func settle(w: SimWorld, victim: SimHamster, src: Dictionary) -> Dictionary:
	if not w.authoritative or not victim.alive:
		return {}
	for h in w.hams:
		StreakTracker.refresh_survival(h, w.t, config)
	var participants := _participants(w)
	var owner: SimHamster = src.get("owner") as SimHamster
	var fatal_id := canonical(w.source_contributor(src, owner))
	var method := String(src.get("method", "normal"))
	var support_copy := DamageTracker.new()
	for row in support.records:
		var copy: Dictionary = row.duplicate(true)
		copy.player_id = canonical(int(copy.player_id))
		support_copy.records.append(copy)
	var resolution := KillResolverService.resolve(victim.team, fatal_id, method,
		_canonical_tracker(tracker(victim.id)).aggregate(w.t, victim.max_hp, config), participants, support_copy, w.t, victim.max_hp, config)
	var killer_info: Dictionary = participants.get(resolution.killer_id, {})
	var killer: SimHamster = w.ham_by_id(int(killer_info.get("actor_id", -1)))
	var before := victim.kill_streak
	var bounty := BountyCalculator.calculate({"seeds": victim.seed_total, "deaths": victim.consecutive_deaths, "streak": before},
		participants.get(resolution.killer_id, {}), resolution.assists, config)
	var event := KillEvent.new()
	sequence += 1
	event.event_id = sequence
	event.killer_id = killer.id if killer != null else -1
	event.victim_id = victim.id
	event.method = String(resolution.method)
	event.victim_streak_before = before
	event.is_shutdown = killer != null and before >= config.shutdown_min
	event.is_first_kill = streak.defeated(victim, killer, bool(killer_info.get("connected", false)))
	event.killer_streak = killer.kill_streak if killer != null else 0
	event.killer_connected = bool(killer_info.get("connected", false))
	event.killer_reward = int(bounty.killer_reward)
	for a: Dictionary in bounty.assists:
		var info: Dictionary = participants[a.player_id]
		var copy: Dictionary = a.duplicate(true)
		copy.contributor_id = a.player_id
		copy.player_id = info.actor_id
		event.assists.append(copy)
	event.victim_position = Vector2(victim.x, victim.y)
	event.identities[victim.id] = {"name": victim.name, "team": victim.team, "seeds": victim.seed_total, "connected": victim.bounty_connected}
	if killer != null:
		event.identities[killer.id] = killer_info
	for a: Dictionary in event.assists:
		event.identities[a.player_id] = participants[a.contributor_id]
	# 全部奖励使用阵亡瞬间的 S 快照；先算完，再发放，禁止逐个领取影响 D。
	for row: Dictionary in bounty.recipients:
		if int(row.reward) > 0:
			SimHamsterLogic.give_xp(w, w.ham_by_id(int(participants[row.player_id].actor_id)), float(row.reward), false)
		row.contributor_id = row.player_id
		row.identity = participants[row.player_id].duplicate(true)
		row.player_id = participants[row.player_id].actor_id
	tracker(victim.id).clear()
	event.debug = bounty
	event.debug.victim_seeds = event.identities[victim.id].seeds
	event.debug.killer_contributor_id = int(resolution.killer_id)
	event.debug.previous_deaths = victim.consecutive_deaths - 1
	event.debug.direct_assists = resolution.assists
	var packet := event.to_dict()
	history.append(packet.duplicate(true))
	while history.size() > config.debug_history_limit:
		history.pop_front()
	w.emit(packet) # 与发放同一逻辑帧，不等吸附动画，不由客户端重算。
	return packet
