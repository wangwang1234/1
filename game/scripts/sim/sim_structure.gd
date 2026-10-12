class_name SimStructure
## owner_contributor_id 在放置时固定，防止 AI 接管领取断线者的哨戒炮赏金。
extends SimEntity
## 鼠窝（base）/ 炮台（turret）/ 旧道具自动炮台（sentry）/ 道具部署物（dep：摄像头、捕鼠夹、掩体、再生力场、哨戒炮、反射器）。对应原型 mkStruct / updStruct。

var range_ := 480.0
var dmg := 30.0
var cd := 0.5
var cd_max := 1.0
var target: SimEntity = null
var t_t := 0.0
var alt := 0
var muzzle_h := 60.0
var alt_off := 0.0
var owner: SimHamster = null
var owner_contributor_id := 0
var life := 0.0
# 道具部署物（kind = dep，见 SimGadgets.update_dep）
var dep := ""                 # 道具 id
var cfg := {}                 # gadgets.json 的 fx（parts 等）
var life_max := 0.0
var uses := 0                 # 反射器已反弹几发
var alert_t := -99.0          # 摄像头：最近一次有敌方仓鼠进入的时间（小地图标红）
var inside := {}              # 摄像头范围内的敌人 id
