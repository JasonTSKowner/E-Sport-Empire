class_name EmpireState
extends RefCounted

const SAVE_PATH := "user://e_sport_empire_save.json"
const GameDataRef = preload("res://scripts/game_data.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")
const TitleDataRef = preload("res://scripts/title_data.gd")
const DevelopmentDataRef = preload("res://scripts/development_data.gd")
const TRAINING_COOLDOWN_WEEKS := 3
const RECOVERY_COOLDOWN_WEEKS := 3

const MATCH_ACTIONS := [
	{
		"key": "press",
		"label": "HIGH PRESS",
		"detail": "Take space immediately. Strong against CONTROL. Costs 18 boost.",
		"boost_delta": -18,
		"minimum_boost": 18,
	},
	{
		"key": "control",
		"label": "BOOST CONTROL",
		"detail": "Keep possession and recharge. Strong against COUNTER. Gains 18 boost.",
		"boost_delta": 18,
		"minimum_boost": 0,
	},
	{
		"key": "counter",
		"label": "FAST COUNTER",
		"detail": "Absorb pressure, then attack the open field. Strong against PRESS. Costs 10 boost.",
		"boost_delta": -10,
		"minimum_boost": 10,
	},
]

const TACTIC_COUNTER := {
	"press": "counter",
	"control": "press",
	"counter": "control",
}

const MATCH_SITUATIONS := {
	"press": {
		"title": "OPPONENT: HIGH PRESS",
		"read": "They commit early, challenge fast and try to starve your boost.",
	},
	"control": {
		"title": "OPPONENT: SLOW CONTROL",
		"read": "They protect possession and wait for your rotation to open.",
	},
	"counter": {
		"title": "OPPONENT: LOW BLOCK",
		"read": "They invite pressure and look for one fast counterattack.",
	},
}

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


func earned_titles() -> Array:
	return data.get("earned_titles", [])


func equipped_title() -> Dictionary:
	var equipped_id := str(data.get("equipped_title_id", ""))
	if equipped_id.is_empty():
		return {}
	for title in earned_titles():
		if str(title.get("id", "")) == equipped_id:
			return title
	return {}


func equip_title(title_id: String) -> Dictionary:
	for title in earned_titles():
		if str(title.get("id", "")) == title_id:
			data["equipped_title_id"] = title_id
			save_game()
			return {"ok": true, "message": "%s equipped." % str(title.get("label", "Title"))}
	return {"ok": false, "message": "That title has not been earned."}


func clear_equipped_title() -> Dictionary:
	data["equipped_title_id"] = ""
	save_game()
	return {"ok": true, "message": "Title unequipped."}


func _grant_title(title: Dictionary) -> bool:
	var title_id := str(title.get("id", ""))
	if title_id.is_empty():
		return false
	for earned in earned_titles():
		if str(earned.get("id", "")) == title_id:
			return false
	data["earned_titles"].push_front(title.duplicate(true))
	if str(data.get("equipped_title_id", "")).is_empty():
		data["equipped_title_id"] = title_id
	return true


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
		int(player.get("mechanics", 50)) * 18
		+ int(player.get("rotation", player.get("teamwork", 50))) * 16
		+ int(player.get("shooting", player.get("mechanics", 50))) * 14
		+ int(player.get("defense", player.get("game_sense", 50))) * 14
		+ int(player.get("game_sense", 50)) * 14
		+ int(player.get("boost_control", player.get("game_sense", 50))) * 10
		+ int(player.get("consistency", player.get("mentality", 50))) * 8
		+ int(player.get("mentality", 50)) * 6
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


func team_attribute_average(mode: String, stat_key: String, format: String = "") -> int:
	var roster := roster_for(mode)
	if roster.is_empty():
		return 0
	var count := roster.size()
	if mode == "Rocket League" and not format.is_empty():
		count = mini(count, playlist_required_players(format))
	var total := 0
	for index in range(count):
		total += int(roster[index].get(stat_key, 50))
	return int(round(float(total) / float(maxi(1, count))))


func team_development_snapshot(mode: String, format: String = "") -> Dictionary:
	var snapshot: Dictionary = {}
	for definition_value in DevelopmentDataRef.PLAYER_STATS:
		var definition: Dictionary = definition_value
		var stat_key := str(definition.get("key", ""))
		snapshot[stat_key] = team_attribute_average(mode, stat_key, format)
	return snapshot


func mode_record(mode: String) -> Dictionary:
	if mode == "Rocket League":
		return playlist_record(selected_rl_playlist())
	return data["modes"][mode]

func mode_mmr(mode: String) -> int:
	return int(mode_record(mode).get("mmr", 100 if mode == "Rocket League" else 600))

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


func development_programs() -> Array:
	return DevelopmentDataRef.TRAINING_PROGRAMS.duplicate(true)


func training_cost(player: Dictionary, program_id: String = "mechanics_lab") -> int:
	var program := DevelopmentDataRef.program(program_id)
	if program.is_empty():
		return 0
	var raw_cost := float(program.get("base_cost", 15))
	raw_cost += float(player_overall(player)) * float(program.get("rating_scale", 0.32))
	var coaching_discount := minf(0.25, float(facility_level("coaching")) * 0.025)
	return maxi(8, int(round(raw_cost * (1.0 - coaching_discount))))


