class_name EmpireState
extends RefCounted

const SAVE_PATH := "user://e_sport_empire_save.json"
const GameDataRef = preload("res://scripts/game_data.gd")

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
				if int(parsed.get("version", 0)) < GameDataRef.VERSION:
					data = _new_save()
					data["fresh_origin"] = true
				else:
					data = parsed
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
	return data["modes"][mode]


func mode_mmr(mode: String) -> int:
	return int(mode_record(mode).get("mmr", 850))


func rank_data(mode: String) -> Dictionary:
	return GameDataRef.rank_for_mmr(mode_mmr(mode))


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
	var cost := 450
	if charge and int(data["cash"]) < cost:
		return {"ok": false, "message": "Not enough cash to refresh scouting."}
	if charge:
		data["cash"] = int(data["cash"]) - cost
	var scouting := facility_level("scouting")
	var prospects: Array = []
	for index in range(6):
		var mode: String = GameDataRef.MODES[index % GameDataRef.MODES.size()]
		var base := rng.randi_range(52 + scouting, 65 + scouting * 2)
		base = clampi(base, 48, 91)
		var potential := clampi(base + rng.randi_range(7, 18 + scouting), base + 2, 99)
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
		player["contract"] = (
			1200 + player_overall(player) * player_overall(player) * 2 + potential * 35
		)
		prospects.append(player)
	data["market"] = prospects
	if charge:
		save_game()
	return {"ok": true, "message": "The scouting board has been refreshed."}


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
	return int(Time.get_unix_time_from_system()) >= int(data.get("sponsor_ready_at", 0))


func sponsor_seconds_left() -> int:
	return maxi(0, int(data.get("sponsor_ready_at", 0)) - int(Time.get_unix_time_from_system()))


func collect_sponsor() -> Dictionary:
	if not sponsor_ready():
		return {"ok": false, "message": "The next sponsor activation is not ready yet."}
	var reward := 2400 + facility_level("hq") * 850 + int(data["reputation"]) * 55
	var fan_reward := 120 + facility_level("studio") * 45
	data["cash"] = int(data["cash"]) + reward
	data["fans"] = int(data["fans"]) + fan_reward
	data["sponsor_ready_at"] = int(Time.get_unix_time_from_system()) + 60 * 60
	save_game()
	return {
		"ok": true,
		"message":
		(
			"Sponsor activated: +%s and +%s fans."
			% [GameDataRef.format_cash(reward), GameDataRef.format_number(fan_reward)]
		),
	}


