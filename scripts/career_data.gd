class_name CareerData
extends RefCounted

const LEVELS := [
	{"level": 1, "name": "Unknown Grinder", "minimum_xp": 0, "color": "71809d"},
	{"level": 2, "name": "Ranked Prospect", "minimum_xp": 80, "color": "2de2ff"},
	{"level": 3, "name": "Rising Threat", "minimum_xp": 200, "color": "58e39b"},
	{"level": 4, "name": "Open Contender", "minimum_xp": 380, "color": "ffbf69"},
	{"level": 5, "name": "Semi-Pro", "minimum_xp": 650, "color": "a779ff"},
	{"level": 6, "name": "Pro Player", "minimum_xp": 1000, "color": "ff5b8d"},
	{"level": 7, "name": "Elite Competitor", "minimum_xp": 1450, "color": "ff7da8"},
	{"level": 8, "name": "World Class", "minimum_xp": 2050, "color": "f2efff"},
	{"level": 9, "name": "Global Star", "minimum_xp": 2800, "color": "b47aff"},
	{"level": 10, "name": "Esports Icon", "minimum_xp": 3800, "color": "ffc76b"},
]

const CLUB_IDENTITIES := [
	{
		"id": "pressure",
		"name": "Relentless Press",
		"short": "PRESS DNA",
		"action": "press",
		"action_label": "HIGH PRESS",
		"goal_bonus": 0.04,
		"color": "ff5b8d",
		"detail": "Your HIGH PRESS calls gain +4 percentage points scoring chance.",
	},
	{
		"id": "control",
		"name": "Calculated Control",
		"short": "CONTROL DNA",
		"action": "control",
		"action_label": "BOOST CONTROL",
		"goal_bonus": 0.04,
		"color": "2de2ff",
		"detail": "Your BOOST CONTROL calls gain +4 percentage points scoring chance.",
	},
	{
		"id": "counter",
		"name": "Counter Culture",
		"short": "COUNTER DNA",
		"action": "counter",
		"action_label": "FAST COUNTER",
		"goal_bonus": 0.04,
		"color": "58e39b",
		"detail": "Your FAST COUNTER calls gain +4 percentage points scoring chance.",
	},
]

const MILESTONES := [
	{
		"id": "first_match",
		"label": "ENTER THE QUEUE",
		"detail": "Play your first ranked match.",
		"progress_key": "ranked_matches",
		"target": 1,
		"cash": 30,
		"xp": 25,
	},
	{
		"id": "first_win",
		"label": "FIRST STATEMENT",
		"detail": "Win your first ranked match.",
		"progress_key": "ranked_wins",
		"target": 1,
		"cash": 40,
		"xp": 30,
	},
	{
		"id": "placement_set",
		"label": "RANK REVEALED",
		"detail": "Complete ten Rocket League placements.",
		"progress_key": "placements",
		"target": 10,
		"cash": 80,
		"xp": 55,
	},
	{
		"id": "first_teammate",
		"label": "NOT SOLO ANYMORE",
		"detail": "Build a two-player Rocket League roster.",
		"progress_key": "rl_roster",
		"target": 2,
		"cash": 100,
		"xp": 60,
	},
	{
		"id": "gold_rank",
		"label": "GOLD STANDARD",
		"detail": "Reach Gold in any Rocket League playlist.",
		"progress_key": "gold_rank",
		"target": 1,
		"cash": 130,
		"xp": 90,
	},
	{
		"id": "musty_unlocked",
		"label": "MECHANICAL THREAT",
		"detail": "Unlock the Musty Flick in the Mechanics Arsenal.",
		"progress_key": "musty_unlocked",
		"target": 1,
		"cash": 110,
		"xp": 90,
	},
	{
		"id": "chemistry_65",
		"label": "REAL DUO",
		"detail": "Raise Rocket League team chemistry to 65.",
		"progress_key": "chemistry",
		"target": 65,
		"cash": 125,
		"xp": 100,
	},
	{
		"id": "cup_winner",
		"label": "COMMUNITY CHAMPION",
		"detail": "Win a community cup.",
		"progress_key": "cup_wins",
		"target": 1,
		"cash": 175,
		"xp": 125,
	},
	{
		"id": "facility_network",
		"label": "REAL INFRASTRUCTURE",
		"detail": "Own five total facility levels.",
		"progress_key": "facility_levels",
		"target": 5,
		"cash": 220,
		"xp": 150,
	},
	{
		"id": "creator_250",
		"label": "AUDIENCE FOUND",
		"detail": "Reach 250 stream followers.",
		"progress_key": "followers",
		"target": 250,
		"cash": 180,
		"xp": 130,
	},
	{
		"id": "season_complete",
		"label": "FULL CAMPAIGN",
		"detail": "Complete one 36-match season.",
		"progress_key": "seasons_finished",
		"target": 1,
		"cash": 300,
		"xp": 200,
	},
	{
		"id": "grand_champion",
		"label": "GRAND CHAMPION",
		"detail": "Reach Grand Champion in any Rocket League playlist.",
		"progress_key": "grand_champion",
		"target": 1,
		"cash": 500,
		"xp": 300,
	},
]


static func level_for_xp(xp: int) -> Dictionary:
	var result: Dictionary = LEVELS[0]
	for level_value in LEVELS:
		var level_data: Dictionary = level_value
		if xp >= int(level_data.get("minimum_xp", 0)):
			result = level_data
	return result


static func next_level_for_xp(xp: int) -> Dictionary:
	for level_value in LEVELS:
		var level_data: Dictionary = level_value
		if xp < int(level_data.get("minimum_xp", 0)):
			return level_data
	return LEVELS[LEVELS.size() - 1]


static func identity(identity_id: String) -> Dictionary:
	for identity_value in CLUB_IDENTITIES:
		var identity_data: Dictionary = identity_value
		if str(identity_data.get("id", "")) == identity_id:
			return identity_data
	return CLUB_IDENTITIES[2]


static func milestone(milestone_id: String) -> Dictionary:
	for milestone_value in MILESTONES:
		var milestone_data: Dictionary = milestone_value
		if str(milestone_data.get("id", "")) == milestone_id:
			return milestone_data
	return {}
