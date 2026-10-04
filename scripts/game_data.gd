class_name GameData
extends RefCounted

const RankedDataRef = preload("res://scripts/ranked_data.gd")

const VERSION := 11
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

const RL_RANK_BASES := {
	"1v1": [
		{"name": "Bronze", "minimum": 0, "accent": "b87333"},
		{"name": "Silver", "minimum": 310, "accent": "b8c2cc"},
		{"name": "Gold", "minimum": 470, "accent": "d9b43b"},
		{"name": "Platinum", "minimum": 620, "accent": "4fd6d2"},
		{"name": "Diamond", "minimum": 760, "accent": "4b9cff"},
		{"name": "Champion", "minimum": 910, "accent": "9b5de5"},
		{"name": "Grand Champion", "minimum": 1170, "accent": "ff5d8f"},
		{"name": "Supersonic Legend", "minimum": 1330, "accent": "f4f1ff"},
	],
	"2v2": [
		{"name": "Bronze", "minimum": 0, "accent": "b87333"},
		{"name": "Silver", "minimum": 370, "accent": "b8c2cc"},
		{"name": "Gold", "minimum": 550, "accent": "d9b43b"},
		{"name": "Platinum", "minimum": 700, "accent": "4fd6d2"},
		{"name": "Diamond", "minimum": 850, "accent": "4b9cff"},
		{"name": "Champion", "minimum": 1020, "accent": "9b5de5"},
		{"name": "Grand Champion", "minimum": 1435, "accent": "ff5d8f"},
		{"name": "Supersonic Legend", "minimum": 1860, "accent": "f4f1ff"},
	],
	"3v3": [
		{"name": "Bronze", "minimum": 0, "accent": "b87333"},
		{"name": "Silver", "minimum": 390, "accent": "b8c2cc"},
		{"name": "Gold", "minimum": 570, "accent": "d9b43b"},
		{"name": "Platinum", "minimum": 720, "accent": "4fd6d2"},
		{"name": "Diamond", "minimum": 870, "accent": "4b9cff"},
		{"name": "Champion", "minimum": 1040, "accent": "9b5de5"},
		{"name": "Grand Champion", "minimum": 1435, "accent": "ff5d8f"},
		{"name": "Supersonic Legend", "minimum": 1860, "accent": "f4f1ff"},
	],
}

const FACILITIES := {
	"hq":
	{
		"name": "Team-Hauptquartier",
		"tag": "HQ",
		"description": "Erhöht das maximale Vereinsansehen und den Sponsorwert.",
		"base_cost": 900,
		"color": "2de2ff",
	},
	"coaching":
	{
		"name": "Leistungszentrum",
		"tag": "CO",
		"description": "Senkt Trainingskosten, verbessert Durchbrüche und zieht stärkere Coaches an.",
		"base_cost": 350,
		"color": "a779ff",
	},
	"scouting":
	{
		"name": "Globales Scouting",
		"tag": "SC",
		"description": "Findet jüngere Talente mit höherem Potenzial.",
		"base_cost": 250,
		"color": "58e39b",
	},
	"analytics":
	{
		"name": "Match-Analyse",
		"tag": "AN",
		"description": "Verbessert Konstanz und deine Siegchance.",
		"base_cost": 400,
		"color": "ffbf69",
	},
	"studio":
	{
		"name": "Content-Studio",
		"tag": "CS",
		"description": "Generiert offline passiv Geld und neue Fans.",
		"base_cost": 300,
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
			"Perfektes Lesen im Mittelfeld öffnet eine klare Chance.",
			"Ein schneller Konter erwischt die Defensive in der Rotation.",
			"Backboard-Druck erzwingt einen Double Commit.",
			"Eine geduldige Fake-Challenge gewinnt den Ballbesitz.",
			"Sauberer Abschluss nach kontrolliertem First Touch.",
		],
		"bad":
		[
			"Der Gegner bestraft einen Overcommit.",
			"Ein verlorenes Fifty im Mittelfeld öffnet das Tor.",
			"Die Boost-Kontrolle bricht in einer langen Defensivphase ein.",
			"Der Gegner verwandelt einen schnellen Infield-Pass.",
		],
		"neutral":
		[
			"Beide Teams verlangsamen das Spiel und resetten ihre Rotation.",
			"Ein enges Mittelfeldduell hält den Spielstand offen.",
			"Starke Paraden auf beiden Seiten halten das Spiel eng.",
		],
	},
	"Fortnite":
	{
		"good":
		[
			"Gute Height-Control sichert die nächste Zone.",
			"Ein sauberer Refresh stabilisiert das Late Game.",
			"Das Trio findet beim Rotate einen sicheren Elim.",
			"Starkes Ressourcenmanagement zahlt sich im Endgame aus.",
			"Ein koordinierter Layer-Wechsel bringt vier Placements.",
		],
		"bad":
		[
			"Eine schwierige Zone kostet zu viele Materialien.",
			"Das Team wird bei einem umkämpften Rotate getrennt.",
			"Ein aggressiver Push kostet wichtige Placement-Punkte.",
			"Der Lobby-Druck erzwingt einen frühen Rückzug.",
		],
		"neutral":
		[
			"Das Team farmt sicher und beobachtet die nächste Zone.",
			"Ein ruhiges Midgame hält alle Optionen offen.",
			"Mehrere Squads rotieren vorbei, ohne zu committen.",
		],
	},
	"Warzone":
	{
		"good":
		[
			"Ein koordinierter Push räumt eine starke Position.",
			"Der Squad gewinnt eine wichtige Rotation in den nächsten Kreis.",
			"Gutes UAV-Timing erzeugt einen wichtigen Teamfight.",
			"Ein disziplinierter Reset macht aus Defense Momentum.",
			"Saubere Kommunikation sichert den nächsten Elim.",
		],
		"bad":
		[
			"Der Squad wird beim Überqueren offenen Geländes eingeklemmt.",
			"Eine späte Rotation gibt dem Gegner die bessere Deckung.",
			"Das Team verliert nach einer riskanten Challenge Momentum.",
			"Ein Gegner-Squad übernimmt die stärkere Position.",
		],
		"neutral":
		[
			"Der Kreis verschiebt sich und alle Squads repositionieren.",
			"Das Team hält Deckung und sammelt Informationen.",
			"Ein kontrollierter Reset hält den ganzen Squad im Spiel.",
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


static func rl_rank_for_mmr(mmr: int, playlist: String) -> Dictionary:
	return RankedDataRef.rank_for_mmr(mmr, playlist)


static func rl_next_rank_for_mmr(mmr: int, playlist: String) -> Dictionary:
	return RankedDataRef.next_rank_for_mmr(mmr, playlist)


static func format_cash(value: int) -> String:
	if value >= 1000000:
		return "€%.2fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "€%.1fK" % (float(value) / 1000.0)
	return "€%d" % value


static func format_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
