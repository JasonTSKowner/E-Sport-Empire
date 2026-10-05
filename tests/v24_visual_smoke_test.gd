extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const MatchVizV24 = preload("res://scripts/match_visualizer_v24.gd")
const TrainingVizV24 = preload("res://scripts/training_visualizer_v24.gd")
const VisualStageV24 = preload("res://scripts/visual_stage_v24.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.4 1/4: release metadata")
	_check(AppConfig.VERSION.begins_with("2.4."), "v2.4 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.4.0", "v2.4 changelog version")

	print("V2.4 2/4: visual stage")
	var stage := VisualStageV24.new().configure(Color("74DFF7"), "home")
	_check(stage.custom_minimum_size.y >= 260.0, "home hero has cinematic height")
	stage.free()

	print("V2.4 3/4: match renderer")
	var match_viz := MatchVizV24.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":90,"control":88,"read":86,"finish":84},
		"actor_index":0, "support_index":1,
	}, "control", 1, 24)
	_check(match_viz.custom_minimum_size.y >= 430.0, "match gameplay gets large visual stage")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 keeps six cars")
	match_viz.free()

	print("V2.4 4/4: training renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingVizV24.new()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 388.0, "training gameplay gets large visual stage")
	_check(not training.focus_mechanic.is_empty(), "training keeps mechanic focus")
	training.free()

	if failures.is_empty():
		print("E-Sport Empire v2.4 visual rebuild smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.4 smoke test failed: %s" % failure)
		quit(1)
