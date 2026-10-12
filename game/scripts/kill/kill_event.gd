class_name KillEvent
extends RefCounted
## RPC 只发送基础 Variant。额外身份快照确保事件晚于复活/断线时仍可正确显示。

var event_id: int = 0
var killer_id: int = -1
var victim_id: int = -1
var victim_death_count: int = 0
var method: String = "normal"
var assists: Array = []
var killer_reward: int = 0
var killer_streak: int = 0
var victim_streak_before: int = 0
var is_first_kill: bool = false
var is_shutdown: bool = false
var killer_connected: bool = false
var identities: Dictionary = {}
var victim_position: Vector2 = Vector2.ZERO
var debug: Dictionary = {}


func to_dict() -> Dictionary:
	return {"t": "kill_event", "event_id": event_id, "killer_id": killer_id, "victim_id": victim_id, "victim_death_count": victim_death_count, "method": method,
		"assists": assists.duplicate(true), "killer_reward": killer_reward, "killer_streak": killer_streak,
		"victim_streak_before": victim_streak_before, "is_first_kill": is_first_kill, "is_shutdown": is_shutdown,
		"killer_connected": killer_connected, "identities": identities.duplicate(true), "victim_position": victim_position,
		"debug": debug.duplicate(true)}
