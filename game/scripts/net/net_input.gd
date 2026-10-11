class_name NetInput
extends RefCounted


static func pack(i: SimHamster.HamInput) -> Dictionary:
	return {"mx": i.mx, "my": i.my, "aim": i.aim, "fire": i.fire,
		"ax": i.aim_x, "ay": i.aim_y, "point": i.has_aim_point, "assist": i.assist}


static func finite_number(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))


static func pack_actions(i: SimHamster.HamInput, choices: Array, input_seq: int) -> Dictionary:
	return {"dash": i.dash, "reload": i.reload, "gadget": i.gadget, "skill": i.skill, "card": i.card,
		"choices": hash(choices), "input_seq": input_seq, "input": pack(i)}


static func roll_direction(i: SimHamster.HamInput) -> Vector2:
	var direction := Vector2(i.mx, i.my)
	return direction.normalized() if direction.length() >= 0.2 else Vector2.from_angle(i.aim)


static func apply_actions(i: SimHamster.HamInput, p: Dictionary, choices: Array) -> bool:
	# Validate the whole command before consuming its sequence or any edge.
	for key in ["dash", "reload", "gadget", "skill"]:
		if not p.get(key) is bool:
			return false
	if not p.get("card") is int or not p.get("choices") is int:
		return false
	var card: int = p.card
	if card < -1 or card >= choices.size():
		return false
	if not p.get("input_seq") is int or p.input_seq < 1 or not p.get("input") is Dictionary:
		return false
	var context := SimHamster.HamInput.new()
	if not apply(context, p.input):
		return false
	# Keep the first pending edge's press-time direction across newer controls.
	if p.dash and not i.dash:
		i.dash_direction = roll_direction(context)
	i.dash = i.dash or p.dash
	i.reload = i.reload or p.reload
	i.gadget = i.gadget or p.gadget
	i.skill = i.skill or p.skill
	if card >= 0 and p.choices == hash(choices):
		i.card = card
	return true


static func apply(i: SimHamster.HamInput, p: Dictionary) -> bool:
	for k in ["mx", "my", "aim", "ax", "ay", "assist"]:
		if not finite_number(p.get(k)):
			return false
	var move: = Vector2(clampf(float(p.mx), -1, 1), clampf(float(p.my), -1, 1)).limit_length()
	i.mx = move.x
	i.my = move.y
	i.ml = move.length()
	i.aim = wrapf(float(p.aim), - PI, PI)
	i.fire = p.get("fire") == true
	i.aim_x = clampf(float(p.ax), -100000, 100000)
	i.aim_y = clampf(float(p.ay), -100000, 100000)
	i.has_aim_point = p.get("point") == true
	# 辅助瞄准强度是玩家自己的设置（rules.json aimAssist.levels），主机只限制范围
	i.assist = clampf(float(p.assist), 0.0, (Data.rule("aimAssist.levels", {}) as Dictionary).values().max())
	return true


static func clear_continuous(i: SimHamster.HamInput) -> void:
	i.mx = 0
	i.my = 0
	i.ml = 0
	i.fire = false


static func clear(i: SimHamster.HamInput) -> void :
	clear_continuous(i)
	i.dash = false
	i.dash_direction = Vector2.ZERO
	i.reload = false
	i.gadget = false
	i.skill = false
	i.card = -1
