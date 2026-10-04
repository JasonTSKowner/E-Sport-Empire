extends "res://scripts/main.gd"

const CUI = preload("res://scripts/ui_kit.gd")
const CinematicSurfaceRef = preload("res://scripts/cinematic_surface.gd")
const Ranked = preload("res://scripts/ranked_data.gd")
const GameData = preload("res://scripts/game_data.gd")
const RankEmblem = preload("res://scripts/rank_emblem.gd")
const PlayerPortrait = preload("res://scripts/player_portrait.gd")
const NavIcon = preload("res://scripts/nav_icon.gd")
const BrandMark = preload("res://scripts/brand_mark.gd")
const AppFont = preload("res://assets/fonts/SpaceGrotesk.ttf")
const TrainingViz = preload("res://scripts/training_visualizer.gd")
const Development = preload("res://scripts/development_data.gd")


func _build_top_bar() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.y = 48.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("080B10")
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.045)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	outer.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	outer.add_child(row)

	var mark := BrandMark.new()
	mark.custom_minimum_size = Vector2(28, 28)
	row.add_child(mark)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -2)
	identity.add_child(CUI.label(str(game.data.get("club_name", "TSK ESPORTS")), 12, CUI.TEXT, 800))
	season_label = CUI.label("", 7, CUI.DIM, 700)
	identity.add_child(season_label)
	row.add_child(identity)

	var money := VBoxContainer.new()
	money.add_theme_constant_override("separation", -2)
	var cap := CUI.label("CLUB FUNDS", 6, CUI.DIM, 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_label = CUI.label("€0", 12, CUI.TEXT, 800)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.add_child(cap)
	money.add_child(cash_label)
	row.add_child(money)
	return outer


func _build_bottom_navigation() -> Control:
	var wrapper := MarginContainer.new()
	wrapper.custom_minimum_size.y = 68
	wrapper.add_theme_constant_override("margin_left", 8)
	wrapper.add_theme_constant_override("margin_right", 8)
	wrapper.add_theme_constant_override("margin_top", 5)
	wrapper.add_theme_constant_override("margin_bottom", 7)

	var dock := PanelContainer.new()
	var dock_style := CUI.box(Color(0.035, 0.045, 0.060, 0.985), 16, Color(1, 1, 1, 0.055), 1)
	dock_style.shadow_size = 12
	dock_style.shadow_color = Color(0, 0, 0, 0.34)
	dock_style.shadow_offset = Vector2(0, 5)
	dock_style.content_margin_left = 4
	dock_style.content_margin_right = 4
	dock_style.content_margin_top = 4
	dock_style.content_margin_bottom = 4
	dock.add_theme_stylebox_override("panel", dock_style)
	wrapper.add_child(dock)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	dock.add_child(row)
	for entry in AppConfigRef.NAV_ENTRIES:
		var page_id := str(entry[0])
		var button := Button.new()
		button.text = "\n" + str(entry[1])
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 50
		button.add_theme_font_override("font", AppFont)
		button.add_theme_font_size_override("font_size", 8)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER

		var icon := NavIcon.new()
		icon.configure(page_id, CUI.MUTED)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -11
		icon.offset_right = 11
		icon.offset_top = 4
		icon.offset_bottom = 24
		button.add_child(icon)
		button.set_meta("nav_icon", icon)
		button.pressed.connect(_show_page.bind(page_id, true))
		row.add_child(button)
		nav_buttons[page_id] = button
	return wrapper


func _refresh_nav() -> void:
	for key in nav_buttons:
		var button: Button = nav_buttons[key]
		var selected := str(key) == current_page
		button.add_theme_color_override("font_color", CUI.TEXT if selected else CUI.DIM)
		button.add_theme_color_override("font_hover_color", CUI.TEXT)
		button.add_theme_color_override("font_pressed_color", CUI.TEXT)
		var icon: Control = button.get_meta("nav_icon", null)
		if icon != null and icon.has_method("set_accent"):
			icon.set_accent(CUI.CYAN if selected else CUI.MUTED)
		var normal := CUI.box(Color(CUI.CYAN.r, CUI.CYAN.g, CUI.CYAN.b, 0.10) if selected else Color.TRANSPARENT, 12)
		normal.shadow_size = 0
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", CUI.box(Color(1, 1, 1, 0.035), 12))
		button.add_theme_stylebox_override("pressed", CUI.box(Color(CUI.CYAN.r, CUI.CYAN.g, CUI.CYAN.b, 0.13), 12))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _page_header(kicker: String, title: String, subtitle: String) -> void:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 1)
	var top := HBoxContainer.new()
	var over := CUI.label(kicker.to_upper(), 7, CUI.CYAN, 800)
	over.add_theme_constant_override("letter_spacing", 1)
	top.add_child(over)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var section_code := CUI.label("// %s" % str(current_page).to_upper(), 7, CUI.DIM, 800)
	section_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(section_code)
	header.add_child(top)
	header.add_child(CUI.label(title, 24, CUI.TEXT, 800))
	if not subtitle.is_empty():
		header.add_child(CUI.label(subtitle, 8, CUI.MUTED, 600))
	page_content.add_child(header)


