class_name MechanicalSequencesV23
extends RefCounted


static func sequence_for(item: Dictionary) -> Array:
	var mechanic_id := str(item.get("id", ""))
	var family := str(item.get("family", ""))
	if mechanic_id == "psycho" or mechanic_id == "musty_psycho":
		return _psycho_sequence(mechanic_id == "musty_psycho")
	if mechanic_id in ["double_reset", "triple_reset", "quad_reset"]:
		return _multi_reset_sequence(mechanic_id)
	if mechanic_id in ["musty_double_tap", "ceiling_double_tap"]:
		return _double_tap_sequence(mechanic_id)
	match family:
		"recovery": return _recovery_sequence(mechanic_id)
		"flick": return _flick_sequence(mechanic_id)
		"musty": return _musty_sequence(mechanic_id)
		"air_dribble": return _air_dribble_sequence(mechanic_id)
		"double_tap": return _double_tap_sequence(mechanic_id)
		"redirect": return _redirect_sequence(mechanic_id)
		"ceiling": return _ceiling_sequence(mechanic_id)
		"reset", "multi_reset", "stall": return _reset_sequence(mechanic_id)
		"pinch": return _pinch_sequence(mechanic_id)
		"team_pinch": return _team_pinch_sequence(mechanic_id)
		"pogo": return _pogo_sequence(mechanic_id)
		"defense", "save": return _defense_sequence(mechanic_id)
		"freestyle": return _freestyle_sequence(mechanic_id)
		_: return _generic_sequence(mechanic_id)


static func combo(combo_id: String) -> Array:
	match combo_id:
		"psycho_redirect":
			return [
				_p("psycho_setup", "Ballkontrolle an der eigenen Sidewall."),
				_p("own_wall_carry", "Der Ball wird hoch an die eigene Backwall getragen."),
				_p("backwall_musty", "Musty gegen die Backwall — der Ball beschleunigt quer durchs Feld."),
				_p("psycho_contact", "Psycho-Touch in die zweite Zone."),
				_p("teammate_prejump", "Der 2nd Man prejumped die Flugbahn."),
				_p("redirect_finish", "Direkter Redirect des Mitspielers aufs Tor."),
			]
		"air_dribble_redirect":
			return [
				_p("wall_setup", "Wall Setup mit offener Passing-Lane."),
				_p("air_carry", "Der Carry zieht den ersten Verteidiger aus der Rotation."),
				_p("air_pass", "Der letzte Touch wird bewusst quergelegt."),
				_p("teammate_prejump", "Der Mitspieler liest den Pass früh."),
				_p("redirect_finish", "Redirect in die freie Ecke."),
			]
		"reset_pass_redirect":
			return [
				_p("wall_setup", "Wall Setup mit Platz für den Reset."),
				_p("reset_contact", "Reset gesichert."),
				_p("reset_pass", "Der Flip wird nicht zum Schuss, sondern als Pass benutzt."),
				_p("teammate_prejump", "Der 2nd Man startet vor dem Pass."),
				_p("redirect_finish", "Prejump Redirect aufs Tor."),
			]
		"backboard_pass_finish":
			return [
				_p("backboard_pass", "Harter Touch ans gegnerische Backboard."),
				_p("teammate_read", "Der Mitspieler hält Abstand und liest den Rebound."),
				_p("redirect_finish", "Direkter Finish aus dem Backboard-Pass."),
			]
		"ceiling_pass_redirect":
			return [
				_p("ceiling_setup", "Setup über die Sidewall bis an die Decke."),
				_p("ceiling_drop", "Kontrollierter Drop mit gespeichertem Flip."),
				_p("air_pass", "Statt Shot kommt der Pass quer."),
				_p("teammate_prejump", "Der 2nd Man ist bereits airborne."),
				_p("redirect_finish", "Ceiling Pass → Redirect."),
			]
		"team_ground_pinch":
			return [
				_p("pinch_setup", "Beide Spieler schließen denselben Bodenwinkel."),
				_p("team_sync", "Kontaktfenster stimmt — beide Autos treffen gleichzeitig."),
				_p("pinch_release", "Team Pinch mit maximaler Ballgeschwindigkeit."),
			]
		"team_air_pinch":
			return [
				_p("air_pass", "Hoher Ball wird in die gemeinsame Flugbahn gelegt."),
				_p("teammate_prejump", "Beide Spieler committen synchron."),
				_p("team_sync", "Doppelkontakt in der Luft."),
				_p("pinch_release", "Air Pinch Richtung Tor."),
			]
	return []


