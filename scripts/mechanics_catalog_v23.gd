class_name MechanicsCatalogV23
extends RefCounted

const CATEGORIES := ["movement", "ground", "aerial", "reset", "ceiling", "pinch", "freestyle", "defense", "team"]

const MECHANICS := [
	# MOVEMENT / RECOVERY
	{"id":"half_flip","label":"Half Flip","category":"movement","family":"recovery","tier":1,"req":{"mechanics":42,"rotation":42},"needs":[]},
	{"id":"wavedash","label":"Wavedash","category":"movement","family":"recovery","tier":1,"req":{"mechanics":48,"rotation":44},"needs":[]},
	{"id":"fast_aerial","label":"Fast Aerial","category":"movement","family":"aerial","tier":1,"req":{"mechanics":54,"boost_control":50},"needs":[]},
	{"id":"speed_flip","label":"Speed Flip","category":"movement","family":"recovery","tier":2,"req":{"mechanics":60,"consistency":54},"needs":["half_flip"]},
	{"id":"wall_dash","label":"Wall Dash","category":"movement","family":"recovery","tier":2,"req":{"mechanics":66,"boost_control":58},"needs":["wavedash"]},
	{"id":"zap_dash","label":"Zap Dash","category":"movement","family":"recovery","tier":3,"req":{"mechanics":74,"consistency":66},"needs":["wavedash","speed_flip"]},
	{"id":"chain_dash","label":"Chain Dash","category":"movement","family":"recovery","tier":3,"req":{"mechanics":77,"consistency":70},"needs":["wall_dash"]},
	{"id":"lix_jump","label":"Lix Jump","category":"movement","family":"recovery","tier":4,"req":{"mechanics":84,"consistency":78},"needs":["zap_dash"]},
	{"id":"hel_jump","label":"Hel Jump","category":"movement","family":"recovery","tier":4,"req":{"mechanics":86,"consistency":80},"needs":["zap_dash"]},
	{"id":"ceiling_shuffle","label":"Ceiling Shuffle","category":"movement","family":"ceiling","tier":4,"req":{"mechanics":88,"boost_control":80},"needs":["wall_dash","fast_aerial"]},
	{"id":"reverse_ceiling_shuffle","label":"Reverse Ceiling Shuffle","category":"movement","family":"ceiling","tier":5,"req":{"mechanics":93,"consistency":87},"needs":["ceiling_shuffle"]},

	# GROUND / FLICKS
	{"id":"hook_shot","label":"Hook Shot","category":"ground","family":"flick","tier":1,"req":{"shooting":48,"game_sense":44},"needs":[]},
	{"id":"powerslide_cut","label":"Powerslide Cut","category":"ground","family":"flick","tier":1,"req":{"mechanics":50,"game_sense":46},"needs":[]},
	{"id":"45_flick","label":"45° Flick","category":"ground","family":"flick","tier":2,"req":{"mechanics":58,"shooting":56},"needs":["powerslide_cut"]},
	{"id":"90_flick","label":"90° Flick","category":"ground","family":"flick","tier":2,"req":{"mechanics":62,"shooting":58},"needs":["45_flick"]},
	{"id":"180_flick","label":"180° Flick","category":"ground","family":"flick","tier":3,"req":{"mechanics":68,"shooting":63},"needs":["90_flick"]},
	{"id":"delay_flick","label":"Delay Flick","category":"ground","family":"flick","tier":3,"req":{"mechanics":70,"game_sense":65},"needs":["45_flick"]},
	{"id":"musty_flick","label":"Musty Flick","category":"ground","family":"musty","tier":3,"req":{"mechanics":72,"shooting":67},"needs":["45_flick"]},
	{"id":"breezi_flick","label":"Breezi Flick","category":"ground","family":"musty","tier":4,"req":{"mechanics":80,"shooting":72},"needs":["musty_flick"]},
	{"id":"mawkzy_flick","label":"Mawkzy Flick","category":"ground","family":"flick","tier":4,"req":{"mechanics":82,"shooting":76,"consistency":72},"needs":["delay_flick"]},
	{"id":"jzr_flick","label":"JZR Flick","category":"ground","family":"flick","tier":4,"req":{"mechanics":84,"shooting":75},"needs":["180_flick"]},
	{"id":"wizard_flick","label":"Wizard Flick","category":"ground","family":"flick","tier":5,"req":{"mechanics":90,"consistency":84},"needs":["breezi_flick"]},
	{"id":"stall_flick","label":"Stall Flick","category":"ground","family":"stall","tier":5,"req":{"mechanics":92,"consistency":86},"needs":["breezi_flick"]},

	# AERIAL / REDIRECT
	{"id":"air_dribble","label":"Air Dribble","category":"aerial","family":"air_dribble","tier":2,"req":{"mechanics":64,"shooting":58,"boost_control":58},"needs":["fast_aerial"]},
	{"id":"ground_air_dribble","label":"Ground-to-Air Dribble","category":"aerial","family":"air_dribble","tier":3,"req":{"mechanics":70,"shooting":63},"needs":["air_dribble"]},
	{"id":"air_dribble_bump","label":"Air Dribble Bump","category":"aerial","family":"air_dribble","tier":3,"req":{"mechanics":72,"game_sense":66},"needs":["air_dribble"]},
	{"id":"double_tap","label":"Double Tap","category":"aerial","family":"double_tap","tier":3,"req":{"mechanics":72,"shooting":70,"game_sense":64},"needs":["fast_aerial"]},
	{"id":"redirect","label":"Redirect","category":"aerial","family":"redirect","tier":2,"req":{"shooting":66,"game_sense":62,"mechanics":62},"needs":["fast_aerial"]},
	{"id":"prejump_redirect","label":"Prejump Redirect","category":"aerial","family":"redirect","tier":4,"req":{"mechanics":80,"game_sense":78,"consistency":72},"needs":["redirect"]},
	{"id":"backboard_redirect","label":"Backboard Redirect","category":"aerial","family":"redirect","tier":4,"req":{"mechanics":82,"shooting":77},"needs":["redirect","double_tap"]},
	{"id":"musty_double_tap","label":"Musty Double Tap","category":"aerial","family":"double_tap","tier":5,"req":{"mechanics":91,"shooting":86,"consistency":82},"needs":["musty_flick","double_tap"]},

	# CEILING
	{"id":"ceiling_shot","label":"Ceiling Shot","category":"ceiling","family":"ceiling","tier":3,"req":{"mechanics":74,"boost_control":68},"needs":["air_dribble"]},
	{"id":"ceiling_double_tap","label":"Ceiling Double Tap","category":"ceiling","family":"double_tap","tier":4,"req":{"mechanics":84,"shooting":78},"needs":["ceiling_shot","double_tap"]},
	{"id":"ceiling_musty","label":"Ceiling Musty","category":"ceiling","family":"musty","tier":5,"req":{"mechanics":90,"shooting":82},"needs":["ceiling_shot","musty_flick"]},
	{"id":"ceiling_pogo","label":"Ceiling Pogo","category":"ceiling","family":"pogo","tier":5,"req":{"mechanics":94,"consistency":88},"needs":["ceiling_shot","pogo"]},

	# RESETS
	{"id":"flip_reset","label":"Flip Reset","category":"reset","family":"reset","tier":3,"req":{"mechanics":78,"boost_control":68},"needs":["air_dribble"]},
	{"id":"preflip_reset","label":"Preflip Reset","category":"reset","family":"reset","tier":4,"req":{"mechanics":82,"consistency":72},"needs":["flip_reset"]},
	{"id":"pop_reset","label":"Pop Reset","category":"reset","family":"reset","tier":4,"req":{"mechanics":82,"shooting":74},"needs":["flip_reset"]},
	{"id":"rapid_reset","label":"Rapid Reset","category":"reset","family":"reset","tier":4,"req":{"mechanics":84,"consistency":76},"needs":["flip_reset"]},
	{"id":"stall_reset","label":"Stall Reset","category":"reset","family":"stall","tier":5,"req":{"mechanics":91,"consistency":84},"needs":["flip_reset","stall_flick"]},
	{"id":"arsenal_reset","label":"Arsenal Reset","category":"reset","family":"reset","tier":5,"req":{"mechanics":91,"boost_control":82},"needs":["flip_reset"]},
	{"id":"maktuf_reset","label":"Maktuf Reset","category":"reset","family":"reset","tier":5,"req":{"mechanics":92,"consistency":85},"needs":["flip_reset"]},
	{"id":"heli_reset","label":"Heli Reset","category":"reset","family":"reset","tier":5,"req":{"mechanics":93,"consistency":86},"needs":["flip_reset"]},
	{"id":"pancake_reset","label":"Pancake Reset","category":"reset","family":"reset","tier":5,"req":{"mechanics":92,"consistency":84},"needs":["flip_reset"]},
	{"id":"reverse_pancake","label":"Reverse Pancake","category":"reset","family":"reset","tier":5,"req":{"mechanics":94,"consistency":88},"needs":["pancake_reset"]},
	{"id":"sideflip_reset","label":"Side-Flip Reset","category":"reset","family":"reset","tier":4,"req":{"mechanics":85,"consistency":78},"needs":["flip_reset"]},
	{"id":"frontflip_reset","label":"Front-Flip Reset","category":"reset","family":"reset","tier":4,"req":{"mechanics":85,"consistency":78},"needs":["flip_reset"]},
	{"id":"squishy_reset","label":"Squishy Reset","category":"reset","family":"reset","tier":5,"req":{"mechanics":92,"game_sense":82},"needs":["flip_reset"]},
	{"id":"double_reset","label":"Double Reset","category":"reset","family":"multi_reset","tier":4,"req":{"mechanics":85,"consistency":78},"needs":["flip_reset"]},
	{"id":"triple_reset","label":"Triple Reset","category":"reset","family":"multi_reset","tier":5,"req":{"mechanics":94,"consistency":88},"needs":["double_reset"]},
	{"id":"quad_reset","label":"Quad Reset","category":"reset","family":"multi_reset","tier":6,"req":{"mechanics":98,"consistency":95},"needs":["triple_reset"]},
	{"id":"reset_musty","label":"Reset Musty","category":"reset","family":"musty","tier":5,"req":{"mechanics":92,"shooting":84},"needs":["flip_reset","musty_flick"]},
	{"id":"reset_redirect","label":"Reset Redirect","category":"reset","family":"redirect","tier":5,"req":{"mechanics":93,"game_sense":86,"shooting":84},"needs":["flip_reset","redirect"]},

	# PINCHES
	{"id":"kuxir_pinch","label":"Kuxir Pinch","category":"pinch","family":"pinch","tier":3,"req":{"mechanics":72,"shooting":66},"needs":["powerslide_cut"]},
	{"id":"ground_pinch","label":"Ground Pinch","category":"pinch","family":"pinch","tier":3,"req":{"mechanics":70,"shooting":66},"needs":[]},
	{"id":"corner_pinch","label":"Corner Pinch","category":"pinch","family":"pinch","tier":4,"req":{"mechanics":80,"game_sense":72},"needs":["ground_pinch"]},
	{"id":"ceiling_pinch","label":"Ceiling Pinch","category":"pinch","family":"pinch","tier":5,"req":{"mechanics":90,"shooting":82},"needs":["ceiling_shot"]},
	{"id":"team_ground_pinch","label":"Team Ground Pinch","category":"pinch","family":"team_pinch","tier":5,"req":{"mechanics":86,"game_sense":82},"needs":["ground_pinch"]},
	{"id":"team_ceiling_pinch","label":"Team Ceiling Pinch","category":"pinch","family":"team_pinch","tier":6,"req":{"mechanics":95,"game_sense":90},"needs":["ceiling_pinch"]},
	{"id":"team_air_pinch","label":"Team Air Pinch","category":"pinch","family":"team_pinch","tier":6,"req":{"mechanics":96,"game_sense":91},"needs":["prejump_redirect"]},

	# FREESTYLE / ELITE
	{"id":"pogo","label":"Pogo","category":"freestyle","family":"pogo","tier":4,"req":{"mechanics":84,"consistency":76},"needs":["fast_aerial"]},
	{"id":"pogo_air_dribble","label":"Pogo Air Dribble","category":"freestyle","family":"pogo","tier":5,"req":{"mechanics":92,"boost_control":84},"needs":["pogo","air_dribble"]},
	{"id":"plan_b","label":"Plan B","category":"freestyle","family":"freestyle","tier":5,"req":{"mechanics":91,"game_sense":82},"needs":["double_tap"]},
	{"id":"turtle_flick","label":"Turtle Flick","category":"freestyle","family":"freestyle","tier":4,"req":{"mechanics":82,"shooting":74},"needs":["musty_flick"]},
	{"id":"psycho","label":"Psycho","category":"freestyle","family":"psycho","tier":5,"req":{"mechanics":89,"defense":82,"game_sense":80},"needs":["double_tap"]},
	{"id":"musty_psycho","label":"Musty Psycho","category":"freestyle","family":"psycho","tier":6,"req":{"mechanics":96,"shooting":88,"consistency":90},"needs":["psycho","musty_flick"]},

	# DEFENSE
	{"id":"shadow_defense","label":"Shadow Defense","category":"defense","family":"defense","tier":1,"req":{"defense":50,"game_sense":48},"needs":[]},
	{"id":"backboard_read","label":"Backboard Read","category":"defense","family":"defense","tier":2,"req":{"defense":62,"game_sense":58},"needs":["fast_aerial"]},
	{"id":"sidewall_read","label":"Sidewall Read","category":"defense","family":"defense","tier":2,"req":{"defense":60,"game_sense":58},"needs":[]},
	{"id":"squishy_save","label":"Squishy Save","category":"defense","family":"save","tier":3,"req":{"defense":72,"mechanics":68},"needs":["backboard_read"]},
	{"id":"prejump_save","label":"Prejump Save","category":"defense","family":"save","tier":4,"req":{"defense":82,"game_sense":80,"mechanics":76},"needs":["backboard_read"]},
	{"id":"ceiling_clear","label":"Ceiling Clear","category":"defense","family":"save","tier":4,"req":{"defense":80,"mechanics":78},"needs":["ceiling_shot"]},
	{"id":"goal_line_recovery","label":"Goal-Line Recovery","category":"defense","family":"recovery","tier":3,"req":{"defense":74,"rotation":72},"needs":["half_flip"]},
	{"id":"backboard_clear","label":"Backboard Clear","category":"defense","family":"defense","tier":3,"req":{"defense":72,"shooting":62},"needs":["backboard_read"]},

	# TEAM / COMBO UNLOCKS
	{"id":"air_dribble_redirect","label":"Air Dribble → Redirect","category":"team","family":"team_combo","tier":4,"req":{"game_sense":76,"mechanics":76},"needs":["air_dribble","redirect"]},
	{"id":"psycho_redirect","label":"Psycho → Redirect","category":"team","family":"team_combo","tier":6,"req":{"game_sense":88,"mechanics":90},"needs":["psycho","prejump_redirect"]},
	{"id":"reset_pass","label":"Reset Pass","category":"team","family":"team_combo","tier":5,"req":{"game_sense":84,"mechanics":86},"needs":["flip_reset","redirect"]},
	{"id":"reset_redirect_team","label":"Reset Pass → Redirect","category":"team","family":"team_combo","tier":6,"req":{"game_sense":90,"mechanics":92},"needs":["reset_pass","prejump_redirect"]},
	{"id":"backboard_pass_finish","label":"Backboard Pass → Finish","category":"team","family":"team_combo","tier":4,"req":{"game_sense":78,"shooting":76},"needs":["double_tap","redirect"]},
	{"id":"ceiling_pass_redirect","label":"Ceiling Pass → Redirect","category":"team","family":"team_combo","tier":6,"req":{"game_sense":90,"mechanics":92},"needs":["ceiling_shot","prejump_redirect"]},
	{"id":"fake_infield_pass","label":"Fake → Infield Pass","category":"team","family":"team_combo","tier":4,"req":{"game_sense":80,"rotation":76},"needs":["powerslide_cut"]},
]