func current_week_key() -> int:
	return (int(data.get("season", 1)) - 1) * 12 + int(data.get("week", 1))


func can_train_player(player: Dictionary) -> bool:
	var last_week := int(player.get("last_training_week", -1))
	return last_week < 0 or current_week_key() - last_week >= TRAINING_COOLDOWN_WEEKS


func training_weeks_left(player: Dictionary) -> int:
	var last_week := int(player.get("last_training_week", -1))
	if last_week < 0:
		return 0
	return maxi(0, TRAINING_COOLDOWN_WEEKS - (current_week_key() - last_week))


func can_rest_team(mode: String) -> bool:
	var rest_weeks: Dictionary = data.get("last_rest_week", {})
	var last_week := int(rest_weeks.get(mode, -1))
	return last_week < 0 or current_week_key() - last_week >= RECOVERY_COOLDOWN_WEEKS

func train_player(player_id: String, program_id: String = "mechanics_lab") -> Dictionary:
	var player := _find_player(player_id)
	if player.is_empty():
		return {"ok": false, "message": "Player not found."}
	var program := DevelopmentDataRef.program(program_id)
	if program.is_empty():
		return {"ok": false, "message": "Unknown development program."}
	if not can_train_player(player):
		return {
			"ok": false,
			"message": "%s returns to training in %d week(s). Play ranked matches to advance the schedule."
			% [str(player.get("name", "Player")), training_weeks_left(player)],
		}
	var cost := training_cost(player, program_id)
	if int(data["cash"]) < cost:
		return {
			"ok": false,
			"message": "You need %s for %s."
			% [GameDataRef.format_cash(cost), str(program.get("label", "training"))],
		}
	var energy_cost := int(program.get("energy", 8))
	if int(data["energy"]) < energy_cost:
		return {"ok": false, "message": "The staff needs more energy."}
	var potential := int(player.get("potential", 99))
	var program_gains: Dictionary = program.get("gains", {})
	var unlocked_before: Array = DevelopmentDataRef.unlocked_mechanics(player)
	var unlocked_before_ids: Array[String] = []
	for move_value in unlocked_before:
		var move: Dictionary = move_value
		unlocked_before_ids.append(str(move.get("id", "")))
	var has_development_room := false
	for stat_key in program_gains:
		if int(player.get(stat_key, 50)) < potential:
			has_development_room = true
			break
	if not has_development_room:
		return {"ok": false, "message": "This program cannot push the player beyond their potential."}
	var coaching := facility_level("coaching")
	var primary := str(program.get("primary", ""))
	var breakthrough := rng.randf() < minf(0.48, 0.12 + float(coaching) * 0.04)
	var applied_gains: Dictionary = {}
	for stat_key in program_gains:
		var requested_gain := int(program_gains[stat_key])
		if str(stat_key) == primary and breakthrough:
			requested_gain += 1
		var before := int(player.get(stat_key, 50))
		var after := mini(potential, before + requested_gain)
		player[stat_key] = after
		if after > before:
			applied_gains[stat_key] = after - before
	player["form"] = clampi(int(player.get("form", 50)) + rng.randi_range(2, 6), 25, 100)
	var fatigue_relief := int(floor(float(coaching) / 2.0))
	var fatigue_gain := maxi(1, int(program.get("fatigue", 5)) - fatigue_relief)
	player["fatigue"] = clampi(int(player.get("fatigue", 0)) + fatigue_gain, 0, 100)
	data["cash"] = int(data["cash"]) - cost
	data["energy"] = int(data["energy"]) - energy_cost
	player["last_training_week"] = current_week_key()
	player["last_training_program"] = program_id
	var history: Array = player.get("training_history", [])
	history.push_front({
		"week": current_week_key(),
		"program": program_id,
		"cost": cost,
		"gains": applied_gains.duplicate(true),
	})
	while history.size() > 10:
		history.pop_back()
	player["training_history"] = history
	save_game()
	var gain_parts: Array[String] = []
	for stat_key in applied_gains:
		var stat_definition := DevelopmentDataRef.stat_definition(str(stat_key))
		gain_parts.append(
			"+%d %s"
			% [int(applied_gains[stat_key]), str(stat_definition.get("label", stat_key))]
		)
	var new_mechanics: Array = []
	for move_value in DevelopmentDataRef.unlocked_mechanics(player):
		var move: Dictionary = move_value
		if str(move.get("id", "")) not in unlocked_before_ids:
			new_mechanics.append(move)
	var unlock_suffix := ""
	if not new_mechanics.is_empty():
		var unlock_names: Array[String] = []
		for move_value in new_mechanics:
			var move: Dictionary = move_value
			unlock_names.append(str(move.get("label", "New mechanic")))
		unlock_suffix = " • UNLOCKED: %s" % ", ".join(unlock_names)
	return {
		"ok": true,
		"message": "%s completed %s for %s: %s%s."
		% [
			player["name"],
			str(program.get("label", "training")),
			GameDataRef.format_cash(cost),
			", ".join(gain_parts),
			(" + breakthrough" if breakthrough else "") + unlock_suffix,
		],
		"program": program_id,
		"cost": cost,
		"gains": applied_gains,
		"breakthrough": breakthrough,
		"unlocked_mechanics": new_mechanics,
	}


