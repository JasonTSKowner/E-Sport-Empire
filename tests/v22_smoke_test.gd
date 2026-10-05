extends SceneTree

const StateV22 = preload("res://scripts/game_state_v22.gd")
const MatchVizV22 = preload("res://scripts/match_visualizer_v22.gd")
const TrainingVizV22 = preload("res://scripts/training_visualizer_v22.gd")
const SetupData = preload("res://scripts/setup_data.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")

var failures: Array[String] = []


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("V2.2 1/5: free training")
	var state := StateV22.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	var cash_before := int(state.data.get("cash", 0))
	_check(state.training_cost(player, "mechanics_lab") == 0, "normal training is free")
	var training := state.train_player("captain", "mechanics_lab")
	_check(bool(training.get("ok", false)), "free mechanics training runs")
	_check(int(state.data.get("cash", 0)) == cash_before, "training does not spend money")
	_check(training.has("mastery_gains"), "training returns mechanic mastery progress")

	print("V2.2 2/5: setup and internet")
	state.data["cash"] = 5000
	var old_ping := state.connection_ping()
	var upgrade := state.buy_setup_upgrade("internet")
	_check(bool(upgrade.get("ok", false)), "internet upgrade purchase")
	_check(state.setup_level("internet") == 1, "internet setup level increased")
	_check(state.connection_ping() < old_ping, "internet upgrade improves ping")
	_check(SetupData.CATEGORIES.size() == 5, "five setup categories")

	print("V2.2 3/5: recovery backup")
	state.data["cash"] = 777
	var backup := state.create_backup_code()
	_check(bool(backup.get("ok", false)), "backup code created")
	var code := str(backup.get("code", ""))
	_check(code.begins_with("EE22-"), "backup code prefix")
	state.data["cash"] = 1
	var restore := state.restore_backup_code(code)
	_check(bool(restore.get("ok", false)), "backup code restores")
	_check(int(state.data.get("cash", 0)) == 777, "backup restores save values")

	print("V2.2 4/5: readable mechanic renderer")
	var visualizer := MatchVizV22.new()
	visualizer.configure({"format": "3v3"})
	visualizer.play_turn({
		"type": "neutral",
		"phase": "psycho_contact",
		"mechanic_label": "Psycho",
		"actor_index": 0,
		"support_index": 1,
	}, "control", 1, 20)
	var visual_state := visualizer.snapshot_state()
	_check(str(visual_state.get("phase", "")) == "psycho_contact", "psycho phase reaches visualizer")
	_check(int(visual_state.get("cars", 0)) == 6, "3v3 rotation renderer has six cars")
	visualizer.free()

	print("V2.2 5/5: drill renderer and changelog")
	player = state.data["roster"][0]
	player["mechanics"] = 92
	player["defense"] = 86
	player["shooting"] = 82
	player["boost_control"] = 80
	player["consistency"] = 82
	var drill := TrainingVizV22.new()
	drill.configure(player, state.training_readiness(player), Color("7FE7FF"))
	_check(drill.custom_minimum_size.y >= 300.0, "training renderer gives gameplay enough height")
	_check(ChangelogData.CURRENT_VERSION == "2.2.0", "v2.2 changelog version")
	drill.free()

	if failures.is_empty():
		print("E-Sport Empire v2.2 gameplay life smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.2 smoke test failed: %s" % failure)
		quit(1)