func create_match(mode: String) -> Dictionary:
	var record := mode_record(mode)
	var mmr := int(record.get("mmr", 850))
	var player_strength := float(team_overall(mode))
	player_strength += float(facility_level("analytics") - 1) * 0.85
	player_strength += float(facility_level("coaching") - 1) * 0.35
	var expected_strength := 55.0 + float(mmr - 800) / 25.0
	var opponent_strength := clampf(expected_strength + rng.randf_range(-4.8, 4.8), 45.0, 98.0)
	var advantage := player_strength - opponent_strength
	var win_chance := clampf(0.5 + advantage * 0.035, 0.16, 0.84)
	var won := rng.randf() <= win_chance
	var opponent_names: Array = GameDataRef.OPPONENTS[mode]
	var opponent: String = opponent_names[rng.randi_range(0, opponent_names.size() - 1)]
	var events := _create_match_events(mode, won)
	var mmr_delta := rng.randi_range(18, 29)
	if int(record.get("placements", 0)) < 5:
		mmr_delta += rng.randi_range(20, 34)
	if not won:
		mmr_delta *= -1
	var old_rank := str(GameDataRef.rank_for_mmr(mmr)["name"])
	record["mmr"] = maxi(0, mmr + mmr_delta)
	record["played"] = int(record.get("played", 0)) + 1
	if won:
		record["wins"] = int(record.get("wins", 0)) + 1
		record["streak"] = maxi(1, int(record.get("streak", 0)) + 1)
	else:
		record["losses"] = int(record.get("losses", 0)) + 1
		record["streak"] = mini(-1, int(record.get("streak", 0)) - 1)
	record["placements"] = mini(5, int(record.get("placements", 0)) + 1)
	var cash_reward := (2300 if won else 850) + facility_level("hq") * 140
	var fan_reward := (180 if won else 38) + facility_level("studio") * 14
	data["cash"] = int(data["cash"]) + cash_reward
	data["fans"] = maxi(0, int(data["fans"]) + fan_reward)
	data["energy"] = maxi(0, int(data["energy"]) - 7)
	if won:
		data["reputation"] = int(data["reputation"]) + 1
	for player in roster_for(mode):
		player["fatigue"] = clampi(int(player.get("fatigue", 0)) + rng.randi_range(4, 9), 0, 100)
		player["form"] = clampi(
			(
				int(player.get("form", 50))
				+ (rng.randi_range(2, 6) if won else -rng.randi_range(1, 4))
			),
			25,
			100
		)
	var new_rank := str(GameDataRef.rank_for_mmr(int(record["mmr"]))["name"])
	var history_entry := {
		"mode": mode,
		"opponent": opponent,
		"won": won,
		"score": events[events.size() - 1]["score"],
		"mmr_delta": mmr_delta,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	data["history"].push_front(history_entry)
	while data["history"].size() > 8:
		data["history"].pop_back()
	data["week"] = int(data.get("week", 1)) + 1
	if int(data["week"]) > 12:
		_finish_season()
	save_game()
	return {
		"mode": mode,
		"opponent": opponent,
		"won": won,
		"events": events,
		"score": events[events.size() - 1]["score"],
		"mmr_delta": mmr_delta,
		"cash": cash_reward,
		"fans": fan_reward,
		"old_rank": old_rank,
		"new_rank": new_rank,
		"promoted": old_rank != new_rank and mmr_delta > 0,
	}


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
	var best_mmr := 0
	for mode in GameDataRef.MODES:
		best_mmr = maxi(best_mmr, int(data["modes"][mode]["mmr"]))
	var bonus := 5000 + maxi(0, best_mmr - 700) * 12
	data["cash"] = int(data["cash"]) + bonus
	data["season"] = int(data.get("season", 1)) + 1
	data["week"] = 1
	data["season_bonus"] = bonus


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


func _new_save() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	return {
		"version": GameDataRef.VERSION,
		"club_name": "TSK ESPORTS",
		"cash": 25000,
		"fans": 2400,
		"reputation": 12,
		"energy": 100,
		"season": 1,
		"week": 1,
		"selected_mode": "Rocket League",
		"last_seen": now,
		"sponsor_ready_at": 0,
		"season_bonus": 0,
		"facilities":
		{
			"hq": 1,
			"coaching": 1,
			"scouting": 1,
			"analytics": 1,
			"studio": 1,
		},
		"modes":
		{
			"Rocket League":
			{"mmr": 860, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
			"Fortnite":
			{"mmr": 840, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
			"Warzone":
			{"mmr": 820, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
		},
		"roster": _starter_roster(),
		"market": [],
		"history": [],
	}


func _starter_roster() -> Array:
	return [
		_player("p_rl_1", "KESHI", "Rocket League", "First Man", "EU", 68, 72, 65, 66, 84),
		_player("p_rl_2", "NOVA", "Rocket League", "Playmaker", "EU", 64, 70, 72, 63, 82),
		_player("p_rl_3", "RIFT", "Rocket League", "Anchor", "MENA", 66, 73, 68, 69, 86),
		_player("p_fn_1", "VEX", "Fortnite", "IGL", "EU", 61, 72, 67, 70, 83),
		_player("p_fn_2", "ARCO", "Fortnite", "Fragger", "NA", 72, 62, 64, 61, 88),
		_player("p_fn_3", "MIST", "Fortnite", "Support", "EU", 63, 68, 73, 67, 81),
		_player("p_wz_1", "KILO", "Warzone", "IGL", "EU", 65, 72, 69, 68, 84),
		_player("p_wz_2", "VANTA", "Warzone", "Slayer", "NA", 71, 63, 64, 62, 87),
		_player("p_wz_3", "GHOST", "Warzone", "Flex", "EU", 66, 67, 71, 65, 82),
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
