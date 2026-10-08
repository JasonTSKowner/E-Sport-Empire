extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const ShellV30 = preload("res://scripts/cinematic_shell_v30.gd")
const MatchVizV30 = preload("res://scripts/match_visualizer_v242.gd")
const TrainingVizV30 = preload("res://scripts/training_visualizer_v242.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V3.0 1/5: release metadata")
	_check(AppConfig.VERSION.begins_with("3.0."), "v3 app version")
	_check(AppConfig.VERSION_BADGE == "V3.0", "v3 version badge")
	_check(ChangelogData.CURRENT_VERSION == "3.0.0", "v3 changelog version")
	_check(str(ChangelogData.latest().get("title", "")).contains("VISUAL REBUILD"), "v3 changelog title")

	print("V3.0 2/5: dedicated shell")
	var shell := ShellV30.new()
	_check(shell != null, "v3 shell compiles")
	shell.free()

	print("V3.0 3/5: perspective match renderer")
	var match_viz := MatchVizV30.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":94,"control":92,"read":90,"finish":88},
		"actor_index":0, "support_index":1,
	}, "control", 1, 30)
	_check(match_viz.custom_minimum_size.y >= 456.0, "v3 match uses large broadcast stage")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "v3 3v3 keeps six cars")
	match_viz.free()

	print("V3.0 4/5: perspective training renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 94
	state._ensure_player_v23(player)
	var training := TrainingVizV30.new()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 408.0, "v3 training keeps large perspective stage")
	_check(not training.focus_mechanic.is_empty(), "v3 training keeps mechanic focus")
	training.free()

	print("V3.0 5/5: main scene")
	var scene := load("res://scenes/Main.tscn") as PackedScene
	_check(scene != null, "v3 Main scene loads")
	if scene != null:
		var main := scene.instantiate()
		_check(main != null, "v3 Main scene instantiates")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v3.0 visual rebuild smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V3.0 smoke test failed: %s" % failure)
		quit(1)
