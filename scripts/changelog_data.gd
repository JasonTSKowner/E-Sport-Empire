class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "2.2.0"

const ENTRIES := [
	{
		"version": "2.2.0",
		"title": "GAMEPLAY & LIFE",
		"date": "05 OCT 2026",
		"items": [
			"Match-Simulation verlangsamt und in lesbare Spielphasen zerlegt.",
			"1st / 2nd / 3rd-Man-Rotation wird sichtbar dargestellt.",
			"Mechanics erzeugen echte Setups statt nur Text-Boni.",
			"Psycho-Setups und Psycho → Teammate-Redirect-Kombos möglich.",
			"Normales Training kostet kein Geld mehr; Fokus wird über Müdigkeit geregelt.",
			"Mechanic-Mastery beeinflusst, wie oft Elite-Plays sauber funktionieren.",
			"Controller, Display, Internet, Ergonomie und Audio können ausgebaut werden.",
			"WLAN/LAN beeinflusst Stabilität und Konstanz statt direkt Mechanics zu geben.",
			"Empire Backup mit portablem Recovery-Code hinzugefügt.",
			"Ingame-Changelog und Versionshinweise hinzugefügt.",
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
