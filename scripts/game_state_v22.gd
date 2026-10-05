class_name EmpireStateV22
extends "res://scripts/game_state.gd"

const SetupDataRef = preload("res://scripts/setup_data.gd")
const MechanicalSequenceRef = preload("res://scripts/mechanical_sequence_data.gd")
const BackupCodecRef = preload("res://scripts/backup_codec.gd")
const DevelopmentV22Ref = preload("res://scripts/development_data.gd")


func _init() -> void:
	super._init()
	_ensure_v22_state()


func load_game() -> Dictionary:
	var offline := super.load_game()
	_ensure_v22_state()
	save_game()
	return offline


func reset_game() -> void:
	super.reset_game()
	_ensure_v22_state()
	save_game()


func _ensure_v22_state() -> void:
	if not data.has("setup") or typeof(data["setup"]) != TYPE_DICTIONARY:
		data["setup"] = {}
	for key in SetupDataRef.CATEGORIES:
		if not data["setup"].has(key):
			data["setup"][key] = 0
	if not data.has("backup") or typeof(data["backup"]) != TYPE_DICTIONARY:
		data["backup"] = {}
	if not data["backup"].has("enabled"):
		data["backup"]["enabled"] = false
	if not data["backup"].has("last_exported_at"):
		data["backup"]["last_exported_at"] = 0
	if not data.has("seen_changelog"):
		data["seen_changelog"] = ""
	for player in data.get("roster", []):
		_ensure_mechanic_mastery(player)
	for player in data.get("market", []):
		_ensure_mechanic_mastery(player)


func _ensure_mechanic_mastery(player: Dictionary) -> void:
	if not player.has("mechanic_mastery") or typeof(player["mechanic_mastery"]) != TYPE_DICTIONARY:
		player["mechanic_mastery"] = {}
	var mastery: Dictionary = player["mechanic_mastery"]
	for move_value in DevelopmentV22Ref.unlocked_mechanics(player):
		var move: Dictionary = move_value
		var move_id := str(move.get("id", ""))
		if not mastery.has(move_id):
			var mechanics := int(player.get("mechanics", 50))
			var consistency := int(player.get("consistency", 50))
			mastery[move_id] = clampi(25 + int(round(float(mechanics + consistency - 100) * 0.65)), 25, 78)


func training_cost(_player: Dictionary, _program_id: String = "mechanics_lab") -> int:
	return 0


func training_readiness(player: Dictionary) -> Dictionary:
	var fatigue := int(player.get("fatigue", 0))
	var blocked := fatigue >= TRAINING_FATIGUE_LIMIT
	var focus := clampi(5 - int(floor(float(fatigue) / 17.0)), 0, 5)
	return {
		"ok": not blocked and focus > 0,
		"sessions_used": 5 - focus,
		"slots_remaining": focus,
		"limit": 5,
		"window_seconds": 0,
		"seconds_until_slot": 0,
		"fatigue": fatigue,
		"fatigue_limit": TRAINING_FATIGUE_LIMIT,
		"fatigue_blocked": blocked,
	}


func training_breakthrough_chance() -> float:
	return clampf(super.training_breakthrough_chance() + setup_training_bonus(), 0.12, 0.62)


