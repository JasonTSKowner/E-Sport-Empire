class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "3.0.0"

const ENTRIES := [
	{
		"version": "3.0.0",
		"title": "VISUAL REBUILD 3.0",
		"date": "08 OCT 2026",
		"items": [
			"Großer Versionssprung: der bisherige v2.4.3 Season-Hub/Perspective-Stand ist jetzt die Basis von E-Sport Empire 3.0.",
			"Home und Ranked bleiben auf große Hero-Flächen statt gestapelter Dashboard-Karten fokussiert.",
			"Match und Training nutzen die neue Arena-/Broadcast-Perspektive mit größerer Spielfläche und weniger Debug-Look.",
			"Ballflug, Rotation, 1st/2nd/3rd-Man-Rollen und Mechanical Sequences bleiben sichtbar und lesbar.",
			"Psycho-, Reset-, Redirect-, Pinch- und Team-Combo-Systeme aus der Mechanical Expansion bleiben vollständig erhalten.",
			"Setup/WLAN, kostenloses Training, Mechanic Mastery, Failure States, Backup und Ingame-Changelog bleiben Teil des 3.0-Core-Loops.",
			"Release-Metadaten, Android-Version und Build-Pipeline wurden auf 3.0 synchronisiert.",
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
			"Mechanics besitzen Setup-, Control-, Read- und Finish-Mastery statt nur einen Gesamtwert.",
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
			"Match-Simulation verlangsamt und in lesbare Spielphasen zerlegt.",
			"1st / 2nd / 3rd-Man-Rotation wird sichtbar dargestellt.",
			"Mechanics erzeugen echte Setups statt nur Text-Boni.",
			"Normales Training kostet kein Geld mehr; Fokus wird über Müdigkeit geregelt.",
			"Controller, Display, Internet, Ergonomie und Audio können ausgebaut werden.",
			"Empire Backup und Ingame-Changelog hinzugefügt.",
		],
	},
]


static func latest() -> Dictionary:
	return ENTRIES[0].duplicate(true)
