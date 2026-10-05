extends SceneTree
## headless 测试入口：godot --headless --path game -s res://tests/run_all.gd [-- --only <文件名片段>]
## 自动发现 res://tests/test_*.gd，运行其中所有 test_ 开头的方法。任何失败 -> 退出码 1。

const TestCase := preload("res://tests/test_case.gd")


func _init() -> void:
	var only := ""
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--only" and i + 1 < args.size():
			only = args[i + 1]
	var files: Array[String] = []
	var dir := DirAccess.open("res://tests")
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			if only == "" or f.contains(only):
				files.append(f)
	files.sort()
	var total := 0
	var failed := 0
	var t0 := Time.get_ticks_msec()
	var report: Array[String] = []
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null:
			report.append("[加载失败] " + f)
			failed += 1
			continue
		var inst: TestCase = script.new()
		for m in inst.get_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			total += 1
			inst.reset()
			var ts := Time.get_ticks_msec()
			inst.call(name)
			var dur := Time.get_ticks_msec() - ts
			if inst.failures.is_empty():
				report.append("  ok   %s.%s (%d ms)%s" % [f.get_basename(), name, dur, ("  " + inst.note) if inst.note != "" else ""])
			else:
				failed += 1
				report.append("  FAIL %s.%s" % [f.get_basename(), name])
				for e in inst.failures:
					report.append("       - " + e)
	for line in report:
		print(line)
	print("测试：%d 项，失败 %d 项，用时 %.1f 秒" % [total, failed, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(1 if failed > 0 else 0)
