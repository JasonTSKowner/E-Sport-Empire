extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const StageV30 = preload("res://scripts/commercial_stage_v30.gd")
const MatchV30 = preload("res://scripts/match_visualizer_v30.gd")
const TrainingV30 = preload("res://scripts/training_visualizer_v30.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")
const MainScene = preload("res://scenes/Main.tscn")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V3.0 1/5: release metadata and shell")
	_check(AppConfig.VERSION.begins_with("3.0."), "v3 app metadata")
	_check(ChangelogData.CURRENT_VERSION == "3.0.0", "v3 changelog metadata")
	var main := MainScene.instantiate()
	_check(str(main.get_script().resource_path).ends_with("commercial_shell_v30.gd"), "main scene loads commercial shell")
	main.free()

	print("V3.0 2/5: commercial stage")
	var stage := StageV30.new().configure(Color("74DFF7"), "home")
	_check(stage.custom_minimum_size.y >= 360.0, "commercial home hero has large stage")
	stage.free()

	print("V3.0 3/5: commercial match broadcast")
	var match_viz := MatchV30.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":92,"control":90,"read":88,"finish":86},
		"actor_index":0, "support_index":1,
	}, "control", 1, 24)
	_check(match_viz.custom_minimum_size.y >= 520.0, "match broadcast gets large gameplay stage")
	_check(int(match_viz.snapshot_state().get("cars",0)) == 6, "3v3 commercial renderer keeps six cars")
	match_viz.free()

	print("V3.0 4/5: performance lab")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics","rotation","shooting","defense","game_sense","boost_control","consistency","mentality"]:
		player[key] = 94
	state._ensure_player_v23(player)
	var training := TrainingV30.new()
	training.configure(player,state.training_readiness(player),Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 472.0, "training gets large performance lab stage")
	_check(not training.focus_mechanic.is_empty(), "training preserves mechanic focus")
	training.free()

	print("V3.0 5/5: legacy gameplay remains")
	_check(state.unlocked_mechanics_v23(player).size() >= 50, "expanded mechanic tree remains available")
	_check(state.training_cost(player,"mechanics_lab") == 0, "normal training remains free")

	if failures.is_empty():
		print("E-Sport Empire v3.0 commercial rebuild smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V3.0 smoke test failed: %s" % failure)
		quit(1)
