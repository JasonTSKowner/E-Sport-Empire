class_name EmpireState
extends RefCounted

const SAVE_PATH := "user://e_sport_empire_save.json"
const GameDataRef = preload("res://scripts/game_data.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")

var data: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()
	data = _new_save()


func load_game() -> Dictionary:
	var offline := {"seconds": 0, "cash": 0, "fans": 0}
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
				_migrate_save(int(data.get("version", 0)))
	_merge_defaults(data, _new_save())
	data["version"] = GameDataRef.VERSION
	if not data.has("market") or data["market"].is_empty():
		generate_market(false)
	offline = apply_offline_progress()
	save_game()
	return offline

func save_game() -> void:
	data["last_seen"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))


func reset_game() -> void:
	data = _new_save()
	generate_market(false)
	save_game()


func apply_offline_progress() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var previous := int(data.get("last_seen", now))
	var elapsed := clampi(now - previous, 0, 8 * 60 * 60)
	var income := int(round(float(passive_income_per_hour()) * float(elapsed) / 3600.0))
	var new_fans := int(round(float(passive_fans_per_hour()) * float(elapsed) / 3600.0))
	if elapsed >= 60:
		data["cash"] = int(data["cash"]) + income
		data["fans"] = int(data["fans"]) + new_fans
	data["last_seen"] = now
	return {"seconds": elapsed, "cash": income, "fans": new_fans}


func passive_income_per_hour() -> int:
	return facility_level("studio") * 18 + facility_level("hq") * 4 + int(data.get("reputation", 0))

func passive_fans_per_hour() -> int:
	return facility_level("studio") * 2 + int(data.get("reputation", 0)) / 4

func selected_mode() -> String:
	return str(data.get("selected_mode", GameDataRef.MODES[0]))


func set_selected_mode(mode: String) -> void:
	if mode in GameDataRef.MODES:
		data["selected_mode"] = mode
		save_game()


func selected_rl_playlist() -> String:
	return RankedDataRef.normalize_playlist(str(data.get("selected_rl_playlist", "1v1")))


func set_selected_rl_playlist(playlist: String) -> void:
	var normalized := RankedDataRef.normalize_playlist(playlist)
	data["selected_rl_playlist"] = normalized
	save_game()


func playlist_required_players(playlist: String) -> int:
	var normalized := RankedDataRef.normalize_playlist(playlist)
	if normalized == "2v2":
		return 2
	if normalized == "3v3":
		return 3
	return 1


func can_queue_playlist(playlist: String) -> bool:
	return roster_for("Rocket League").size() >= playlist_required_players(playlist)


func roster_for(mode: String) -> Array:
	var result: Array = []
	for player in data.get("roster", []):
		if str(player.get("mode", "")) == mode:
			result.append(player)
	result.sort_custom(func(a, b): return player_overall(a) > player_overall(b))
	return result


func player_overall(player: Dictionary) -> int:
	var total := (
		int(player.get("mechanics", 50)) * 34
		+ int(player.get("game_sense", 50)) * 28
		+ int(player.get("teamwork", 50)) * 23
		+ int(player.get("mentality", 50)) * 15
	)
	return clampi(int(round(float(total) / 100.0)), 1, 99)


func team_overall(mode: String) -> int:
	var roster := roster_for(mode)
	if roster.is_empty():
		return 35
	var total := 0.0
	for player in roster:
		var base := float(player_overall(player))
		var form_bonus := float(player.get("form", 50) - 50) * 0.08
		var fatigue_penalty := float(player.get("fatigue", 0)) * 0.055
		total += base + form_bonus - fatigue_penalty
	return clampi(int(round(total / roster.size())), 1, 99)


func mode_record(mode: String) -> Dictionary:
	if mode == "Rocket League":
		return playlist_record(selected_rl_playlist())
	return data["modes"][mode]

func mode_mmr(mode: String) -> int:
	return int(mode_record(mode).get("mmr", 600))

func rank_data(mode: String) -> Dictionary:
	if mode == "Rocket League":
		return GameDataRef.rl_rank_for_mmr(mode_mmr(mode), selected_rl_playlist())
	return GameDataRef.rank_for_mmr(mode_mmr(mode))

func next_rank_data(mode: String) -> Dictionary:
	if mode == "Rocket League":
		return GameDataRef.rl_next_rank_for_mmr(mode_mmr(mode), selected_rl_playlist())
	return GameDataRef.next_rank_for_mmr(mode_mmr(mode))


func playlist_record(format: String) -> Dictionary:
	var key := format
	if key not in ["1v1", "2v2", "3v3"]:
		key = "1v1"
	return data["rl_playlists"][key]


func placement_target(mode: String) -> int:
	return 10 if mode == "Rocket League" else 5


func placements_complete(mode: String) -> bool:
	return int(mode_record(mode).get("placements", 0)) >= placement_target(mode)