static func all() -> Array:
	return MECHANICS.duplicate(true)


static func definition(mechanic_id: String) -> Dictionary:
	for value in MECHANICS:
		var item: Dictionary = value
		if str(item.get("id", "")) == mechanic_id:
			return item.duplicate(true)
	return {}


static func requirements_met(player: Dictionary, item: Dictionary, unlocked_ids: Array = []) -> bool:
	for stat_key in item.get("req", {}):
		if int(player.get(stat_key, 0)) < int(item.get("req", {})[stat_key]):
			return false
	for prerequisite in item.get("needs", []):
		if str(prerequisite) not in unlocked_ids:
			return false
	return true


static func unlocked(player: Dictionary) -> Array:
	var result: Array = []
	var unlocked_ids: Array = []
	var changed := true
	while changed:
		changed = false
		for value in MECHANICS:
			var item: Dictionary = value
			var item_id := str(item.get("id", ""))
			if item_id in unlocked_ids:
				continue
			if requirements_met(player, item, unlocked_ids):
				unlocked_ids.append(item_id)
				result.append(item.duplicate(true))
				changed = true
	return result


static func unlocked_ids(player: Dictionary) -> Array:
	var ids: Array = []
	for item in unlocked(player):
		ids.append(str(item.get("id", "")))
	return ids


static func next_unlocks(player: Dictionary, limit: int = 6) -> Array:
	var ids := unlocked_ids(player)
	var candidates: Array = []
	for value in MECHANICS:
		var item: Dictionary = value
		if str(item.get("id", "")) in ids:
			continue
		var prereq_ok := true
		for need in item.get("needs", []):
			if str(need) not in ids:
				prereq_ok = false
				break
		if prereq_ok:
			candidates.append(item.duplicate(true))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return progress(player, a) > progress(player, b))
	return candidates.slice(0, mini(limit, candidates.size()))


static func progress(player: Dictionary, item: Dictionary) -> int:
	var req: Dictionary = item.get("req", {})
	if req.is_empty():
		return 100
	var ratio := 1.0
	for key in req:
		ratio = minf(ratio, float(int(player.get(key, 0))) / float(maxi(1, int(req[key]))))
	return clampi(int(round(ratio * 100.0)), 0, 100)


static func category_count(category: String) -> int:
	var count := 0
	for value in MECHANICS:
		if str(value.get("category", "")) == category:
			count += 1
	return count
