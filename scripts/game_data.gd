class_name GameData
extends RefCounted

const VERSION := 3
const MODES := ["Rocket League", "Fortnite", "Warzone"]

const MODE_SHORT := {
	"Rocket League": "RL",
	"Fortnite": "FN",
	"Warzone": "WZ",
}

const MODE_COLORS := {
	"Rocket League": Color("2de2ff"),
	"Fortnite": Color("a779ff"),
	"Warzone": Color("58e39b"),
}

const RANKS := [
	{"name": "Open Circuit", "minimum": 0, "accent": "71809d"},
	{"name": "Challenger", "minimum": 900, "accent": "38bdf8"},
	{"name": "Contender", "minimum": 1100, "accent": "22d3a6"},
	{"name": "Pro League", "minimum": 1300, "accent": "a779ff"},
	{"name": "Elite Series", "minimum": 1525, "accent": "ffbf69"},
	{"name": "World Class", "minimum": 1775, "accent": "ff5b8d"},
]

const FACILITIES := {
	"hq":
	{
		"name": "Team Headquarters",
		"tag": "HQ",
		"description": "Raises the club reputation ceiling and sponsor value.",
		"base_cost": 12500,
		"color": "2de2ff",
	},
	"coaching":
	{
		"name": "Performance Center",
		"tag": "CO",
		"description": "Training creates stronger gains and less fatigue.",
		"base_cost": 9800,
		"color": "a779ff",
	},
	"scouting":
	{
		"name": "Global Scouting",
		"tag": "SC",
		"description": "Finds younger prospects with higher potential.",
		"base_cost": 11000,
		"color": "58e39b",
	},
	"analytics":
	{
		"name": "Match Analytics",
		"tag": "AN",
		"description": "Improves consistency and your match win chance.",
		"base_cost": 13500,
		"color": "ffbf69",
	},
	"studio":
	{
		"name": "Content Studio",
		"tag": "CS",
		"description": "Generates passive cash and new fans while offline.",
		"base_cost": 8000,
		"color": "ff5b8d",
	},
}

const FIRST_NAMES := [
	"Aero",
	"Aki",
	"Axel",
	"Blaze",
	"Cairo",
	"Clutch",
	"Dexo",
	"Drift",
	"Echo",
	"Frost",
	"Ghost",
	"Havoc",
	"Jett",
	"Kairo",
	"Lynx",
	"Mako",
	"Nexo",
	"Nova",
	"Onyx",
	"Pulse",
	"Raze",
	"Reign",
	"Rift",
	"Sage",
	"Shadow",
	"Spark",
	"Storm",
	"Vanta",
	"Volt",
	"Zen",
]

const REGIONS := ["EU", "NA", "SAM", "MENA", "OCE", "APAC"]

const OPPONENTS := {
	"Rocket League":
	[
		"Nova Union",
		"Apex Core",
		"Orbit Blue",
		"Titan Forge",
		"Royal Pulse",
		"Zero Point",
		"Nightshift",
		"Vertex Club",
		"Vanguard",
		"Solaris",
	],
	"Fortnite":
	[
		"Crimson Seven",
		"Skyline",
		"Northstar",
		"Phantom Grid",
		"Team Kinetic",
		"Vortex",
		"Arc Society",
		"Monarch",
		"Outliers",
		"Eclipse",
	],
	"Warzone":
	[
		"Strike Unit",
		"Iron Wolves",
		"Blackline",
		"Sector Nine",
		"Sentinel",
		"Red Crown",
		"Deadzone",
		"Atlas Crew",
		"Omega",
		"Division X",
	],
}

const EVENT_LINES := {
	"Rocket League":
	{
		"good":
		[
			"Perfect midfield read creates a clean opening.",
			"Fast counterattack catches the defense rotating out.",
			"Backboard pressure forces a double commit.",
			"A patient fake challenge wins possession.",
			"Clinical finish after a controlled first touch.",
		],
		"bad":
		[
			"The opponent punishes an overcommit.",
			"A lost midfield fifty opens the net.",
			"Boost control slips during a long defensive phase.",
			"The rival team converts a quick infield pass.",
		],
		"neutral":
		[
			"Both teams slow the play and reset their rotations.",
			"A tense midfield battle keeps the score unchanged.",
			"Strong saves at both ends keep the series close.",
		],
	},
	"Fortnite":
	{
		"good":
		[
			"Smart height control secures the next moving zone.",
			"A clean refresh stabilizes the late game.",
			"The trio finds a low-risk elimination on the rotate.",
			"Excellent resource management pays off in endgame.",
			"A coordinated layer switch gains four placements.",
		],
		"bad":
		[
			"A difficult zone pull burns too many materials.",
			"The team is split during a contested rotate.",
			"An aggressive push costs valuable placement points.",
			"The lobby pressure forces an early disengage.",
		],
		"neutral":
		[
			"The team farms safely and tracks the next zone.",
			"A quiet midgame keeps every option open.",
			"Multiple squads rotate past without committing.",
		],
	},
	"Warzone":
	{
		"good":
		[
			"A coordinated push clears a strong position.",
			"The squad wins a key rotation into the next circle.",
			"UAV timing creates a high-value team fight.",
			"A disciplined reset turns defense into momentum.",
			"Clean communication secures another elimination.",
		],
		"bad":
		[
			"The squad gets pinched while crossing open ground.",
			"A late rotation gives the opponent better cover.",
			"The team loses momentum after a risky challenge.",
			"A rival squad steals the stronger power position.",
		],
		"neutral":
		[
			"The circle shifts and every squad repositions.",
			"The team holds cover while gathering information.",
			"A careful reset keeps the full squad active.",
		],
	},
}


static func rank_for_mmr(mmr: int) -> Dictionary:
	var result: Dictionary = RANKS[0]
	for rank_data in RANKS:
		if mmr >= int(rank_data["minimum"]):
			result = rank_data
	return result


static func next_rank_for_mmr(mmr: int) -> Dictionary:
	for rank_data in RANKS:
		if mmr < int(rank_data["minimum"]):
			return rank_data
	return RANKS[RANKS.size() - 1]


static func format_cash(value: int) -> String:
	if value >= 1000000:
		return "$%.2fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "$%.1fK" % (float(value) / 1000.0)
	return "$%d" % value


static func format_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