func unlocked_mechanics(player: Dictionary) -> Array:
	return DevelopmentDataRef.unlocked_mechanics(player)


func next_mechanic(player: Dictionary) -> Dictionary:
	return DevelopmentDataRef.next_mechanic(player)


func rest_team(mode: String) -> Dictionary:
	if not can_rest_team(mode):
		return {"ok": false, "message": "%s recovery is on a three-week cooldown." % mode}
	for player in roster_for(mode):
		player["fatigue"] = maxi(0, int(player.get("fatigue", 0)) - 24)
		player["form"] = clampi(int(player.get("form", 50)) + 2, 25, 100)
	data["energy"] = mini(100, int(data["energy"]) + 12)
	var rest_weeks: Dictionary = data.get("last_rest_week", {})
	rest_weeks[mode] = current_week_key()
	data["last_rest_week"] = rest_weeks
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
			"rotation": clampi(base + rng.randi_range(-4, 5), 35, 95),
			"shooting": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"defense": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"game_sense": clampi(base + rng.randi_range(-4, 5), 35, 95),
			"boost_control": clampi(base + rng.randi_range(-4, 5), 35, 95),
			"consistency": clampi(base + rng.randi_range(-6, 4), 35, 95),
			"teamwork": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"mentality": clampi(base + rng.randi_range(-5, 5), 35, 95),
			"potential": potential,
			"form": rng.randi_range(45, 68),
			"fatigue": 0,
			"last_training_week": -1,
			"last_training_program": "",
			"training_history": [],
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

func match_action_definitions() -> Array:
	return MATCH_ACTIONS.duplicate(true)


func _match_action_definition(action: String) -> Dictionary:
	for definition_value in MATCH_ACTIONS:
		var definition: Dictionary = definition_value
		if str(definition.get("key", "")) == action:
			return definition
	return {}


func can_play_match_action(session: Dictionary, action: String) -> bool:
	var definition: Dictionary = _match_action_definition(action)
	if definition.is_empty():
		return false
	return int(session.get("boost", 0)) >= int(definition.get("minimum_boost", 0))


func prepare_match(mode: String) -> Dictionary:
	var roster := roster_for(mode)
	if roster.is_empty():
		return {"ok": false, "message": "You need at least one active player before queueing."}
	var format := match_format(mode)
	if mode == "Rocket League" and not can_queue_playlist(format):
		return {
			"ok": false,
			"message": "%s requires %d active Rocket League players." % [format, playlist_required_players(format)],
		}
	var record: Dictionary = playlist_record(format) if mode == "Rocket League" else mode_record(mode)
	var mmr_before := int(record.get("mmr", 100 if mode == "Rocket League" else 600))
	var opponent_mmr := _opponent_mmr_for(mmr_before)
	var team_stats := team_development_snapshot(mode, format)
	var player_strength := _competitive_strength(mode, format)
	player_strength += float(facility_level("analytics")) * 0.45
	player_strength += float(facility_level("coaching")) * 0.25
	var consistency := float(team_stats.get("consistency", 50))
	var performance_swing := clampf(5.1 - consistency * 0.045, 0.8, 4.0)
	player_strength += rng.randf_range(-performance_swing, performance_swing)
	var profile: Dictionary = _roll_opponent_profile()
	var expected_strength := 54.0 + float(opponent_mmr - 100) / 30.0
	var opponent_strength := clampf(
		expected_strength + rng.randf_range(-3.5, 3.5) + float(profile["strength_mod"]),
		32.0,
		99.0
	)
	var opponent := ""
	if format == "1v1":
		opponent = str(GameDataRef.FIRST_NAMES[rng.randi_range(0, GameDataRef.FIRST_NAMES.size() - 1)])
	else:
		var opponent_names: Array = GameDataRef.OPPONENTS[mode]
		opponent = opponent_names[rng.randi_range(0, opponent_names.size() - 1)]
	var situations: Array = []
	var situation_keys := ["press", "control", "counter"]
	for index in range(6):
		situations.append(str(situation_keys[rng.randi_range(0, situation_keys.size() - 1)]))
	return {
		"ok": true,
		"resolved": false,
		"mode": mode,
		"format": format,
		"opponent": opponent,
		"opponent_mmr": opponent_mmr,
		"opponent_profile": profile,
		"mmr_before": mmr_before,
		"player_strength": player_strength,
		"opponent_strength": opponent_strength,
		"team_stats": team_stats,
		"turn": 0,
		"regulation_turns": 6,
		"our_score": 0,
		"their_score": 0,
		"decision_score": 0,
		"boost": clampi(25 + int(round(float(team_stats.get("boost_control", 50)) * 0.55)), 35, 78),
		"last_action": "",
		"situations": situations,
		"decisions": [],
		"events": [],
	}


