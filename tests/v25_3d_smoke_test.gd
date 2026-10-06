extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const Arena3D = preload("res://scripts/arena_3d_stage.gd")
const MatchV25 = preload("res://scripts/match_visualizer_v25.gd")
const TrainingV25 = preload("res://scripts/training_visualizer_v25.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.5 1/4: release metadata")
	_check(AppConfig.VERSION.begins_with("2.5."), "v2.5 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.5.0", "v2.5 changelog version")

	print("V2.5 2/4: real 3D arena")
	var arena := Arena3D.new()
	arena.configure_team_count(3)
	_check(arena.built, "3D arena builds")
	_check(arena.camera_3d != null, "3D camera exists")
	_check(arena.ball_node != null, "3D ball exists")
	_check(arena.our_cars.size() == 3 and arena.their_cars.size() == 3, "3v3 creates six 3D cars")
	arena.set_match_state(
		[Vector2(0.30,0.25),Vector2(0.35,0.50),Vector2(0.25,0.75)],
		[Vector2(0.70,0.75),Vector2(0.65,0.50),Vector2(0.75,0.25)],
		[Vector2(0.1,0),Vector2(0.05,0),Vector2(0.02,0)],
		[Vector2(-0.1,0),Vector2(-0.05,0),Vector2(-0.02,0)],
		[Vector2(0.55,0.25),Vector2(0.50,0.50),Vector2(0.40,0.75)],
		Vector2(0.52,0.45), 0.62, Vector2(0.82,0.50), 0.72,
		0, 1, "psycho_contact", 0.0
	)
	_check(arena.ball_node.position.y > 1.0, "airborne ball has real 3D height")
	arena.free()

	print("V2.5 3/4: 3D match wrapper")
	var match_viz := MatchV25.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral", "phase":"psycho_contact", "mechanic_label":"Psycho",
		"mechanic_family":"psycho", "mechanic_components":{"setup":92,"control":90,"read":88,"finish":86},
		"actor_index":0, "support_index":1,
	}, "control", 1, 25)
	_check(match_viz.custom_minimum_size.y >= 470.0, "match reserves large 3D gameplay surface")
	_check(match_viz.arena_3d != null and match_viz.arena_3d.built, "match owns real 3D stage")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "match telemetry still exposes six cars")
	_check(str(match_viz.snapshot_state().get("phase", "")) == "psycho_contact", "psycho reaches 3D match wrapper")
	match_viz.free()

	print("V2.5 4/4: 3D training wrapper")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingV25.new()
	training._ready()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 470.0, "training reserves large 3D gameplay surface")
	_check(training.arena_3d != null and training.arena_3d.built, "training owns real 3D stage")
	_check(not training.focus_mechanic.is_empty(), "training still selects mechanic focus")
	training.free()

	if failures.is_empty():
		print("E-Sport Empire v2.5 real 3D arena smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.5 smoke test failed: %s" % failure)
		quit(1)