func visible_rank_name(mode: String) -> String:
	if mode == "Rocket League" and not placements_complete(mode):
		return "UNRANKED"
	return str(rank_data(mode).get("name", "UNRANKED"))


func _opponent_mmr_for(player_mmr: int) -> int:
	# Matchmaking usually stays close, but not every lobby is perfectly even.
	var spread := (rng.randf_range(-100.0, 100.0) + rng.randf_range(-100.0, 100.0)) * 0.5
	return maxi(0, player_mmr + int(round(spread)))

func _mmr_delta_for(
	mode: String, record: Dictionary, player_mmr: int, opponent_mmr: int, won: bool
) -> int:
	# RL MMR only cares about the result and relative opponent rating.
	# Goals, saves, score and other personal stats never enter this calculation.
	var in_placements := int(record.get("placements", 0)) < placement_target(mode)
	if mode == "Rocket League":
		var relative_adjustment := clampi(int(round(float(opponent_mmr - player_mmr) / 90.0)), -2, 2)
		var magnitude := 10
		if in_placements:
			magnitude = 30 - int(record.get("placements", 0))
			magnitude += relative_adjustment if won else -relative_adjustment
			magnitude = clampi(magnitude, 20, 30)
		else:
			magnitude += relative_adjustment if won else -relative_adjustment
			magnitude = clampi(magnitude, 9, 11)
		return magnitude if won else -magnitude

	var expected := 1.0 / (1.0 + pow(10.0, float(opponent_mmr - player_mmr) / 400.0))
	var k := 26.0 if in_placements else 20.0
	var actual := 1.0 if won else 0.0
	var delta := int(round(k * (actual - expected)))
	return maxi(1, delta) if won else mini(-1, delta)

func facility_level(key: String) -> int:
	return int(data.get("facilities", {}).get(key, 1))


func facility_cost(key: String) -> int:
	var definition: Dictionary = GameDataRef.FACILITIES[key]
	var level := facility_level(key)
	return int(round(float(definition["base_cost"]) * pow(1.72, maxi(0, level))))

func buy_facility(key: String) -> Dictionary:
	if not GameDataRef.FACILITIES.has(key):
		return {"ok": false, "message": "Unknown facility."}
	var level := facility_level(key)
	if level >= 10:
		return {"ok": false, "message": "This facility is already max level."}
	var cost := facility_cost(key)
	if int(data["cash"]) < cost:
		return {"ok": false, "message": "Not enough cash for this upgrade."}
	data["cash"] = int(data["cash"]) - cost
	data["facilities"][key] = level + 1
	data["reputation"] = int(data["reputation"]) + 1
	save_game()
	return {
		"ok": true,
		"message": "%s reached level %d." % [GameDataRef.FACILITIES[key]["name"], level + 1],
	}


func training_cost(player: Dictionary) -> int:
	if str(player.get("id", "")) == "captain":
		return 0
	return 10 + int(round(float(player_overall(player)) * 0.55))

func train_player(player_id: String) -> Dictionary:
	var player := _find_player(player_id)
	if player.is_empty():
		return {"ok": false, "message": "Player not found."}
	var cost := training_cost(player)
	if int(data["cash"]) < cost:
		return {"ok": false, "message": "Not enough cash for this session."}
	if int(data["energy"]) < 9:
		return {"ok": false, "message": "The staff needs more energy."}
	if player_overall(player) >= int(player.get("potential", 99)):
		return {"ok": false, "message": "This player has reached their current potential."}
	var coaching := facility_level("coaching")
	var stats := ["mechanics", "game_sense", "teamwork", "mentality"]
	var stat: String = stats[rng.randi_range(0, stats.size() - 1)]
	var gain := 1
	if rng.randf() < 0.18 + coaching * 0.035:
		gain += 1
	player[stat] = mini(int(player[stat]) + gain, int(player.get("potential", 99)))
	player["form"] = clampi(int(player.get("form", 50)) + rng.randi_range(2, 6), 25, 100)
	player["fatigue"] = clampi(int(player.get("fatigue", 0)) + maxi(3, 9 - coaching), 0, 100)
	data["cash"] = int(data["cash"]) - cost
	data["energy"] = int(data["energy"]) - 9
	save_game()
	return {
		"ok": true,
		"message": "%s gained +%d %s." % [player["name"], gain, stat.replace("_", " ")],
	}


func rest_team(mode: String) -> Dictionary:
	for player in roster_for(mode):
		player["fatigue"] = maxi(0, int(player.get("fatigue", 0)) - 24)
		player["form"] = clampi(int(player.get("form", 50)) + 2, 25, 100)
	data["energy"] = mini(100, int(data["energy"]) + 18)
	save_game()
	return {"ok": true, "message": "%s division completed recovery." % mode}