func current_match_situation(session: Dictionary) -> Dictionary:
	if session.is_empty() or not bool(session.get("ok", false)):
		return {}
	var turn := int(session.get("turn", 0))
	var situations: Array = session.get("situations", [])
	var situation_keys := ["press", "control", "counter"]
	while situations.size() <= turn:
		situations.append(str(situation_keys[rng.randi_range(0, situation_keys.size() - 1)]))
	session["situations"] = situations
	var opponent_action := str(situations[turn])
	var source: Dictionary = MATCH_SITUATIONS[opponent_action]
	return {
		"turn": turn,
		"opponent_action": opponent_action,
		"title": str(source["title"]),
		"read": str(source["read"]),
		"overtime": turn >= int(session.get("regulation_turns", 6)),
	}


func play_match_turn(session: Dictionary, action: String) -> Dictionary:
	if bool(session.get("resolved", false)):
		return {"ok": false, "message": "This match is already complete."}
	var action_definition: Dictionary = _match_action_definition(action)
	if action_definition.is_empty():
		return {"ok": false, "message": "Unknown tactical call."}
	if not can_play_match_action(session, action):
		return {"ok": false, "message": "Not enough tactical boost for that call. Use BOOST CONTROL to recharge."}
	var situation: Dictionary = current_match_situation(session)
	if situation.is_empty():
		return {"ok": false, "message": "The match situation could not be loaded."}
	var opponent_action := str(situation["opponent_action"])
	var perfect_action := str(TACTIC_COUNTER[opponent_action])
	var opponent_counter := str(TACTIC_COUNTER[action])
	var tactical_edge := 0
	if action == perfect_action:
		tactical_edge = 1
	elif opponent_action == opponent_counter:
		tactical_edge = -1
	var repeated_call := action == str(session.get("last_action", ""))
	if repeated_call:
		# Repeating a call is readable: even a correct counter loses its full edge.
		tactical_edge = maxi(-1, tactical_edge - 1)
	var boost_before := int(session.get("boost", 45))
	var boost_after := clampi(boost_before + int(action_definition.get("boost_delta", 0)), 0, 100)
	session["boost"] = boost_after
	session["last_action"] = action
	var strength_edge := clampf(
		(float(session.get("player_strength", 50.0)) - float(session.get("opponent_strength", 50.0))) / 100.0,
		-0.18,
		0.18
	)
	var team_stats: Dictionary = session.get("team_stats", {})
	var action_attack := 0.0
	if action == "press":
		action_attack = (
			float(team_stats.get("mechanics", 50))
			+ float(team_stats.get("shooting", 50))
			- 100.0
		) / 1000.0
	elif action == "control":
		action_attack = (
			float(team_stats.get("game_sense", 50))
			+ float(team_stats.get("boost_control", 50))
			- 100.0
		) / 1150.0
	else:
		action_attack = (
			float(team_stats.get("rotation", 50))
			+ float(team_stats.get("shooting", 50))
			- 100.0
		) / 1050.0
	var defensive_edge := (
		float(team_stats.get("defense", 50))
		+ float(team_stats.get("rotation", 50))
		- 100.0
	) / 1050.0
	var our_goal_chance := clampf(
		0.20 + strength_edge + float(tactical_edge) * 0.13 + action_attack,
		0.04,
		0.56
	)
	var their_goal_chance := clampf(
		0.20 - strength_edge - float(tactical_edge) * 0.11 - defensive_edge,
		0.04,
		0.52
	)
	var roll := rng.randf()
	var our_goal := 0
	var their_goal := 0
	if roll < our_goal_chance:
		our_goal = 1
	elif roll < our_goal_chance + their_goal_chance:
		their_goal = 1

	var turn := int(session.get("turn", 0))
	var score_before_ours := int(session.get("our_score", 0))
	var score_before_theirs := int(session.get("their_score", 0))
	var our_score := score_before_ours + our_goal
	var their_score := score_before_theirs + their_goal
	# The eighth decision is a guaranteed overtime decider so a match can
	# never become an endless tapping loop.
	if turn >= 7:
		var decider_chance := clampf(
			0.50
			+ float(int(session.get("decision_score", 0)) + tactical_edge) * 0.045
			+ strength_edge
			+ (float(team_stats.get("mentality", 50)) - 50.0) / 260.0
			+ (float(team_stats.get("consistency", 50)) - 50.0) / 420.0,
			0.16,
			0.84
		)
		if rng.randf() <= decider_chance:
			our_goal = 1
			their_goal = 0
			our_score = score_before_ours + 1
			their_score = score_before_theirs
		else:
			our_goal = 0
			their_goal = 1
			our_score = score_before_ours
			their_score = score_before_theirs + 1

	var event_type := "neutral"
	var event_text := "Both teams trade pressure without giving up the goal."
	if our_goal > 0:
		event_type = "good"
		var signature_text := _signature_goal_text(str(session.get("mode", "Rocket League")))
		if not signature_text.is_empty():
			event_text = signature_text
		elif action == "press":
			event_text = "Your press forces a rushed touch and TSK converts."
		elif action == "control":
			event_text = "Boost control creates space for a composed finish."
		else:
			event_text = "The counter opens the field and TSK scores."
	elif their_goal > 0:
		event_type = "bad"
		if tactical_edge < 0:
			event_text = "The opponent reads your call and punishes the rotation."
		else:
			event_text = "A tight challenge falls their way and the opponent scores."
	elif tactical_edge > 0:
		event_text = "Perfect read. TSK controls the sequence but the shot stays out."
	elif tactical_edge < 0:
		event_text = "The call is countered, but the defense survives the pressure."

	var turn_after := turn + 1
	session["turn"] = turn_after
	session["our_score"] = our_score
	session["their_score"] = their_score
	session["decision_score"] = int(session.get("decision_score", 0)) + tactical_edge
	var feedback := "EVEN READ"
	if tactical_edge > 0:
		feedback = "PERFECT READ"
	elif tactical_edge < 0:
		feedback = "OUTPLAYED"
	if repeated_call and tactical_edge <= 0:
		feedback = "READABLE REPEAT"
	var event := {
		"time": _interactive_event_time(turn),
		"type": event_type,
		"text": event_text,
		"score": "%d - %d" % [our_score, their_score],
		"call": action,
		"feedback": feedback,
		"boost": boost_after,
	}
	var events: Array = session.get("events", [])
	events.append(event)
	session["events"] = events
	var decisions: Array = session.get("decisions", [])
	decisions.append({"turn": turn, "action": action, "opponent_action": opponent_action, "quality": tactical_edge})
	session["decisions"] = decisions
	var regulation_turns := int(session.get("regulation_turns", 6))
	var finished := turn_after >= regulation_turns and our_score != their_score
	return {
		"ok": true,
		"event": event,
		"feedback": feedback,
		"quality": tactical_edge,
		"boost_before": boost_before,
		"boost_after": boost_after,
		"finished": finished,
		"overtime": turn_after >= regulation_turns and not finished,
	}


