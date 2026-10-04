class_name CareerData
extends RefCounted

const LEVELS := [
	{"level": 1, "name": "Unbekannter Grinder", "minimum_xp": 0, "color": "71809d"},
	{"level": 2, "name": "Ranked-Talent", "minimum_xp": 80, "color": "2de2ff"},
	{"level": 3, "name": "Aufstrebende Gefahr", "minimum_xp": 200, "color": "58e39b"},
	{"level": 4, "name": "Open-Anwärter", "minimum_xp": 380, "color": "ffbf69"},
	{"level": 5, "name": "Semi-Pro", "minimum_xp": 650, "color": "a779ff"},
	{"level": 6, "name": "Profi-Spieler", "minimum_xp": 1000, "color": "ff5b8d"},
	{"level": 7, "name": "Elite-Spieler", "minimum_xp": 1450, "color": "ff7da8"},
	{"level": 8, "name": "World Class", "minimum_xp": 2050, "color": "f2efff"},
	{"level": 9, "name": "Globaler Star", "minimum_xp": 2800, "color": "b47aff"},
	{"level": 10, "name": "Esport-Ikone", "minimum_xp": 3800, "color": "ffc76b"},
]

const CLUB_IDENTITIES := [
	{
		"id": "pressure",
		"name": "Dauerhafter Druck",
		"short": "PRESS-DNA",
		"action": "press",
		"action_label": "HOHER DRUCK",
		"goal_bonus": 0.04,
		"color": "ff5b8d",
		"detail": "Dein hoher Druck erhält +4 Prozentpunkte Torchance.",
	},
	{
		"id": "control",
		"name": "Kontrolliertes Spiel",
		"short": "CONTROL-DNA",
		"action": "control",
		"action_label": "BOOST-KONTROLLE",
		"goal_bonus": 0.04,
		"color": "2de2ff",
		"detail": "Deine Boost-Kontrolle erhält +4 Prozentpunkte Torchance.",
	},
	{
		"id": "counter",
		"name": "Konter-Kultur",
		"short": "KONTER-DNA",
		"action": "counter",
		"action_label": "SCHNELLER KONTER",
		"goal_bonus": 0.04,
		"color": "58e39b",
		"detail": "Dein schneller Konter erhält +4 Prozentpunkte Torchance.",
	},
]

const MILESTONES := [
	{
		"id": "first_match",
		"label": "AB IN DIE QUEUE",
		"detail": "Spiele dein erstes Ranked-Match.",
		"progress_key": "ranked_matches",
		"target": 1,
		"cash": 30,
		"xp": 25,
	},
	{
		"id": "first_win",
		"label": "ERSTES ZEICHEN",
		"detail": "Gewinne dein erstes Ranked-Match.",
		"progress_key": "ranked_wins",
		"target": 1,
		"cash": 40,
		"xp": 30,
	},
	{
		"id": "placement_set",
		"label": "RANG ENTHÜLLT",
		"detail": "Schließe zehn Rocket-League-Placements ab.",
		"progress_key": "placements",
		"target": 10,
		"cash": 80,
		"xp": 55,
	},
	{
		"id": "first_teammate",
		"label": "NICHT MEHR SOLO",
		"detail": "Baue einen Rocket-League-Kader mit zwei Spielern.",
		"progress_key": "rl_roster",
		"target": 2,
		"cash": 100,
		"xp": 60,
	},
	{
		"id": "gold_rank",
		"label": "GOLD-STANDARD",
		"detail": "Erreiche Gold in einer Rocket-League-Playlist.",
		"progress_key": "gold_rank",
		"target": 1,
		"cash": 130,
		"xp": 90,
	},
	{
		"id": "musty_unlocked",
		"label": "MECHANISCHE GEFAHR",
		"detail": "Schalte den Musty Flick bei den Mechaniken frei.",
		"progress_key": "musty_unlocked",
		"target": 1,
		"cash": 110,
		"xp": 90,
	},
	{
		"id": "chemistry_65",
		"label": "ECHTES DUO",
		"detail": "Erhöhe die Rocket-League-Teamchemie auf 65.",
		"progress_key": "chemistry",
		"target": 65,
		"cash": 125,
		"xp": 100,
	},
	{
		"id": "cup_winner",
		"label": "COMMUNITY-CHAMPION",
		"detail": "Gewinne einen Community Cup.",
		"progress_key": "cup_wins",
		"target": 1,
		"cash": 175,
		"xp": 125,
	},
	{
		"id": "facility_network",
		"label": "ECHTE INFRASTRUKTUR",
		"detail": "Besitze insgesamt fünf Einrichtungslevel.",
		"progress_key": "facility_levels",
		"target": 5,
		"cash": 220,
		"xp": 150,
	},
	{
		"id": "creator_250",
		"label": "COMMUNITY GEFUNDEN",
		"detail": "Erreiche 250 Stream-Follower.",
		"progress_key": "followers",
		"target": 250,
		"cash": 180,
		"xp": 130,
	},
	{
		"id": "season_complete",
		"label": "VOLLE SAISON",
		"detail": "Schließe eine Saison mit 36 Spielen ab.",
		"progress_key": "seasons_finished",
		"target": 1,
		"cash": 300,
		"xp": 200,
	},
	{
		"id": "grand_champion",
		"label": "GRAND CHAMPION",
		"detail": "Erreiche Grand Champion in einer Rocket-League-Playlist.",
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
