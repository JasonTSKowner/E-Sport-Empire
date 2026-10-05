class_name EmpireStateV23
extends "res://scripts/game_state_v22.gd"

const MechanicsV23Ref = preload("res://scripts/mechanics_catalog_v23.gd")
const SequencesV23Ref = preload("res://scripts/mechanical_sequences_v23.gd")


func _init() -> void:
	super._init()
	_ensure_v23_state()


func load_game() -> Dictionary:
	var offline := super.load_game()
	_ensure_v23_state()
	save_game()
	return offline


func reset_game() -> void:
	super.reset_game()
	_ensure_v23_state()
	save_game()


func _ensure_v23_state() -> void:
	for player in data.get("roster", []):
		_ensure_player_v23(player)
	for player in data.get("market", []):
		_ensure_player_v23(player)


func _ensure_player_v23(player: Dictionary) -> void:
	if not player.has("mechanic_mastery_detail") or typeof(player["mechanic_mastery_detail"]) != TYPE_DICTIONARY:
		player["mechanic_mastery_detail"] = {}
	if not player.has("mechanic_mastery") or typeof(player["mechanic_mastery"]) != TYPE_DICTIONARY:
		player["mechanic_mastery"] = {}
	var details: Dictionary = player["mechanic_mastery_detail"]
	var legacy: Dictionary = player["mechanic_mastery"]
	for item_value in MechanicsV23Ref.unlocked(player):
		var item: Dictionary = item_value
		var mechanic_id := str(item.get("id", ""))
		if mechanic_id.is_empty():
			continue
		if not details.has(mechanic_id) or typeof(details[mechanic_id]) != TYPE_DICTIONARY:
			var mechanics := int(player.get("mechanics", 50))
			var shooting := int(player.get("shooting", 50))
			var sense := int(player.get("game_sense", 50))
			var consistency := int(player.get("consistency", 50))
			var boost := int(player.get("boost_control", 50))
			var tier := int(item.get("tier", 1))
			var difficulty_penalty := maxi(0, tier - 1) * 4
			details[mechanic_id] = {
				"setup": clampi(20 + int(round(float(mechanics + boost - 90) * 0.55)) - difficulty_penalty, 18, 88),
				"control": clampi(20 + int(round(float(mechanics + consistency - 90) * 0.55)) - difficulty_penalty, 18, 88),
				"read": clampi(20 + int(round(float(sense + consistency - 90) * 0.50)) - difficulty_penalty, 18, 88),
				"finish": clampi(20 + int(round(float(shooting + mechanics - 90) * 0.50)) - difficulty_penalty, 18, 88),
			}
		legacy[mechanic_id] = _detail_average(details[mechanic_id])
	player["mechanic_mastery_detail"] = details
	player["mechanic_mastery"] = legacy


func _detail_average(detail: Dictionary) -> int:
	return clampi(int(round(float(
		int(detail.get("setup", 0))
		+ int(detail.get("control", 0))
		+ int(detail.get("read", 0))
		+ int(detail.get("finish", 0))
	) / 4.0)), 0, 100)


func mechanic_components(player: Dictionary, mechanic_id: String) -> Dictionary:
	_ensure_player_v23(player)
	var detail: Dictionary = player.get("mechanic_mastery_detail", {}).get(mechanic_id, {})
	return detail.duplicate(true)


func mechanic_mastery(player: Dictionary, mechanic_id: String) -> int:
	_ensure_player_v23(player)
	var detail: Dictionary = player.get("mechanic_mastery_detail", {}).get(mechanic_id, {})
	if not detail.is_empty():
		return _detail_average(detail)
	return super.mechanic_mastery(player, mechanic_id)


func unlocked_mechanics_v23(player: Dictionary) -> Array:
	_ensure_player_v23(player)
	return MechanicsV23Ref.unlocked(player)


func next_mechanics_v23(player: Dictionary, limit: int = 6) -> Array:
	return MechanicsV23Ref.next_unlocks(player, limit)


