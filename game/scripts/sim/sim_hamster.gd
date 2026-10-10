class_name SimHamster
extends SimEntity
## 仓鼠（玩家 / AI）。字段对应原型 makeHam。

class HamInput:
	extends RefCounted
	var mx := 0.0
	var my := 0.0
	var ml := 0.0
	var aim := 0.0
	var fire := false
	var dash := false
	var reload := false
	var gadget := false
	var card := -1
	var aim_x := 0.0      # 鼠标指向的地面点（投掷落点用）
	var aim_y := 0.0
	var has_aim_point := false
	var assist := 0.0    # 手动瞄准辅助强度（玩家设置；0 = 关，AI 不用）


class AiState:
	extends RefCounted
	var lane := "mid"
	var wp := 1
	var state := "push"
	var retarget := 0.0
	var target: SimEntity = null
	var strafe := 1.0
	var strafe_t := 0.0
	var card_t := 0.0
	var dash_t := 2.0
	var stuck_t := 0.0
	var last_x := 0.0
	var last_y := 0.0
	var inv := {}            # 听到声音去侦察：{x, y, t}
	var jungle_t := 20.0     # 下次考虑去打野的时间
	var camp := {}           # 要去打的营地
	var prof := {}           # 难度参数（difficulty.json 的一档，SimWorld.ai_profile）
	var react_t := 0.0       # 发现新仓鼠目标后的反应时间：倒计时结束前不开火
	var last_tid := 0        # 上一个目标的 id（换目标时重新计反应时间）
	var burst_t := 0.0       # 点射节奏：>0 在连射，<0 在停顿
	var dodge_t := 0.0       # 下次检查飞来子弹的倒计时
	var dodge_x := 0.0       # 正在躲闪的侧移方向（dodge_left > 0 时有效）
	var dodge_y := 0.0
	var dodge_left := 0.0
	var seen := {}           # 最后一次看到仓鼠目标的位置：{x, y}
	var goal_t := 0.0        # 战术判断（捡东西 / 支援 / 被围）的下次检查倒计时
	var pick := {}           # 正要去捡的东西 / 去支援的位置：{x, y, why}


var ctl := "ai"               # player / ai
var name := ""
var idx := 0
var skin := "gold"
var alive := true
var respawn_t := 0.0
var lvl := 1
var xp := 0.0
var xp_next := 41
var pending := 0
var talent_pend := 0
var choices: Array = []       # [{t, id, k}]
var weapon_id := "pistol"
var evo := {"a": 0, "b": 0, "c": 0}
var ammo := 0
var reload_t := 0.0
var reload_dur := 1.0
var bloom := 0.0
var fire_cd := 0.0
var dash_cd := 0.0
var roll_t := 0.0
var rdx := 1.0
var rdy := 0.0
var iframes := 0.0
var hurt_t := 0.0
var shield := 0
var shield_t := 8.0
var gadget := {"id": "frag", "lvl": 1, "cd": 2.0}
var ab := {}                  # 通用强化 id -> 级
var tal := {}                 # 天赋 id -> true
var st := {}                  # calc_stats 结果
var crown_t := 0.0
var invis_t := 0.0
var stun_t := 0.0
var blind_t := 0.0
var air := {}                 # 弹射飞行：{t, dur, x0, y0, x1, y1, hgt}
var z := 0.0
var pad_cd := 0.0
var base_heal_t := 0.0         # 鼠窝回血的下一跳倒计时
var last_shot_t := -9.0
var shot_n := 0
var ramp := 0.0
var burst_n := 0
var burst_t := 0.0
var steady_t := 0.0
var dazzle_t := 0.0
var aggro_t := -9.0
var dash_hit := {}
var heat := 0.0
var munch_t := 0.0
var spit_t := 0.0
var undy_used := false
var banner_k := 1.0
var kills := 0
var deaths := 0
var dmg_dealt := 0.0
var bdmg := 0.0
var walk := 0.0               # 走路相位（表现层用）
var moving := false
var puff := 0.0               # 腮帮子鼓起程度 = 经验进度
var step_t := 0.0
var inp := HamInput.new()
var ai: AiState = null
var kill_streak := 0
var evo_key := ""             # 进化参数缓存
var evo_params := {}
# 批次 2：武器状态
var spin := 0.0               # 加特林转速 0..1
var dual_side := 1            # 双持：+1 右手 / -1 左手
var haste_t := 0.0            # 冲锋枪 B9 急速
var marks: Array = []         # 左轮神枪手标记的目标 id
var mark_hold := 0.0
var mark_acc := 0.0
var deadeye_shot := false
var swing_t := 0.0            # 武士刀
var swing_dir := 1.0
var swing_n := 0
var iaido_hit := {}
var iaido_on := false
var dash_spd := 1.0
var flame_t := 0.0            # 喷火器连喷计时 / 火洼计时
var puddle_t := -9.0
var gl_n := 0                 # 榴弹特种弹计数
var charge := 0.0             # 电磁炮蓄力
var ch_hold := 0.0
var beam_t := 0.0             # 激光
var beams: Array = []         # [{x0,y0,x1,y1,h,hit,side}]
var beam_tick_t := -9.0
var focus_id := -1
var focus_n := 0
var ammo_f := 0.0
# 批次 2：道具 / 天赋 / 宠物
var eshield := 0.0            # 能量护盾剩余吸收量
var eshield_t := 0.0
var med_t := 0.0
var med_rate := 0.0
var jet_t := 0.0
var beacon := {}              # {x, y, until}
var squad_t := 20.0
var pet_list: Array = []      # SimPet


func is_alive() -> bool:
	return alive and not dead


func evo_lv(k: String) -> int:
	return int(evo.get(k, 0))


func evo_total() -> int:
	return evo_lv("a") + evo_lv("b") + evo_lv("c")


func weapon() -> Dictionary:
	return Data.weapon(weapon_id)
