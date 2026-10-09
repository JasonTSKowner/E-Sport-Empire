extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const ShellV25 = preload("res://scripts/cinematic_shell_v25.gd")
const MatchVizV25 = preload("res://scripts/match_visualizer_v25.gd")
const TrainingVizV25 = preload("res://scripts/training_visualizer_v25.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.5 1/4: metadata and shell")
	_check(AppConfig.VERSION.begins_with("2.5."), "v2.5 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.5.0", "v2.5 changelog")
	var shell := ShellV25.new()
	_check(shell != null, "v2.5 shell compiles")
	shell.free()

	print("V2.5 2/4: large readable match renderer")
	var match_viz := MatchVizV25.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":90,"control":88,"read":86,"finish":84},
		"actor_index":0, "support_index":1,
	}, "control", 1, 24)
	_check(match_viz.custom_minimum_size.y >= 550.0, "match stage is gameplay-first")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 still renders six cars")
	match_viz.free()

	print("V2.5 3/4: immersive training renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingVizV25.new()
	training._ready()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 540.0, "training stage dominates screen")
	_check(not training.focus_mechanic.is_empty(), "training keeps mechanic focus")
	training.free()

	print("V2.5 4/4: main scene")
	var scene := load("res://scenes/Main.tscn") as PackedScene
	_check(scene != null, "main scene loads")
	if scene != null:
		var main := scene.instantiate()
		_check(main != null, "main scene instantiates")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.5 visual gameplay smoke test: PASS")
		quit(0)
	for failure in failures:
		push_error("V2.5 smoke test failed: %s" % failure)
	quit(1)