func train_player(player_id: String, program_id: String = "mechanics_lab") -> Dictionary:
	var result := super.train_player(player_id, program_id)
	if not bool(result.get("ok", false)):
		return result
	var player := _find_player(player_id)
	if player.is_empty():
		return result
	_ensure_player_v23(player)
	var details: Dictionary = player.get("mechanic_mastery_detail", {})
	var gains: Dictionary = {}
	for item_value in MechanicsV23Ref.unlocked(player):
		var item: Dictionary = item_value
		var mechanic_id := str(item.get("id", ""))
		var detail: Dictionary = details.get(mechanic_id, {}).duplicate(true)
		if detail.is_empty():
			continue
		var before := _detail_average(detail)
		match program_id:
			"mechanics_lab":
				detail["setup"] = mini(100, int(detail.get("setup", 0)) + 3)
				detail["control"] = mini(100, int(detail.get("control", 0)) + 3)
				detail["finish"] = mini(100, int(detail.get("finish", 0)) + 1)
			"rotation_review":
				detail["read"] = mini(100, int(detail.get("read", 0)) + 3)
			"finishing_pack":
				detail["finish"] = mini(100, int(detail.get("finish", 0)) + 3)
				detail["control"] = mini(100, int(detail.get("control", 0)) + 1)
			"defensive_reads":
				detail["read"] = mini(100, int(detail.get("read", 0)) + 2)
				detail["control"] = mini(100, int(detail.get("control", 0)) + 1)
			"boost_routes":
				detail["setup"] = mini(100, int(detail.get("setup", 0)) + 2)
				detail["control"] = mini(100, int(detail.get("control", 0)) + 2)
			"mental_coaching":
				for key in ["setup", "control", "read", "finish"]:
					detail[key] = mini(100, int(detail.get(key, 0)) + 1)
		details[mechanic_id] = detail
		var after := _detail_average(detail)
		if after > before:
			gains[mechanic_id] = after - before
	player["mechanic_mastery_detail"] = details
	var legacy: Dictionary = player.get("mechanic_mastery", {})
	for mechanic_id in details:
		legacy[mechanic_id] = _detail_average(details[mechanic_id])
	player["mechanic_mastery"] = legacy
	result["v23_mastery_gains"] = gains
	save_game()
	return result


func _mechanical_replay_for_event(event: Dictionary, roster: Array, format: String, score: String) -> Array:
	if roster.is_empty():
		return []
	var quality := int(event.get("quality", 0))
	var event_type := str(event.get("type", "neutral"))
	if event_type == "bad":
		return []
	var player: Dictionary = roster[0]
	_ensure_player_v23(player)
	var mechanic := _choose_context_mechanic(player, event, format)
	if mechanic.is_empty():
		return []
	var mechanic_id := str(mechanic.get("id", ""))
	var mastery := mechanic_mastery(player, mechanic_id)
	var components := mechanic_components(player, mechanic_id)
	var combo_id := _v23_combo_id(mechanic, roster, format)
	var definitions := SequencesV23Ref.combo(combo_id) if not combo_id.is_empty() else SequencesV23Ref.sequence_for(mechanic)
	if definitions.is_empty():
		return []

	var base_trigger := 0.05 + float(mastery) * 0.0045
	if quality > 0:
		base_trigger += 0.10
	if event_type == "good":
		base_trigger += 0.16
	base_trigger += setup_consistency_bonus() * 0.45
	if rng.randf() > clampf(base_trigger, 0.08, 0.66):
		return []

	var success_score := (
		float(int(components.get("setup", mastery))) * 0.24
		+ float(int(components.get("control", mastery))) * 0.29
		+ float(int(components.get("read", mastery))) * 0.19
		+ float(int(components.get("finish", mastery))) * 0.28
	)
	success_score += float(int(player.get("consistency", 50)) - 50) * 0.18
	success_score += (connection_stability() - 0.90) * 35.0
	var force_success := event_type == "good"
	var success_chance := clampf(0.20 + success_score / 125.0, 0.32, 0.94)
	var will_fail := not force_success and rng.randf() > success_chance
	var fail_index := -1
	if will_fail and definitions.size() >= 3:
		fail_index = rng.randi_range(1, definitions.size() - 2)

	var result: Array = []
	for index in range(definitions.size()):
		var phase: Dictionary = definitions[index]
		var replay_event := _v23_replay_phase(event, phase, score, mechanic, mastery, components, combo_id)
		result.append(replay_event)
		if index == fail_index:
			var failure := SequencesV23Ref.failure_for(mechanic, str(phase.get("phase", "setup")))
			result.append(_v23_replay_phase(event, failure, score, mechanic, mastery, components, combo_id))
			break
	return result


