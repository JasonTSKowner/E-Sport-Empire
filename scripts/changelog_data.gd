class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "2.5.0"

const ENTRIES := [
	{
		"version": "2.5.0",
		"title": "REAL 3D ARENA",
		"date": "06 OCT 2026",
		"items": [
			"Match und Training nutzen jetzt echte Godot-3D-SubViewports statt gezeichneter 2D-Taktikfelder.",
			"Neue 3D-Arena mit Perspektivkamera, Goals, Boards, Boost-Pads, Stadionlicht und echter räumlicher Tiefe.",
			"Spieler werden als 3D-Car-Meshes dargestellt; aktive Spieler und Support-Rollen werden direkt auf dem Feld hervorgehoben.",
			"Ballflugbahnen und Rotationswege werden räumlich dargestellt und folgen weiter der bestehenden Match-Simulation.",
			"Aerials, Resets, Mustys, Psychos, Ceiling-Plays, Pogos und Redirects heben Autos sichtbar vom Boden ab und verändern ihre Ausrichtung.",
			"Kamera verfolgt Mechanical Plays enger und bleibt bei normalen Rotationen weiter genug draußen, damit das Teamplay lesbar bleibt.",
			"Home und Ranked nutzen dieselbe 3D-Arena als visuelle Bühne statt separater Dashboard-Karten.",
			"Training zeigt den ausgewählten Drill in derselben 3D-Welt mit Zielzone, Ball-Prediction und nächster Fahrroute.",
			"Alle Mechanics, Combo-Logik, Setup/WLAN, Backup, Changelog und Progressionssysteme bleiben erhalten.",
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
			"Match-Ansicht nutzt einen neuen Broadcast-Arena-Renderer mit größeren Autos, Ball und klarerer Tiefenwirkung.",
			"Ballflugbahnen werden als lesbare Bögen dargestellt, damit Mechanical Plays nicht mehr wie Teleports wirken.",
			"1st-, 2nd- und 3rd-Man-Rotationen bleiben sichtbar, aber deutlich weniger debug-artig.",
			"Training nutzt einen eigenen Arena-Renderer mit größerem Gameplay-Bereich, Zielzone und klarer Bewegungsroute.",
			"Weniger Mikro-Text und weniger verschachtelte Panels auf den wichtigsten Mobile-Screens.",
	],
	},
	{
		"version": "2.3.0",
		"title": "MECHANICAL EXPANSION",
		"date": "05 OCT 2026",
		"items": [
			"Massiver Mechanic-Tree mit Movement, Flicks, Aerials, Resets, Ceiling, Pinches, Defense, Freestyle und Team-Plays.",
			"Mechanics besitzen jetzt Setup-, Control-, Read- und Finish-Mastery statt nur einen Gesamtwert.",
			"Mechanic-Unlocks hängen zusätzlich von vorherigen Skills im Tree ab.",
			"Match-KI wählt Mechanics abhängig von Spielsituation, Playstyle, Mastery und Match-Kontext.",
			"Neue Failure States und mehrstufige Reset-Chains bis Quad Reset.",
			"Neue Team-Plays inklusive Psycho- und Musty-Psycho-Redirects.",
	],
	},
	{
		"version": "2.2.0",
		"title": "GAMEPLAY & LIFE",
		"date": "05 OCT 2026",
		"items": [
			"Lesbarere Matchphasen und sichtbare 1st-/2nd-/3rd-Man-Rotation.",
			"Kostenloses Drill-Training mit Müdigkeit und Mechanic-Mastery.",
			"Setup, Internet, Empire Backup und Ingame-Changelog hinzugefügt.",
	],
	},
	{
		"version": "2.1.0",
		"title": "CINEMATIC UI",
		"date": "04 OCT 2026",
		"items": [
			"Neue Cinematic Shell und visuellere Spielerprofile.",
			"Scouting-, Team- und Vereinsseiten entschlackt.",
			"Mobile Layout weiter auf 412×915 optimiert.",
	],
	},
]

static func latest() -> Dictionary:
	return ENTRIES[0].duplicate(true)
