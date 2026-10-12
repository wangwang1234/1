class_name KillPresentationUI
extends Node
## 一局一个展示路由器：信息条和全场横幅共享；私人播报严格落到身份对应的视口。

var config: KillConfig
var feed: KillFeedUI
var global_banner: GlobalBannerUI
var views: Array[Dictionary] = []
var last_event_id: int = 0


func setup(settings: KillConfig) -> void:
	config = settings
	feed = KillFeedUI.new(config)
	global_banner = GlobalBannerUI.new(config)


func attach(parent: Node, player_id: int = -1, hud: Hud = null) -> StreakBannerUI:
	var layer := CanvasLayer.new()
	layer.layer = config.announcement_layer
	layer.name = "KillAnnouncements"
	parent.add_child(layer)
	var feed_canvas := feed.attach(layer)
	global_banner.attach(layer)
	var banner := StreakBannerUI.new()
	layer.add_child(banner)
	banner.setup(config, player_id)
	views.append({"layer": layer, "banner": banner, "feed_canvas": feed_canvas, "hud": hud, "was_alive": true})
	if hud != null:
		hud.kill_banner = banner
	return banner


func receive(event: Dictionary) -> void:
	var sequence := int(event.get("event_id", 0))
	if sequence <= last_event_id:
		return
	last_event_id = sequence
	feed.receive(event)
	global_banner.receive(event)
	for view in views:
		view.banner.receive(event)
		if int(event.get("victim_id", -1)) == view.banner.player_id:
			view.was_alive = false


func preview(event: Dictionary) -> void:
	## 仅开发面板调用；不走真实事件去重、不发RPC、不改服务器S或连续数。
	feed.receive(event)
	global_banner.receive(event)
	for view in views:
		view.banner.receive(event)


func _process(delta: float) -> void:
	if config == null:
		return
	feed.tick(delta)
	global_banner.tick(delta)
	for view in views:
		var banner: StreakBannerUI = view.banner
		var hud: Hud = view.hud
		if hud != null and is_instance_valid(hud) and hud.me != null:
			var alive := hud.me.alive
			if not alive and bool(view.was_alive):
				banner.defeated() # 快照先于事件到达，也必须立即清空瓜子排。
			if alive and banner.has_death and banner.death_snapshot_target >= 0 and hud.me.deaths >= banner.death_snapshot_target:
				banner.respawned() # 可靠击败事件早于旧快照到达时，不闪掉提示；复活特效丢包时也能恢复。
			view.was_alive = alive
			view.feed_canvas.top_exclusion = hud.minimap_bottom + config.feed_row_height * hud.root.size.y / config.reference_height
			banner.bottom_exclusion = hud.touch_exclusion_top()
		banner.tick(delta)


func respawned(player_id: int) -> void:
	for view in views:
		if view.banner.player_id == player_id:
			view.banner.respawned()
			view.was_alive = true


func reset_display() -> void:
	feed.clear()
	global_banner.clear()
	for view in views:
		view.banner.defeated()
		view.banner.respawned()
