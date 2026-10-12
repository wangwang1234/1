extends SceneTree
## 调用真实GDScript计算器生成校验表，禁止另写一份赏金公式作为“验证”。


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := args[0] if not args.is_empty() else "res://../work/kill_phase1/calibration"
	DirAccess.make_dir_recursive_absolute(output_dir)
	var inputs: Dictionary = Data.load_json("kill_calibration")
	var thresholds: Array = Data.progression().cumulativeThresholds
	var rows: Array = []
	var csv := "配置,阶段,内部成长档位,累计瓜子S,收入每秒,赏金池P,击败者所得,等价收入秒数,达到锚点\n"
	var markdown := "# 赏金收入锚点校验\n\n同水平、无助攻、无连续阵亡衰减、无终结。D=1；收入为用户估算，未作为真人实测。成长档位仅作开发校验，游戏不显示等级数字。\n\n"
	markdown += "| 配置 | 阶段 | 内部成长档位 | S | 估算收入/秒 | 击败者所得 | 等价秒数 | 15～20秒锚点 |\n|---|---|---:|---:|---:|---:|---:|---|\n"
	for preset: Dictionary in inputs.presets:
		var config := load(String(preset.path)) as KillConfig
		assert(config.validation_errors().is_empty())
		for sample: Dictionary in inputs.samples:
			var seeds := float(thresholds[int(sample.internal_stage) - 1])
			var pool := BountyCalculator.pool(seeds, int(inputs.previous_deaths), int(inputs.victim_streak), config)
			var reward := BountyCalculator.reward(config.kill_share * float(pool.P) * BountyCalculator.difference(seeds, seeds, config), config)
			var seconds := reward / float(sample.income_per_second)
			var pass_anchor := seconds >= float(inputs.target_seconds_min) and seconds <= float(inputs.target_seconds_max)
			rows.append({"preset": preset.name, "phase": sample.phase, "internal_stage": sample.internal_stage, "seeds": seeds,
				"income_per_second": sample.income_per_second, "P": pool.P, "reward": reward, "income_seconds": seconds, "meets_anchor": pass_anchor,
				"BASE": config.base, "RATIO": config.ratio, "CAP": config.cap})
			csv += "%s,%s,%d,%d,%.3f,%.4f,%d,%.4f,%s\n" % [preset.name, sample.phase, sample.internal_stage, seeds, sample.income_per_second, pool.P, reward, seconds, pass_anchor]
			markdown += "| %s | %s | %d | %d | %.3f | %d | %.2f | %s |\n" % [preset.name, sample.phase, sample.internal_stage, seeds, sample.income_per_second, reward, seconds, "符合" if pass_anchor else "偏低" if seconds < float(inputs.target_seconds_min) else "偏高"]
	markdown += "\n默认：BASE=20 / RATIO=0.10 / CAP=300。建议校准：20 / 0.10 / 120，当前实战使用。候选：32 / 0.065 / 100，仅供选择，未改变实战。\n\n"
	markdown += "默认与建议校准均按确认后的 D 两位小数规则复现 81 / 18 / 9。候选方案不是算例基准。\n\n"
	markdown += "CAP=120 时，同水平基础奖励最多72颗，按后期3颗/秒等价24秒；开局S=0时为12颗，等价12秒。仅限三个代表阶段的数值比较；各阶段真实收入与玩家S分布需后续实测。\n"
	_write(output_dir.path_join("CALIBRATION.md"), markdown)
	_write(output_dir.path_join("calibration.csv"), csv)
	_write(output_dir.path_join("calibration.json"), JSON.stringify(rows, "  ") + "\n")
	var progression_csv := "到达内部成长档位,本次所需瓜子,累计门槛\n"
	for i in thresholds.size():
		progression_csv += "%d,%d,%d\n" % [i + 1, 0 if i == 0 else int(thresholds[i]) - int(thresholds[i - 1]), thresholds[i]]
	_write(output_dir.path_join("progression_50.csv"), progression_csv)
	print("校验表已生成：", output_dir)
	quit()


func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "无法写入校验表")
	file.store_string(content)
