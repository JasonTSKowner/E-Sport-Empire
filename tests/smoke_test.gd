extends SceneTree

const EmpireStateRef = preload("res://scripts/game_state.gd")
const GameDataRef = preload("res://scripts/game_data.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")
const RankEmblemRef = preload("res://scripts/rank_emblem.gd")
const TitleDataRef = preload("res://scripts/title_data.gd")
const DevelopmentDataRef = preload("res://scripts/development_data.gd")
const CoachingDataRef = preload("res://scripts/coaching_data.gd")
const MainScene = preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	print("SMOKE 1/6: ranked data")
	var state: EmpireStateRef = EmpireStateRef.new()
	state.reset_game()
	_check(state.data.get("version") == GameDataRef.VERSION, "save version")
	_check(state.data.get("roster", []).size() == 1, "from-zero captain roster")
	_check(state.data.get("market", []).size() == 6, "market generation")
	_check(state.data.get("coaching_market", []).size() == CoachingDataRef.OFFER_COUNT, "coaching market generation")
	_check(not state.data.has("energy"), "global energy removed")
	_check(state.selected_rl_playlist() == "1v1", "default playlist")
	for playlist in RankedDataRef.PLAYLISTS:
		var record := state.playlist_record(playlist)
		_check(int(record.get("mmr", 0)) == 100, "%s starting mmr" % playlist)
		_check(int(record.get("placements", -1)) == 0, "%s fresh placements" % playlist)
		_check(record.get("mmr_history", []).size() == 1, "%s mmr history" % playlist)

	_check(str(RankedDataRef.rank_for_mmr(310, "1v1").get("tier_name", "")) == "Silver I", "1v1 silver anchor")
	_check(str(RankedDataRef.rank_for_mmr(550, "2v2").get("tier_name", "")) == "Gold I", "2v2 gold anchor")
	_check(str(RankedDataRef.rank_for_mmr(870, "3v3").get("tier_name", "")) == "Diamond I", "3v3 diamond anchor")
	_check(str(RankedDataRef.rank_for_mmr(1860, "3v3").get("family", "")) == "Supersonic Legend", "3v3 ssl anchor")
	_check(RankedDataRef.tier_rows("2v2").size() == 22, "complete rank table")
	_check(RankedDataRef.top_ladder("1v1").size() == 12, "top twelve ladder")
	_check(RankedDataRef.around_player(100, "1v1").size() == 7, "around-you ladder")

	print("SMOKE 2/6: queue and MMR")
	var one_before := int(state.playlist_record("1v1")["mmr"])
	var first_match: Dictionary = state.create_match("Rocket League")
	_check(bool(first_match.get("ok", false)), "1v1 match creation")
	_check(first_match.get("events", []).size() >= 6 and first_match.get("events", []).size() <= 8, "match decision count")
	_check(first_match.get("decisions", []).size() == first_match.get("events", []).size(), "decision event parity")
	_check(abs(int(first_match.get("mmr_delta", 0))) >= 20, "placement delta lower bound")
	_check(abs(int(first_match.get("mmr_delta", 0))) <= 30, "placement delta upper bound")
	_check(int(state.playlist_record("1v1")["mmr"]) != one_before, "1v1 mmr changed")
	_check(int(state.playlist_record("2v2")["placements"]) == 0, "playlist independence")
	var tactical_state: EmpireStateRef = EmpireStateRef.new()
	tactical_state.reset_game()
	var tactical_session: Dictionary = tactical_state.prepare_match("Rocket League")
	_check(tactical_session.get("team_stats", {}).size() == 8, "eight development stats enter match")
	_check(int(tactical_session.get("boost", 0)) > 45, "boost control shapes starting boost")
	var opening: Dictionary = tactical_state.current_match_situation(tactical_session)
	var tactical_counters := {"press": "counter", "control": "press", "counter": "control"}
	var opening_call := str(tactical_counters[str(opening["opponent_action"])])
	var boost_before := int(tactical_session.get("boost", 0))
	var opening_result: Dictionary = tactical_state.play_match_turn(tactical_session, opening_call)
	_check(int(opening_result.get("quality", 0)) == 1, "correct tactical read rewarded")
	_check(int(opening_result.get("boost_after", 0)) != boost_before, "tactical boost changes")
	var opening_odds: Dictionary = opening_result.get("odds", {})
	_check(not opening_odds.is_empty(), "match action exposes odds")
	_check(abs(float(opening_odds.get("our_goal", 0.0)) + float(opening_odds.get("their_goal", 0.0)) + float(opening_odds.get("neutral", 0.0)) - 1.0) < 0.001, "match action odds total 100 percent")

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

	print("SMOKE 3/6: real time, coaching and migration")
	var schedule_state: EmpireStateRef = EmpireStateRef.new()
	schedule_state.reset_game()
	var captain: Dictionary = schedule_state.data["roster"][0]
	_check(DevelopmentDataRef.PLAYER_STATS.size() == 8, "eight player stats")
	_check(schedule_state.training_cost(captain, "rotation_review") > 0, "captain training costs cash")
	_check(not bool(schedule_state.train_player("captain", "rotation_review").get("ok", true)), "zero-cash training blocked")
	schedule_state.data["cash"] = 500
	var rotation_before := int(captain.get("rotation", 0))
	var sense_before := int(captain.get("game_sense", 0))
	var cash_before_training := int(schedule_state.data["cash"])
	var training_result := schedule_state.train_player("captain", "rotation_review")
	_check(bool(training_result.get("ok", false)), "paid focused training succeeds")
	_check(int(captain.get("rotation", 0)) >= rotation_before + 2, "rotation program improves rotation")
	_check(int(captain.get("game_sense", 0)) >= sense_before + 1, "rotation program improves game sense")
	_check(int(schedule_state.data["cash"]) < cash_before_training, "training deducts cash")
	_check(captain.get("training_history", []).size() == 1, "training history recorded")
	_check(schedule_state.training_breakthrough_chance() >= 0.12, "training exposes breakthrough chance")
	_check(bool(schedule_state.train_player("captain", "mechanics_lab").get("ok", false)), "training can repeat immediately")
	_check(captain.get("training_history", []).size() == 2, "repeat training history recorded")
	var coach_odds_total := 0.0
	for odds_value in schedule_state.coaching_rank_odds():
		coach_odds_total += float(odds_value.get("chance", 0.0))
	_check(abs(coach_odds_total - 1.0) < 0.001, "coach rank odds total 100 percent")
	_check(schedule_state.coaching_free_offer_chance() > 0.0 and schedule_state.coaching_free_offer_chance() < 0.02, "free coach offer is extremely rare")
	var first_offer: Dictionary = schedule_state.data["coaching_market"][0]
	first_offer["price"] = 0
	first_offer["free"] = true
	var coached_stat := str(first_offer.get("specialty", "mechanics"))
	var coached_before := int(captain.get(coached_stat, 0))
	var coaching_result := schedule_state.book_coaching_session(str(first_offer["id"]), "captain")
	_check(bool(coaching_result.get("ok", false)), "coaching session succeeds")
	_check(int(captain.get(coached_stat, 0)) > coached_before, "coaching guarantees stat gain")
	_check(float(coaching_result.get("bonus_chance", 0.0)) > 0.0, "coaching result exposes bonus chance")
	captain["fatigue"] = 20
	schedule_state.data["fatigue_updated_at"] = schedule_state.real_time_now() - 5 * 60
	var recovered := schedule_state.apply_real_time_fatigue_recovery(false)
	_check(recovered >= 5, "fatigue recovers with real elapsed time")
	_check(int(captain.get("fatigue", 0)) <= 15, "automatic recovery lowers fatigue")
	var real_time_match := schedule_state.create_match("Rocket League")
	_check(bool(real_time_match.get("ok", false)), "real-time schedule match")
	_check(int(schedule_state.data.get("season_match", 0)) == 1, "match advances season fixture only")
	_check(schedule_state.real_time_label().contains(":"), "device clock label")
	_check(schedule_state.community_cup_win_chance("Rocket League") >= 0.16, "community cup exposes win chance")
	_check(schedule_state.scouting_elite_potential_chance() >= 0.0, "scouting exposes elite chance")

	var reveal_state: EmpireStateRef = EmpireStateRef.new()
	reveal_state.reset_game()
	var reveal_record := reveal_state.playlist_record("1v1")
	reveal_record["placements"] = 9
	reveal_record["played"] = 9
	var reveal_match: Dictionary = reveal_state.create_match("Rocket League")
	_check(bool(reveal_match.get("rank_revealed", false)), "placement ten rank reveal")
	_check(int(reveal_match.get("placements_after", 0)) == 10, "placement ten completed")

	var migrated: EmpireStateRef = EmpireStateRef.new()
	migrated.reset_game()
	migrated.data["version"] = 5
	migrated.data["cash"] = 47
	migrated.data["rl_playlists"]["1v1"] = migrated._new_ranked_record(625, 1)
	migrated.data["rl_playlists"]["1v1"]["peak_mmr"] = 650
	migrated.data["rl_playlists"]["1v1"]["season_peak_mmr"] = 640
	migrated.data["rl_playlists"]["1v1"]["mmr_history"] = [600, 625]
	migrated.data["roster"][0].erase("rotation")
	migrated.data["roster"][0].erase("shooting")
	migrated.data["roster"][0].erase("defense")
	migrated.data["roster"][0].erase("boost_control")
	migrated.data["roster"][0].erase("consistency")
	migrated.data.erase("fatigue_updated_at")
	migrated.data.erase("coaching_market")
	migrated.data.erase("season_match")
	migrated.data["week"] = 7
	migrated._migrate_save(5)
	_check(int(migrated.data.get("cash", 0)) == 47, "migration preserves economy")
	_check(int(migrated.data["rl_playlists"]["1v1"]["mmr"]) == 125, "migration rebases current MMR")
	_check(int(migrated.data["rl_playlists"]["1v1"]["peak_mmr"]) == 150, "migration rebases peak MMR")
	_check(migrated.data["rl_playlists"]["1v1"]["mmr_history"] == [100, 125], "migration rebases MMR history")
	_check(migrated.data["roster"][0].has("rotation"), "migration adds rotation")
	_check(migrated.data["roster"][0].has("shooting"), "migration adds shooting")
	_check(migrated.data["roster"][0].has("defense"), "migration adds defense")
	_check(migrated.data["roster"][0].has("boost_control"), "migration adds boost control")
	_check(migrated.data["roster"][0].has("consistency"), "migration adds consistency")
	_check(int(migrated.data["roster"][0].get("potential", 0)) >= 96, "captain can reach complete mechanics arsenal")
	_check(migrated.data.has("fatigue_updated_at"), "migration adds real-time fatigue recovery")
	_check(migrated.data.has("coaching_market"), "migration adds coaching market")
	_check(int(migrated.data.get("season_match", -1)) == 6, "migration converts old week to season fixture")
	_check(migrated.data.has("earned_titles"), "migration adds title locker")
	_check(migrated.playlist_record("1v1").has("gc_reward_wins"), "migration adds title progress")
	_check(migrated.data.get("streaming", {}).has("total_donation_cash"), "migration adds donation totals")

	var donation_roll := schedule_state._roll_stream_donations(3, true, "Free", 0.0)
	_check(int(donation_roll.get("cash", 0)) > 0, "stream donation can generate virtual cash")
	_check(donation_roll.get("events", []).size() >= 1, "stream donation event generated")
	_check(schedule_state.stream_donation_chance(3, true, "Free") < 0.30, "early donations stay occasional")
	_check(schedule_state.estimated_stream_donation_chance(true) >= schedule_state.estimated_stream_donation_chance(false), "stream odds expose win bonus")
	schedule_state.set_streaming_enabled(true)
	var stream_cash_before := int(schedule_state.data.get("cash", 0))
	var integrated_stream := schedule_state._stream_payload(true, {"key": "normal"}, "1v1", 0.0)
	_check(bool(integrated_stream.get("live", false)), "stream payload live")
	_check(int(integrated_stream.get("donation_cash", 0)) > 0, "stream payload carries donations")
	_check(int(schedule_state.data.get("cash", 0)) > stream_cash_before, "stream donations reach club cash")
	_check(int(schedule_state.data.get("streaming", {}).get("total_donations", 0)) >= 1, "stream donation total tracked")
	captain["mechanics"] = 90
	captain["defense"] = 84
	captain["consistency"] = 82
	captain["shooting"] = 85
	captain["boost_control"] = 82
	var unlocked_mechanics := schedule_state.unlocked_mechanics(captain)
	_check(unlocked_mechanics.size() >= 7, "elite stats unlock advanced mechanics")
	_check(str(unlocked_mechanics[unlocked_mechanics.size() - 1].get("id", "")) == "psycho", "psycho progression unlock")

	var emblem := RankEmblemRef.new()
	emblem.configure(RankedDataRef.rank_for_mmr(1435, "2v2"))
	_check(emblem.family == "Grand Champion", "rank emblem family")
	emblem.free()

	var title_state: EmpireStateRef = EmpireStateRef.new()
	title_state.reset_game()
	var title_record := title_state.playlist_record("2v2")
	title_record["placements"] = 10
	var gc_rank := RankedDataRef.rank_for_mmr(1500, "2v2")
	for reward_win in range(TitleDataRef.RANK_REWARD_WINS):
		title_state._update_rank_title_progress(title_record, gc_rank, "2v2", true)
	_check(title_state.earned_titles().size() == 1, "grand champion title unlock")
	_check(not title_state.equipped_title().is_empty(), "first title auto equips")
	_check(int(title_record.get("gc_reward_wins", 0)) == 10, "rank reward wins cap")
	var equipped_id := str(title_state.equipped_title().get("id", ""))
	_check(bool(title_state.equip_title(equipped_id).get("ok", false)), "earned title equips")
	_check(bool(title_state.clear_equipped_title().get("ok", false)), "title unequips")
	var placement_state: EmpireStateRef = EmpireStateRef.new()
	placement_state.reset_game()
	var placement_record := placement_state.playlist_record("2v2")
	placement_record["mmr"] = 3002
	placement_record["placements"] = 10
	placement_record["season_wins"] = 10
	var season_titles := placement_state._finish_season()
	_check(season_titles.size() == 1, "world number one title unlock")
	_check(str(season_titles[0].get("label", "")).contains("WORLD #1"), "world number one title label")
	_check(int(placement_state.data.get("season_match", -1)) == 0, "new season resets fixture count")

	print("SMOKE 4/6: mobile ranked UI")
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
	_check(main.page_content.get_child_count() >= 16, "ladder content")
	main.ranked_view = "ranks"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 27, "all-ranks content")
	main.ranked_view = "titles"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 9, "title locker content")
	main.game.data["cash"] = 500
	main._show_page("team", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 8, "development and coaching page content")
	_check(main.season_label.text.contains("MATCH"), "real-time season header")
	_check(main.reputation_label.text == "0", "reputation replaces energy in header")
	_check(main._chance_text(0.125) == "13%", "chance formatting")
	var stat_grid: Control = main._development_stat_grid(main.game.data["roster"][0])
	_check(stat_grid.get_child_count() == 2, "development stat grid rows")
	_check(stat_grid.get_child(0).get_child_count() == 4, "development stat grid columns")
	stat_grid.free()
	var program_grid: Control = main._training_program_grid(main.game.data["roster"][0])
	_check(program_grid.get_child_count() == 6, "six mobile training program buttons")
	program_grid.free()

	print("SMOKE 5/6: full match flow")
	main.ranked_view = "overview"
	main._show_page("play", false)
	main._start_match("Rocket League")
	await process_frame
	_check(main.match_interactive, "Rocket League match is interactive")
	var counters := {"press": "counter", "control": "press", "counter": "control"}
	for decision_index in range(8):
		if main.match_finished:
			break
		var situation: Dictionary = main.game.current_match_situation(main.match_session)
		var best_action := str(counters.get(str(situation.get("opponent_action", "press")), "counter"))
		if not main.game.can_play_match_action(main.match_session, best_action):
			best_action = "control"
		main._choose_match_action(best_action)
		await process_frame
	_check(main.match_finished, "match finishes")
	_check(bool(main.match_result.get("ok", false)), "interactive result saved")
	_check(main.match_result.get("decisions", []).size() >= 6, "interactive decisions recorded")
	_check(main.match_result_box.visible, "match result panel")
	_check(main.match_continue_button.visible, "match continue button")
	await main._close_match()
	print("SMOKE 6/6: continue return")
	_check(main.match_overlay == null, "match overlay closes")
	_check(main.current_page == "play", "returns to ranked")
	main.queue_free()

	if failures.is_empty():
		print("E-Sport Empire v0.4.9 smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("Smoke test failed: %s" % failure)
		quit(1)
