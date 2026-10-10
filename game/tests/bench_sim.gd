extends SceneTree
## 逻辑耗时基准（不是测试，run_all 不会跑它）：godot --headless --path game -s res://tests/bench_sim.gd [-- --seconds 600 --seed 7]
## 只跑 sim（不渲染），统计每个 60Hz 逻辑步的耗时分布和流场（寻路）计算次数。

const TC := preload("res://tests/test_case.gd")


func _bench(mode: String, ai: int, seconds: float, seed_: int) -> void:
	var w := TC.make_world(mode, seed_, ai, ai)
	var ts: Array = []
	for i in int(seconds * 60.0):
		var t0 := Time.get_ticks_usec()
		w.step(1.0 / 60.0)
		ts.append((Time.get_ticks_usec() - t0) / 1000.0)
		w.events.clear()
		if w.over:
			break
	var s := ts.duplicate()
	s.sort()
	var avg := 0.0
	for x in ts:
		avg += x
	avg /= maxf(1.0, ts.size())
	print("%s %d 对 %d，%.0f 秒：平均 %.2f ms/步，99%% %.2f ms，99.9%% %.2f ms，最大 %.2f ms，超过 8 ms 的步 %d 个，流场 %d 次%s" % [
		mode, ai, ai, w.t, avg, s[int(s.size() * 0.99)], s[int(s.size() * 0.999)], s[-1], ts.filter(func(x): return x > 8.0).size(), int(w.map.get("bfs_count") if w.map.get("bfs_count") != null else -1),
		"（%s 胜）" % w.winner if w.over else ""])
	w.dispose()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seconds := 600.0
	var seed_ := 7
	for i in args.size():
		if args[i] == "--seconds" and i + 1 < args.size():
			seconds = float(args[i + 1])
		if args[i] == "--seed" and i + 1 < args.size():
			seed_ = int(args[i + 1])
	print("CPU：%s，%d 线程" % [OS.get_processor_name(), OS.get_processor_count()])
	_bench("slice", 3, minf(seconds, 120.0), seed_)
	_bench("full", 5, seconds, seed_)
	quit(0)