func _signature_goal_text(mode: String) -> String:
	if mode != "Rocket League":
		return ""
	var roster := roster_for(mode)
	if roster.is_empty():
		return ""
	var player: Dictionary = roster[0]
	var signature := DevelopmentDataRef.signature_move(player)
	if signature.is_empty():
		return ""
	var mechanics := int(player.get("mechanics", 50))
	var consistency := int(player.get("consistency", 50))
	var trigger_chance := clampf(0.10 + float(mechanics - 50) * 0.009 + float(consistency - 50) * 0.003, 0.10, 0.52)
	if rng.randf() > trigger_chance:
		return ""
	return "%s creates the goal with %s." % [str(player.get("name", "TSK")), str(signature.get("event", "an elite mechanic"))]


func _interactive_event_time(turn: int) -> String:
	if turn >= 6:
		return "OT +%d" % (turn - 5)
	var seconds_left := maxi(0, 260 - turn * 45)
	return "%d:%02d" % [seconds_left / 60, seconds_left % 60]


func create_match(mode: String) -> Dictionary:
	var session: Dictionary = prepare_match(mode)
	if not bool(session.get("ok", false)):
		return session
	var safety := 0
	while safety < 10:
		var definitions: Array = match_action_definitions()
		var available_definitions: Array = []
		for definition_value in definitions:
			var candidate: Dictionary = definition_value
			if can_play_match_action(session, str(candidate.get("key", ""))):
				available_definitions.append(candidate)
		var definition: Dictionary = available_definitions[rng.randi_range(0, available_definitions.size() - 1)]
		var turn_result: Dictionary = play_match_turn(session, str(definition["key"]))
		if not bool(turn_result.get("ok", false)):
			return turn_result
		if bool(turn_result.get("finished", false)):
			break
		safety += 1
	return finalize_match(session)


