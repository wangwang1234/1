class_name StreakTracker
extends RefCounted

var has_first_kill: bool = false


static func refresh_survival(h: SimHamster, now: float, config: KillConfig) -> void:
	if h.alive and now - h.alive_since >= config.fade_reset_time:
		h.consecutive_deaths = 0


func defeated(victim: SimHamster, killer: SimHamster, qualified: bool = true) -> bool:
	victim.kill_streak = 0
	victim.consecutive_deaths += 1
	if killer == null:
		return false
	var first := not has_first_kill
	has_first_kill = true
	killer.kills += 1
	if qualified:
		killer.kill_streak += 1
		killer.consecutive_deaths = 0
	return first
