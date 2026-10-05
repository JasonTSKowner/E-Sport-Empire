class_name MechanicalSequenceData
extends RefCounted

const SEQUENCES := {
	"air_dribble": [
		{"phase": "wall_setup", "text": "Ball wird kontrolliert an die Seitenwand genommen."},
		{"phase": "air_carry", "text": "Erster Touch aus der Wall — der Ball bleibt nah am Auto."},
		{"phase": "air_carry_2", "text": "Zweiter kontrollierter Touch hält den Air Dribble am Leben."},
		{"phase": "finish_touch", "text": "Der letzte Touch setzt den Abschluss aufs Tor."},
	],
	"musty_flick": [
		{"phase": "control_setup", "text": "Ballkontrolle vor dem letzten Verteidiger."},
		{"phase": "musty_load", "text": "Das Auto kippt unter den Ball und lädt den Musty."},
		{"phase": "musty_release", "text": "Musty Flick — der Ball beschleunigt über die Challenge."},
	],
	"flip_reset": [
		{"phase": "wall_setup", "text": "Wall Setup mit genug Abstand für den Aerial."},
		{"phase": "reset_contact", "text": "Vier Räder unter den Ball — Flip Reset gesichert."},
		{"phase": "reset_delay", "text": "Kurzer Delay, der Verteidiger muss zuerst reagieren."},
		{"phase": "finish_touch", "text": "Der gespeicherte Flip wird für den Abschluss benutzt."},
	],
	"double_reset": [
		{"phase": "wall_setup", "text": "Wall Setup in den freien Raum."},
		{"phase": "reset_contact", "text": "Erster Flip Reset unter dem Ball."},
		{"phase": "second_reset", "text": "Der Ball bleibt nah genug für den zweiten Reset."},
		{"phase": "finish_touch", "text": "Zweiter Flip wird für den Finish genutzt."},
	],
	"psycho": [
		{"phase": "psycho_setup", "text": "KESHI nimmt den Ball kontrolliert an die eigene Sidewall."},
		{"phase": "own_wall_carry", "text": "Er fährt mit dem Ball hoch und öffnet den Winkel zur eigenen Backwall."},
		{"phase": "backwall_musty", "text": "Musty gegen die eigene Backwall — der Ball wird quer über das Feld beschleunigt."},
		{"phase": "psycho_contact", "text": "KESHI recovered und trifft den Psycho-Touch Richtung gegnerisches Tor."},
	],
	"triple_reset": [
		{"phase": "wall_setup", "text": "Hoher Wall Setup mit viel Boost."},
		{"phase": "reset_contact", "text": "Erster Reset."},
		{"phase": "second_reset", "text": "Zweiter Reset bei weiterhin enger Ballkontrolle."},
		{"phase": "third_reset", "text": "Dritter Reset — der Verteidiger hat kaum noch einen Read."},
		{"phase": "finish_touch", "text": "Der letzte Flip setzt den Abschluss."},
	],
}

const COMBOS := {
	"psycho_redirect": [
		{"phase": "psycho_setup", "text": "KESHI nimmt den Ball kontrolliert an die eigene Sidewall."},
		{"phase": "own_wall_carry", "text": "Er fährt mit dem Ball hoch und öffnet den Winkel zur eigenen Backwall."},
		{"phase": "backwall_musty", "text": "Musty gegen die eigene Backwall — der Ball schießt quer durchs Feld."},
		{"phase": "psycho_contact", "text": "Psycho-Touch Richtung zweite Zone — der Mitspieler liest ihn früh."},
		{"phase": "teammate_prejump", "text": "Der 2nd Man prejumped, während KESHI bereits aus der Aktion rotiert."},
		{"phase": "redirect_finish", "text": "Redirect vom Mitspieler — der Psycho wird direkt ins Tor verlängert."},
	],
	"air_dribble_redirect": [
		{"phase": "wall_setup", "text": "Wall Setup mit klarer Passing-Lane."},
		{"phase": "air_carry", "text": "Der Air Dribble zieht den ersten Verteidiger aus der Rotation."},
		{"phase": "air_pass", "text": "Der letzte Carry-Touch wird quer als Pass abgelegt."},
		{"phase": "teammate_prejump", "text": "Der 2nd Man liest den Pass früh und geht hoch."},
		{"phase": "redirect_finish", "text": "Redirect aufs Tor."},
	],
}


static func sequence(mechanic_id: String) -> Array:
	return SEQUENCES.get(mechanic_id, []).duplicate(true)


static func combo(combo_id: String) -> Array:
	return COMBOS.get(combo_id, []).duplicate(true)