func generate_market(charge: bool = true) -> Dictionary:
	var cost := 5
	if charge and int(data["cash"]) < cost:
		return {"ok": false, "message": "You need €5 for a fresh scouting search."}
	if charge:
		data["cash"] = int(data["cash"]) - cost
	var scouting := facility_level("scouting")
	var prospects: Array = []
	for index in range(6):
		var mode: String = GameDataRef.MODES[index % GameDataRef.MODES.size()]
		var base := rng.randi_range(47 + scouting, 57 + scouting * 2)
		base = clampi(base, 42, 91)
		var potential := clampi(base + rng.randi_range(8, 18 + scouting), base + 2, 99)
		var player := {
			"id": "prospect_%d_%d" % [int(Time.get_ticks_msec()), index],
			"name": GameDataRef.FIRST_NAMES[rng.randi_range(0, GameDataRef.FIRST_NAMES.size() - 1)],
			"mode": mode,
			"role": _role_for_mode(mode, index),
			"region": GameDataRef.REGIONS[rng.randi_range(0, GameDataRef.REGIONS.size() - 1)],
			"age": rng.randi_range(maxi(16, 21 - scouting), 24),
			"mechanics": clampi(base + rng.randi_range(-4, 5), 35, 95),
			"game_sense": clampi(base + rng.randi_range(-4, 5), 35, 95),
			"teamwork": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"mentality": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"potential": potential,
			"form": rng.randi_range(45, 68),
			"fatigue": 0,
		}
		player["contract"] = 20 + player_overall(player) + int(round(float(potential) * 0.8))
		prospects.append(player)
	data["market"] = prospects
	if charge:
		save_game()
	return {"ok": true, "message": "Fresh amateur scouting reports are ready."}

func sign_player(prospect_id: String) -> Dictionary:
	var prospect: Dictionary = {}
	for candidate in data.get("market", []):
		if str(candidate.get("id", "")) == prospect_id:
			prospect = candidate
			break
	if prospect.is_empty():
		return {"ok": false, "message": "This prospect is no longer available."}
	var cost := int(prospect.get("contract", 0))
	if int(data["cash"]) < cost:
		return {"ok": false, "message": "Not enough cash for this contract."}
	var mode := str(prospect["mode"])
	var current := roster_for(mode)
	var replaced := ""
	if current.size() >= 3:
		var weakest: Dictionary = current[current.size() - 1]
		replaced = str(weakest["name"])
		data["roster"].erase(weakest)
	var signed := prospect.duplicate(true)
	signed.erase("contract")
	signed["id"] = "player_%d" % int(Time.get_ticks_msec())
	data["roster"].append(signed)
	data["market"].erase(prospect)
	data["cash"] = int(data["cash"]) - cost
	data["reputation"] = int(data["reputation"]) + 1
	save_game()
	var message := "%s signed for the %s division." % [signed["name"], mode]
	if not replaced.is_empty():
		message += " %s was released." % replaced
	return {"ok": true, "message": message}


func sponsor_ready() -> bool:
	return sponsor_eligible() and int(Time.get_unix_time_from_system()) >= int(data.get("sponsor_ready_at", 0))

func sponsor_seconds_left() -> int:
	if not sponsor_eligible():
		return 0
	return maxi(0, int(data.get("sponsor_ready_at", 0)) - int(Time.get_unix_time_from_system()))

func collect_sponsor() -> Dictionary:
	if not sponsor_eligible():
		return {"ok": false, "message": "No sponsor is interested yet. Build attention first."}
	if not sponsor_ready():
		return {"ok": false, "message": "The next sponsor activation is not ready yet."}
	var reward := 35 + int(data["reputation"]) * 3 + facility_level("hq") * 15
	var fan_reward := 8 + facility_level("studio") * 3
	data["cash"] = int(data["cash"]) + reward
	data["fans"] = int(data["fans"]) + fan_reward
	data["sponsor_ready_at"] = int(Time.get_unix_time_from_system()) + 24 * 60 * 60
	save_game()
	return {
		"ok": true,
		"message": "Small sponsor activation: +%s and +%d fans." % [GameDataRef.format_cash(reward), fan_reward],
	}

