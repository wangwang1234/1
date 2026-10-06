class_name SimDecoy
extends SimEntity
## 诱饵仓鼠气球：会被敌人当成仓鼠攻击，走路发出脚步声，时间到或被打爆就“噗”地消失。

var owner: SimHamster = null
var skin := "gold"
var weapon_id := "pistol"
var t := 0.0
var life := 8.0
var step_t := 0.0
