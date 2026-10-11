extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const ShellV26 = preload("res://scripts/cinematic_shell_v26.gd")
const ProStageV26 = preload("res://scripts/professional_stage_v26.gd")
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
	print("V2.6 1/5: release metadata")
	_check(AppConfig.VERSION.begins_with("2.6."), "v2.6 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.6.0", "v2.6 changelog version")

	print("V2.6 2/5: professional shell")
	var shell := ShellV26.new()
	_check(shell != null, "professional shell compiles")
	shell.free()
	var stage := ProStageV26.new().configure(Color("74DFF7"), "hero")
	stage.custom_minimum_size.y = 650
	_check(stage.custom_minimum_size.y >= 650.0, "professional hero owns the screen")
	stage.free()

	print("V2.6 3/5: gameplay compatibility")
	var match_viz := MatchVizV25.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	_check(match_viz.custom_minimum_size.y >= 550.0, "v2.5 match renderer preserved")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 renderer remains six-car")
	match_viz.free()

	print("V2.6 4/5: training compatibility")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingVizV25.new()
	training._ready()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 540.0, "gameplay-first training preserved")
	training.free()

	print("V2.6 5/5: main scene")
	var scene := load("res://scenes/Main.tscn") as PackedScene
	_check(scene != null, "main scene loads")
	if scene != null:
		var main := scene.instantiate()
		_check(main != null, "main scene instantiates with v2.6 shell")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.6 professional overhaul smoke test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("V2.6 smoke test failed: %s" % failure)
	quit(1)
