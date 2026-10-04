class_name DevelopmentData
extends RefCounted

const PLAYER_STATS := [
	{"key": "mechanics", "label": "Mechanics", "short": "MECH", "color": "2de2ff"},
	{"key": "rotation", "label": "Rotation", "short": "ROT", "color": "a779ff"},
	{"key": "shooting", "label": "Shooting", "short": "SHOT", "color": "ffbf69"},
	{"key": "defense", "label": "Defense", "short": "DEF", "color": "58e39b"},
	{"key": "game_sense", "label": "Spielverständnis", "short": "SENSE", "color": "b68cff"},
	{"key": "boost_control", "label": "Boost-Kontrolle", "short": "BOOST", "color": "4fd6d2"},
	{"key": "consistency", "label": "Consistency", "short": "CONS", "color": "ff7da8"},
	{"key": "mentality", "label": "Mentality", "short": "MENTAL", "color": "ffd166"},
]

const TRAINING_PROGRAMS := [
	{
		"id": "mechanics_lab",
		"label": "Mechanik-Labor",
		"short": "MECHANICS",
		"button_detail": "+2 MECH / +1 SCHUSS",
		"detail": "+2 Mechanik  •  +1 Schuss",
		"primary": "mechanics",
		"gains": {"mechanics": 2, "shooting": 1},
		"base_cost": 20,
		"rating_scale": 0.42,
		"fatigue": 8,
		"color": "2de2ff",
	},
	{
		"id": "rotation_review",
		"label": "Rotationsanalyse",
		"short": "ROTATION",
		"button_detail": "+2 ROT / +1 VERST.",
		"detail": "+2 Rotation  •  +1 Spielverständnis",
		"primary": "rotation",
		"gains": {"rotation": 2, "game_sense": 1},
		"base_cost": 15,
		"rating_scale": 0.32,
		"fatigue": 4,
		"color": "a779ff",
	},
	{
		"id": "finishing_pack",
		"label": "Abschluss-Training",
		"short": "SHOOTING",
		"button_detail": "+2 SCHUSS / +1 MECH",
		"detail": "+2 Schuss  •  +1 Mechanik",
		"primary": "shooting",
		"gains": {"shooting": 2, "mechanics": 1},
		"base_cost": 18,
		"rating_scale": 0.38,
		"fatigue": 7,
		"color": "ffbf69",
	},
	{
		"id": "defensive_reads",
		"label": "Defensiv-Reads",
		"short": "DEFENSE",
		"button_detail": "+2 DEF / +1 ROT",
		"detail": "+2 Defense  •  +1 Rotation",
		"primary": "defense",
		"gains": {"defense": 2, "rotation": 1},
		"base_cost": 17,
		"rating_scale": 0.36,
		"fatigue": 6,
		"color": "58e39b",
	},
	{
		"id": "boost_routes",
		"label": "Boost-Routen",
		"short": "BOOST",
		"button_detail": "+2 BOOST / +1 CONS",
		"detail": "+2 Boost-Kontrolle  •  +1 Konstanz",
		"primary": "boost_control",
		"gains": {"boost_control": 2, "consistency": 1},
		"base_cost": 14,
		"rating_scale": 0.30,
		"fatigue": 4,
		"color": "4fd6d2",
	},
	{
		"id": "mental_coaching",
		"label": "Mentaltraining",
		"short": "MENTAL",
		"button_detail": "+2 MENTAL / +1 KONST.",
		"detail": "+2 Mentalität  •  +1 Konstanz",
		"primary": "mentality",
		"gains": {"mentality": 2, "consistency": 1},
		"base_cost": 12,
		"rating_scale": 0.26,
		"fatigue": 2,
		"color": "ffd166",
	},
]

const MECHANIC_ARSENAL := [
	{
		"id": "half_flip",
		"label": "Half Flip",
		"requirements": {"mechanics": 50, "rotation": 45},
		"event": "eine saubere Recovery in den Konter",
	},
	{
		"id": "fast_aerial",
		"label": "Fast Aerial",
		"requirements": {"mechanics": 56, "boost_control": 52},
		"event": "einen Fast-Aerial-Abschluss",
	},
	{
		"id": "air_dribble",
		"label": "Air Dribble",
		"requirements": {"mechanics": 64, "shooting": 58},
		"event": "einen kontrollierten Air-Dribble-Abschluss",
	},
	{
		"id": "musty_flick",
		"label": "Musty Flick",
		"requirements": {"mechanics": 72, "shooting": 67},
		"event": "einen Musty Flick über den letzten Verteidiger",
	},
	{
		"id": "flip_reset",
		"label": "Flip Reset",
		"requirements": {"mechanics": 78, "boost_control": 68},
		"event": "einen sauberen Flip-Reset-Abschluss",
	},
	{
		"id": "double_reset",
		"label": "Double Reset",
		"requirements": {"mechanics": 85, "consistency": 78},
		"event": "einen Double-Reset-Abschluss",
	},
	{
		"id": "psycho",
		"label": "Psycho",
		"requirements": {"mechanics": 89, "defense": 82},
		"event": "einen Psycho vom eigenen Backboard",
	},
	{
		"id": "triple_reset",
		"label": "Triple Reset",
		"requirements": {"mechanics": 94, "consistency": 88},
		"event": "einen Triple-Reset-Abschluss",
	},
]


