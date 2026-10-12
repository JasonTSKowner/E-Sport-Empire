class_name ChangelogData
extends RefCounted

const CURRENT_VERSION := "2.5.1"

const ENTRIES := [
	{
		"version": "2.5.1",
		"title": "PREMIUM REBUILD",
		"date": "12 OCT 2026",
		"items": [
			"Home wurde zu einer echten Season-Hero-Ansicht mit Spielerportrait, Rank-Badge und klarer Hauptaktion umgebaut.",
			"Ranked nutzt eine größere Competitive-Stage mit stärkerer Arena-Atmosphäre und weniger Dashboard-Optik.",
			"Team- und Scout-Ansichten verwenden neue vollflächige Player Cards statt formularartiger Datenblöcke.",
			"Player Cards zeigen OVR, Potenzial, Esports-Silhouette, Kernstats, Rotation, Consistency und Boost-Control in einer gemeinsamen visuellen Fläche.",
			"Der Vereinsbereich besitzt jetzt ein sichtbares Club HQ mit eigenen Modulen für HQ, Performance, Scouting, Analytics und Content.",
			"Anlagen-Level verändern die dargestellten HQ-Module und geben Vereinsfortschritt damit erstmals sichtbare Form.",
			"Training zeigt keine €0-Käufe mehr: normale Sessions erscheinen als Fokus-Drills und bleiben kostenlos.",
			"Match- und Training-Autos erhielten Chassis-, Dach-, Rad-, Glas-, Licht-, Schatten- und mehrschichtige Boost-Details.",
			"Ballhöhe wurde mit stärkeren Bodenschatten, Höhenlinie, Panel-Details und größerer Tiefenskalierung deutlich lesbarer.",
			"Gameplay-Flächen wurden weiter vergrößert; Mechanical Setups und Rotationen laufen langsamer und lesbarer.",
			"Alle Mechanics, Team-Combos, Failure States, Mastery, Setup/WLAN, Backup und Progressionssysteme bleiben erhalten.",
		],
	},
	{
		"version": "2.5.0",
		"title": "GAMEPLAY PRESENTATION",
		"date": "11 OCT 2026",
		"items": [
			"Match- und Training-Kamera wurden für Mobile deutlich stärker auf Gameplay statt Taktikdiagramm ausgerichtet.",
			"Autos sind größer, besitzen klarere Fahrzeugrichtung, Räder, Glas, Lichtdetails, Schatten und stärkere Boost-Trails.",
			"Ballhöhe ist durch Bodenschatten, vertikale Distanz und größere Ball-Darstellung leichter zu lesen.",
			"Ballflugbahnen zeigen jetzt eine klarere Kurve mit Zwischenpunkten und sichtbarer Landezone.",
			"1st-, 2nd- und 3rd-Man-Rotation bleibt sichtbar; aktive und unterstützende Laufwege erhalten klarere Pfeile.",
			"Arena, Sidewalls, Goals, Crowd und Licht-Rigs wurden stärker räumlich aufgebaut, damit Gameplay weniger flach wirkt.",
			"Training verwendet dieselbe Broadcast-/Arena-Sprache wie Matches und zeigt Drill-Ziel, Fahrzeugweg und Ballweg klarer.",
			"Match-Playback wurde weiter verlangsamt, damit Mechanical Setups, Redirects und Rotationen lesbar bleiben.",
			"Alle Mechanics, Team-Combos, Mastery-, Setup-, Backup- und Progressionssysteme der vorherigen Versionen bleiben erhalten.",
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
			"Mobile-Visuals und Android-Release-Metadaten wurden auf den aktuellen v2.4.3-Stand synchronisiert.",
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
			"Spielerprofil und Rank-Präsentation wurden größer und stärker auf visuelle Hierarchie ausgerichtet.",
			"Alle Gameplay-, Mechanic-, Setup-, Backup- und Progressionssysteme aus v2.3 bleiben erhalten.",
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
			"Neue Failure States: verfehlte Resets, zu weite Carries, schlechte Backboard-Reads, verpasste Redirects und Pinches.",
			"Mehrstufige Reset-Chains bis Quad Reset werden sichtbar ausgespielt.",
			"Neue Team-Plays wie Reset Pass → Redirect, Ceiling Pass → Redirect, Backboard Pass → Finish und Team Pinches.",
			"Psycho- und Musty-Psycho-Plays können weiterhin in Teammate-Redirects übergehen.",
			"Training zeigt die höchste freigeschaltete Mechanik mit passendem Ablauf statt generischem Movement.",
			"Mechanic Library im Training zeigt Unlock-Fortschritt, Tier und einzelne Mastery-Komponenten.",
			"Mechanical Match-Phasen laufen langsamer, damit Ballweg, Rotation und Reads sichtbar bleiben.",
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
