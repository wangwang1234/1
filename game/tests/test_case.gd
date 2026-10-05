extends RefCounted
## 测试基类：失败不抛异常，记录到 failures。

var failures: Array[String] = []
var note := ""


func reset() -> void:
	failures.clear()
	note = ""


func check(cond: bool, msg: String) -> bool:
	if not cond:
		failures.append(msg)
	return cond


func eq(a: Variant, b: Variant, msg: String) -> bool:
	return check(a == b, "%s：期望 %s，实际 %s" % [msg, str(b), str(a)])


func near(a: float, b: float, eps: float, msg: String) -> bool:
	return check(absf(a - b) <= eps, "%s：期望 %.4f±%.4f，实际 %.4f" % [msg, b, eps, a])


static func make_world(mode: String = "slice", seed_: int = 7, ai_blue: int = 3, ai_red: int = 3, players: Array = []) -> SimWorld:
	var w := SimWorld.new()
	w.setup({"mode": mode, "seed": seed_, "players": players, "ai": {"blue": ai_blue, "red": ai_red}})
	return w


static func run(w: SimWorld, seconds: float) -> void:
	var dt := 1.0 / 60.0
	var n := int(seconds * 60.0)
	for i in n:
		w.step(dt)
		w.events.clear()
		if w.over:
			break
