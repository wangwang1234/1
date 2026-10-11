extends Node
## OS-window focus integration probe; driven through X11 by tools/test_native_focus.py.
var main: Node
var out := ""
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	out = OS.get_environment("BUGFIX_REVIEW")
	InputBindings.load_saved({})
	InputBindings.apply_actions()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.7).timeout
	main.start_match({"mode": "slice", "seed": 7})
	await main.match_started
	get_viewport().disable_3d = true
func _process(delta: float) -> void:
	elapsed += delta
	if main == null or main.match_view == null:
		return
	var mv: MatchView = main.match_view
	var file := FileAccess.open(out.path_join("native_state.json"), FileAccess.WRITE)
	var h: SimHamster = mv.local
	file.store_string(JSON.stringify({"ready": true, "paused": mv.paused, "tree_paused": get_tree().paused, "focus_pause": main._focus_paused, "menu": main.pause_menu != null, "mx": h.inp.mx, "my": h.inp.my, "fire": h.inp.fire, "x": h.x, "y": h.y}))
	if elapsed > 90:
		get_tree().quit()