func _section_title(title: String, subtitle: String) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title_label := CUI.label(title.to_upper(), 9, CUI.TEXT, 800)
	row.add_child(title_label)
	var line := HSeparator.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_style := StyleBoxFlat.new()
	line_style.bg_color = Color(1, 1, 1, 0.07)
	line_style.content_margin_top = 0.5
	line_style.content_margin_bottom = 0.5
	line.add_theme_stylebox_override("separator", line_style)
	row.add_child(line)
	wrapper.add_child(row)
	if not subtitle.is_empty():
		wrapper.add_child(CUI.label(subtitle, 8, CUI.DIM, 600))
	return wrapper


func _metric_block(caption: String, value: String, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", -1)
	var value_label := CUI.label(value, 17 if value.length() < 9 else 12, CUI.TEXT, 800)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption_label := CUI.label(caption.to_upper(), 7, Color(accent.r, accent.g, accent.b, 0.80), 800)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)
	box.add_child(caption_label)
	return box


func _build_home_page() -> void:
	_page_header("COMMAND CENTER", "Dein Run", "")
	page_content.add_child(_origin_card())
	page_content.add_child(_home_next_steps_card())
	var contacts: Array = game.data.get("contacts", [])
	if not contacts.is_empty():
		page_content.add_child(_section_title("NEUER KONTAKT", ""))
		page_content.add_child(_contact_card(contacts[0]))
	page_content.add_child(_section_title("LETZTE SPIELE", ""))
	_build_history_list(page_content, 2)


func _origin_card() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := Ranked.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else Ranked.unranked_data(mmr)
	var accent := Ranked.color_for_family(str(shown_rank.get("family", "Unranked")))

	var panel := CinematicSurfaceRef.new().configure(accent, "rank", 1.0)
	panel.custom_minimum_size.y = 224
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 8)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(CUI.label("ROCKET LEAGUE  /  %s" % playlist, 8, Color(accent.r, accent.g, accent.b, 0.90), 800))
	copy.add_child(CUI.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 28, CUI.TEXT, 800))
	copy.add_child(CUI.label("PLACEMENT %d / 10" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, CUI.MUTED, 700))
	var record_label := "%dS  %dN" % [int(record.get("wins", 0)), int(record.get("losses", 0))]
	copy.add_child(CUI.label("%s  ·  TEAM %d OVR" % [record_label, game.team_overall("Rocket League")], 9, CUI.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblem.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(118, 118)
	hero.add_child(emblem)
	box.add_child(hero)

	if not placed:
		box.add_child(CUI.progress(placements, 10, accent, 5))
	else:
		var progress := Ranked.progress_for_mmr(mmr, playlist)
		box.add_child(CUI.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 5))

	var action := CUI.button("RANKED SPIELEN", accent, true)
	action.custom_minimum_size.y = 48
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return panel


func _home_next_steps_card() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var placements := int(record.get("placements", 0))
	var chemistry := game.team_chemistry("Rocket League")
	var claimable := game.claimable_milestone_count()
	var panel := CinematicSurfaceRef.new().configure(CUI.GOLD if claimable > 0 else CUI.CYAN, "default", 0.65)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(CUI.label("NÄCHSTES ZIEL", 7, CUI.DIM, 800))
	var title := "Placement %d von 10" % (placements + 1) if placements < 10 else "Ranked verbessern"
	if claimable > 0:
		title = "%d Belohnung%s bereit" % [claimable, "en" if claimable != 1 else ""]
	copy.add_child(CUI.label(title, 16, CUI.TEXT, 800))
	copy.add_child(CUI.label("Chemie %d%%  ·  %d Spiele" % [chemistry, int(record.get("played", 0))], 8, CUI.MUTED, 700))
	row.add_child(copy)
	var level := CUI.label("LV %d" % game.career_level(), 20, CUI.GOLD, 800)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(level)
	return panel


func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := Ranked.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else Ranked.unranked_data(mmr)
	var accent := Ranked.color_for_family(str(shown_rank.get("family", "Unranked")))

	var panel := CinematicSurfaceRef.new().configure(accent, "rank", 1.0)
	panel.custom_minimum_size.y = 210
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(CUI.label("%s RANKED" % playlist, 8, Color(accent.r, accent.g, accent.b, 0.90), 800))
	details.add_child(CUI.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 27, CUI.TEXT, 800))
	details.add_child(CUI.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 9, CUI.MUTED, 700))
	details.add_child(CUI.label("BILANZ  %d–%d   ·   WINRATE %.1f%%" % [int(record.get("wins", 0)), int(record.get("losses", 0)), Ranked.win_rate(record)], 8, CUI.DIM, 700))
	row.add_child(details)
	var emblem := RankEmblem.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(116, 116)
	row.add_child(emblem)
	box.add_child(row)

	if not placed:
		box.add_child(CUI.progress(placements, 10, accent, 5))
	else:
		var progress := Ranked.progress_for_mmr(mmr, playlist)
		box.add_child(CUI.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 5))
	return panel


