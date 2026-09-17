extends SceneTree

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
	_check(int(opening_result.get("momentum", 0)) > 0, "perfect read creates momentum")
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
	_check(str(rivalry_result.get("tier", "")) == "RIVAL", "three meetings create rivalry")
	_check(int(rivalry_result.get("bonus_fans", 0)) > 0, "rivalry win guarantees fan bonus")
	_check(chemistry_state.top_rivals(3).size() == 1, "rival tracker persists record")

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
	migrated.data.erase("career_xp")
	migrated.data.erase("claimed_milestones")
	migrated.data.erase("club_identity")
	migrated.data.erase("team_chemistry")
	migrated.data.erase("rivals")
	migrated.data.erase("cup_wins")
	migrated.data.erase("seasons_finished")
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
	_check(migrated.data.has("career_xp"), "migration adds career XP")
	_check(migrated.data.has("claimed_milestones"), "migration adds milestone claims")
	_check(str(migrated.data.get("club_identity", "")) == "counter", "migration adds club DNA")
	_check(migrated.data.has("team_chemistry"), "migration adds chemistry")
	_check(migrated.data.has("rivals"), "migration adds rivals")
	_check(migrated.data.has("staff"), "migration adds staff HQ")
	_check(migrated.data.has("season_stats"), "migration adds season objectives")
	_check(migrated.data.has("active_sponsor"), "migration adds sponsor contracts")
	_check(migrated.data.has("pro_circuit"), "migration adds Pro Circuit")

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
	var bronze_record := title_state.playlist_record("1v1")
	bronze_record["placements"] = 10
	var bronze_titles := title_state._update_rank_title_progress(
		bronze_record, RankedDataRef.rank_for_mmr(100, "1v1"), "1v1", false
	)
	_check(bronze_titles.size() == 1, "Bronze season title unlock")
	_check(str(bronze_titles[0].get("label", "")).contains("BRONZE"), "Bronze title label")
	_check(TitleDataRef.RANK_FAMILIES.size() == 8, "Bronze through SSL title catalog")
	# Isolate the elite reward test from the automatic rank credential above.
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

	print("SMOKE 4/7: dynasty systems")
	var dynasty_state: EmpireStateRef = EmpireStateRef.new()
	dynasty_state.reset_game()
	dynasty_state.data["cash"] = 5000
	var dynasty_captain: Dictionary = dynasty_state.data["roster"][0]
	var cost_before_staff := dynasty_state.training_cost(dynasty_captain, "mechanics_lab")
	_check(bool(dynasty_state.hire_staff("performance_kael").get("ok", false)), "performance director hire")
	_check(dynasty_state.training_cost(dynasty_captain, "mechanics_lab") < cost_before_staff, "performance staff discounts training")
	_check(bool(dynasty_state.hire_staff("analyst_ivy").get("ok", false)), "tactical analyst hire")
	_check(bool(dynasty_state.hire_staff("coach_mara").get("ok", false)), "head coach hire")
	var staffed_session := dynasty_state.prepare_match("Rocket League")
	var staffed_odds := dynasty_state.match_action_odds(staffed_session, "counter")
	_check(abs(float(staffed_odds.get("analyst_bonus", 0.0)) - 0.006) < 0.001, "analyst exact scoring bonus")
	_check(float(staffed_session.get("coach_strength_bonus", 0.0)) > 0.0, "head coach strength bonus")
	_check(int(dynasty_state.data.get("season_stats", {}).get("staff_hires", 0)) == 3, "staff season progress")
	dynasty_state.data["reputation"] = 3
	dynasty_state.data["fans"] = 150
	var sponsor_cash_before := int(dynasty_state.data.get("cash", 0))
	_check(bool(dynasty_state.accept_sponsor_contract("local_launch").get("ok", false)), "sponsor contract signs")
	_check(int(dynasty_state.data.get("cash", 0)) > sponsor_cash_before, "sponsor upfront is paid")
	var sponsor_tick := dynasty_state._progress_sponsor_contract(true)
	_check(int(sponsor_tick.get("matches", 0)) == 1 and int(sponsor_tick.get("wins", 0)) == 1, "sponsor progress tracks result")
	_check(int(sponsor_tick.get("payout", 0)) > 0, "sponsor match payout")

	var circuit_state: EmpireStateRef = EmpireStateRef.new()
	circuit_state.reset_game()
	circuit_state.playlist_record("1v1")["played"] = 3
	_check(bool(circuit_state.start_pro_circuit("open_circuit").get("ok", false)), "open circuit starts")
	var circuit_mmr_before := int(circuit_state.playlist_record("1v1").get("mmr", 0))
	var circuit_fixture_before := int(circuit_state.data.get("season_match", 0))
	var circuit_session := circuit_state.prepare_pro_circuit_match()
	_check(str(circuit_session.get("competition", "")) == "pro_circuit", "circuit session type")
	var circuit_finished := false
	var circuit_safety := 0
	var circuit_counters := {"press": "counter", "control": "press", "counter": "control"}
	while not circuit_finished and circuit_safety < 10:
		var circuit_situation := circuit_state.current_match_situation(circuit_session)
		var circuit_action := str(circuit_counters.get(str(circuit_situation.get("opponent_action", "press")), "counter"))
		if not circuit_state.can_play_match_action(circuit_session, circuit_action):
			circuit_action = "control"
		var circuit_turn := circuit_state.play_match_turn(circuit_session, circuit_action)
		circuit_finished = bool(circuit_turn.get("finished", false))
		circuit_safety += 1
	var circuit_match := circuit_state.finalize_match(circuit_session)
	_check(bool(circuit_match.get("ok", false)), "circuit match finalizes")
	_check(not bool(circuit_match.get("ranked", true)), "circuit result is non-ranked")
	_check(int(circuit_state.playlist_record("1v1").get("mmr", 0)) == circuit_mmr_before, "circuit never changes MMR")
	_check(int(circuit_state.data.get("season_match", 0)) == circuit_fixture_before, "circuit does not consume ranked fixture")
	_check(not circuit_match.get("circuit", {}).is_empty(), "circuit bracket advances or ends")
	_check(circuit_match.get("match_stats", {}).has("shots_ours"), "circuit returns match analytics")
	_check(int(circuit_state.data.get("season_stats", {}).get("matches", 0)) == 1, "circuit advances season objective")

	var champion_state: EmpireStateRef = EmpireStateRef.new()
	champion_state.reset_game()
	champion_state.playlist_record("1v1")["played"] = 3
	champion_state.start_pro_circuit("open_circuit")
	champion_state._advance_pro_circuit(true)
	champion_state._advance_pro_circuit(true)
	var title_result := champion_state._advance_pro_circuit(true)
	_check(bool(title_result.get("champion", false)), "three circuit wins lift trophy")
	_check(int(champion_state.data.get("circuit_titles", 0)) == 1, "circuit title tracked")
	_check(int(title_result.get("reward", {}).get("cash", 0)) == 180, "circuit prize exact")
	_check(not title_result.get("unlocked_title", {}).is_empty(), "circuit champion title unlock")
	_check(str(champion_state.equipped_title().get("category", "")) == "PRO CIRCUIT", "circuit title auto equips")

	var visualizer := MatchVisualizerRef.new()
	visualizer.configure({"format": "3v3", "momentum": 0})
	visualizer.play_turn({"type": "good"}, "press", 1, 30)
	var visual_state := visualizer.snapshot_state()
	_check(int(visual_state.get("cars", 0)) == 6, "visualizer renders 3v3 cars")
	_check(int(visual_state.get("momentum", 0)) == 30, "visualizer tracks momentum")
	visualizer.free()

	print("SMOKE 5/7: mobile ranked UI")
	var main := MainScene.instantiate()
	root.add_child(main)
	for frame in range(3):
		await process_frame
	main.game.reset_game()
	main.game.set_selected_mode("Rocket League")
	main.game.set_selected_rl_playlist("1v1")
	main._show_page("home", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 10, "career home content")
	main._show_page("empire", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 8, "club DNA empire content")
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
	main.ranked_view = "circuit"
	main._show_page("play", false)
	await process_frame
	_check(main.page_content.get_child_count() >= 8, "Pro Circuit event board content")
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

	print("SMOKE 6/7: full match flow")
	main.ranked_view = "overview"
	main._show_page("play", false)
	main._start_match("Rocket League")
	await process_frame
	_check(main.match_interactive, "Rocket League match is interactive")
	_check(main.match_visualizer != null, "live arena visualizer mounted")
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
	_check(main.match_result.get("match_stats", {}).has("shots_ours"), "post-match analytics recorded")
	_check(main.match_result_box.visible, "match result panel")
	_check(main.match_continue_button.visible, "match continue button")
	await main._close_match()
	print("SMOKE 7/7: continue return")
	_check(main.match_overlay == null, "match overlay closes")
	_check(main.current_page == "play", "returns to ranked")
	main.queue_free()

	if failures.is_empty():
		print("E-Sport Empire v0.6.0 smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("Smoke test failed: %s" % failure)
		quit(1)
