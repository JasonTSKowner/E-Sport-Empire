extends "res://scripts/cinematic_shell_v243.gd"

const MatchVizV25Ref = preload("res://scripts/match_visualizer_v251.gd")
const TrainingVizV25Ref = preload("res://scripts/training_visualizer_v251.gd")
const PremiumStageV25Ref = preload("res://scripts/premium_stage_v25.gd")
const PlayerCardV25Ref = preload("res://scripts/player_card_v25.gd")
const ClubHQV25Ref = preload("res://scripts/club_hq_v25.gd")
const PlayerPortraitV25Ref = preload("res://scripts/player_portrait.gd")
const RankEmblemV25Ref = preload("res://scripts/rank_emblem.gd")
const RankedV25 = preload("res://scripts/ranked_data.gd")
const GameDataV25 = preload("res://scripts/game_data.gd")
const UIV25 = preload("res://scripts/ui_kit.gd")
const MechanicsV25 = preload("res://scripts/mechanics_catalog_v23.gd")

func _build_match_overlay() -> void:
	super._build_match_overlay()
	if match_visualizer == null or not is_instance_valid(match_visualizer):
		return
	var old := match_visualizer
	var parent := old.get_parent()
	var index := old.get_index()
	if parent == null:
		return
	parent.remove_child(old)
	old.queue_free()
	var replacement := MatchVizV25Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.82

func _build_home_page() -> void:
	page_content.add_child(_home_hero_v25())
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	quick.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV25.CYAN))
	quick.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV25.GREEN))
	quick.add_child(_metric_block("FORM", _form_label_v25(record), UIV25.GOLD))
	page_content.add_child(quick)
	page_content.add_child(_section_title("LETZTES SPIEL", ""))
	_build_history_list(page_content, 1)

func _form_label_v25(record: Dictionary) -> String:
	var wins := int(record.get("wins", 0))
	var losses := int(record.get("losses", 0))
	var played := wins + losses
	if played <= 0:
		return "–"
	return "%d%%" % int(round(float(wins) / float(played) * 100.0))

func _home_hero_v25() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := PremiumStageV25Ref.new().configure(accent, "home")
	stage.custom_minimum_size.y = 390

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV25.label("SEASON 1  /  ROCKET LEAGUE", 8, Color(accent.r,accent.g,accent.b,0.92), 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV25.badge(playlist, accent))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("DEIN COMPETITIVE RUN", 8, UIV25.MUTED, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 34, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(9))
	copy.add_child(UIV25.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	hero.add_child(copy)

	var art := Control.new()
	art.custom_minimum_size = Vector2(150, 164)
	var roster := game.roster_for("Rocket League")
	if not roster.is_empty():
		var captain: Dictionary = roster[0]
		var portrait := PlayerPortraitV25Ref.new().configure(str(captain.get("name", "PLAYER")), accent)
		portrait.position = Vector2(10, 4)
		portrait.size = Vector2(114, 148)
		portrait.custom_minimum_size = Vector2(114, 148)
		art.add_child(portrait)
	var emblem := RankEmblemV25Ref.new().configure(shown_rank)
	emblem.position = Vector2(87, 96)
	emblem.size = Vector2(64, 64)
	emblem.custom_minimum_size = Vector2(64, 64)
	art.add_child(emblem)
	hero.add_child(art)
	box.add_child(hero)

	var objective := HBoxContainer.new()
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_theme_constant_override("separation", 0)
	objective_copy.add_child(UIV25.label("NÄCHSTES ZIEL", 7, UIV25.DIM, 800))
	objective_copy.add_child(UIV25.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH STARTEN", 13, UIV25.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV25.badge("%d/10" % mini(placements,10) if not placed else "%d MMR" % mmr, accent))
	box.add_child(objective)

	if not placed:
		box.add_child(UIV25.progress(placements, 10, accent, 6))
	else:
		var progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 6))

	var action := UIV25.button("RANKED MATCH STARTEN", accent, true)
	action.custom_minimum_size.y = 54
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage

