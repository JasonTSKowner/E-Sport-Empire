extends SceneTree

const EmpireStateRef = preload("res://scripts/game_state.gd")
const GameDataRef = preload("res://scripts/game_data.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")
const RankEmblemRef = preload("res://scripts/rank_emblem.gd")
const MainScene = preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var state: EmpireStateRef = EmpireStateRef.new()
	state.reset_game()
	_check(state.data.get("version") == GameDataRef.VERSION, "save version")
	_check(state.data.get("roster", []).size() == 1, "from-zero captain roster")
	_check(state.data.get("market", []).size() == 6, "market generation")
	_check(state.selected_rl_playlist() == "1v1", "default playlist")
	for playlist in RankedDataRef.PLAYLISTS:
		var record := state.playlist_record(playlist)
		_check(int(record.get("mmr", 0)) == 600, "%s starting mmr" % playlist)
		_check(int(record.get("placements", -1)) == 0, "%s fresh placements" % playlist)
		_check(record.get("mmr_history", []).size() == 1, "%s mmr history" % playlist)

	_check(str(RankedDataRef.rank_for_mmr(310, "1v1").get("tier_name", "")) == "Silver I", "1v1 silver anchor")
	_check(str(RankedDataRef.rank_for_mmr(550, "2v2").get("tier_name", "")) == "Gold I", "2v2 gold anchor")
	_check(str(RankedDataRef.rank_for_mmr(870, "3v3").get("tier_name", "")) == "Diamond I", "3v3 diamond anchor")
	_check(str(RankedDataRef.rank_for_mmr(1860, "3v3").get("family", "")) == "Supersonic Legend", "3v3 ssl anchor")
	_check(RankedDataRef.tier_rows("2v2").size() == 22, "complete rank table")
	_check(RankedDataRef.top_ladder("1v1").size() == 12, "top twelve ladder")
	_check(RankedDataRef.around_player(600, "1v1").size() == 7, "around-you ladder")

	var one_before := int(state.playlist_record("1v1")["mmr"])
	var first_match: Dictionary = state.create_match("Rocket League")
	_check(bool(first_match.get("ok", false)), "1v1 match creation")
	_check(first_match.get("events", []).size() == 9, "match event count")
	_check(abs(int(first_match.get("mmr_delta", 0))) >= 20, "placement delta lower bound")
	_check(abs(int(first_match.get("mmr_delta", 0))) <= 30, "placement delta upper bound")
	_check(int(state.playlist_record("1v1")["mmr"]) != one_before, "1v1 mmr changed")
	_check(int(state.playlist_record("2v2")["placements"]) == 0, "playlist independence")

	var normal_record := state.playlist_record("1v1")
	normal_record["placements"] = 10
	var normal_win := state._mmr_delta_for("Rocket League", normal_record, 900, 960, true)
	var normal_loss := state._mmr_delta_for("Rocket League", normal_record, 900, 840, false)
	_check(normal_win >= 9 and normal_win <= 11, "normal win delta")
	_check(normal_loss <= -9 and normal_loss >= -11, "normal loss delta")

	_check(not state.can_queue_playlist("2v2"), "2v2 roster lock")
	var teammate: Dictionary = state.data["roster"][0].duplicate(true)
	teammate["id"] = "test_teammate"
	teammate["name"] = "NOVA"
	state.data["roster"].append(teammate)
	_check(state.can_queue_playlist("2v2"), "2v2 roster unlock")
	state.set_selected_rl_playlist("2v2")
	var two_match: Dictionary = state.create_match("Rocket League")
	_check(bool(two_match.get("ok", false)), "2v2 match creation")
	_check(str(two_match.get("format", "")) == "2v2", "2v2 format")

	var reveal_state: EmpireStateRef = EmpireStateRef.new()
	reveal_state.reset_game()
	var reveal_record := reveal_state.playlist_record("1v1")
	reveal_record["placements"] = 9
	reveal_record["played"] = 9
	var reveal_match: Dictionary = reveal_state.create_match("Rocket League")
	_check(bool(reveal_match.get("rank_revealed", false)), "placement ten rank reveal")
	_check(int(reveal_match.get("placements_after", 0)) == 10, "placement ten completed")

	var migrated: EmpireStateRef = EmpireStateRef.new()
	migrated.data = reveal_state.data.duplicate(true)
	migrated.data["cash"] = 47
	migrated.data["rl_playlists"]["1v1"].erase("peak_mmr")
	migrated.data["rl_playlists"]["1v1"].erase("mmr_history")
	migrated._migrate_save(4)
	_check(int(migrated.data.get("cash", 0)) == 47, "migration preserves economy")
	_check(migrated.data["rl_playlists"]["1v1"].has("peak_mmr"), "migration adds peak")
	_check(migrated.data["rl_playlists"]["1v1"].has("mmr_history"), "migration adds history")

	var emblem := RankEmblemRef.new()
	emblem.configure(RankedDataRef.rank_for_mmr(1435, "2v2"))
	_check(emblem.family == "Grand Champion", "rank emblem family")
	emblem.free()

	var main := MainScene.instantiate()
	root.add_child(main)
	for frame in range(3):
		await process_frame
	main.game.reset_game()
	main.game.set_selected_mode("Rocket League")
	main.game.set_selected_rl_playlist("1v1")
	main.ranked_view = "overview"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() > 10, "ranked overview content")
	_check(main.page_scroll.scroll_deadzone <= 8, "mobile scroll deadzone")
	_check(main.page_scroll.scroll_vertical_custom_step >= 64.0, "mobile scroll step")

	main.ranked_view = "ladder"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() > 20, "ladder content")
	main.ranked_view = "ranks"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 27, "all-ranks content")

	main.ranked_view = "overview"
	main._show_page("play", false)
	main._start_match("Rocket League")
	await process_frame
	if main.match_timer != null:
		main.match_timer.stop()
	for event_index in range(12):
		main._advance_match()
	_check(main.match_finished, "match finishes")
	_check(main.match_result_box.visible, "match result panel")
	_check(main.match_continue_button.visible, "match continue button")
	await main._close_match()
	_check(main.match_overlay == null, "match overlay closes")
	_check(main.current_page == "play", "returns to ranked")
	main.queue_free()

	if failures.is_empty():
		print("E-Sport Empire v0.4.5 smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("Smoke test failed: %s" % failure)
		quit(1)
