extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const MatchVizV26 = preload("res://scripts/match_visualizer_v26.gd")
const TrainingVizV26 = preload("res://scripts/training_visualizer_v26.gd")
const ShellV26 = preload("res://scripts/cinematic_shell_v26.gd")
const StageV26 = preload("res://scripts/visual_stage_v26.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.6 1/6: release metadata")
	_check(AppConfig.VERSION.begins_with("2.6."), "v2.6 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.6.0", "v2.6 changelog version")

	print("V2.6 2/6: home hero stage")
	var stage := StageV26.new().configure(Color("74DFF7"), "home")
	_check(stage.custom_minimum_size.y >= 500.0, "home stage fills more of the mobile screen")
	stage.free()

	print("V2.6 3/6: match presentation")
	var match_viz := MatchVizV26.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":94,"control":92,"read":90,"finish":88},
		"actor_index":0, "support_index":1,
	}, "control", 1, 34)
	_check(match_viz.custom_minimum_size.y >= 548.0, "match stage is larger than v2.5")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 keeps six cars")
	_check(match_viz._depth_scale(Vector2(0.0,0.5)) > match_viz._depth_scale(Vector2(1.0,0.5)) * 2.5, "v2.6 perspective has stronger depth")
	match_viz.free()

	print("V2.6 4/6: training presentation")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 95
	state._ensure_player_v23(player)
	var training := TrainingVizV26.new()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 520.0, "training stage is larger than v2.5")
	_check(not training.focus_mechanic.is_empty(), "training keeps mechanic focus")
	_check(training._v241_depth_scale(Vector2(0.0,0.5)) > training._v241_depth_scale(Vector2(1.0,0.5)) * 2.4, "training perspective has stronger depth")
	training.free()

	print("V2.6 5/6: shell compile")
	var shell := ShellV26.new()
	_check(shell != null, "v2.6 shell compiles")
	shell.free()

	print("V2.6 6/6: main scene")
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	_check(main_scene != null, "Main scene loads")
	if main_scene != null:
		var main := main_scene.instantiate()
		_check(main != null, "Main scene instantiates with v2.6 shell")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.6 presentation overhaul smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.6 smoke test failed: %s" % failure)
		quit(1)
