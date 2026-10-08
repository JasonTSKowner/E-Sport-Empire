class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "3.0.0"

const ENTRIES := [
	{
		"version": "3.0.0",
		"title": "COMMERCIAL REBUILD",
		"date": "08 OCT 2026",
		"items": [
			"Komplette neue Commercial UI-Schicht für die wichtigsten Mobile-Screens.",
			"Home wurde als Match-Night-Stadion-Hero mit Crowd, Licht-Rigs, Arena-Tiefe und klarer Hauptaktion neu gebaut.",
			"Ranked nutzt eine eigene Competitive-Bühne mit größerem Rank-Fokus und weniger Dashboard-Optik.",
			"Spielerprofile wurden als Starting-Roster-Präsentation statt Formular-/Kartenansicht neu aufgebaut.",
			"Scouting nutzt jetzt visuelle Live-Reports mit größerer Spielerinszenierung.",
			"Match wurde als großer Broadcast-Arena-Renderer mit tiefer Perspektive, Tor-Tunneln, Crowd, Scorebug und größeren Fahrzeugen neu gebaut.",
			"Ballflugbahnen, Ballhöhe und Mechanical Plays bleiben sichtbar, wirken aber deutlich weniger wie Debug-Grafiken.",
			"Training wurde als Performance Lab mit Arena-Perspektive, Ghost-Frames, Zielzone und lesbaren Mechanic-Phasen neu gebaut.",
			"Psycho, Redirects, Reset-Chains, Team-Combos, Rotation, Mastery und Failure States aus v2.3 bleiben vollständig erhalten.",
			"Setup/WLAN, kostenloses Training, Backup und bestehende Karriere-/Vereinsprogression bleiben erhalten.",
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
		],
	},
	{
		"version": "2.3.0",
		"title": "MECHANICAL EXPANSION",
		"date": "05 OCT 2026",
		"items": [
			"Massiver Mechanic-Tree mit Movement, Flicks, Aerials, Resets, Ceiling, Pinches, Defense, Freestyle und Team-Plays.",
			"Mechanics besitzen Setup-, Control-, Read- und Finish-Mastery.",
			"Neue Failure States und Team-Plays inklusive Psycho-Redirect und Reset-Pass-Combos.",
			"Mechanical Match-Phasen laufen langsamer, damit Ballweg, Rotation und Reads sichtbar bleiben.",
		],
	},
	{
		"version": "2.2.0",
		"title": "GAMEPLAY & LIFE",
		"date": "05 OCT 2026",
		"items": [
			"Lesbare Match-Phasen, echte Rotation und Mechanical Setups.",
			"Normales Training kostet kein Geld mehr; Fokus wird über Müdigkeit geregelt.",
			"Setup, Internet, Recovery-Backup und Ingame-Changelog hinzugefügt.",
		],
	},
]

static func latest() -> Dictionary:
	return ENTRIES[0].duplicate(true)
