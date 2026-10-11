extends SceneTree

const AppConfigRef = preload("res://scripts/app_config.gd")
const EmpireStateRef = preload("res://scripts/game_state.gd")
const GameDataRef = preload("res://scripts/game_data.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")
const RankEmblemRef = preload("res://scripts/rank_emblem.gd")
const TitleDataRef = preload("res://scripts/title_data.gd")
const DevelopmentDataRef = preload("res://scripts/development_data.gd")
const CoachingDataRef = preload("res://scripts/coaching_data.gd")
const CareerDataRef = preload("res://scripts/career_data.gd")
const DynastyDataRef = preload("res://scripts/dynasty_data.gd")
const MatchVisualizerRef = preload("res://scripts/match_visualizer.gd")
const TrainingVisualizerRef = preload("res://scripts/training_visualizer.gd")
const MainScene = preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	print("SMOKE 1/7: ranked data")
	var state: EmpireStateRef = EmpireStateRef.new()
	state.reset_game()
	_check(state.data.get("version") == GameDataRef.VERSION, "save version")
	_check(AppConfigRef.VERSION.begins_with("2.0."), "v2.0 art direction app version")
	_check(AppConfigRef.NAV_ENTRIES.size() == 4, "four focused mobile navigation destinations")
	_check(AppConfigRef.navigation_ids().has(AppConfigRef.DEFAULT_PAGE), "default page exists in navigation")
	_check(state.data.get("roster", []).size() == 1, "from-zero captain roster")
	_check(state.data.get("market", []).size() == 6, "market generation")
	_check(state.data.get("coaching_market", []).size() == CoachingDataRef.OFFER_COUNT, "coaching market generation")
	_check(not state.data.has("energy"), "global energy removed")
	_check(CareerDataRef.LEVELS.size() == 10, "ten career levels")
	_check(CareerDataRef.MILESTONES.size() == 12, "twelve career milestones")
	_check(DynastyDataRef.STAFF_ROLES.size() == 4, "four staff departments")
	_check(DynastyDataRef.SPONSOR_CONTRACTS.size() == 3, "three sponsor contracts")
	_check(DynastyDataRef.CIRCUIT_EVENTS.size() == 3, "three circuit tiers")
	_check(DynastyDataRef.SEASON_OBJECTIVES.size() == 6, "six season objectives")
	_check(state.career_xp() == 0 and state.career_level() == 1, "fresh career origin")
	_check(str(state.club_identity().get("id", "")) == "counter", "counter culture default identity")
	_check(state.team_chemistry("Rocket League") == 35, "fresh team chemistry")
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

	print("SMOKE 2/7: queue and MMR")
	var one_before := int(state.playlist_record("1v1")["mmr"])
	var first_match: Dictionary = state.create_match("Rocket League")
	_check(bool(first_match.get("ok", false)), "1v1 match creation")
	_check(first_match.get("events", []).size() >= 6 and first_match.get("events", []).size() <= 8, "core auto simulation event count")
	_check(first_match.get("decisions", []).size() == first_match.get("events", []).size(), "simulation telemetry parity")
	_check(first_match.get("broadcast_events", []).size() == first_match.get("events", []).size() * 3, "broadcast replay expands every core event into three phases")
	_check(str(first_match.get("broadcast_events", [])[0].get("phase", "")) == "buildup", "broadcast replay starts with buildup phase")
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
	_check(opening_result.has("momentum") and abs(int(opening_result.get("momentum", 0))) <= 100, "match turn returns bounded momentum")
	_check(int(opening_result.get("match_stats", {}).get("possession_ours", 0)) > 0, "live match stats update")
	var opening_odds: Dictionary = opening_result.get("odds", {})
	_check(not opening_odds.is_empty(), "match action exposes odds")
	_check(abs(float(opening_odds.get("our_goal", 0.0)) + float(opening_odds.get("their_goal", 0.0)) + float(opening_odds.get("neutral", 0.0)) - 1.0) < 0.001, "match action odds total 100 percent")
	var identity_odds := tactical_state.match_action_odds(tactical_session, "counter")
	_check(abs(float(identity_odds.get("identity_bonus", 0.0)) - 0.04) < 0.001, "club DNA exposes exact action bonus")

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

	print("SMOKE 3/7: real time, coaching and migration")
	var schedule_state: EmpireStateRef = EmpireStateRef.new()
	schedule_state.reset_game()
	var captain: Dictionary = schedule_state.data["roster"][0]
	_check(DevelopmentDataRef.PLAYER_STATS.size() == 8, "eight player stats")
	_check(not DevelopmentDataRef.player_archetype(captain).is_empty(), "dynamic player archetype")
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
	_check(int(schedule_state.training_readiness(captain).get("slots_remaining", -1)) == 2, "focused training spends one slot")
	_check(bool(schedule_state.train_player("captain", "mechanics_lab").get("ok", false)), "second focused training succeeds")
	_check(bool(schedule_state.train_player("captain", "finishing_pack").get("ok", false)), "third focused training succeeds")
	_check(captain.get("training_history", []).size() == 3, "focused session history recorded")
	_check(int(schedule_state.training_readiness(captain).get("slots_remaining", -1)) == 0, "focused sessions exhaust")
	_check(not bool(schedule_state.train_player("captain", "defensive_reads").get("ok", true)), "fourth immediate training blocked")
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
	_check(int(real_time_match.get("career_xp", 0)) >= 10, "match grants career XP")
	var first_milestone: Dictionary = schedule_state.career_milestones()[0]
	_check(bool(first_milestone.get("complete", false)), "first-match milestone completes")
	var milestone_cash_before := int(schedule_state.data.get("cash", 0))
	var milestone_claim := schedule_state.claim_career_milestone("first_match")
	_check(bool(milestone_claim.get("ok", false)), "completed milestone claims")
	_check(int(schedule_state.data.get("cash", 0)) > milestone_cash_before, "milestone guaranteed cash reward")
	_check(schedule_state.real_time_label().contains(":"), "device clock label")
	_check(schedule_state.community_cup_win_chance("Rocket League") >= 0.16, "community cup exposes win chance")
	_check(schedule_state.scouting_elite_potential_chance() >= 0.0, "scouting exposes elite chance")

	var chemistry_state: EmpireStateRef = EmpireStateRef.new()
	chemistry_state.reset_game()
	var chemistry_teammate: Dictionary = chemistry_state.data["roster"][0].duplicate(true)
	chemistry_teammate["id"] = "chemistry_teammate"
	chemistry_teammate["name"] = "SYNC"
	chemistry_state.data["roster"].append(chemistry_teammate)
	chemistry_state.data["cash"] = 500
	var chemistry_before := chemistry_state.team_chemistry("Rocket League")
	var scrim_result := chemistry_state.team_scrim("Rocket League")
	_check(bool(scrim_result.get("ok", false)), "instant team scrim succeeds")
	_check(chemistry_state.team_chemistry("Rocket League") > chemistry_before, "scrim guarantees chemistry")
	_check(int(scrim_result.get("career", {}).get("xp", 0)) == 8, "scrim grants career XP")
	_check(bool(chemistry_state.set_club_identity("pressure").get("ok", false)), "club identity switches freely")
	chemistry_state.set_selected_rl_playlist("2v2")
	var chemistry_session := chemistry_state.prepare_match("Rocket League")
	_check(int(chemistry_session.get("team_chemistry", 0)) == chemistry_state.team_chemistry("Rocket League"), "match receives chemistry")
	var pressure_odds := chemistry_state.match_action_odds(chemistry_session, "press")
	_check(bool(pressure_odds.get("identity_active", false)), "selected club DNA activates")
	chemistry_state._update_rival("Rocket League", "2v2", "Nova Union", false)
	chemistry_state._update_rival("Rocket League", "2v2", "Nova Union", true)
	var rivalry_result := chemistry_state._update_rival("Rocket League", "2v2", "Nova Union", true)
	_check(bool(rivalry_result.get("rewarded", false)), "rival win threshold rewards")
	_check(int(rivalry_result.get("cash", 0)) >= 75, "rival reward cash")
	_check(int(rivalry_result.get("reputation", 0)) >= 10, "rival reward reputation")

	var legacy := GameDataRef.new_save()
	legacy.erase("schema_version")
	legacy.erase("settings")
	legacy.erase("career")
	legacy.erase("dynasty")
	legacy.erase("club_identity")
	legacy.erase("team_chemistry")
	legacy["selected_rl_playlist"] = "1v1"
	legacy["roster"] = [legacy["roster"][0]]
	_check(schedule_state._migrate_data(legacy), "legacy save migrated")
	_check(int(legacy.get("schema_version", 0)) == GameDataRef.SCHEMA_VERSION, "legacy schema version updated")
	_check(legacy.has("settings"), "legacy settings added")
	_check(legacy.has("career"), "legacy career added")
	_check(legacy.has("dynasty"), "legacy dynasty added")
	_check(legacy.has("club_identity"), "legacy club identity added")
	_check(legacy.has("team_chemistry"), "legacy chemistry added")

	print("SMOKE 4/7: dynasty systems")
	var dynasty_state: EmpireStateRef = EmpireStateRef.new()
	dynasty_state.reset_game()
	dynasty_state.data["cash"] = 12000
	var facility_before := dynasty_state.facility_level("training")
	var facility_upgrade := dynasty_state.upgrade_facility("training")
	_check(bool(facility_upgrade.get("ok", false)), "training facility upgrade")
	_check(dynasty_state.facility_level("training") == facility_before + 1, "training facility level")
	var staff_market := dynasty_state.staff_market()
	_check(staff_market.size() == DynastyDataRef.STAFF_ROLES.size(), "one staff offer per role")
	var hired := dynasty_state.hire_staff(str(staff_market[0].get("id", "")))
	_check(bool(hired.get("ok", false)), "staff hire")
	var sponsor_offer := dynasty_state.available_sponsors()[0]
	var sponsor_sign := dynasty_state.sign_sponsor(str(sponsor_offer.get("id", "")))
	_check(bool(sponsor_sign.get("ok", false)), "sponsor sign")
	var active_sponsors := dynasty_state.active_sponsors()
	_check(active_sponsors.size() == 1, "one active sponsor")
	var sponsor_income := dynasty_state.passive_income_per_hour()
	_check(sponsor_income > 0, "sponsor contributes passive income")
	var objective_rows := dynasty_state.season_objectives()
	_check(objective_rows.size() == DynastyDataRef.SEASON_OBJECTIVES.size(), "season objectives list")

	print("SMOKE 5/7: mobile ranked UI")
	var main = MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	_check(main.current_page == "home", "home page default")
	_check(main.nav_buttons.size() == 4, "four bottom nav destinations")
	_check(not main.nav_buttons.has("market"), "scout removed from primary navigation")
	_check(main.page_content.get_child_count() >= 6 and main.page_content.get_child_count() <= 8, "home dashboard intentionally compact")
	main._show_page("play", false)
	await process_frame
	_check(main.current_page == "play", "ranked page opens")
	_check(main.page_content.get_child_count() >= 9, "ranked overview content")
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
	main.ranked_view = "circuit"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 8, "Pro Circuit event board content")
	main.game.data["cash"] = 500
	main.team_view = "training"
	main._show_page("team", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 5 and main.page_content.get_child_count() <= 6, "focused training view stays compact")
	main.team_view = "coaching"
	main._show_page("team", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 5 and main.page_content.get_child_count() <= 6, "focused coaching view stays compact")
	main.team_view = "roster"
	main._show_page("team", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 7, "focused roster view content")
	_check(main.season_label.text.contains("SPIEL"), "German real-time season header")
	_check(main.cash_label != null and main.fans_label == null and main.reputation_label != null, "professional mobile header shows cash and reputation")
	_check(main._chance_text(0.125) == "13%", "chance formatting")
	var stat_grid: Control = main._development_stat_grid(main.game.data["roster"][0])
	_check(stat_grid.get_child_count() == 2, "development stat grid rows")
	_check(stat_grid.get_child(0).get_child_count() == 4, "development stat grid columns")
	stat_grid.free()
	var program_grid: Control = main._training_program_grid(main.game.data["roster"][0])
	_check(program_grid.get_child_count() == 6, "six mobile training program buttons")
	program_grid.free()

	print("SMOKE 6/7: full auto-sim match flow")
	main.ranked_view = "overview"
	main._show_page("play", false)
	main._start_match("Rocket League")
	await process_frame
	_check(not main.match_interactive, "Rocket League match uses auto simulation")
	_check(main.match_session.is_empty(), "no player decision session exposed")
	_check(main.match_decision_box == null, "decision UI removed from live match")
	_check(main.match_visualizer != null, "top-down live arena visualizer mounted")
	_check(bool(main.match_result.get("ok", false)), "auto-sim result saved")
	_check(main.match_result.get("events", []).size() >= 6, "core auto-sim events recorded")
	_check(main.match_result.get("broadcast_events", []).size() >= 18, "broadcast replay events recorded")
	_check(main.match_result.get("match_stats", {}).has("shots_ours"), "post-match analytics recorded")
	if main.match_timer != null:
		main.match_timer.stop()
	for event_index in range(main.match_result.get("broadcast_events", []).size() + 1):
		if main.match_finished:
			break
		main._advance_match()
		await process_frame
	_check(main.match_finished, "auto-sim playback finishes")
	_check(main.match_result_box.visible, "match result panel")
	_check(main.match_continue_button.visible, "match continue button")
	await main._close_match()
	print("SMOKE 7/7: continue return")
	_check(main.match_overlay == null, "match overlay closes")
	_check(main.current_page == "play", "returns to ranked")
	main.queue_free()

	if failures.is_empty():
		print("E-Sport Empire v2.0 art direction smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("Smoke test failed: %s" % failure)
		quit(1)