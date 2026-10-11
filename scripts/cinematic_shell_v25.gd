extends "res://scripts/cinematic_shell_v243.gd"

const UIV25 = preload("res://scripts/ui_kit.gd")
const StageV25 = preload("res://scripts/professional_stage_v25.gd")
const ShowcaseV25 = preload("res://scripts/player_showcase_v25.gd")
const RankedV25 = preload("res://scripts/ranked_data.gd")
const RankEmblemV25 = preload("res://scripts/rank_emblem.gd")
const GameDataV25 = preload("res://scripts/game_data.gd")
const NavIconV25 = preload("res://scripts/nav_icon.gd")
const BrandMarkV25 = preload("res://scripts/brand_mark.gd")
const FontV25 = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _build_top_bar() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.y = 56
	var style := StyleBoxFlat.new()
	style.bg_color = Color("05080D")
	style.border_width_bottom = 1
	style.border_color = Color(0.72, 0.84, 0.92, 0.07)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 7
	outer.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	outer.add_child(row)
	var mark := BrandMarkV25.new()
	mark.custom_minimum_size = Vector2(32, 32)
	row.add_child(mark)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -2)
	identity.add_child(UIV25.label(str(game.data.get("club_name", "TSK ESPORTS")).to_upper(), 13, UIV25.TEXT, 800))
	season_label = UIV25.label("", 7, UIV25.DIM, 700)
	identity.add_child(season_label)
	row.add_child(identity)

	var money := VBoxContainer.new()
	money.add_theme_constant_override("separation", -2)
	var cap := UIV25.label("GUTHABEN", 6, UIV25.DIM, 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_label = UIV25.label("€0", 13, UIV25.TEXT, 800)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.add_child(cap)
	money.add_child(cash_label)
	row.add_child(money)
	return outer

func _build_bottom_navigation() -> Control:
	var wrapper := MarginContainer.new()
	wrapper.custom_minimum_size.y = 66
	wrapper.add_theme_constant_override("margin_left", 8)
	wrapper.add_theme_constant_override("margin_right", 8)
	wrapper.add_theme_constant_override("margin_top", 4)
	wrapper.add_theme_constant_override("margin_bottom", 7)
	var dock := PanelContainer.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.025, 0.035, 0.048, 0.985)
	ds.corner_radius_top_left = 16
	ds.corner_radius_top_right = 16
	ds.corner_radius_bottom_left = 16
	ds.corner_radius_bottom_right = 16
	ds.border_width_left = 1
	ds.border_width_top = 1
	ds.border_width_right = 1
	ds.border_width_bottom = 1
	ds.border_color = Color(0.78, 0.88, 0.95, 0.08)
	ds.content_margin_left = 4
	ds.content_margin_right = 4
	ds.content_margin_top = 3
	ds.content_margin_bottom = 3
	dock.add_theme_stylebox_override("panel", ds)
	wrapper.add_child(dock)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	dock.add_child(row)
	for entry in AppConfigRef.NAV_ENTRIES:
		var page_id := str(entry[0])
		var button := Button.new()
		button.text = "\n" + str(entry[1])
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 50
		button.add_theme_font_override("font", FontV25)
		button.add_theme_font_size_override("font_size", 8)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon := NavIconV25.new()
		icon.configure(page_id, UIV25.MUTED)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -11
		icon.offset_right = 11
		icon.offset_top = 5
		icon.offset_bottom = 25
		button.add_child(icon)
		button.set_meta("nav_icon", icon)
		var active_line := ColorRect.new()
		active_line.color = UIV25.CYAN
		active_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		active_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
		active_line.offset_left = 18
		active_line.offset_right = -18
		active_line.offset_top = 0
		active_line.offset_bottom = 2
		active_line.visible = false
		button.add_child(active_line)
		button.set_meta("active_line", active_line)
		button.pressed.connect(_show_page.bind(page_id, true))
		row.add_child(button)
		nav_buttons[page_id] = button
	return wrapper

func _refresh_nav() -> void:
	for key in nav_buttons:
		var button: Button = nav_buttons[key]
		var selected := str(key) == current_page
		button.add_theme_color_override("font_color", UIV25.TEXT if selected else UIV25.DIM)
		button.add_theme_color_override("font_hover_color", UIV25.TEXT)
		button.add_theme_color_override("font_pressed_color", UIV25.TEXT)
		var icon: Control = button.get_meta("nav_icon", null)
		if icon != null and icon.has_method("set_accent"):
			icon.set_accent(UIV25.CYAN if selected else UIV25.MUTED)
		var line: ColorRect = button.get_meta("active_line", null)
		if line != null:
			line.visible = selected
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.04, 0.075, 0.09, 0.72) if selected else Color.TRANSPARENT
		normal.corner_radius_top_left = 11
		normal.corner_radius_top_right = 11
		normal.corner_radius_bottom_left = 11
		normal.corner_radius_bottom_right = 11
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", UIV25.box(Color(1, 1, 1, 0.03), 11))
		button.add_theme_stylebox_override("pressed", UIV25.box(Color(UIV25.CYAN.r, UIV25.CYAN.g, UIV25.CYAN.b, 0.10), 11))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _page_header(kicker: String, title: String, subtitle: String) -> void:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 1)
	var top := HBoxContainer.new()
	var over := UIV25.label(kicker.to_upper(), 7, UIV25.CYAN, 800)
	over.add_theme_constant_override("letter_spacing", 1)
	top.add_child(over)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var code := UIV25.label("ESE / %s" % str(current_page).to_upper(), 7, UIV25.DIM, 800)
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(code)
	header.add_child(top)
	header.add_child(UIV25.label(title, 26, UIV25.TEXT, 800))
	if not subtitle.is_empty():
		header.add_child(UIV25.label(subtitle, 8, UIV25.MUTED, 600))
	page_content.add_child(header)