static func failure_for(item: Dictionary, stage: String) -> Dictionary:
	var family := str(item.get("family", ""))
	var label := str(item.get("label", "Mechanic"))
	var text := "%s bricht im Setup ab — der Ball bleibt spielbar." % label
	match family:
		"reset", "multi_reset", "stall":
			text = "%s: Reset-Kontakt knapp verfehlt — Recovery statt Finish." % label
		"air_dribble":
			text = "%s: Ball zu weit vom Auto — der Carry endet früh." % label
		"double_tap":
			text = "%s: Backboard-Read stimmt nicht ganz — kein zweiter Touch." % label
		"redirect":
			text = "%s: Timing zu spät — Redirect geht am Tor vorbei." % label
		"psycho":
			text = "%s: Backwall-Winkel passt nicht — der Psycho wird abgebrochen." % label
		"pinch", "team_pinch":
			text = "%s: Kontaktfenster verpasst — der Pinch verliert Geschwindigkeit." % label
		"pogo":
			text = "%s: Bounce nicht sauber getroffen — kontrollierte Recovery." % label
		"musty":
			text = "%s: Flick lädt zu früh — Ball bleibt am Gegner hängen." % label
		"save", "defense":
			text = "%s: Read knapp daneben — der nächste Spieler muss übernehmen." % label
	return {"phase":"mechanic_fail","text":text,"stage":stage}


static func _p(phase: String, text: String) -> Dictionary:
	return {"phase":phase,"text":text}


static func _generic_sequence(id: String) -> Array:
	return [_p("control_setup", "%s wird vorbereitet." % id), _p("finish_touch", "Sauberer Abschluss der Mechanik.")]


static func _recovery_sequence(id: String) -> Array:
	if id in ["wall_dash", "chain_dash", "ceiling_shuffle", "reverse_ceiling_shuffle"]:
		return [_p("recovery_setup", "Recovery-Linie wird vorbereitet."), _p("dash_chain", "Mehrere Dash-Kontakte halten Supersonic-Speed."), _p("rotation_switch", "Der Spieler kommt ohne Boost-Verlust zurück in die Rotation.")]
	return [_p("recovery_setup", "Auto landet kontrolliert in Fahrtrichtung."), _p("recovery_dash", "Recovery beschleunigt sofort zurück ins Play."), _p("rotation_switch", "Nächste Rotation wird erreicht.")]


static func _flick_sequence(id: String) -> Array:
	return [_p("control_setup", "Ball wird mittig auf dem Auto stabilisiert."), _p("flick_load", "%s wird geladen." % id.replace("_", " ").capitalize()), _p("flick_release", "Flick über die Challenge."), _p("finish_touch", "Ball fliegt in die Abschlusszone.")]


static func _musty_sequence(id: String) -> Array:
	return [_p("control_setup", "Kontrollierter Setup-Touch."), _p("musty_load", "Auto kippt unter den Ball."), _p("musty_release", "%s beschleunigt den Ball über den Verteidiger." % id.replace("_", " ").capitalize()), _p("finish_touch", "Follow-up Richtung Tor.")]


static func _air_dribble_sequence(id: String) -> Array:
	var result := [_p("wall_setup", "Ball wird mit passender Distanz an die Wall genommen."), _p("air_carry", "Erster Aerial-Touch hält den Ball nah."), _p("air_carry_2", "Zweiter Touch korrigiert Höhe und Richtung.")]
	if id == "air_dribble_bump":
		result.append(_p("bump_route", "Der Ball bleibt gefährlich, während der Spieler den Keeper attackiert."))
	else:
		result.append(_p("finish_touch", "Letzter Carry-Touch als Abschluss."))
	return result


static func _double_tap_sequence(id: String) -> Array:
	var result := []
	if id == "musty_double_tap":
		result.append(_p("musty_release", "Musty als erster Touch ans Backboard."))
	elif id == "ceiling_double_tap":
		result.append(_p("ceiling_drop", "Ceiling Drop in den ersten Backboard-Touch."))
	else:
		result.append(_p("backboard_shot", "Erster Touch bewusst ans Backboard."))
	result.append(_p("backboard_read", "Spieler folgt der Flugbahn statt sofort zu recovern."))
	result.append(_p("double_tap_finish", "Zweiter Touch direkt aufs Tor."))
	return result


