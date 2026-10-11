class_name SpectatorState
extends RefCounted
## 每个本地玩家独立的观战状态；不改变模拟、队伍或视野。

var target_id := -1
var elapsed := 0.0
var was_alive := true
var last_position := Vector3.ZERO

func candidates(w: SimWorld, owner: SimHamster, eligible: Callable = Callable()) -> Array:
	var out: Array = []
	for h in w.hams:
		if h != owner and h.team == owner.team and h.alive and not h.dead and (not eligible.is_valid() or eligible.call(h.id)):
			out.append(h)
	# Human teammates first, stable within each group.
	out.sort_custom(func(a: SimHamster, b: SimHamster) -> bool:
		if (a.ctl == "player") != (b.ctl == "player"):
			return a.ctl == "player"
		return a.id < b.id)
	return out

func update(w: SimWorld, owner: SimHamster, dt: float, delay: float, eligible: Callable = Callable()) -> SimHamster:
	if owner.alive:
		elapsed = 0.0
		target_id = -1
		was_alive = true
		last_position = Vector3(owner.x * 0.01, 0, owner.y * 0.01)
		return owner
	if was_alive:
		last_position = Vector3(owner.x * 0.01, 0, owner.y * 0.01)
		was_alive = false
	elapsed += dt
	if elapsed < delay or w.over:
		target_id = -1
		return null
	var choices := candidates(w, owner, eligible)
	for h in choices:
		if h.id == target_id:
			return h
	target_id = choices[0].id if not choices.is_empty() else -1
	return choices[0] if not choices.is_empty() else null

func cycle(w: SimWorld, owner: SimHamster, direction: int, eligible: Callable = Callable()) -> void:
	if owner.alive or w.over or direction == 0:
		return
	var choices := candidates(w, owner, eligible)
	if choices.is_empty():
		target_id = -1
		return
	var current := -1
	for i in choices.size():
		if choices[i].id == target_id:
			current = i
	if current < 0:
		target_id = choices[0 if direction > 0 else choices.size() - 1].id
	else:
		target_id = choices[posmod(current + direction, choices.size())].id
	elapsed = INF # Manual switching can skip the death-location hold.