func finalize_match(session: Dictionary) -> Dictionary:
	if bool(session.get("resolved", false)):
		return {"ok": false, "message": "This match result was already saved."}
	var regulation_turns := int(session.get("regulation_turns", 6))
	var our_score := int(session.get("our_score", 0))
	var their_score := int(session.get("their_score", 0))
	if int(session.get("turn", 0)) < regulation_turns or our_score == their_score:
		return {"ok": false, "message": "The match is not finished yet."}
	var mode := str(session.get("mode", "Rocket League"))
	var format := str(session.get("format", "1v1"))
	var opponent := str(session.get("opponent", "Unknown"))
	var opponent_mmr := int(session.get("opponent_mmr", 100))
	var profile: Dictionary = session.get("opponent_profile", {})
	var events: Array = session.get("events", [])
	var won := our_score > their_score
	var record: Dictionary = playlist_record(format) if mode == "Rocket League" else mode_record(mode)
	var mmr_before := int(session.get("mmr_before", record.get("mmr", 100)))

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
	var roster := roster_for(mode)
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
	var unlocked_titles: Array = []
	if mode == "Rocket League":
		unlocked_titles = _update_rank_title_progress(record, new_rank_data, format, won)
	data["history"].push_front({
		"kind": "ranked",
		"mode": mode,
		"format": format,
		"opponent": opponent,
		"opponent_mmr": opponent_mmr,
		"opponent_profile": str(profile["label"]),
		"won": won,
		"score": "%d - %d" % [our_score, their_score],
		"mmr_delta": mmr_delta,
		"mmr_before": mmr_before,
		"mmr_after": mmr_after,
		"old_rank": old_rank,
		"new_rank": new_rank,
		"stream_donation_cash": int(stream.get("donation_cash", 0)),
		"timestamp": int(Time.get_unix_time_from_system()),
	})
	while data["history"].size() > 20:
		data["history"].pop_back()
	data["week"] = int(data.get("week", 1)) + 1
	if int(data["week"]) > 12:
		unlocked_titles.append_array(_finish_season())
	session["resolved"] = true
	save_game()
	var decision_score := int(session.get("decision_score", 0))
	var tactical_grade := "C"
	if decision_score >= 4:
		tactical_grade = "S"
	elif decision_score >= 2:
		tactical_grade = "A"
	elif decision_score >= 0:
		tactical_grade = "B"
	return {
		"ok": true,
		"mode": mode,
		"format": format,
		"opponent": opponent,
		"opponent_mmr": opponent_mmr,
		"opponent_profile": profile,
		"won": won,
		"events": events,
		"score": "%d - %d" % [our_score, their_score],
		"mmr_delta": mmr_delta,
		"mmr_before": mmr_before,
		"mmr_after": mmr_after,
		"cash": int(stream.get("donation_cash", 0)),
		"fans": 0,
		"attention": attention,
		"streaming": bool(stream.get("live", false)),
		"stream_viewers": int(stream.get("viewers", 0)),
		"live_chat": stream.get("chat", []),
		"comments": stream.get("comments", []),
		"stream_followers": int(stream.get("followers", 0)),
		"stream_donation_cash": int(stream.get("donation_cash", 0)),
		"stream_donations": stream.get("donations", []),
		"decision_score": decision_score,
		"tactical_grade": tactical_grade,
		"decisions": session.get("decisions", []),
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
		"unlocked_titles": unlocked_titles,
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


func _update_rank_title_progress(
	record: Dictionary, rank_data: Dictionary, format: String, won: bool
) -> Array:
	var unlocked: Array = []
	if not won or int(record.get("placements", 0)) < placement_target("Rocket League"):
		return unlocked
	var family := str(rank_data.get("family", ""))
	if family not in ["Grand Champion", "Supersonic Legend"]:
		return unlocked
	record["gc_reward_wins"] = mini(
		TitleDataRef.RANK_REWARD_WINS,
		int(record.get("gc_reward_wins", 0)) + 1
	)
	if int(record["gc_reward_wins"]) >= TitleDataRef.RANK_REWARD_WINS:
		var gc_title := TitleDataRef.rank_title(int(data.get("season", 1)), "Grand Champion", format)
		if _grant_title(gc_title):
			unlocked.append(gc_title)
	if family == "Supersonic Legend":
		record["ssl_reward_wins"] = mini(
			TitleDataRef.RANK_REWARD_WINS,
			int(record.get("ssl_reward_wins", 0)) + 1
		)
		if int(record["ssl_reward_wins"]) >= TitleDataRef.RANK_REWARD_WINS:
			var ssl_title := TitleDataRef.rank_title(
				int(data.get("season", 1)), "Supersonic Legend", format
			)
			if _grant_title(ssl_title):
				unlocked.append(ssl_title)
	return unlocked


func _finish_season() -> Array:
	var unlocked: Array = []
	var finished_season := int(data.get("season", 1))
	for playlist in RankedDataRef.PLAYLISTS:
		var record := playlist_record(playlist)
		var season_played := int(record.get("season_wins", 0)) + int(record.get("season_losses", 0))
		if (
			int(record.get("placements", 0)) >= placement_target("Rocket League")
			and season_played >= 10
		):
			var position := RankedDataRef.estimated_position(int(record.get("mmr", 100)), playlist)
			if position <= 100:
				var placement_title := TitleDataRef.placement_title(finished_season, playlist, position)
				if _grant_title(placement_title):
					unlocked.append(placement_title)
	data["season"] = finished_season + 1
	data["week"] = 1
	data["season_bonus"] = 0
	for playlist in RankedDataRef.PLAYLISTS:
		var record := playlist_record(playlist)
		record["season_wins"] = 0
		record["season_losses"] = 0
		record["season_peak_mmr"] = int(record.get("mmr", 100))
		record["gc_reward_wins"] = 0
		record["ssl_reward_wins"] = 0
	return unlocked

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
	_ensure_player_development_stats(player)
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
		"rotation": clampi(base + rng.randi_range(-4, 5), 35, 95),
		"shooting": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"defense": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"game_sense": clampi(base + rng.randi_range(-4, 5), 35, 95),
		"boost_control": clampi(base + rng.randi_range(-4, 5), 35, 95),
		"consistency": clampi(base + rng.randi_range(-6, 4), 35, 95),
		"teamwork": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"mentality": clampi(base + rng.randi_range(-5, 5), 35, 95),
		"potential": potential,
		"source": source,
	}