func train_player(player_id: String, program_id: String = "mechanics_lab") -> Dictionary:
	var result := super.train_player(player_id, program_id)
	if not bool(result.get("ok", false)):
		return result
	var player := _find_player(player_id)
	if player.is_empty():
		return result
	_ensure_mechanic_mastery(player)
	var mastery: Dictionary = player["mechanic_mastery"]
	var program := DevelopmentV22Ref.program(program_id)
	var primary := str(program.get("primary", ""))
	var mastery_gains: Dictionary = {}
	for move_value in DevelopmentV22Ref.unlocked_mechanics(player):
		var move: Dictionary = move_value
		var move_id := str(move.get("id", ""))
		var before := int(mastery.get(move_id, 25))
		var gain := 1
		if program_id == "mechanics_lab":
			gain = 3 if move_id != str(DevelopmentV22Ref.signature_move(player).get("id", "")) else 5
		elif primary in ["consistency", "shooting", "boost_control"]:
			gain = 2
		var after := clampi(before + gain, 0, 100)
		mastery[move_id] = after
		if after > before:
			mastery_gains[move_id] = after - before
	player["mechanic_mastery"] = mastery
	var desk_relief := setup_fatigue_relief()
	if desk_relief > 0:
		player["fatigue"] = maxi(0, int(player.get("fatigue", 0)) - desk_relief)
	result["cost"] = 0
	result["mastery_gains"] = mastery_gains
	result["message"] = str(result.get("message", "Training beendet.")).replace(" für €0", " kostenlos")
	save_game()
	return result


func mechanic_mastery(player: Dictionary, mechanic_id: String) -> int:
	_ensure_mechanic_mastery(player)
	return clampi(int(player.get("mechanic_mastery", {}).get(mechanic_id, 0)), 0, 100)


func setup_level(key: String) -> int:
	_ensure_v22_state()
	return clampi(int(data.get("setup", {}).get(key, 0)), 0, SetupDataRef.max_level(key))


func setup_tier(key: String) -> Dictionary:
	return SetupDataRef.tier(key, setup_level(key))


func setup_upgrade_cost(key: String) -> int:
	return SetupDataRef.next_cost(key, setup_level(key))


func buy_setup_upgrade(key: String) -> Dictionary:
	if key not in SetupDataRef.CATEGORIES:
		return {"ok": false, "message": "Unbekanntes Setup-Upgrade."}
	var level := setup_level(key)
	var max_level := SetupDataRef.max_level(key)
	if level >= max_level:
		return {"ok": false, "message": "%s ist bereits auf Max-Level." % str(SetupDataRef.definition(key).get("name", key))}
	var cost := setup_upgrade_cost(key)
	if int(data.get("cash", 0)) < cost:
		return {"ok": false, "message": "Du brauchst %s für dieses Upgrade." % GameDataRef.format_cash(cost)}
	data["cash"] = int(data.get("cash", 0)) - cost
	data["setup"][key] = level + 1
	var tier := setup_tier(key)
	save_game()
	return {
		"ok": true,
		"message": "%s installiert: %s." % [str(SetupDataRef.definition(key).get("name", key)), str(tier.get("name", "Upgrade"))],
		"level": level + 1,
		"tier": tier,
		"cost": cost,
	}


func setup_training_bonus() -> float:
	return float(setup_tier("controller").get("training", 0.0)) + float(setup_tier("display").get("training", 0.0))


func setup_consistency_bonus() -> float:
	return (
		float(setup_tier("controller").get("consistency", 0.0))
		+ float(setup_tier("display").get("consistency", 0.0))
		+ float(setup_tier("internet").get("consistency", 0.0))
		+ float(setup_tier("audio").get("sense", 0.0))
	)


func setup_fatigue_relief() -> int:
	return int(setup_tier("desk").get("fatigue_relief", 0))


func connection_stability() -> float:
	return clampf(float(setup_tier("internet").get("stability", 0.88)), 0.80, 1.0)


func connection_ping() -> int:
	return int(setup_tier("internet").get("ping", 46))


func setup_rating() -> int:
	var total := 0
	var maximum := 0
	for key in SetupDataRef.CATEGORIES:
		total += setup_level(key)
		maximum += SetupDataRef.max_level(key)
	return int(round(float(total) / float(maxi(1, maximum)) * 100.0))


func prepare_match(mode: String) -> Dictionary:
	var session := super.prepare_match(mode)
	return _apply_v22_session_modifiers(session)


func prepare_pro_circuit_match() -> Dictionary:
	var session := super.prepare_pro_circuit_match()
	return _apply_v22_session_modifiers(session)


