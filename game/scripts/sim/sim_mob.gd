class_name SimMob
extends SimEntity
## 野怪：蟑螂（roach）、鼠帮枪手（rat）、鼠王（boss）。对应原型 mkMob / updMob。

var camp: Dictionary = {}     # 所属营地（鼠王和召唤出来的小弟为空）
var hx := 0.0                 # 家
var hy := 0.0
var spd := 120.0
var target: SimEntity = null
var heading := 0.0
var t := 0.0
var ph := 0.0
var wt := 0.0                 # 闲逛计时
var tx := 0.0
var ty := 0.0
var cd := 1.0
var tele := 0.0               # 枪手蹲下瞄准（红色激光）
var burst := 0
var bt := 0.0
var walk := 0.0
var recoil := 0.0
var leash := 520.0
var returning := false
var ring_t := 4.0
var sum_t := 9.0
var los_t := 0.0
var st_t := 0.0               # 枪手横移换向计时
var sdir := 1.0
var bcd := 0.0                # 蟑螂咬人冷却
var summoned := false