static func program(program_id: String) -> Dictionary:
	for definition_value in TRAINING_PROGRAMS:
		var definition: Dictionary = definition_value
		if str(definition.get("id", "")) == program_id:
			return definition
	return {}


static func stat_definition(stat_key: String) -> Dictionary:
	for definition_value in PLAYER_STATS:
		var definition: Dictionary = definition_value
		if str(definition.get("key", "")) == stat_key:
			return definition
	return {}


static func player_archetype(player: Dictionary) -> Dictionary:
	var candidates := [
		{
			"id": "mechanical_finisher",
			"label": "Mechanischer Finisher",
			"short": "FINISHER",
			"color": "2de2ff",
			"score": int(player.get("mechanics", 50)) + int(player.get("shooting", 50)),
		},
		{
			"id": "defensive_anchor",
			"label": "Defensiv-Anker",
			"short": "ANCHOR",
			"color": "58e39b",
			"score": int(player.get("rotation", 50)) + int(player.get("defense", 50)),
		},
		{
			"id": "field_general",
			"label": "Spielmacher",
			"short": "PLAYMAKER",
			"color": "a779ff",
			"score": int(player.get("game_sense", 50)) + int(player.get("boost_control", 50)),
		},
		{
			"id": "clutch_specialist",
			"label": "Clutch-Spezialist",
			"short": "CLUTCH",
			"color": "ffbf69",
			"score": int(player.get("consistency", 50)) + int(player.get("mentality", 50)),
		},
	]
	var highest := -1
	var lowest := 999
	var best: Dictionary = candidates[0]
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var score := int(candidate.get("score", 0))
		lowest = mini(lowest, score)
		if score > highest:
			highest = score
			best = candidate
	if highest - lowest <= 6:
		return {
			"id": "complete_player",
			"label": "Kompletter Spieler",
			"short": "ALL-ROUND",
			"color": "f2efff",
			"score": highest,
		}
	return best.duplicate(true)


static func requirements_met(player: Dictionary, move: Dictionary) -> bool:
	var requirements: Dictionary = move.get("requirements", {})
	for stat_key in requirements:
		if int(player.get(stat_key, 0)) < int(requirements[stat_key]):
			return false
	return true


static func unlocked_mechanics(player: Dictionary) -> Array:
	var unlocked: Array = []
	for move_value in MECHANIC_ARSENAL:
		var move: Dictionary = move_value
		if requirements_met(player, move):
			unlocked.append(move)
	return unlocked


static func next_mechanic(player: Dictionary) -> Dictionary:
	for move_value in MECHANIC_ARSENAL:
		var move: Dictionary = move_value
		if not requirements_met(player, move):
			return move
	return {}


static func mechanic_progress(player: Dictionary, move: Dictionary) -> int:
	var requirements: Dictionary = move.get("requirements", {})
	if requirements.is_empty():
		return 100
	var lowest_ratio := 1.0
	for stat_key in requirements:
		var target := maxi(1, int(requirements[stat_key]))
		lowest_ratio = minf(lowest_ratio, float(int(player.get(stat_key, 0))) / float(target))
	return clampi(int(round(lowest_ratio * 100.0)), 0, 100)


static func requirement_text(move: Dictionary) -> String:
	var parts: Array[String] = []
	var requirements: Dictionary = move.get("requirements", {})
	for stat_key in requirements:
		var definition := stat_definition(str(stat_key))
		parts.append("%s %d" % [str(definition.get("short", stat_key)).to_upper(), int(requirements[stat_key])])
	return "  •  ".join(parts)


static func signature_move(player: Dictionary) -> Dictionary:
	var unlocked := unlocked_mechanics(player)
	if unlocked.is_empty():
		return {}
	return unlocked[unlocked.size() - 1]
