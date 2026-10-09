extends "res://scripts/cinematic_shell_v243.gd"

const TrainingVizV25 = preload("res://scripts/training_visualizer_v25.gd")
const MatchVizV25 = preload("res://scripts/match_visualizer_v25.gd")
const CompetitiveStageV25 = preload("res://scripts/competitive_stage_v25.gd")
const UIV25 = preload("res://scripts/ui_kit.gd")
const GameDataV25 = preload("res://scripts/game_data.gd")
const RankedV25 = preload("res://scripts/ranked_data.gd")
const RankEmblemV25 = preload("res://scripts/rank_emblem.gd")

func _build_home_page() -> void:
	page_content.add_child(_home_competitive_stage_v25())

func _home_competitive_stage_v25() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := CompetitiveStageV25.new().configure(accent, "home")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV25.label("SEASON %d  //  ROCKET LEAGUE" % int(game.data.get("season", 1)), 8, accent, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV25.badge(playlist, accent))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("DEIN COMPETITIVE RUN", 9, UIV25.MUTED, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 36, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(8))
	copy.add_child(UIV25.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(170, 170)
	hero.add_child(emblem)
	box.add_child(hero)

	box.add_child(UIV25.v_space(14))
	var objective := VBoxContainer.new()
	objective.add_theme_constant_override("separation", 2)
	objective.add_child(UIV25.label("NÄCHSTES ZIEL", 7, UIV25.DIM, 800))
	objective.add_child(UIV25.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH FORTSETZEN", 17, UIV25.TEXT, 800))
	box.add_child(objective)
	if not placed:
		box.add_child(UIV25.progress(placements, 10, accent, 7))
	else:
		var rank_progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(rank_progress.get("value", 0)), float(rank_progress.get("maximum", 1)), accent, 7))

	var action := UIV25.button("MATCH STARTEN", accent, true)
	action.custom_minimum_size.y = 56
	action.add_theme_font_size_override("font_size", 13)
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)

	box.add_child(UIV25.v_space(8))
	var performance := HBoxContainer.new()
	performance.add_theme_constant_override("separation", 4)
	performance.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV25.CYAN))
	performance.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV25.GREEN))
	performance.add_child(_metric_block("PING", "%d ms" % _v23().connection_ping(), UIV25.PURPLE))
	box.add_child(performance)

	box.add_child(UIV25.v_space(5))
	var played := int(record.get("played", 0))
	var footer := "DEIN ERSTES RANKED-MATCH WARTET." if played == 0 else "%d MATCHES GESPIELT  ·  %.1f%% WINRATE" % [played, RankedV25.win_rate(record)]
	var footer_label := UIV25.label(footer, 8, UIV25.MUTED, 700)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer_label)
	return stage

func _origin_card() -> Control:
	return _home_competitive_stage_v25()

func _build_play_page() -> void:
	if game.selected_mode() != "Rocket League" or ranked_view != "overview":
		super._build_play_page()
		return

	page_content.add_child(_playlist_bar_v25())
	page_content.add_child(_ranked_competitive_stage_v25())
	page_content.add_child(_ranked_secondary_actions_v25())

func _playlist_bar_v25() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var selected := game.selected_rl_playlist()
	var roster_size := game.roster_for("Rocket League").size()
	for playlist in RankedV25.PLAYLISTS:
		var required := game.playlist_required_players(str(playlist))
		var available := roster_size >= required
		var text := "%s  %s" % [str(playlist).to_upper(), "✓" if available else "%d/%d" % [mini(roster_size, required), required]]
		var button := UIV25.button(text, UIV25.CYAN if str(playlist) == selected else UIV25.DIM, str(playlist) == selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 42
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_select_rl_playlist.bind(str(playlist)))
		row.add_child(button)
	return row

func _ranked_competitive_stage_v25() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var available := game.can_queue_playlist(playlist)
	var required := game.playlist_required_players(playlist)
	var roster_size := game.roster_for("Rocket League").size()
	var stage := CompetitiveStageV25.new().configure(accent, "rank")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var competition := UIV25.label("COMPETITIVE  //  ROCKET LEAGUE  //  %s" % playlist, 8, accent, 800)
	competition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(competition)
	meta.add_child(UIV25.badge("BEREIT" if available else "GESPERRT", UIV25.GREEN if available else UIV25.RED))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 36, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(8))
	copy.add_child(UIV25.label("BILANZ  %d–%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	copy.add_child(UIV25.label("WINRATE  %.1f%%" % RankedV25.win_rate(record), 9, UIV25.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(170, 170)
	hero.add_child(emblem)
	box.add_child(hero)

	if not placed:
		box.add_child(UIV25.progress(placements, 10, accent, 7))
	else:
		var progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 7))

	box.add_child(UIV25.v_space(10))
	var queue_meta := HBoxContainer.new()
	var queue_copy := VBoxContainer.new()
	queue_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_copy.add_child(UIV25.label("SPIELSUCHE", 7, UIV25.DIM, 800))
	queue_copy.add_child(UIV25.label("%s RANKED" % playlist, 18, UIV25.TEXT, 800))
	queue_meta.add_child(queue_copy)
	queue_meta.add_child(UIV25.badge("ONLINE", UIV25.GREEN if available else UIV25.MUTED))
	box.add_child(queue_meta)

	var queue_text := "MATCH SUCHEN" if available else "NOCH %d SPIELER HOLEN" % maxi(0, required - roster_size)
	var queue := UIV25.button(queue_text, accent, available)
	queue.disabled = not available
	queue.custom_minimum_size.y = 58
	queue.add_theme_font_size_override("font_size", 13)
	queue.pressed.connect(_start_match.bind("Rocket League"))
	box.add_child(queue)

	var performance := HBoxContainer.new()
	performance.add_theme_constant_override("separation", 4)
	performance.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV25.CYAN))
	performance.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV25.GREEN))
	performance.add_child(_metric_block("PING", "%d ms" % _v23().connection_ping(), UIV25.PURPLE))
	box.add_child(performance)
	return stage