func create_match(mode: String) -> Dictionary:
	var roster := roster_for(mode)
	if roster.is_empty():
		return {"ok": false, "message": "You need at least one active player before queueing."}
	var format := match_format(mode)
	if mode == "Rocket League" and not can_queue_playlist(format):
		return {
			"ok": false,
			"message": "%s requires %d active Rocket League players." % [format, playlist_required_players(format)],
		}
	var record := mode_record(mode)
	var mmr_before := int(record.get("mmr", 600))
	var opponent_mmr := _opponent_mmr_for(mmr_before)

	var player_strength := _competitive_strength(mode, format)
	player_strength += float(facility_level("analytics")) * 0.45
	player_strength += float(facility_level("coaching")) * 0.25

	var profile := _roll_opponent_profile()
	var expected_strength := 48.0 + float(opponent_mmr - 600) / 30.0
	var opponent_strength := clampf(
		expected_strength + rng.randf_range(-3.5, 3.5) + float(profile["strength_mod"]),
		35.0,
		99.0
	)
	var advantage := player_strength - opponent_strength
	var win_chance := clampf(0.5 + advantage * 0.038, 0.12, 0.88)
	var won := rng.randf() <= win_chance

	var opponent := ""
	if format == "1v1":
		opponent = str(GameDataRef.FIRST_NAMES[rng.randi_range(0, GameDataRef.FIRST_NAMES.size() - 1)])
	else:
		var opponent_names: Array = GameDataRef.OPPONENTS[mode]
		opponent = opponent_names[rng.randi_range(0, opponent_names.size() - 1)]

	var events := _create_match_events(mode, won)
	var placements_before := int(record.get("placements", 0))
	var mmr_delta := _mmr_delta_for(mode, record, mmr_before, opponent_mmr, won)
	var old_rank_data := GameDataRef.rl_rank_for_mmr(mmr_before, format) if mode == "Rocket League" else GameDataRef.rank_for_mmr(mmr_before)
	var old_rank := "UNRANKED" if mode == "Rocket League" and placements_before < placement_target(mode) else str(old_rank_data["name"])
	record["mmr"] = maxi(0, mmr_before + mmr_delta)
	record["played"] = int(record.get("played", 0)) + 1
	if won:
		record["wins"] = int(record.get("wins", 0)) + 1
		record["season_wins"] = int(record.get("season_wins", 0)) + 1
		record["streak"] = maxi(1, int(record.get("streak", 0)) + 1)
	else:
		record["losses"] = int(record.get("losses", 0)) + 1
		record["season_losses"] = int(record.get("season_losses", 0)) + 1
		record["streak"] = mini(-1, int(record.get("streak", 0)) - 1)
	record["placements"] = mini(placement_target(mode), int(record.get("placements", 0)) + 1)
	record["peak_mmr"] = maxi(int(record.get("peak_mmr", mmr_before)), int(record["mmr"]))
	record["season_peak_mmr"] = maxi(int(record.get("season_peak_mmr", mmr_before)), int(record["mmr"]))
	var mmr_history: Array = record.get("mmr_history", [])
	mmr_history.append(int(record["mmr"]))
	while mmr_history.size() > 30:
		mmr_history.pop_front()
	record["mmr_history"] = mmr_history
	var last_results: Array = record.get("last_results", [])
	last_results.push_front("W" if won else "L")
	while last_results.size() > 10:
		last_results.pop_back()
	record["last_results"] = last_results

	data["energy"] = maxi(0, int(data["energy"]) - 5)
	var participating_players := roster.size()
	if mode == "Rocket League":
		participating_players = mini(roster.size(), playlist_required_players(format))
	for player_index in range(participating_players):
		var player: Dictionary = roster[player_index]
		player["fatigue"] = clampi(int(player.get("fatigue", 0)) + rng.randi_range(3, 7), 0, 100)
		player["form"] = clampi(
			int(player.get("form", 50)) + (rng.randi_range(1, 4) if won else -rng.randi_range(1, 3)),
			25,
			100
		)

	var stream := _stream_payload(won, profile, format)
	var attention := _attention_roll(won, profile, mode, format, int(stream.get("viewers", 0)))
	data["attention"] = int(data.get("attention", 0)) + int(attention.get("points", 0))
	data["reputation"] = int(data.get("reputation", 0)) + int(attention.get("reputation", 0))
	if attention.has("contact") and typeof(attention["contact"]) == TYPE_DICTIONARY:
		var contact: Dictionary = attention["contact"]
		if not contact.is_empty():
			data["contacts"].push_front(contact)
			while data["contacts"].size() > 6:
				data["contacts"].pop_back()

	var placements_after := int(record.get("placements", 0))
	var mmr_after := int(record["mmr"])
	var new_rank_data := GameDataRef.rl_rank_for_mmr(mmr_after, format) if mode == "Rocket League" else GameDataRef.rank_for_mmr(mmr_after)
	var new_rank := "UNRANKED" if mode == "Rocket League" and placements_after < placement_target(mode) else str(new_rank_data["name"])
	data["history"].push_front({
		"kind": "ranked",
		"mode": mode,
		"format": format,
		"opponent": opponent,
		"opponent_mmr": opponent_mmr,
		"opponent_profile": str(profile["label"]),
		"won": won,
		"score": events[events.size() - 1]["score"],
		"mmr_delta": mmr_delta,
		"mmr_before": mmr_before,
		"mmr_after": mmr_after,
		"old_rank": old_rank,
		"new_rank": new_rank,
		"timestamp": int(Time.get_unix_time_from_system()),
	})
	while data["history"].size() > 20:
		data["history"].pop_back()
	data["week"] = int(data.get("week", 1)) + 1
	if int(data["week"]) > 12:
		_finish_season()
	save_game()
	return {
		"ok": true,
		"mode": mode,
		"format": format,
		"opponent": opponent,
		"opponent_mmr": opponent_mmr,
		"opponent_profile": profile,
		"won": won,
		"events": events,
		"score": events[events.size() - 1]["score"],
		"mmr_delta": mmr_delta,
		"mmr_before": mmr_before,
		"mmr_after": mmr_after,
		"cash": 0,
		"fans": 0,
		"attention": attention,
		"streaming": bool(stream.get("live", false)),
		"stream_viewers": int(stream.get("viewers", 0)),
		"live_chat": stream.get("chat", []),
		"comments": stream.get("comments", []),
		"stream_followers": int(stream.get("followers", 0)),
		"old_rank": old_rank,
		"new_rank": new_rank,
		"old_rank_data": old_rank_data,
		"new_rank_data": new_rank_data,
		"opponent_rank_data": GameDataRef.rl_rank_for_mmr(opponent_mmr, format) if mode == "Rocket League" else {},
		"placements_before": placements_before,
		"placements_after": placements_after,
		"division_progress": RankedDataRef.progress_for_mmr(mmr_after, format) if mode == "Rocket League" else {},
		"rank_revealed": (
			mode == "Rocket League"
			and placements_before < placement_target(mode)
			and placements_after >= placement_target(mode)
		),
		"promoted": (
			old_rank != new_rank
			and mmr_delta > 0
			and placements_before >= placement_target(mode)
		),
		"demoted": (
			old_rank != new_rank
			and mmr_delta < 0
			and placements_before >= placement_target(mode)
		),
	}


