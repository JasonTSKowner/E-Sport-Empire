extends SceneTree

const Arena3D = preload("res://scripts/arena_3d_view_v252.gd")
const MatchV25 = preload("res://scripts/match_visualizer_v25.gd")
const TrainingV25 = preload("res://scripts/training_visualizer_v25.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")
const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")

var failures: Array[String] = []


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("V2.5 1/4: release metadata")
	_check(AppConfig.VERSION.begins_with("2.5."), "v2.5 app version")
	_check(AppConfig.VERSION_BADGE == "V2.5", "v2.5 badge")
	_check(ChangelogData.CURRENT_VERSION == "2.5.0", "v2.5 changelog version")

	print("V2.5 2/4: 3D arena core and readability")
	var arena := Arena3D.new()
	root.add_child(arena)
	arena.configure(Color("37D6F6"), Color("FF6B7A"), false)
	await process_frame
	_check(arena.viewport_3d != null, "SubViewport created")
	_check(arena.camera != null, "3D camera created")
	_check(arena.our_cars.size() == 3, "three friendly cars created")
	_check(arena.their_cars.size() == 3, "three opponent cars created")
	_check(arena.ball_root != null, "3D ball created")
	_check(arena.ball_path_markers.size() == 12, "twelve visible ball prediction markers")
	_check(arena.rotation_markers.size() == 18, "rotation marker pool created")
	_check(arena.role_labels.size() == 3, "1st 2nd 3rd role labels created")
	arena.sync_match(
		[Vector2(0.25,0.40),Vector2(0.18,0.62),Vector2(0.08,0.50)],
		[Vector2(0.70,0.42),Vector2(0.78,0.58),Vector2(0.90,0.50)],
		[Vector2(0.12,0.02),Vector2(0.08,-0.01),Vector2(0.04,0.0)],
		[Vector2(-0.10,0.01),Vector2(-0.08,-0.02),Vector2(-0.03,0.0)],
		Vector2(0.52,0.50), 0.65, Vector2(0.82,0.46), 0.35,
		[Vector2(0.56,0.48),Vector2(0.43,0.58),Vector2(0.26,0.50)],
		0, 1, "reset_2", "multi_reset"
	)
	_check(arena.trajectory_mesh.get_surface_count() > 0, "ball trajectory generated")
	_check(arena.rotation_mesh.get_surface_count() > 0, "rotation paths generated")
	_check(arena.our_cars[0].position.y > 0.55, "reset phase lifts active car into the air")
	_check(arena.ball_path_markers[0].visible, "ball prediction markers visible during flight")
	_check(arena.role_labels[0].visible, "active role label visible")
	arena.queue_free()
	await process_frame

	print("V2.5 3/4: match renderer")
	var match_viz := MatchV25.new()
	match_viz.configure({"format":"3v3"})
	root.add_child(match_viz)
	await process_frame
	_check(match_viz.custom_minimum_size.y >= 492.0, "match visualizer reserves large 3D stage")
	_check(match_viz.arena_3d != null, "match visualizer owns 3D arena")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 logic remains six cars")
	match_viz.queue_free()
	await process_frame

	print("V2.5 4/4: training renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingV25.new()
	training.configure(player, state.training_readiness(player), Color("37D6F6"))
	root.add_child(training)
	await process_frame
	_check(training.custom_minimum_size.y >= 460.0, "training reserves large 3D stage")
	_check(training.arena_3d != null, "training visualizer owns 3D arena")
	_check(not training.focus_mechanic.is_empty(), "training keeps mechanic focus")
	training.queue_free()
	await process_frame

	if failures.is_empty():
		print("E-Sport Empire v2.5 Arena 3D smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.5 Arena 3D smoke test failed: %s" % failure)
		quit(1)