func _stream_payload(
	won: bool, profile: Dictionary, format: String, forced_donation_roll: float = -1.0
) -> Dictionary:
	if not streaming_enabled():
		return {
			"live": false,
			"viewers": 0,
			"chat": [],
			"comments": [],
			"followers": 0,
			"donation_cash": 0,
			"donations": [],
		}
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
	var donation_result := _roll_stream_donations(viewers, won, plan, forced_donation_roll)
	var donations: Array = donation_result.get("events", [])
	var donation_cash := int(donation_result.get("cash", 0))
	for donation in donations:
		chat.append({
			"user": str(donation.get("user", "viewer")),
			"text": "DONATED %s  •  %s"
			% [
				GameDataRef.format_cash(int(donation.get("amount", 0))),
				str(donation.get("message", "great stream")),
			],
		})
	stream_data["followers"] = followers + follower_gain
	stream_data["total_views"] = int(stream_data.get("total_views", 0)) + viewers
	stream_data["peak_viewers"] = maxi(int(stream_data.get("peak_viewers", 0)), viewers)
	stream_data["last_comments"] = comments
	stream_data["last_donations"] = donations
	stream_data["total_donations"] = int(stream_data.get("total_donations", 0)) + donations.size()
	stream_data["total_donation_cash"] = int(stream_data.get("total_donation_cash", 0)) + donation_cash
	data["cash"] = int(data.get("cash", 0)) + donation_cash
	return {
		"live": true,
		"viewers": viewers,
		"chat": chat,
		"comments": comments,
		"followers": follower_gain,
		"format": format,
		"donation_cash": donation_cash,
		"donations": donations,
	}


func stream_donation_chance(viewers: int, won: bool, plan: String) -> float:
	var chance := 0.16 + float(mini(viewers, 80)) * 0.006
	if won:
		chance += 0.06
	if plan == "Creator":
		chance += 0.035
	elif plan == "Pro":
		chance += 0.07
	return clampf(chance, 0.16, 0.68)


func _roll_stream_donations(
	viewers: int, won: bool, plan: String, forced_roll: float = -1.0
) -> Dictionary:
	var roll := forced_roll if forced_roll >= 0.0 else rng.randf()
	if roll > stream_donation_chance(viewers, won, plan):
		return {"cash": 0, "events": []}
	var donation_count := 1
	if viewers >= 25 and rng.randf() < 0.32:
		donation_count += 1
	if viewers >= 80 and rng.randf() < 0.18:
		donation_count += 1
	var donors := ["boosted_ben", "aerial_aki", "gg_mate", "zero_ping", "rotation_police", "ranked_grinder"]
	var messages := ["clean mechanics", "keep grinding", "that read was perfect", "for the road to SSL", "insane finish", "run it back"]
	var events: Array = []
	var total_cash := 0
	for index in range(donation_count):
		var amount := rng.randi_range(1, 4) + int(floor(float(viewers) / 12.0))
		if plan == "Creator":
			amount += 1
		elif plan == "Pro":
			amount += 2
		if rng.randf() < 0.05:
			amount *= 2
		amount = clampi(amount, 1, 75)
		total_cash += amount
		events.append({
			"user": donors[rng.randi_range(0, donors.size() - 1)],
			"amount": amount,
			"message": messages[rng.randi_range(0, messages.size() - 1)],
		})
	return {"cash": total_cash, "events": events}


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


func _ensure_player_development_stats(player: Dictionary) -> void:
	if str(player.get("id", "")) == "captain":
		player["potential"] = maxi(96, int(player.get("potential", 96)))
	var mechanics := int(player.get("mechanics", 50))
	var game_sense := int(player.get("game_sense", 50))
	var teamwork := int(player.get("teamwork", game_sense))
	var mentality := int(player.get("mentality", 50))
	if not player.has("rotation"):
		player["rotation"] = clampi(int(round(float(game_sense + teamwork) / 2.0)), 1, 99)
	if not player.has("shooting"):
		player["shooting"] = clampi(
			int(round(float(mechanics * 2 + mentality) / 3.0)),
			1,
			99
		)
	if not player.has("defense"):
		player["defense"] = clampi(
			int(round(float(game_sense + teamwork + mentality) / 3.0)),
			1,
			99
		)
	if not player.has("boost_control"):
		player["boost_control"] = clampi(
			int(round(float(mechanics + game_sense) / 2.0)),
			1,
			99
		)
	if not player.has("consistency"):
		player["consistency"] = clampi(
			int(round(float(game_sense + teamwork + mentality) / 3.0)),
			1,
			99
		)
	if not player.has("last_training_week"):
		player["last_training_week"] = -1
	if not player.has("last_training_program"):
		player["last_training_program"] = ""
	if not player.has("training_history") or typeof(player["training_history"]) != TYPE_ARRAY:
		player["training_history"] = []


