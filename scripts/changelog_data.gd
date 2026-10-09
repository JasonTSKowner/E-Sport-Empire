class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "2.5.0"

const ENTRIES := [
	{
		"version": "2.5.0",
		"title": "VISUAL GAMEPLAY",
		"date": "09 OCT 2026",
		"items": [
			"Training wurde von einer Menü-Karte zu einer gameplay-first Arena-Ansicht umgebaut.",
			"Arena nimmt deutlich mehr Bildschirmfläche ein; Fokus, Müdigkeit und Mechanic-Mastery liegen direkt im HUD.",
			"Defense-, Finishing- und Rotation-Drills zeigen jetzt passende Gegner-, Keeper- oder Support-Ghosts.",
			"Autos, Ball, Tore, Seitenwände, Crowd und Licht wurden für stärkere Tiefe und bessere Lesbarkeit neu gezeichnet.",
			"Match-Broadcast nutzt größere Fahrzeuge, klarere Ballflugbahnen und weniger debug-artige Rotationspfade.",
			"Mechanical Plays und wichtige Matchphasen laufen langsamer, damit Setups, Rotation und Redirects sichtbar bleiben.",
			"Alle Mechanics-, Teamplay-, Setup-, Backup- und Progressionssysteme bleiben erhalten.",
		],
	},
	{
		"version": "2.4.3",
		"title": "SEASON HUB & PERSPECTIVE PASS",
		"date": "06 OCT 2026",
		"items": [
			"Startseite wurde als Season Hub mit größerer Rank-Inszenierung und klarerem nächstem Ziel aufgebaut.",
			"Ranked nutzt eine fokussiertere Competitive-Hero-Fläche statt gestapelter Dashboard-Karten.",
			"Match- und Training-Renderer wurden in eine stärkere Arena-/Broadcast-Perspektive überführt.",
			"Ballflug, aktive Spieler, Support-Rollen und Rotationswege bleiben lesbar, wirken aber weniger wie Debug-Overlays.",
			"Mechanical Plays, Psycho-Setups, Redirects und Team-Combos aus v2.3 bleiben vollständig erhalten.",
		],
	},
	{
		"version": "2.4.0",
		"title": "VISUAL REBUILD",
		"date": "05 OCT 2026",
		"items": [
			"Home und Ranked wurden von gestapelten App-Karten auf große visuelle Hero-Flächen umgebaut.",
			"Match-Ansicht nutzt einen Broadcast-Arena-Renderer mit klarerer Tiefenwirkung.",
			"Ballflugbahnen werden als lesbare Bögen dargestellt.",
			"1st-, 2nd- und 3rd-Man-Rotationen bleiben sichtbar.",
		],
	},
	{
		"version": "2.3.0",
		"title": "MECHANICAL EXPANSION",
		"date": "05 OCT 2026",
		"items": [
			"Massiver Mechanic-Tree mit Movement, Flicks, Aerials, Resets, Ceiling, Pinches, Defense, Freestyle und Team-Plays.",
			"Mechanics besitzen Setup-, Control-, Read- und Finish-Mastery.",
			"Neue Failure States und Team-Plays inklusive Psycho-Redirects.",
		],
	},
	{
		"version": "2.2.0",
		"title": "GAMEPLAY & LIFE",
		"date": "05 OCT 2026",
		"items": [
			"Lesbarere Matchphasen, sichtbare Rotation, kostenloses Training, Setup/WLAN und Empire Backup.",
		],
	},
]

static func latest() -> Dictionary:
	return ENTRIES[0].duplicate(true)
