extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const MatchVizV26 = preload("res://scripts/match_visualizer_v26.gd")
const TrainingVizV26 = preload("res://scripts/training_visualizer_v26.gd")
const WorldStageV26 = preload("res://scripts/world_stage_v26.gd")
const PlayerV26 = preload("res://scripts/player_presentation_v26.gd")
const RadarV26 = preload("res://scripts/stat_radar_v26.gd")
const ShellV26 = preload("res://scripts/cinematic_shell_v26.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.6 1/6: release metadata")
	_check(AppConfig.VERSION.begins_with("2.6."),"v2.6 app version")
	_check(ChangelogData.CURRENT_VERSION=="2.6.0","v2.6 changelog version")

	print("V2.6 2/6: world and player presentation")
	var stage:=WorldStageV26.new().configure(Color("74DFF7"),"home")
	_check(stage.custom_minimum_size.y>=404.0,"home world stage height")
	stage.free()
	var person:=PlayerV26.new().configure("KESHI",Color("74DFF7"),92,98,"profile")
	_check(person.player_name=="KESHI" and person.overall==92,"player presentation config")
	person.free()
	var radar:=RadarV26.new().configure({"MECH":92,"SHOT":88,"DEF":84,"SENSE":90},Color("74DFF7"))
	_check(int(radar.values.get("MECH",0))==92,"performance radar config")
	radar.free()

	print("V2.6 3/6: match broadcast")
	var match_viz:=MatchVizV26.new()
	match_viz._ready()
	match_viz.configure({"format":"3v3"})
	match_viz.play_turn({
		"type":"neutral","phase":"psycho_contact","mechanic_label":"Psycho",
		"mechanic_family":"psycho","mechanic_components":{"setup":94,"control":92,"read":90,"finish":89},
		"actor_index":0,"support_index":1,
	},"control",1,34)
	_check(match_viz.custom_minimum_size.y>=548.0,"v2.6 match stage height")
	_check(int(match_viz.snapshot_state().get("cars",0))==6,"v2.6 3v3 keeps six cars")
	_check(match_viz._depth_scale(Vector2(0.0,0.5))>match_viz._depth_scale(Vector2(1.0,0.5)),"v2.6 match perspective")
	match_viz.free()

	print("V2.6 4/6: training session")
	var state:=StateV23.new()
	state.reset_game()
	var player: Dictionary=state.data["roster"][0]
	for key in ["mechanics","rotation","shooting","defense","game_sense","boost_control","consistency","mentality"]:
		player[key]=94
	state._ensure_player_v23(player)
	var training:=TrainingVizV26.new()
	training.configure(player,state.training_readiness(player),Color("74DFF7"))
	_check(training.custom_minimum_size.y>=512.0,"v2.6 training stage height")
	_check(not training.focus_mechanic.is_empty(),"v2.6 training mechanic focus")
	_check(training._v241_depth_scale(Vector2(0.0,0.5))>training._v241_depth_scale(Vector2(1.0,0.5)),"v2.6 training perspective")
	_check(training._sequence_labels_v26().size()==4,"training sequence strip has four readable phases")
	training.free()

	print("V2.6 5/6: shell compile")
	var shell:=ShellV26.new()
	_check(shell!=null,"v2.6 shell compiles")
	shell.free()

	print("V2.6 6/6: main scene")
	var packed:=load("res://scenes/Main.tscn") as PackedScene
	_check(packed!=null,"Main scene loads")
	if packed!=null:
		var main:=packed.instantiate()
		_check(main!=null,"Main scene instantiates with v2.6 shell")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.6 extreme visual smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.6 smoke test failed: %s"%failure)
		quit(1)