func _migrate_save(from_version: int) -> void:
	# v0.4.6 rebases the old 600-MMR seed to the intended 100-MMR origin.
	# Subtracting the same 500 points from current, peak and history values
	# preserves every earned or lost point instead of resetting progress.
	if not data.has("rl_playlists") or typeof(data["rl_playlists"]) != TYPE_DICTIONARY:
		var legacy_mmr := 600
		if data.has("modes") and typeof(data["modes"]) == TYPE_DICTIONARY:
			legacy_mmr = int(data["modes"].get("Rocket League", {}).get("mmr", 600))
		data["rl_playlists"] = {
			"1v1": _new_ranked_record(legacy_mmr, 1),
			"2v2": _new_ranked_record(600, 1),
			"3v3": _new_ranked_record(600, 1),
		}
	for playlist in RankedDataRef.PLAYLISTS:
		if not data["rl_playlists"].has(playlist) or typeof(data["rl_playlists"][playlist]) != TYPE_DICTIONARY:
			data["rl_playlists"][playlist] = _new_ranked_record(600, 1)
		var record: Dictionary = data["rl_playlists"][playlist]
		if from_version < 6 and int(record.get("mmr_schema", 1)) < 2:
			var old_mmr := int(record.get("mmr", 600))
			var old_peak := int(record.get("peak_mmr", old_mmr))
			var old_season_peak := int(record.get("season_peak_mmr", old_mmr))
			record["mmr"] = maxi(0, old_mmr - 500)
			record["peak_mmr"] = maxi(0, old_peak - 500)
			record["season_peak_mmr"] = maxi(0, old_season_peak - 500)
			var rebased_history: Array = []
			for value in record.get("mmr_history", [old_mmr]):
				rebased_history.append(maxi(0, int(value) - 500))
			record["mmr_history"] = rebased_history
		var current_mmr := int(record.get("mmr", 100))
		record["mmr_schema"] = 2
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
		if not record.has("gc_reward_wins"):
			record["gc_reward_wins"] = 0
		if not record.has("ssl_reward_wins"):
			record["ssl_reward_wins"] = 0
	for collection_key in ["roster", "market", "contacts"]:
		for player in data.get(collection_key, []):
			if typeof(player) == TYPE_DICTIONARY:
				_ensure_player_development_stats(player)
	if not data.has("last_rest_week") or typeof(data["last_rest_week"]) != TYPE_DICTIONARY:
		data["last_rest_week"] = {}
	if not data.has("earned_titles") or typeof(data["earned_titles"]) != TYPE_ARRAY:
		data["earned_titles"] = []
	if not data.has("equipped_title_id"):
		data["equipped_title_id"] = ""
	if not data.has("streaming") or typeof(data["streaming"]) != TYPE_DICTIONARY:
		data["streaming"] = {}
	var streaming: Dictionary = data["streaming"]
	if not streaming.has("total_donations"):
		streaming["total_donations"] = 0
	if not streaming.has("total_donation_cash"):
		streaming["total_donation_cash"] = 0
	if not streaming.has("last_donations") or typeof(streaming["last_donations"]) != TYPE_ARRAY:
		streaming["last_donations"] = []
	data["selected_rl_playlist"] = RankedDataRef.normalize_playlist(str(data.get("selected_rl_playlist", "1v1")))
	if from_version < 8:
		data["version"] = 8


func _new_ranked_record(starting_mmr: int = 100, mmr_schema: int = 2) -> Dictionary:
	return {
		"mmr": starting_mmr,
		"mmr_schema": mmr_schema,
		"wins": 0,
		"losses": 0,
		"played": 0,
		"placements": 0,
		"streak": 0,
		"peak_mmr": starting_mmr,
		"season_peak_mmr": starting_mmr,
		"season_wins": 0,
		"season_losses": 0,
		"gc_reward_wins": 0,
		"ssl_reward_wins": 0,
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
		"earned_titles": [],
		"equipped_title_id": "",
		"last_rest_week": {},
		"facilities": {"hq": 0, "coaching": 0, "scouting": 0, "analytics": 0, "studio": 0},
		"rl_playlists": {
			"1v1": _new_ranked_record(100),
			"2v2": _new_ranked_record(100),
			"3v3": _new_ranked_record(100),
		},
		"modes": {
			"Rocket League": {"mmr": 100, "wins": 0, "losses": 0, "played": 0, "placements": 0, "streak": 0},
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
			"total_donations": 0,
			"total_donation_cash": 0,
			"last_donations": [],
		},
		"market": [],
		"history": [],
	}

func _starter_roster() -> Array:
	return [
		_player("captain", "KESHI", "Rocket League", "Captain", "EU", 58, 58, 55, 60, 96),
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
		"rotation": int(round(float(game_sense + teamwork) / 2.0)),
		"shooting": int(round(float(mechanics * 2 + mentality) / 3.0)),
		"defense": int(round(float(game_sense + teamwork + mentality) / 3.0)),
		"game_sense": game_sense,
		"boost_control": int(round(float(mechanics + game_sense) / 2.0)),
		"consistency": int(round(float(game_sense + teamwork + mentality) / 3.0)),
		"teamwork": teamwork,
		"mentality": mentality,
		"potential": potential,
		"form": 55,
		"fatigue": 0,
		"last_training_week": -1,
		"last_training_program": "",
		"training_history": [],
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