func _metric_block(caption: String, value: String, accent: Color) -> Control:
	var wrap := VBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 1)
	var value_label := UIV25.label(value, 18 if value.length() < 8 else 13, UIV25.TEXT, 800)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cap := UIV25.label(caption.to_upper(), 7, Color(accent.r, accent.g, accent.b, 0.70), 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(value_label)
	wrap.add_child(cap)
	var line := ColorRect.new()
	line.color = Color(accent.r, accent.g, accent.b, 0.24)
	line.custom_minimum_size.y = 1
	wrap.add_child(line)
	return wrap

func _build_home_page() -> void:
	page_content.add_child(_home_professional_stage())
	var roster := game.roster_for("Rocket League")
	if not roster.is_empty():
		page_content.add_child(_home_player_strip(roster[0]))
	page_content.add_child(_section_title("AKTUELL", ""))
	_build_history_list(page_content, 1)

func _home_professional_stage() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV25.new().configure(accent, "hero")
	stage.custom_minimum_size.y = 342
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV25.label("SEASON 1  ·  ROCKET LEAGUE", 8, UIV25.CYAN, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV25.badge(playlist, UIV25.CYAN))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV25.label("COMPETITIVE RUN", 8, UIV25.MUTED, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 34, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(5))
	copy.add_child(UIV25.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(148, 148)
	hero.add_child(emblem)
	box.add_child(hero)

	var objective := HBoxContainer.new()
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_child(UIV25.label("NÄCHSTER SCHRITT", 7, UIV25.DIM, 800))
	objective_copy.add_child(UIV25.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH", 13, UIV25.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV25.badge("%d/10" % mini(placements, 10) if not placed else "%d MMR" % mmr, accent))
	box.add_child(objective)
	box.add_child(UIV25.progress(placements if not placed else float(RankedV25.progress_for_mmr(mmr, playlist).get("value", 0)), 10 if not placed else float(RankedV25.progress_for_mmr(mmr, playlist).get("maximum", 1)), accent, 5))
	var action := UIV25.button("MATCH STARTEN", UIV25.CYAN, true)
	action.custom_minimum_size.y = 50
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage

func _origin_card() -> Control:
	return _home_professional_stage()

func _home_player_strip(player: Dictionary) -> Control:
	var panel := StageV25.new().configure(UIV25.CYAN, "player")
	panel.custom_minimum_size.y = 108
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var mini_show := ShowcaseV25.new().configure(player, UIV25.CYAN, game.player_overall(player))
	mini_show.custom_minimum_size = Vector2(72, 88)
	row.add_child(mini_show)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(UIV25.label("STARTING PLAYER", 7, UIV25.DIM, 800))
	info.add_child(UIV25.label(str(player.get("name", "PLAYER")).to_upper(), 18, UIV25.TEXT, 800))
	info.add_child(UIV25.label("%d OVR  ·  %d POT" % [game.player_overall(player), int(player.get("potential", 80))], 9, UIV25.MUTED, 700))
	row.add_child(info)
	var chem := UIV25.label("%d%%\nCHEMIE" % game.team_chemistry("Rocket League"), 14, UIV25.GREEN, 800)
	chem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(chem)
	return panel

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual := RankedV25.rank_for_mmr(mmr, playlist)
	var shown := actual if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown.get("family", "Unranked")))
	var stage := StageV25.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 286
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 13)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var top := HBoxContainer.new()
	var tag := UIV25.label("COMPETITIVE  ·  %s" % playlist, 8, UIV25.CYAN, 800)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	top.add_child(UIV25.badge("BEREIT", UIV25.GREEN))
	box.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(actual.get("tier_name", "RANKED")), 32, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(6))
	copy.add_child(UIV25.label("BILANZ  %d–%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	copy.add_child(UIV25.label("%.1f%% WINRATE" % RankedV25.win_rate(record), 9, UIV25.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown)
	emblem.custom_minimum_size = Vector2(152, 152)
	row.add_child(emblem)
	box.add_child(row)
	box.add_child(UIV25.progress(placements if not placed else float(RankedV25.progress_for_mmr(mmr, playlist).get("value", 0)), 10 if not placed else float(RankedV25.progress_for_mmr(mmr, playlist).get("maximum", 1)), accent, 5))
	return stage

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := StageV25.new().configure(accent, "player")
	stage.custom_minimum_size.y = 270
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var visual := ShowcaseV25.new().configure(player, accent, game.player_overall(player))
	visual.custom_minimum_size = Vector2(136, 176)
	row.add_child(visual)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV25.label("STARTER", 7, accent, 800))
	copy.add_child(UIV25.label(str(player.get("name", "PLAYER")).to_upper(), 25, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%s  ·  %s  ·  %d J." % [str(player.get("role", "PLAYER")).to_upper(), str(player.get("region", "EU")), int(player.get("age", 16))], 8, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(7))
	copy.add_child(UIV25.label("%d OVR" % game.player_overall(player), 31, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("POTENZIAL %d" % int(player.get("potential", 80)), 9, UIV25.GREEN, 800))
	row.add_child(copy)
	box.add_child(row)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	stats.add_child(_metric_block("MECH", str(int(player.get("mechanics", 50))), UIV25.CYAN))
	stats.add_child(_metric_block("SHOT", str(int(player.get("shooting", 50))), UIV25.GOLD))
	stats.add_child(_metric_block("DEF", str(int(player.get("defense", 50))), UIV25.GREEN))
	stats.add_child(_metric_block("SENSE", str(int(player.get("game_sense", 50))), UIV25.PURPLE))
	box.add_child(stats)
	return stage

func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var stage := StageV25.new().configure(accent, "player")
	stage.custom_minimum_size.y = 250
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var visual := ShowcaseV25.new().configure(player, accent, game.player_overall(player))
	visual.custom_minimum_size = Vector2(118, 158)
	row.add_child(visual)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UIV25.label("SCOUT REPORT", 7, accent, 800))
	info.add_child(UIV25.label(str(player.get("name", "PLAYER")).to_upper(), 21, UIV25.TEXT, 800))
	info.add_child(UIV25.label("%s  ·  %s  ·  %d J." % [str(player.get("role", "PLAYER")).to_upper(), str(player.get("region", "EU")), int(player.get("age", 16))], 8, UIV25.MUTED, 700))
	info.add_child(UIV25.v_space(6))
	info.add_child(UIV25.label("%d OVR" % game.player_overall(player), 28, UIV25.TEXT, 800))
	info.add_child(UIV25.label("POT %d" % int(player.get("potential", 50)), 9, UIV25.GREEN, 800))
	row.add_child(info)
	box.add_child(row)
	var price := int(player.get("contract", 0))
	var sign := UIV25.button("VERPFLICHTEN  ·  %s" % GameDataV25.format_cash(price), UIV25.CYAN, true)
	sign.disabled = int(game.data.get("cash", 0)) < price
	sign.pressed.connect(_sign_player.bind(str(player.get("id", ""))))
	box.add_child(sign)
	return stage

func _training_program_grid(player: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	var readiness := game.training_readiness(player)
	var focus_ready := bool(readiness.get("ok", false))
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var button := UIV25.button(str(program.get("short", "TRAIN")).to_upper() + "\nGRATIS", UIV25.CYAN, false, true)
		button.disabled = not focus_ready
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		var marker := ColorRect.new()
		marker.color = Color(UIV25.CYAN.r, UIV25.CYAN.g, UIV25.CYAN.b, 0.72)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		marker.offset_left = 0
		marker.offset_right = 2
		marker.offset_top = 10
		marker.offset_bottom = -10
		button.add_child(marker)
		grid.add_child(button)
	return grid

func _build_empire_page() -> void:
	_page_header("ORGANISATION", "Verein", "")
	_empire_view_switch()
	match empire_view:
		"staff":
			page_content.add_child(_staff_hq_card())
		"facilities":
			page_content.add_child(_section_title("ANLAGEN", ""))
			for key in GameDataV25.FACILITIES:
				page_content.add_child(_facility_card(key))
		_:
			var stage := StageV25.new().configure(UIV25.GOLD, "club")
			stage.custom_minimum_size.y = 224
			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 16)
			margin.add_theme_constant_override("margin_right", 16)
			margin.add_theme_constant_override("margin_top", 14)
			margin.add_theme_constant_override("margin_bottom", 14)
			stage.add_child(margin)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 8)
			margin.add_child(box)
			box.add_child(UIV25.label("CLUB HQ", 8, UIV25.GOLD, 800))
			box.add_child(UIV25.label(str(game.data.get("club_name", "TSK ESPORTS")).to_upper(), 28, UIV25.TEXT, 800))
			box.add_child(UIV25.label("DEIN ESPORTS-PROJEKT", 9, UIV25.MUTED, 700))
			var status := HBoxContainer.new()
			status.add_theme_constant_override("separation", 5)
			status.add_child(_metric_block("€ / H", GameDataV25.format_cash(game.passive_income_per_hour()), UIV25.GOLD))
			status.add_child(_metric_block("FANS / H", "+%s" % GameDataV25.format_number(game.passive_fans_per_hour()), UIV25.CYAN))
			status.add_child(_metric_block("LEVEL", str(game.career_level()), UIV25.GREEN))
			box.add_child(status)
			page_content.add_child(stage)
			page_content.add_child(_club_identity_card())