func _competitive_strength(mode: String, format: String) -> float:
	var roster := roster_for(mode)
	if roster.is_empty():
		return 0.0
	var count := roster.size()
	if mode == "Rocket League":
		count = mini(count, playlist_required_players(format))
	var total := 0.0
	for index in range(count):
		var player: Dictionary = roster[index]
		var base := float(player_overall(player))
		var form_bonus := float(int(player.get("form", 50)) - 50) * 0.08
		var fatigue_penalty := float(int(player.get("fatigue", 0))) * 0.055
		total += base + form_bonus - fatigue_penalty
	return total / float(maxi(1, count))

func _create_match_events(mode: String, won: bool) -> Array:
	var events: Array = []
	var our_score := 0
	var their_score := 0
	for index in range(9):
		var type := "neutral"
		var roll := rng.randf()
		var good_bias := 0.58 if won else 0.35
		if roll < good_bias:
			type = "good"
			if rng.randf() < 0.58:
				our_score += 1
		elif roll < 0.82:
			type = "bad"
			if rng.randf() < 0.56:
				their_score += 1
		var lines: Array = GameDataRef.EVENT_LINES[mode][type]
		(
			events
			. append(
				{
					"time": _event_time(mode, index),
					"type": type,
					"text": lines[rng.randi_range(0, lines.size() - 1)],
					"score": "%d - %d" % [our_score, their_score],
				}
			)
		)
	if won and our_score <= their_score:
		our_score = their_score + 1
	elif not won and their_score <= our_score:
		their_score = our_score + 1
	events[events.size() - 1]["score"] = "%d - %d" % [our_score, their_score]
	events[events.size() - 1]["text"] = (
		"The final moment confirms a hard-earned victory."
		if won
		else "The series ends, but the review already starts."
	)
	events[events.size() - 1]["type"] = "good" if won else "bad"
	return events


func _event_time(mode: String, index: int) -> String:
	if mode == "Rocket League":
		var seconds_left := maxi(0, 300 - index * 34)
		return "%d:%02d" % [seconds_left / 60, seconds_left % 60]
	if mode == "Fortnite":
		return "ZONE %d" % mini(9, index + 1)
	return "CIRCLE %d" % mini(9, index + 1)


func _finish_season() -> void:
	data["season"] = int(data.get("season", 1)) + 1
	data["week"] = 1
	data["season_bonus"] = 0
	for playlist in RankedDataRef.PLAYLISTS:
		var record := playlist_record(playlist)
		record["season_wins"] = 0
		record["season_losses"] = 0
		record["season_peak_mmr"] = int(record.get("mmr", 600))

func sponsor_eligible() -> bool:
	var followers := int(data.get("streaming", {}).get("followers", 0))
	return int(data.get("reputation", 0)) >= 3 and (int(data.get("fans", 0)) >= 100 or followers >= 120)


func match_format(mode: String) -> String:
	if mode == "Rocket League":
		return selected_rl_playlist()
	var size := roster_for(mode).size()
	return "Squad" if size > 0 else "LOCKED"


func streaming_enabled() -> bool:
	return bool(data.get("streaming", {}).get("enabled", false))


func set_streaming_enabled(enabled: bool) -> Dictionary:
	data["streaming"]["enabled"] = enabled
	save_game()
	return {
		"ok": true,
		"message": "Stream armed for the next match." if enabled else "Streaming switched off.",
	}


func stream_plan() -> String:
	var streaming: Dictionary = data.get("streaming", {})
	var plan := str(streaming.get("plan", "Free"))
	if plan != "Free" and int(Time.get_unix_time_from_system()) >= int(streaming.get("plan_until", 0)):
		streaming["plan"] = "Free"
		streaming["plan_until"] = 0
		plan = "Free"
	return plan