func _ranked_queue_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var available := game.can_queue_playlist(playlist)
	var required := game.playlist_required_players(playlist)
	var roster_size := game.roster_for("Rocket League").size()
	var placement_mode := int(record.get("placements", 0)) < 10
	var panel := CinematicSurfaceRef.new().configure(CUI.CYAN, "queue", 0.85)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(CUI.label("MATCHMAKING", 7, CUI.DIM, 800))
	copy.add_child(CUI.label("%s RANKED" % playlist, 17, CUI.TEXT, 800))
	copy.add_child(CUI.label("Placement" if placement_mode else "MMR-basiertes Matchmaking", 8, CUI.MUTED, 700))
	row.add_child(copy)
	row.add_child(CUI.label("READY" if available else "%d/%d" % [roster_size, required], 11, CUI.GREEN if available else CUI.GOLD, 800))
	box.add_child(row)

	var queue := CUI.button("MATCH SUCHEN" if available else "KADER UNVOLLSTÄNDIG", CUI.CYAN, available)
	queue.custom_minimum_size.y = 50
	queue.disabled = not available
	queue.pressed.connect(_start_match.bind("Rocket League"))
	box.add_child(queue)
	return panel


func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var panel := CinematicSurfaceRef.new().configure(accent, "player", 0.95)
	panel.custom_minimum_size.y = 220
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var portrait := PlayerPortrait.new().configure(str(player.get("name", "PLAYER")), accent)
	portrait.custom_minimum_size = Vector2(112, 128)
	row.add_child(portrait)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	identity.add_child(CUI.label(str(player.get("name", "PLAYER")).to_upper(), 25, CUI.TEXT, 800))
	identity.add_child(CUI.label("%s  /  %s  /  %d J." % [str(player.get("role", "PLAYER")).to_upper(), str(player.get("region", "EU")), int(player.get("age", 16))], 8, CUI.MUTED, 700))
	var archetype := Development.player_archetype(player)
	identity.add_child(CUI.label(str(archetype.get("label", "Kompletter Spieler")).to_upper(), 8, Color(str(archetype.get("color", "F5F7FA"))), 800))
	identity.add_child(CUI.v_space(6))
	var ovr_row := HBoxContainer.new()
	ovr_row.add_theme_constant_override("separation", 14)
	var ovr_box := VBoxContainer.new()
	ovr_box.add_child(CUI.label(str(game.player_overall(player)), 34, CUI.TEXT, 800))
	ovr_box.add_child(CUI.label("OVERALL", 7, CUI.DIM, 800))
	ovr_row.add_child(ovr_box)
	var pot_box := VBoxContainer.new()
	pot_box.add_child(CUI.label(str(int(player.get("potential", 99))), 22, accent, 800))
	pot_box.add_child(CUI.label("POTENZIAL", 7, CUI.DIM, 800))
	ovr_row.add_child(pot_box)
	identity.add_child(ovr_row)
	row.add_child(identity)
	box.add_child(row)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	stats.add_child(_metric_block("MECH", str(int(player.get("mechanics", 50))), CUI.CYAN))
	stats.add_child(_metric_block("SCHUSS", str(int(player.get("shooting", 50))), CUI.GOLD))
	stats.add_child(_metric_block("DEF", str(int(player.get("defense", 50))), CUI.GREEN))
	stats.add_child(_metric_block("SENSE", str(int(player.get("game_sense", 50))), CUI.PURPLE))
	box.add_child(stats)
	return panel


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var readiness := game.training_readiness(player)
	var panel := CinematicSurfaceRef.new().configure(accent, "training", 0.85)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var header := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(CUI.label("PERFORMANCE LAB", 7, CUI.DIM, 800))
	copy.add_child(CUI.label(str(player.get("name", "PLAYER")).to_upper(), 20, CUI.TEXT, 800))
	header.add_child(copy)
	var focus := CUI.label("%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 3))], 22, CUI.GREEN if bool(readiness.get("ok", false)) else CUI.RED, 800)
	focus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(focus)
	box.add_child(header)

	var training := TrainingViz.new()
	training.configure(player, readiness, accent)
	training.custom_minimum_size.y = 220
	box.add_child(training)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	stats.add_child(_metric_block("FORM", str(int(player.get("form", 50))), CUI.GREEN))
	stats.add_child(_metric_block("MÜDIG", str(int(player.get("fatigue", 0))), CUI.GOLD))
	stats.add_child(_metric_block("MECH", str(int(player.get("mechanics", 50))), CUI.CYAN))
	stats.add_child(_metric_block("BOOST", str(int(player.get("boost_control", 50))), CUI.PURPLE))
	box.add_child(stats)

	var training_title := HBoxContainer.new()
	training_title.add_child(CUI.label("TRAINING", 8, CUI.TEXT, 800))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training_title.add_child(spacer)
	training_title.add_child(CUI.label("BONUS %s" % _chance_text(game.training_breakthrough_chance()), 7, CUI.GREEN, 800))
	box.add_child(training_title)
	box.add_child(_training_program_grid(player))
	return panel