func _origin_card() -> Control:
	return _home_hero_v25()

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := PremiumStageV25Ref.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 320
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var tag := UIV25.label("COMPETITIVE  /  %s" % playlist, 8, Color(accent.r,accent.g,accent.b,0.92), 800)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(tag)
	meta.add_child(UIV25.badge("BEREIT", UIV25.GREEN))
	box.add_child(meta)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 33, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(10))
	copy.add_child(UIV25.label("BILANZ  %d–%d" % [int(record.get("wins",0)), int(record.get("losses",0))], 9, UIV25.DIM, 700))
	copy.add_child(UIV25.label("WINRATE %.1f%%" % RankedV25.win_rate(record), 9, UIV25.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV25Ref.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(154,154)
	row.add_child(emblem)
	box.add_child(row)
	if not placed:
		box.add_child(UIV25.progress(placements,10,accent,6))
	else:
		var progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,6))
	return stage

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := PremiumStageV25Ref.new().configure(accent, "player")
	stage.custom_minimum_size.y = 292
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stage.add_child(margin)
	var card := PlayerCardV25Ref.new().configure(player, accent, game.player_overall(player), int(player.get("potential",99)), "roster")
	margin.add_child(card)
	return stage

func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	var stage := PremiumStageV25Ref.new().configure(accent, "scout")
	stage.custom_minimum_size.y = 268
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stage.add_child(margin)
	var card := PlayerCardV25Ref.new().configure(player, accent, game.player_overall(player), int(player.get("potential",50)), "scout")
	card.custom_minimum_size.y = 246
	margin.add_child(card)
	root.add_child(stage)
	var price := int(player.get("contract",0))
	var sign := UIV25.button("VERPFLICHTEN  ·  %s" % GameDataV25.format_cash(price), accent, true)
	sign.custom_minimum_size.y = 50
	sign.disabled = int(game.data.get("cash",0)) < price
	sign.pressed.connect(_sign_player.bind(str(player.get("id",""))))
	root.add_child(sign)
	return root

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	identity.add_child(UIV25.label("PERFORMANCE LAB", 7, UIV25.DIM, 800))
	identity.add_child(UIV25.label(str(player.get("name","SPIELER")).to_upper(), 25, UIV25.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV25.badge("LIVE DRILL", accent))
	root.add_child(header)

	var training := TrainingVizV25Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining",0)), int(readiness.get("limit",5))], UIV25.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue",0))), UIV25.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV25.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size()-1]
		var mech_id := str(best.get("id",""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mastery_row := HBoxContainer.new()
		var mech_name := UIV25.label(str(best.get("label","MECHANIC")).to_upper(), 10, UIV25.TEXT, 800)
		mech_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mech_name)
		mastery_row.add_child(UIV25.badge("%d%%" % mastery, accent))
		root.add_child(mastery_row)
		root.add_child(UIV25.label("SET %d   CTRL %d   READ %d   FIN %d" % [int(detail.get("setup",mastery)),int(detail.get("control",mastery)),int(detail.get("read",mastery)),int(detail.get("finish",mastery))],8,UIV25.MUTED,700))

	root.add_child(UIV25.label("DRILL WÄHLEN", 7, UIV25.DIM, 800))
	root.add_child(_training_program_grid(player))
	var upcoming := state.next_mechanics_v23(player,1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV25.label("NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label","MECHANIC")),MechanicsV25.progress(player,next)],8,UIV25.MUTED,700))
	return root

func _training_program_grid(player: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var readiness := game.training_readiness(player)
	var focus_ready := bool(readiness.get("ok",false))
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id",""))
		var button := UIV25.button("%s\nFOKUS-DRILL" % str(program.get("short","TRAIN")), UIV25.CYAN, false, true)
		button.disabled = not focus_ready
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size",9)
		button.tooltip_text = str(program.get("button_detail","STAT-BONI"))
		if not focus_ready:
			if bool(readiness.get("fatigue_blocked",false)):
				button.tooltip_text = "Training pausiert: Müdigkeit zu hoch."
			else:
				button.tooltip_text = "Nächster Fokus-Slot in %s." % _format_duration(int(readiness.get("seconds_until_slot",0)))
		button.pressed.connect(_train_player.bind(str(player.get("id","")),program_id))
		grid.add_child(button)
	return grid

func _build_empire_page() -> void:
	_page_header("CLUB HQ", "Verein", "")
	_empire_view_switch()
	match empire_view:
		"staff":
			page_content.add_child(_staff_hq_card())
		"facilities":
			page_content.add_child(_section_title("ANLAGEN", "AUSBAU UND INFRASTRUKTUR"))
			for key in GameDataV25.FACILITIES:
				page_content.add_child(_facility_card(key))
		_:
			var levels := {}
			for key in GameDataV25.FACILITIES:
				levels[str(key)] = game.facility_level(str(key))
			var hq := ClubHQV25Ref.new().configure(UIV25.GOLD, levels, game.passive_income_per_hour(), game.passive_fans_per_hour())
			page_content.add_child(hq)
			page_content.add_child(_club_identity_card())