func stream_plan_cost(plan: String) -> int:
	if plan == "Creator":
		return 8
	if plan == "Pro":
		return 20
	return 0


func buy_stream_plan(plan: String) -> Dictionary:
	if plan not in ["Creator", "Pro"]:
		return {"ok": false, "message": "Unknown streaming plan."}
	var cost := stream_plan_cost(plan)
	if int(data.get("cash", 0)) < cost:
		return {"ok": false, "message": "You cannot afford the %s plan yet." % plan}
	data["cash"] = int(data["cash"]) - cost
	data["streaming"]["plan"] = plan
	data["streaming"]["plan_until"] = int(Time.get_unix_time_from_system()) + 30 * 24 * 60 * 60
	save_game()
	return {
		"ok": true,
		"message": "%s activated for 30 days. Better tools, not guaranteed viewers." % plan,
	}


func accept_contact(contact_id: String) -> Dictionary:
	var selected: Dictionary = {}
	for contact in data.get("contacts", []):
		if str(contact.get("id", "")) == contact_id:
			selected = contact
			break
	if selected.is_empty():
		return {"ok": false, "message": "That contact is no longer available."}
	var mode := str(selected.get("mode", "Rocket League"))
	if roster_for(mode).size() >= 3:
		return {"ok": false, "message": "The %s roster is already full." % mode}
	var player := selected.duplicate(true)
	player["id"] = "player_%d" % int(Time.get_ticks_msec())
	player["form"] = 52
	player["fatigue"] = 0
	player.erase("source")
	data["roster"].append(player)
	data["contacts"].erase(selected)
	save_game()
	var available_format := "%dv%d" % [roster_for(mode).size(), roster_for(mode).size()]
	return {
		"ok": true,
		"message": "%s joined your %s grind. %s is now available." % [player["name"], mode, available_format],
	}


func play_community_cup(mode: String) -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	if int(mode_record(mode).get("played", 0)) < 3:
		return {"ok": false, "message": "Play at least 3 ranked matches before entering a community cup."}
	if now < int(data.get("cup_ready_at", 0)):
		return {"ok": false, "message": "No new community cup is open yet."}
	var entry_fee := 0 if int(data.get("reputation", 0)) < 4 else 5
	if int(data.get("cash", 0)) < entry_fee:
		return {"ok": false, "message": "You need %s for the entry fee." % GameDataRef.format_cash(entry_fee)}
	data["cash"] = int(data["cash"]) - entry_fee
	var strength := float(team_overall(mode))
	var win_chance := clampf(0.34 + (strength - 55.0) * 0.018, 0.16, 0.72)
	var won := rng.randf() <= win_chance
	var prize := 0
	if won:
		prize = rng.randi_range(12, 35) + int(data.get("reputation", 0)) * 2
		data["cash"] = int(data["cash"]) + prize
		data["fans"] = int(data["fans"]) + rng.randi_range(2, 8)
		data["reputation"] = int(data["reputation"]) + 1
		data["earned_prize_money"] = int(data.get("earned_prize_money", 0)) + prize
	data["cup_ready_at"] = now + 30 * 60
	data["history"].push_front({
		"kind": "cup",
		"mode": mode,
		"format": match_format(mode),
		"opponent": "Community Open",
		"won": won,
		"score": "WIN" if won else "OUT",
		"mmr_delta": 0,
		"timestamp": now,
	})
	while data["history"].size() > 10:
		data["history"].pop_back()
	save_game()
	return {
		"ok": true,
		"message": ("Cup win: +%s prize money." % GameDataRef.format_cash(prize)) if won else "You were knocked out. Ranked still pays €0 — cups are where money starts.",
	}


func _roll_opponent_profile() -> Dictionary:
	var roll := rng.randf()
	if roll < 0.08:
		return {"key": "smurf", "label": "SMURF / UNDERRANKED", "strength_mod": 12.0, "attention_mult": 1.8}
	if roll < 0.14:
		return {"key": "boosted", "label": "BOOSTED PLAYER", "strength_mod": -10.0, "attention_mult": 0.7}
	if roll < 0.22:
		return {"key": "peaking", "label": "PEAKING TODAY", "strength_mod": 5.0, "attention_mult": 1.25}
	if roll < 0.30:
		return {"key": "tilted", "label": "TILTED", "strength_mod": -5.0, "attention_mult": 0.85}
	if roll < 0.36:
		return {"key": "returning", "label": "RETURNING PLAYER", "strength_mod": 7.0, "attention_mult": 1.35}
	return {"key": "normal", "label": "NORMAL MATCH", "strength_mod": 0.0, "attention_mult": 1.0}