func _apply_v22_session_modifiers(session: Dictionary) -> Dictionary:
	if not bool(session.get("ok", false)):
		return session
	var stability := connection_stability()
	var setup_bonus := setup_consistency_bonus() * 10.0
	var connection_penalty := (1.0 - stability) * 8.0
	session["player_strength"] = float(session.get("player_strength", 50.0)) + setup_bonus - connection_penalty
	session["connection_stability"] = stability
	session["connection_ping"] = connection_ping()
	session["setup_rating"] = setup_rating()
	session["estimated_win_chance"] = estimated_match_win_chance(session)
	return session


func create_backup_code() -> Dictionary:
	_ensure_v22_state()
	data["backup"]["enabled"] = true
	data["backup"]["last_exported_at"] = int(Time.get_unix_time_from_system())
	save_game()
	var code := BackupCodecRef.encode(data)
	return {"ok": true, "code": code, "message": "Empire Backup erstellt. Bewahre den Recovery-Code außerhalb der App auf."}


func restore_backup_code(code: String) -> Dictionary:
	var decoded := BackupCodecRef.decode(code)
	if not bool(decoded.get("ok", false)):
		return decoded
	var restored = decoded.get("data", {})
	if typeof(restored) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Backup enthält keinen gültigen Spielstand."}
	data = restored
	_migrate_save(int(data.get("version", 0)))
	_merge_defaults(data, super._new_save())
	_ensure_v22_state()
	data["backup"]["enabled"] = true
	save_game()
	return {"ok": true, "message": "Empire Backup wiederhergestellt.", "season": int(data.get("season", 1)), "cash": int(data.get("cash", 0))}


func disable_backup() -> Dictionary:
	_ensure_v22_state()
	data["backup"]["enabled"] = false
	save_game()
	return {"ok": true, "message": "Empire Backup ist deaktiviert. Lokales Autosave bleibt aktiv."}


func backup_enabled() -> bool:
	_ensure_v22_state()
	return bool(data.get("backup", {}).get("enabled", false))


func _build_broadcast_replay(core_events: Array) -> Array:
	var replay: Array = []
	if core_events.is_empty():
		return replay
	var previous_score := "0 - 0"
	var roster := roster_for("Rocket League")
	var format := selected_rl_playlist()
	for event_value in core_events:
		var event: Dictionary = event_value
		var action := str(event.get("call", "control"))
		var quality := int(event.get("quality", 0))
		var momentum_value := int(event.get("momentum", 0))
		var mechanical := _mechanical_replay_for_event(event, roster, format, previous_score)
		if not mechanical.is_empty():
			for phase_value in mechanical:
				replay.append(phase_value)
		else:
			replay.append(_replay_phase("buildup", _buildup_text(action), previous_score, action, 0, momentum_value))
			replay.append(_replay_phase("challenge", _challenge_text(quality), previous_score, action, quality, momentum_value))
			if format != "1v1":
				replay.append(_replay_phase("rotation_switch", "1st Man rotiert raus — der 2nd Man übernimmt die nächste Zone.", previous_score, action, quality, momentum_value))
		var resolved := event.duplicate(true)
		resolved["phase"] = (
			"goal_ours" if str(event.get("type", "")) == "good"
			else "goal_theirs" if str(event.get("type", "")) == "bad"
			else "chance_ours" if quality > 0
			else "chance_theirs" if quality < 0
			else "reset"
		)
		resolved["count_stats"] = true
		replay.append(resolved)
		previous_score = str(event.get("score", previous_score))
	var total := replay.size()
	for index in range(total):
		replay[index]["time"] = _broadcast_time(index, total)
	return replay


func _replay_phase(phase: String, text: String, score: String, action: String, quality: int, momentum_value: int) -> Dictionary:
	return {
		"type": "neutral",
		"text": text,
		"score": score,
		"call": action,
		"quality": quality,
		"momentum": momentum_value,
		"phase": phase,
		"count_stats": false,
	}


