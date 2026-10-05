extends SceneTree

const StateV23 = preload("res://scripts/game_state_v23.gd")
const MechanicsV23 = preload("res://scripts/mechanics_catalog_v23.gd")
const SequencesV23 = preload("res://scripts/mechanical_sequences_v23.gd")
const MatchVizV23 = preload("res://scripts/match_visualizer_v23.gd")
const TrainingVizV23 = preload("res://scripts/training_visualizer_v23.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const AppConfig = preload("res://scripts/app_config.gd")

var failures: Array[String] = []


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("V2.3 1/6: large mechanic tree")
	_check(MechanicsV23.MECHANICS.size() >= 70, "mechanic catalog contains at least 70 mechanics")
	_check(MechanicsV23.category_count("reset") >= 10, "reset tree is deep")
	_check(MechanicsV23.category_count("team") >= 5, "team mechanic branch exists")
	_check(not MechanicsV23.definition("psycho_redirect").is_empty(), "psycho redirect exists in tree")

	print("V2.3 2/6: unlock prerequisites")
	var elite := {
		"mechanics": 99, "rotation": 95, "shooting": 96, "defense": 94,
		"game_sense": 96, "boost_control": 96, "consistency": 97, "mentality": 94,
	}
	var elite_unlocks := MechanicsV23.unlocked(elite)
	_check(elite_unlocks.size() >= 60, "elite player unlocks most mechanics")
	var rookie := {
		"mechanics": 55, "rotation": 52, "shooting": 52, "defense": 52,
		"game_sense": 52, "boost_control": 52, "consistency": 52, "mentality": 52,
	}
	_check(MechanicsV23.unlocked(rookie).size() < elite_unlocks.size(), "rookie has smaller mechanic arsenal")

	print("V2.3 3/6: component mastery training")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	for key in ["mechanics", "rotation", "shooting", "defense", "game_sense", "boost_control", "consistency", "mentality"]:
		player[key] = 95
	state._ensure_player_v23(player)
	var before := state.mechanic_components(player, "flip_reset")
	var result := state.train_player("captain", "mechanics_lab")
	var after := state.mechanic_components(player, "flip_reset")
	_check(bool(result.get("ok", false)), "v2.3 training still runs")
	_check(int(after.get("setup", 0)) >= int(before.get("setup", 0)), "training improves setup mastery")
	_check(int(after.get("control", 0)) >= int(before.get("control", 0)), "training improves control mastery")
	_check(state.mechanic_mastery(player, "flip_reset") > 0, "component mastery produces total mastery")

	print("V2.3 4/6: sequence and failure states")
	var quad := SequencesV23.sequence_for(MechanicsV23.definition("quad_reset"))
	_check(quad.size() >= 6, "quad reset has multi-stage sequence")
	var psycho_combo := SequencesV23.combo("psycho_redirect")
	_check(psycho_combo.size() >= 6, "psycho redirect combo remains multi-stage")
	var failure := SequencesV23.failure_for(MechanicsV23.definition("flip_reset"), "reset_contact")
	_check(str(failure.get("phase", "")) == "mechanic_fail", "failure state emitted")

	print("V2.3 5/6: expanded renderer")
	var visualizer := MatchVizV23.new()
	visualizer.configure({"format":"3v3"})
	visualizer.play_turn({
		"type":"neutral", "phase":"reset_3", "mechanic_label":"Triple Reset",
		"mechanic_family":"multi_reset", "mechanic_components":{"setup":90,"control":88,"read":84,"finish":86},
		"actor_index":0, "support_index":1,
	}, "control", 1, 20)
	var snapshot := visualizer.snapshot_state()
	_check(str(snapshot.get("phase", "")) == "reset_3", "new reset phase reaches renderer")
	_check(int(snapshot.get("cars", 0)) == 6, "3v3 renderer remains intact")
	visualizer.free()

	print("V2.3 6/6: training renderer and release metadata")
	var drill := TrainingVizV23.new()
	drill.configure(player, state.training_readiness(player), Color("7FE7FF"))
	_check(drill.custom_minimum_size.y >= 300.0, "expanded mechanic drill keeps gameplay height")
	_check(not drill.focus_mechanic.is_empty(), "training chooses expanded mechanic focus")
	_check(ChangelogData.CURRENT_VERSION == "2.3.0", "v2.3 changelog version")
	_check(AppConfig.VERSION.begins_with("2.3."), "v2.3 app version")
	drill.free()

	if failures.is_empty():
		print("E-Sport Empire v2.3 mechanical expansion smoke test: PASS")
		quit(0)
	else:
		for failure_label in failures:
			push_error("V2.3 smoke test failed: %s" % failure_label)
		quit(1)
