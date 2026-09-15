extends SceneTree

const EmpireStateRef = preload("res://scripts/game_state.gd")
const GameDataRef = preload("res://scripts/game_data.gd")
const MainScene = preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var state: EmpireState = EmpireStateRef.new()
	state.reset_game()
	_check(state.data.get("version") == GameDataRef.VERSION, "save version")
	_check(state.data.get("roster", []).size() == 9, "starter roster size")
	_check(state.data.get("market", []).size() == 6, "market generation")
	for mode in GameDataRef.MODES:
		_check(state.roster_for(mode).size() == 3, "%s roster" % mode)
		_check(state.team_overall(mode) > 50, "%s overall" % mode)
		var match_result: Dictionary = state.create_match(mode)
		_check(match_result.get("events", []).size() == 9, "%s match events" % mode)
		_check(str(match_result.get("score", "")).contains("-"), "%s score" % mode)
	var first_player: Dictionary = state.data["roster"][0]
	var training: Dictionary = state.train_player(str(first_player["id"]))
	_check(training.get("ok", false), "training action")
	var sponsor: Dictionary = state.collect_sponsor()
	_check(sponsor.get("ok", false), "sponsor action")
	state.data["cash"] = 1000000
	var upgrade: Dictionary = state.buy_facility("hq")
	_check(upgrade.get("ok", false), "facility upgrade")
	var prospect: Dictionary = state.data["market"][0]
	var signing: Dictionary = state.sign_player(str(prospect["id"]))
	_check(signing.get("ok", false), "player signing")

	var main := MainScene.instantiate()
	root.add_child(main)
	for frame in range(3):
		await process_frame
	for page in ["home", "team", "play", "market", "empire"]:
		main._show_page(page, false)
		await process_frame
		_check(main.page_content.get_child_count() > 3, "%s page content" % page)
	main._start_match("Rocket League")
	main.match_timer.stop()
	for event_index in range(10):
		main._advance_match()
	_check(main.match_result_box.visible, "match result panel")
	_check(main.match_continue_button.visible, "match continue button")
	main.queue_free()
	if failures.is_empty():
		print("E-Sport Empire smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("Smoke test failed: %s" % failure)
		quit(1)
