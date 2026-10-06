class_name SimLob
extends RefCounted
## 抛物投掷物（手雷、燃烧瓶、闪光弹、烟雾弹、照明弹、冰冻弹、榴弹、子炸弹）。对应原型 throwLob / updLobs。
## kind: frag / molo / flsh / smk / flr / frz / gnade / bomb

var kind := "frag"
var team := "neutral"
var owner: SimHamster = null
var x := 0.0
var y := 0.0
var z := 20.0
var vx := 0.0
var vy := 0.0
var vz := 0.0
var fuse := -1.0
var aoe := 130.0
var dmg := 70.0
var kb := 380.0
var impact := false
var t := 0.0
var rot := 0.0
var dead := false
var id := 0
var lvl := 1
var sticky := false
var stuck := false
var att: SimEntity = null   # 黏在谁身上
var ox := 0.0
var oy := 0.0
var slow_stick := 0.0
var bounce_n := 0
var split_on_bounce := false
var split_ang := 0.7
var split_vz := 0.4
var special := ""           # 榴弹特种弹：smoke / flash / fire
var gas_r := 0.0
var gas_life := 0.0
var gas_dps := 0.0
var gas_slow := 0.0


func clone() -> SimLob:
	var L := SimLob.new()
	for p in ["kind", "team", "owner", "x", "y", "z", "vx", "vy", "vz", "fuse", "aoe", "dmg", "kb", "impact", "t", "rot", "lvl", "sticky", "stuck",
			"slow_stick", "bounce_n", "split_on_bounce", "split_ang", "split_vz", "special", "gas_r", "gas_life", "gas_dps", "gas_slow"]:
		L.set(p, get(p))
	return L
