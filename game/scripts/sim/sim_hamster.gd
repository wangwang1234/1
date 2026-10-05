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


func is_alive() -> bool:
	return alive and not dead


func evo_lv(k: String) -> int:
	return int(evo.get(k, 0))


func evo_total() -> int:
	return evo_lv("a") + evo_lv("b") + evo_lv("c")


func weapon() -> Dictionary:
	return Data.weapon(weapon_id)