func _ranked_secondary_actions_v25() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	for entry in [["circuit", "TURNIER"], ["ladder", "RANGLISTE"], ["titles", "TITEL"]]:
		var button := UIV25.button(str(entry[1]), UIV25.DIM, false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 40
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_select_ranked_view.bind(str(entry[0])))
		row.add_child(button)
	return row

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
	var replacement := MatchVizV25.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 2.0

func _advance_match() -> void:
	super._advance_match()
	if match_timer == null or match_finished or match_visualizer == null:
		return
	var mechanic_play := not str(match_visualizer.mechanic_label).is_empty()
	var important_phase := str(match_visualizer.phase) in ["shot", "save", "goal", "psycho_contact", "redirect_finish", "reset_2", "reset_3", "reset_4"]
	match_timer.wait_time = 2.35 if important_phase else 2.15 if mechanic_play else 1.85

func _build_team_page() -> void:
	if team_view != "training":
		super._build_team_page()
		return

	game.apply_real_time_fatigue_recovery(false)
	var mode: String = game.selected_mode()
	var accent: Color = GameDataV25.MODE_COLORS.get(mode, UIV25.CYAN)
	var roster := game.roster_for(mode)
	var selected_player: Dictionary = {}
	if not roster.is_empty():
		selected_player = roster[0]
		for roster_player in roster:
			if str(roster_player.get("id", "")) == selected_team_player_id:
				selected_player = roster_player
				break
		selected_team_player_id = str(selected_player.get("id", "captain"))

	page_content.add_child(_training_nav_v25(accent))
	if selected_player.is_empty():
		var empty := UIV25.label("Kein Spieler für Training verfügbar.", 11, UIV25.MUTED, 700)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page_content.add_child(empty)
		return
	page_content.add_child(_training_scene_v25(selected_player, accent))

func _training_nav_v25(accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)

	var title_row := HBoxContainer.new()
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("separation", -1)
	title.add_child(UIV25.label("PERFORMANCE LAB", 8, accent, 800))
	title.add_child(UIV25.label("Training", 23, UIV25.TEXT, 800))
	title_row.add_child(title)
	title_row.add_child(UIV25.badge("ROCKET LEAGUE", accent))
	root.add_child(title_row)

	var switch := HBoxContainer.new()
	switch.add_theme_constant_override("separation", 4)
	for entry in [["roster", "KADER"], ["training", "TRAINING"], ["coaching", "COACH"], ["scouting", "SCOUT"]]:
		var view_id := str(entry[0])
		var selected := view_id == "training"
		var button := UIV25.button(str(entry[1]), accent if selected else UIV25.DIM, selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 38
		button.add_theme_font_size_override("font_size", 8)
		button.disabled = selected
		if not selected:
			button.pressed.connect(_select_team_view.bind(view_id))
		switch.add_child(button)
	root.add_child(switch)
	return root

func _training_scene_v25(player: Dictionary, accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	var state := _v23()
	var readiness := state.training_readiness(player)

	var training := TrainingVizV25.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var action_header := HBoxContainer.new()
	var drill_label := UIV25.label("DRILL WÄHLEN", 8, UIV25.DIM, 800)
	drill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_header.add_child(drill_label)
	var free := UIV25.label("NORMALES TRAINING · GRATIS", 7, UIV25.GREEN, 800)
	free.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_header.add_child(free)
	root.add_child(action_header)

	root.add_child(_training_program_grid_v25(player, accent))
	return root

func _training_program_grid_v25(player: Dictionary, accent: Color) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var readiness := game.training_readiness(player)
	var focus_ready := bool(readiness.get("ok", false))
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var short_name := str(program.get("short", "DRILL")).replace(" TRAINING", "").replace(" REVIEW", "")
		var button := UIV25.button(short_name, accent, false, true)
		button.disabled = not focus_ready
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 8)
		if not focus_ready:
			button.tooltip_text = "Training aktuell nicht bereit."
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		grid.add_child(button)
	return grid
