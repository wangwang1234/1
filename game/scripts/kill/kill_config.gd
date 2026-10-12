class_name KillConfig
extends Resource
## 系统数值的唯一入口；默认算例与实战校准资源共享此类型。

@export_group("赏金")
@export var base: float = 20.0
@export var ratio: float = 0.10
@export var cap: float = 300.0
@export var kill_share: float = 0.6
@export var assist_share: float = 0.2
@export var decay: float = 0.7
@export var fade_min: float = 0.3
@export var fade_reset_time: float = 90.0
@export var d_min: float = 0.5
@export var d_max: float = 1.5
@export var d_round_decimals: int = 2 # 导演确认：D先保留两位，再对最终赏金四舍五入。
@export var shutdown_min: int = 4
@export var shutdown_step: float = 0.25
@export var shutdown_max: float = 2.0
@export var reward_min: int = 1
@export_group("贡献")
@export var assist_window: float = 10.0
@export var assist_min: float = 0.10
@export var control_per_second: float = 0.10
@export var recon_contribution: float = 0.05
@export var comparison_epsilon: float = 0.000000001 # 消除60Hz时钟累积误差；标称助攻门槛不变。
@export_group("调试")
@export var debug_history_limit: int = 100
@export var debug_preview_streak_max: int = 999
@export_group("展示共享值")
@export var gold_seed_value: int = 5
@export var reward_projectile_max: int = 12
@export var gold_row_max: int = 4

@export_group("第二阶段布局")
@export var reference_height: float = 1080.0
@export var seed_bottom_ratio: float = 0.22
@export var seed_height: float = 48.0
@export var gold_seed_height: float = 64.0
@export var seed_width_ratio: float = 0.5
@export var seed_gap: float = 10.0
@export var title_gap: float = 16.0
@export var title_size: int = 44
@export var highlight_title_size: int = 64
@export var subtitle_size: int = 24
@export var title_outline: int = 4
@export var subtitle_outline: int = 2
@export var tag_icon_size: float = 56.0
@export var method_icon_size: float = 32.0
@export var feed_row_height: float = 36.0
@export var feed_font_size: int = 22
@export var feed_assist_size: int = 16
@export var feed_max_rows: int = 5
@export var feed_width: float = 720.0
@export var feed_margin: float = 18.0
@export var feed_top: float = 24.0
@export var feed_name_width: float = 170.0
@export var feed_assist_width: float = 200.0
@export var banner_top_ratio: float = 0.12
@export var banner_size: int = 40
@export var death_top_ratio: float = 0.36
@export var toast_font_size: int = 24
@export var mobile_clearance: float = 32.0
@export var viewport_margin: float = 16.0
@export var announcement_layer: int = 12
@export var white_title: Color = Color("#ffffff")
@export var title_ink: Color = Color("#3b2418")
@export var gold_top: Color = Color("#ffe27a")
@export var gold_bottom: Color = Color("#e8a317")
@export var subtitle_color: Color = Color("#ffe9a8")
@export var disconnected_color: Color = Color("#9a9693")
@export_group("第二阶段停留与淡出")
@export var ordinary_stay: float = 1.5
@export var five_stay: float = 2.5
@export var unstoppable_stay: float = 2.0
@export var assist_stay: float = 1.2
@export var feed_stay: float = 5.0
@export var feed_fade: float = 0.3
@export var banner_stay: float = 2.0
@export var five_streak: int = 5
@export var unstoppable_streak: int = 6


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if base < 0.0 or ratio < 0.0 or cap <= 0.0:
		errors.append("BASE/RATIO 必须非负，CAP 必须为正")
	if kill_share < 0.0 or assist_share < 0.0 or kill_share + assist_share > 1.0:
		errors.append("赏金份额必须非负且总和不超过 1")
	if decay <= 0.0 or decay > 1.0 or fade_min <= 0.0 or fade_min > 1.0 or fade_reset_time <= 0.0:
		errors.append("衰减参数无效")
	if d_min <= 0.0 or d_max < d_min or shutdown_min < 1 or shutdown_step < 0.0 or shutdown_max < 1.0:
		errors.append("差距或终结参数无效")
	if d_round_decimals < 0 or d_round_decimals > 6:
		errors.append("D的小数位必须在0至6之间")
	if assist_window <= 0.0 or assist_min <= 0.0 or control_per_second < 0.0 or recon_contribution < 0.0:
		errors.append("贡献参数无效")
	if comparison_epsilon < 0.0 or comparison_epsilon >= assist_min:
		errors.append("浮点容差必须非负且小于助攻门槛")
	if reward_min < 1 or debug_history_limit < 1 or debug_preview_streak_max < 1:
		errors.append("领取下限及调试上限必须为正")
	if gold_seed_value < 1 or gold_row_max < 1 or reward_projectile_max < 1:
		errors.append("展示参数必须为正")
	if reference_height <= 0.0 or seed_bottom_ratio <= 0.0 or seed_bottom_ratio >= 1.0 or seed_width_ratio <= 0.0:
		errors.append("视口缩放与瓜子排位置参数无效")
	for value in [seed_height, gold_seed_height, seed_gap, title_gap, tag_icon_size, method_icon_size, feed_row_height, feed_width, feed_name_width, feed_assist_width]:
		if value <= 0.0:
			errors.append("布局尺寸必须为正")
	if feed_max_rows < 1 or title_size < 1 or highlight_title_size < 1 or subtitle_size < 1 or banner_size < 1:
		errors.append("字体及信息条上限必须为正")
	if ordinary_stay <= 0.0 or five_stay <= 0.0 or unstoppable_stay <= 0.0 or assist_stay <= 0.0 or feed_stay <= 0.0 or feed_fade <= 0.0 or banner_stay <= 0.0:
		errors.append("停留与淡出时长必须为正")
	if five_streak < 1 or unstoppable_streak <= five_streak:
		errors.append("高光播报门槛无效")
	return errors
