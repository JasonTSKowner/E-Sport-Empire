extends SceneTree

const Arena3D = preload("res://scripts/arena_3d_view_v25.gd")
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
	print("V2.5 1/3: 3D arena core")
	var arena := Arena3D.new().configure(Color("37D6F6"), Color("FF6B7A"), false)
	_check(arena.viewport_3d != null, "SubViewport created")
	_check(arena.camera != null, "3D camera created")
	_check(arena.our_cars.size() == 3, "three friendly cars created")
	_check(arena.their_cars.size() == 3, "three opponent cars created")
	_check(arena.ball_root != null, "3D ball created")
	arena.sync_match(
		[Vector2(0.25,0.40),Vector2(0.18,0.62),Vector2(0.08,0.50)],
		[Vector2(0.70,0.42),Vector2(0.78,0.58),Vector2(0.90,0.50)],
		[Vector2(0.12,0.02),Vector2(0.08,-0.01),Vector2(0.04,0.0)],
		[Vector2(-0.10,0.01),Vector2(-0.08,-0.02),Vector2(-0.03,0.0)],
		Vector2(0.52,0.50), 0.55, Vector2(0.82,0.46), 0.25,
		[Vector2(0.56,0.48),Vector2(0.43,0.58),Vector2(0.26,0.50)],
		0, 1
	)
	_check(arena.trajectory_mesh.get_surface_count() > 0, "ball trajectory generated")
	_check(arena.rotation_mesh.get_surface_count() > 0, "rotation paths generated")
	arena.free()

	print("V2.5 2/3: match renderer")
	var match_viz := MatchV25.new()
	match_viz.configure({"format":"3v3"})
	match_viz._ready()
	_check(match_viz.custom_minimum_size.y >= 492.0, "match visualizer reserves large 3D stage")
	_check(match_viz.arena_3d != null, "match visualizer owns 3D arena")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 logic remains six cars")
	match_viz.free()

	print("V2.5 3/3: training renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingV25.new()
	training.configure(player, state.training_readiness(player), Color("37D6F6"))
	training._ready()
	_check(training.custom_minimum_size.y >= 460.0, "training reserves large 3D stage")
	_check(training.arena_3d != null, "training visualizer owns 3D arena")
	_check(not training.focus_mechanic.is_empty(), "training keeps mechanic focus")
	training.free()

	if failures.is_empty():
		print("E-Sport Empire v2.5 Arena 3D smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.5 Arena 3D smoke test failed: %s" % failure)
		quit(1)