func _buildup_text(action: String) -> String:
	if action == "press":
		return "TSK nimmt früh Raum. Der 1st Man geht zum Ball, der 2nd Man hält die Anschlussposition."
	if action == "counter":
		return "TSK bleibt kompakt. Der 3rd Man sichert, bis der Clear wirklich kontrollierbar ist."
	return "Kontrollierter Aufbau: Ballbesitz zuerst, Boost-Routen bleiben hinter dem Play offen."


func _challenge_text(quality: int) -> String:
	if quality > 0:
		return "Der 1st Man gewinnt die Challenge und rotiert danach sofort aus der Balllinie."
	if quality < 0:
		return "Die Challenge geht verloren; der nächste Spieler übernimmt als Safety."
	return "Neutrales Fifty — beide Teams resetten ihre Rotation."


func _mechanical_replay_for_event(event: Dictionary, roster: Array, format: String, score: String) -> Array:
	if roster.is_empty():
		return []
	var quality := int(event.get("quality", 0))
	var event_type := str(event.get("type", "neutral"))
	if quality < 0 or event_type == "bad":
		return []
	var player: Dictionary = roster[0]
	_ensure_mechanic_mastery(player)
	var unlocked := DevelopmentV22Ref.unlocked_mechanics(player)
	if unlocked.is_empty():
		return []
	var selected: Dictionary = unlocked[unlocked.size() - 1]
	var mechanic_id := str(selected.get("id", ""))
	var mastery := mechanic_mastery(player, mechanic_id)
	var trigger := clampf(0.10 + float(mastery) * 0.004 + float(int(player.get("mechanics", 50)) - 60) * 0.004, 0.10, 0.58)
	if event_type == "good":
		trigger = minf(0.72, trigger + 0.16)
	if rng.randf() > trigger:
		return []
	var combo_id := _mechanical_combo_id(mechanic_id, roster, format)
	var definitions := MechanicalSequenceRef.combo(combo_id) if not combo_id.is_empty() else MechanicalSequenceRef.sequence(mechanic_id)
	if definitions.is_empty():
		return []
	var result: Array = []
	for phase_value in definitions:
		var phase: Dictionary = phase_value
		var replay_event := _replay_phase(
			str(phase.get("phase", "buildup")),
			str(phase.get("text", "Mechanical Play")),
			score,
			str(event.get("call", "control")),
			quality,
			int(event.get("momentum", 0))
		)
		replay_event["mechanic_id"] = mechanic_id
		replay_event["mechanic_label"] = str(selected.get("label", mechanic_id))
		replay_event["mechanic_mastery"] = mastery
		replay_event["combo_id"] = combo_id
		replay_event["actor_index"] = 0
		replay_event["support_index"] = 1 if roster.size() > 1 else -1
		result.append(replay_event)
	return result


func _mechanical_combo_id(mechanic_id: String, roster: Array, format: String) -> String:
	if format == "1v1" or roster.size() < 2:
		return ""
	var teammate: Dictionary = roster[1]
	var chemistry := team_chemistry("Rocket League", format)
	if chemistry < 65:
		return ""
	var redirect_ready := (
		int(teammate.get("mechanics", 50)) >= 76
		and int(teammate.get("rotation", 50)) >= 72
		and int(teammate.get("game_sense", 50)) >= 74
	)
	if not redirect_ready:
		return ""
	var chance := clampf(0.18 + float(chemistry - 65) * 0.008 + float(int(teammate.get("consistency", 50)) - 50) * 0.004, 0.18, 0.62)
	if rng.randf() > chance:
		return ""
	if mechanic_id == "psycho":
		return "psycho_redirect"
	if mechanic_id == "air_dribble":
		return "air_dribble_redirect"
	return ""