func _attention_roll(
	won: bool, profile: Dictionary, mode: String, format: String, viewers: int
) -> Dictionary:
	var chance := 0.08
	if won:
		chance += 0.08
	if str(profile.get("key", "normal")) == "smurf":
		chance += 0.12
	chance += minf(0.12, float(viewers) * 0.006)
	chance *= float(profile.get("attention_mult", 1.0))
	if rng.randf() > chance:
		return {"points": 0, "reputation": 0, "text": "No unusual attention after this match."}
	var roll := rng.randf()
	var points := rng.randi_range(1, 4)
	var reputation_gain := 0
	var text := ""
	var contact: Dictionary = {}
	if roll < 0.48:
		text = "Your opponent checked your profile after the match."
		if rng.randf() < 0.45:
			contact = _make_contact(mode, "Opponent")
			text = "%s sent you a queue request after the match." % contact["name"]
	elif roll < 0.68 and format != "1v1":
		contact = _make_contact(mode, "Random teammate")
		text = "%s, a random teammate, wants to queue again." % contact["name"]
	elif roll < 0.88:
		text = "A small clip from the match started getting shared."
		points += 2
	else:
		text = "A small tournament organizer noticed your recent results."
		points += 3
		reputation_gain = 1
	return {"points": points, "reputation": reputation_gain, "text": text, "contact": contact}


func _make_contact(mode: String, source: String) -> Dictionary:
	var base := clampi(team_overall(mode) + rng.randi_range(-4, 6), 45, 88)
	var potential := clampi(base + rng.randi_range(8, 20), base + 2, 99)
	return {
		"id": "contact_%d_%d" % [int(Time.get_ticks_msec()), rng.randi_range(100, 999)],
		"name": GameDataRef.FIRST_NAMES[rng.randi_range(0, GameDataRef.FIRST_NAMES.size() - 1)],
		"mode": mode,
		"role": _role_for_mode(mode, roster_for(mode).size()),
		"region": GameDataRef.REGIONS[rng.randi_range(0, GameDataRef.REGIONS.size() - 1)],
		"age": rng.randi_range(16, 22),
		"mechanics": clampi(base + rng.randi_range(-4, 5), 35, 95),
		"game_sense": clampi(base + rng.randi_range(-4, 5), 35, 95),
		"teamwork": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"mentality": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"potential": potential,
		"source": source,
	}


func _stream_payload(won: bool, profile: Dictionary, format: String) -> Dictionary:
	if not streaming_enabled():
		return {"live": false, "viewers": 0, "chat": [], "comments": [], "followers": 0}
	var stream_data: Dictionary = data["streaming"]
	var plan := stream_plan()
	var followers := int(stream_data.get("followers", 0))
	var plan_mult := 1.0
	if plan == "Creator":
		plan_mult = 1.12
	elif plan == "Pro":
		plan_mult = 1.28
	var viewers := int(round(float(1 + followers / 25 + int(data.get("reputation", 0)) / 2) * plan_mult))
	viewers += rng.randi_range(0, 2)
	if won:
		viewers += 1
	if str(profile.get("key", "normal")) in ["smurf", "peaking", "returning"]:
		viewers += rng.randi_range(1, 3)
	viewers = maxi(1, viewers)

	var chat_templates := [
		"clean",
		"nice read",
		"gg",
		"that was actually good",
		"who is TSK?",
		"bro is underrated",
		"queue again",
		"that opponent looks way better than this rank",
	]
	var comment_templates := [
		"bro is actually underrated",
		"played against this guy before, solid",
		"that match was closer than the rank says",
		"who even is TSK?",
		"the grind from zero is kinda fire",
		"clean game",
	]
	var chat: Array = []
	var chat_count := mini(7, maxi(1, viewers / 2))
	for index in range(chat_count):
		chat.append({
			"user": "viewer_%d" % rng.randi_range(10, 999),
			"text": chat_templates[rng.randi_range(0, chat_templates.size() - 1)],
		})
	var comments: Array = []
	var comment_count := mini(4, viewers / 3)
	for index in range(comment_count):
		comments.append({
			"user": "user_%d" % rng.randi_range(100, 9999),
			"text": comment_templates[rng.randi_range(0, comment_templates.size() - 1)],
		})
	var follower_gain := 0
	if viewers >= 2:
		follower_gain = rng.randi_range(0, maxi(1, viewers / 3))
		if won and rng.randf() < 0.45:
			follower_gain += 1
	stream_data["followers"] = followers + follower_gain
	stream_data["total_views"] = int(stream_data.get("total_views", 0)) + viewers
	stream_data["peak_viewers"] = maxi(int(stream_data.get("peak_viewers", 0)), viewers)
	stream_data["last_comments"] = comments
	return {
		"live": true,
		"viewers": viewers,
		"chat": chat,
		"comments": comments,
		"followers": follower_gain,
		"format": format,
	}


func _find_player(player_id: String) -> Dictionary:
	for player in data.get("roster", []):
		if str(player.get("id", "")) == player_id:
			return player
	return {}