func _v23_replay_phase(event: Dictionary, phase: Dictionary, score: String, mechanic: Dictionary, mastery: int, components: Dictionary, combo_id: String) -> Dictionary:
	var replay_event := _replay_phase(
		str(phase.get("phase", "buildup")),
		str(phase.get("text", "Mechanical Play")),
		score,
		str(event.get("call", "control")),
		int(event.get("quality", 0)),
		int(event.get("momentum", 0))
	)
	replay_event["mechanic_id"] = str(mechanic.get("id", ""))
	replay_event["mechanic_label"] = str(mechanic.get("label", "Mechanic"))
	replay_event["mechanic_family"] = str(mechanic.get("family", ""))
	replay_event["mechanic_mastery"] = mastery
	replay_event["mechanic_components"] = components.duplicate(true)
	replay_event["combo_id"] = combo_id
	replay_event["actor_index"] = 0
	replay_event["support_index"] = 1 if combo_id != "" else -1
	return replay_event


func _choose_context_mechanic(player: Dictionary, event: Dictionary, format: String) -> Dictionary:
	var unlocked := MechanicsV23Ref.unlocked(player)
	if unlocked.is_empty():
		return {}
	var action := str(event.get("call", "control"))
	var quality := int(event.get("quality", 0))
	var scored: Array = []
	for item_value in unlocked:
		var item: Dictionary = item_value
		var category := str(item.get("category", ""))
		if category == "team" and format == "1v1":
			continue
		var family := str(item.get("family", ""))
		var mastery := mechanic_mastery(player, str(item.get("id", "")))
		var weight := float(mastery) * 0.45 - float(int(item.get("tier", 1))) * 2.5
		if action == "counter" and family in ["flick", "musty", "pinch", "recovery"]:
			weight += 19.0
		if action == "control" and family in ["air_dribble", "reset", "multi_reset", "ceiling", "pogo", "psycho"]:
			weight += 20.0
		if action == "press" and family in ["redirect", "double_tap", "team_combo", "team_pinch"]:
			weight += 18.0
		if quality == 0 and family in ["recovery", "defense", "save"]:
			weight += 14.0
		if quality > 0 and family in ["double_tap", "reset", "multi_reset", "musty", "psycho"]:
			weight += 8.0
		weight += rng.randf_range(-7.0, 7.0)
		scored.append({"item":item,"weight":weight})
	if scored.is_empty():
		return {}
	scored.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("weight", 0.0)) > float(b.get("weight", 0.0)))
	var pick_pool := mini(4, scored.size())
	var pick_index := 0
	if pick_pool > 1 and rng.randf() < 0.36:
		pick_index = rng.randi_range(0, pick_pool - 1)
	return (scored[pick_index].get("item", {}) as Dictionary).duplicate(true)


func _v23_combo_id(mechanic: Dictionary, roster: Array, format: String) -> String:
	if format == "1v1" or roster.size() < 2:
		return ""
	var teammate: Dictionary = roster[1]
	_ensure_player_v23(teammate)
	var chemistry := team_chemistry("Rocket League", format)
	if chemistry < 64:
		return ""
	var mate_mechs := int(teammate.get("mechanics", 50))
	var mate_sense := int(teammate.get("game_sense", 50))
	var mate_rotation := int(teammate.get("rotation", 50))
	var mate_consistency := int(teammate.get("consistency", 50))
	var ready := mate_mechs >= 72 and mate_sense >= 70 and mate_rotation >= 68
	if not ready:
		return ""
	var chance := clampf(0.10 + float(chemistry - 60) * 0.007 + float(mate_consistency - 50) * 0.004, 0.10, 0.64)
	if rng.randf() > chance:
		return ""
	var mechanic_id := str(mechanic.get("id", ""))
	if mechanic_id in ["psycho", "musty_psycho"] and mate_mechs >= 78:
		return "psycho_redirect"
	if mechanic_id in ["air_dribble", "ground_air_dribble"]:
		return "air_dribble_redirect"
	if mechanic_id in ["flip_reset", "double_reset", "reset_musty"] and mate_mechs >= 80:
		return "reset_pass_redirect"
	if mechanic_id in ["double_tap", "backboard_redirect"]:
		return "backboard_pass_finish"
	if mechanic_id in ["ceiling_shot", "ceiling_musty"] and mate_mechs >= 82:
		return "ceiling_pass_redirect"
	if mechanic_id == "team_ground_pinch":
		return "team_ground_pinch"
	if mechanic_id == "team_air_pinch" and mate_mechs >= 90:
		return "team_air_pinch"
	return ""
