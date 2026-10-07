extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const MatchVizV25 = preload("res://scripts/match_visualizer_v25.gd")
const TrainingVizV25 = preload("res://scripts/training_visualizer_v25.gd")
const VisualStageV25 = preload("res://scripts/visual_stage_v25.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.5 1/5: release metadata")
	_check(AppConfig.VERSION.begins_with("2.5."), "v2.5 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.5.0", "v2.5 changelog version")

	print("V2.5 2/5: visual assets")
	_check(ResourceLoader.exists("res://assets/game/car_team.svg"), "team car vector exists")
	_check(ResourceLoader.exists("res://assets/game/car_opponent.svg"), "opponent car vector exists")
	_check(ResourceLoader.exists("res://assets/game/ball.svg"), "ball vector exists")
	var team_car := load("res://assets/game/car_team.svg")
	var opponent_car := load("res://assets/game/car_opponent.svg")
	var ball := load("res://assets/game/ball.svg")
	_check(team_car is Texture2D, "team car imports as texture")
	_check(opponent_car is Texture2D, "opponent car imports as texture")
	_check(ball is Texture2D, "ball imports as texture")

	print("V2.5 3/5: match broadcast renderer")
	var match_viz := MatchVizV25.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral",
		"phase":"psycho_contact",
		"mechanic_label":"Psycho",
		"mechanic_family":"psycho",
		"mechanic_components":{"setup":91,"control":89,"read":86,"finish":84},
		"actor_index":0,
		"support_index":1,
	}, "control", 1, 24)
	_check(match_viz.custom_minimum_size.y >= 448.0, "match gets large readable visual stage")
	_check(int(match_viz.snapshot_state().get("cars", 0)) == 6, "3v3 keeps six cars")
	_check(str(match_viz.snapshot_state().get("phase", "")) == "psycho_contact", "psycho phase reaches v2.5 renderer")
	match_viz.free()

	print("V2.5 4/5: training broadcast renderer")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 92
	state._ensure_player_v23(player)
	var training := TrainingVizV25.new()
	training._ready()
	training.configure(player, state.training_readiness(player), Color("74DFF7"))
	_check(training.custom_minimum_size.y >= 410.0, "training gets large readable visual stage")
	_check(not training.focus_mechanic.is_empty(), "training keeps expanded mechanic focus")
	training.free()

	print("V2.5 5/5: hero stage")
	var stage := VisualStageV25.new().configure(Color("74DFF7"), "home")
	_check(stage.custom_minimum_size.y >= 260.0, "hero stage remains cinematic")
	stage.free()

	if failures.is_empty():
		print("E-Sport Empire v2.5 clean visual foundation smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.5 smoke test failed: %s" % failure)
		quit(1)