func _role_for_mode(mode: String, index: int) -> String:
	var slot := index % 3
	if mode == "Rocket League":
		return ["First Man", "Playmaker", "Anchor"][slot]
	if mode == "Fortnite":
		return ["IGL", "Fragger", "Support"][slot]
	return ["IGL", "Slayer", "Flex"][slot]


func _migrate_save(from_version: int) -> void:
	# v0.4.5 keeps every v0.4.4 resource and progression value. Only the
	# playlist records receive the new season, peak and history fields.
	if not data.has("rl_playlists") or typeof(data["rl_playlists"]) != TYPE_DICTIONARY:
		var legacy_mmr := 600
		if data.has("modes") and typeof(data["modes"]) == TYPE_DICTIONARY:
			legacy_mmr = int(data["modes"].get("Rocket League", {}).get("mmr", 600))
		data["rl_playlists"] = {
			"1v1": _new_ranked_record(legacy_mmr),
			"2v2": _new_ranked_record(600),
			"3v3": _new_ranked_record(600),
		}
	for playlist in RankedDataRef.PLAYLISTS:
		if not data["rl_playlists"].has(playlist) or typeof(data["rl_playlists"][playlist]) != TYPE_DICTIONARY:
			data["rl_playlists"][playlist] = _new_ranked_record(600)
		var record: Dictionary = data["rl_playlists"][playlist]
		var current_mmr := int(record.get("mmr", 600))
		if not record.has("peak_mmr"):
			record["peak_mmr"] = current_mmr
		if not record.has("season_peak_mmr"):
			record["season_peak_mmr"] = current_mmr
		if not record.has("season_wins"):
			record["season_wins"] = int(record.get("wins", 0))
		if not record.has("season_losses"):
			record["season_losses"] = int(record.get("losses", 0))
		if not record.has("mmr_history") or typeof(record["mmr_history"]) != TYPE_ARRAY:
			record["mmr_history"] = [current_mmr]
		if not record.has("last_results") or typeof(record["last_results"]) != TYPE_ARRAY:
			record["last_results"] = []
	data["selected_rl_playlist"] = RankedDataRef.normalize_playlist(str(data.get("selected_rl_playlist", "1v1")))
	if from_version < 5:
		data["version"] = 5


func _new_ranked_record(starting_mmr: int = 600) -> Dictionary:
	return {
		"mmr": starting_mmr,
		"wins": 0,
		"losses": 0,
		"played": 0,
		"placements": 0,
		"streak": 0,
		"peak_mmr": starting_mmr,
		"season_peak_mmr": starting_mmr,
		"season_wins": 0,
		"season_losses": 0,
		"mmr_history": [starting_mmr],
		"last_results": [],
	}


func _new_save() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	return {
		"version": GameDataRef.VERSION,
		"club_name": "TSK ESPORTS",
		"cash": 0,
		"fans": 0,
		"reputation": 0,
		"attention": 0,
		"energy": 100,
		"season": 1,
		"week": 1,
		"selected_mode": "Rocket League",
		"selected_rl_playlist": "1v1",
		"last_seen": now,
		"sponsor_ready_at": 0,
		"season_bonus": 0,
		"cup_ready_at": 0,
		"earned_prize_money": 0,
		"facilities": {"hq": 0, "coaching": 0, "scouting": 0, "analytics": 0, "studio": 0},
		"rl_playlists": {
			"1v1": _new_ranked_record(600),
			"2v2": _new_ranked_record(600),
			"3v3": _new_ranked_record(600),
		},
		"modes": {
			"Rocket League": {"mmr": 600, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
			"Fortnite": {"mmr": 600, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
			"Warzone": {"mmr": 600, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
		},
		"roster": _starter_roster(),
		"contacts": [],
		"streaming": {
			"enabled": false,
			"platform": "PulseLive",
			"plan": "Free",
			"plan_until": 0,
			"followers": 0,
			"total_views": 0,
			"peak_viewers": 0,
			"last_comments": [],
		},
		"market": [],
		"history": [],
	}

func _starter_roster() -> Array:
	return [
		_player("captain", "KESHI", "Rocket League", "Captain", "EU", 58, 58, 55, 60, 92),
	]

func _player(
	id: String,
	nickname: String,
	mode: String,
	role: String,
	region: String,
	mechanics: int,
	game_sense: int,
	teamwork: int,
	mentality: int,
	potential: int
) -> Dictionary:
	return {
		"id": id,
		"name": nickname,
		"mode": mode,
		"role": role,
		"region": region,
		"age": 18,
		"mechanics": mechanics,
		"game_sense": game_sense,
		"teamwork": teamwork,
		"mentality": mentality,
		"potential": potential,
		"form": 55,
		"fatigue": 0,
	}


func _merge_defaults(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults:
		if not target.has(key):
			target[key] = _clone_value(defaults[key])
		elif typeof(target[key]) == TYPE_DICTIONARY and typeof(defaults[key]) == TYPE_DICTIONARY:
			_merge_defaults(target[key], defaults[key])


func _clone_value(value):
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value