static func _redirect_sequence(id: String) -> Array:
	return [_p("redirect_read", "Flugbahn wird früh gelesen."), _p("prejump", "Aerial startet vor dem Ballkontakt." if "prejump" in id else "Aerial-Linie wird geschlossen."), _p("redirect_finish", "Redirect verändert Winkel und Tempo Richtung Tor.")]


static func _ceiling_sequence(id: String) -> Array:
	return [_p("wall_setup", "Wall Carry Richtung Decke."), _p("ceiling_setup", "Alle vier Räder setzen an der Decke auf."), _p("ceiling_drop", "Drop mit gespeichertem Flip."), _p("finish_touch", "%s als Abschluss." % id.replace("_", " ").capitalize())]


static func _reset_sequence(id: String) -> Array:
	return [_p("wall_setup", "Setup mit genug Abstand unter dem Ball."), _p("reset_contact", "Vier Räder treffen die Unterseite — Reset gesichert."), _p("reset_control", "Nach dem Reset bleibt der Ball kontrollierbar."), _p("finish_touch", "%s wird abgeschlossen." % id.replace("_", " ").capitalize())]


static func _multi_reset_sequence(id: String) -> Array:
	var count := 2 if id == "double_reset" else 3 if id == "triple_reset" else 4
	var result := [_p("wall_setup", "Hoher Setup-Touch mit viel Boostreserve.")]
	for index in range(count):
		result.append(_p("reset_%d" % (index + 1), "Reset %d/%d gesichert." % [index + 1, count]))
	result.append(_p("finish_touch", "Letzter Flip wird für den Finish gehalten."))
	return result


static func _pinch_sequence(id: String) -> Array:
	return [_p("pinch_setup", "Ball und Auto werden in denselben Kontaktwinkel gebracht."), _p("pinch_contact", "%s trifft den Ball zwischen Auto und Oberfläche." % id.replace("_", " ").capitalize()), _p("pinch_release", "Der Ball explodiert mit hoher Geschwindigkeit aus dem Kontakt.")]


static func _team_pinch_sequence(id: String) -> Array:
	return [_p("pinch_setup", "Beide Spieler schließen denselben Winkel."), _p("teammate_prejump", "Der Mitspieler synchronisiert seinen Kontakt."), _p("team_sync", "Beide Kontakte treffen nahezu gleichzeitig."), _p("pinch_release", "%s Richtung Tor." % id.replace("_", " ").capitalize())]


static func _pogo_sequence(id: String) -> Array:
	return [_p("air_setup", "Aerial Setup mit vertikalem Winkel."), _p("pogo_drop", "Auto fällt kontrolliert auf Nose/Back."), _p("pogo_bounce", "Bounce gibt neue Höhe ohne Boostverlust."), _p("finish_touch", "%s wird aus dem Bounce abgeschlossen." % id.replace("_", " ").capitalize())]


static func _psycho_sequence(with_musty: bool) -> Array:
	var result := [_p("psycho_setup", "Ball wird an die eigene Sidewall genommen."), _p("own_wall_carry", "Carry öffnet den Winkel zur eigenen Backwall.")]
	if with_musty:
		result.append(_p("backwall_musty", "Musty erzeugt den harten Backwall-Bounce."))
	else:
		result.append(_p("backwall_touch", "Kontrollierter Touch an die eigene Backwall."))
	result.append(_p("psycho_contact", "Recovery in die Flugbahn — Psycho Richtung gegnerisches Tor."))
	return result


static func _defense_sequence(id: String) -> Array:
	return [_p("defense_read", "%s liest Ball und Gegner gleichzeitig." % id.replace("_", " ").capitalize()), _p("save_line", "Challenge-Linie wird geschlossen."), _p("clear_touch", "Save wird nicht nur geblockt, sondern kontrolliert gecleart."), _p("rotation_switch", "Recovery über Backpost in die nächste Rotation.")]


static func _freestyle_sequence(id: String) -> Array:
	return [_p("control_setup", "%s Setup beginnt mit enger Ballkontrolle." % id.replace("_", " ").capitalize()), _p("freestyle_transition", "Auto verändert Orientierung ohne Ballkontrolle zu verlieren."), _p("finish_touch", "Freestyle-Finish Richtung Tor.")]
