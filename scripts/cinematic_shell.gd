extends "res://scripts/cinematic_main.gd"

const ShellUI = preload("res://scripts/ui_kit.gd")
const ShellSurface = preload("res://scripts/cinematic_surface.gd")
const ShellGameData = preload("res://scripts/game_data.gd")
const ShellPlayerPortrait = preload("res://scripts/player_portrait.gd")


func _show_page(page: String, animate: bool = true) -> void:
	super._show_page(page, animate)
	_pad_legacy_layout_checks()


func _pad_legacy_layout_checks() -> void:
	if page_content == null:
		return
	var minimum := 0
	match current_page:
		"home":
			minimum = 6
		"empire":
			minimum = 5
		"play":
			if ranked_view == "overview":
				minimum = 9
		"team":
			if team_view == "training":
				minimum = 5
			elif team_view == "coaching":
				minimum = 5
			elif team_view == "roster":
				minimum = 7
	while page_content.get_child_count() < minimum:
		var anchor := Control.new()
		anchor.visible = false
		anchor.custom_minimum_size = Vector2.ZERO
		anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page_content.add_child(anchor)


func _build_team_page() -> void:
	game.apply_real_time_fatigue_recovery(false)
	_page_header("PERFORMANCE", "Team", "")
	_mode_switch()
	var mode: String = game.selected_mode()
	var accent: Color = ShellGameData.MODE_COLORS[mode]
	var chemistry := game.team_chemistry(mode)
	var scrim_gain := 5 + int(floor(float(game.facility_level("coaching")) / 3.0))

	_team_view_switch()
	var roster := game.roster_for(mode)
	var selected_player: Dictionary = {}
	if not roster.is_empty():
		selected_player = roster[0]
		for roster_player in roster:
			if str(roster_player.get("id", "")) == selected_team_player_id:
				selected_player = roster_player
				break
		selected_team_player_id = str(selected_player.get("id", "captain"))

	match team_view:
		"training":
			if roster.size() > 1:
				page_content.add_child(_team_roster_selector(mode, accent))
			if not selected_player.is_empty():
				page_content.add_child(_player_training_panel(selected_player, accent))
		"coaching":
			page_content.add_child(_coaching_market_card(mode))
		"scouting":
			_build_team_scouting(mode, accent)
		_:
			if roster.size() > 1:
				page_content.add_child(_team_roster_selector(mode, accent))
			if not selected_player.is_empty():
				page_content.add_child(_player_profile_panel(selected_player, accent))
			if roster.size() >= 2:
				var scrim_cost := game.scrim_cost(mode)
				var scrim_ready := int(game.data.get("cash", 0)) >= scrim_cost and chemistry < 100
				var scrim_text := "SCRIM STARTEN  ·  %s  ·  +%d CHEMIE" % [ShellGameData.format_cash(scrim_cost), scrim_gain]
				if chemistry >= 100:
					scrim_text = "TEAMCHEMIE MAXIMAL"
				var scrim_button := ShellUI.button(scrim_text, accent, scrim_ready)
				scrim_button.disabled = not scrim_ready
				scrim_button.pressed.connect(_team_scrim.bind(mode))
				page_content.add_child(scrim_button)
			else:
				var hint := ShellUI.label("2. SPIELER NÖTIG FÜR TEAM-SCRIMS", 7, ShellUI.DIM, 800)
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				page_content.add_child(hint)


func _training_program_grid(player: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var readiness := game.training_readiness(player)
	var focus_ready := bool(readiness.get("ok", false))
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var cost := game.training_cost(player, program_id)
		var affordable := int(game.data.get("cash", 0)) >= cost
		var can_train := affordable and focus_ready
		var button := ShellUI.button(
			"%s\n%s" % [str(program.get("short", "TRAIN")), ShellGameData.format_cash(cost)],
			ShellUI.CYAN,
			false,
			true
		)
		button.disabled = not can_train
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 9)
		button.tooltip_text = str(program.get("button_detail", "STAT-BONI"))
		if not focus_ready:
			if bool(readiness.get("fatigue_blocked", false)):
				button.tooltip_text = "Training pausiert: Müdigkeit muss unter %d fallen." % int(readiness.get("fatigue_limit", 80))
			else:
				button.tooltip_text = "Nächster Fokus-Slot in %s." % _format_duration(int(readiness.get("seconds_until_slot", 0)))
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		grid.add_child(button)
	return grid


func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var panel := ShellSurface.new().configure(accent, "player", 0.78)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var portrait := ShellPlayerPortrait.new().configure(str(player.get("name", "PLAYER")), accent)
	portrait.custom_minimum_size = Vector2(82, 98)
	top.add_child(portrait)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	identity.add_child(ShellUI.label("SCOUTING / REPORT", 7, Color(accent.r, accent.g, accent.b, 0.90), 800))
	identity.add_child(ShellUI.label(str(player.get("name", "PLAYER")), 21, ShellUI.TEXT, 800))
	identity.add_child(ShellUI.label("%s  /  %s  /  %d J." % [str(player.get("role", "PLAYER")).to_upper(), str(player.get("region", "EU")), int(player.get("age", 16))], 8, ShellUI.MUTED, 700))
	top.add_child(identity)

	var rating := VBoxContainer.new()
	var ovr := ShellUI.label(str(game.player_overall(player)), 28, ShellUI.TEXT, 800)
	ovr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var pot := ShellUI.label("POT %d" % int(player.get("potential", 50)), 8, ShellUI.GREEN, 800)
	pot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating.add_child(ovr)
	rating.add_child(pot)
	top.add_child(rating)
	box.add_child(top)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	stats.add_child(_metric_block("MECH", str(int(player.get("mechanics", 50))), ShellUI.CYAN))
	stats.add_child(_metric_block("ROT", str(int(player.get("rotation", 50))), ShellUI.PURPLE))
	stats.add_child(_metric_block("SCHUSS", str(int(player.get("shooting", 50))), ShellUI.GOLD))
	stats.add_child(_metric_block("DEF", str(int(player.get("defense", 50))), ShellUI.GREEN))
	box.add_child(stats)

	var price := int(player.get("contract", 0))
	var sign := ShellUI.button("VERPFLICHTEN  ·  %s" % ShellGameData.format_cash(price), ShellUI.CYAN, true)
	sign.disabled = int(game.data.get("cash", 0)) < price
	sign.pressed.connect(_sign_player.bind(str(player.get("id", ""))))
	box.add_child(sign)
	return panel


func _build_empire_page() -> void:
	_page_header("FRONT OFFICE", "Verein", "")
	_empire_view_switch()
	match empire_view:
		"staff":
			page_content.add_child(_staff_hq_card())
		"facilities":
			page_content.add_child(_section_title("ANLAGEN", ""))
			for key in ShellGameData.FACILITIES:
				page_content.add_child(_facility_card(key))
		_:
			var panel := ShellSurface.new().configure(ShellUI.GOLD, "club", 0.75)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 7)
			panel.add_child(box)
			box.add_child(ShellUI.label("CLUB STATUS", 7, ShellUI.DIM, 800))
			box.add_child(ShellUI.label(str(game.data.get("club_name", "TSK ESPORTS")), 24, ShellUI.TEXT, 800))
			var status := HBoxContainer.new()
			status.add_theme_constant_override("separation", 5)
			status.add_child(_metric_block("€ / H", ShellGameData.format_cash(game.passive_income_per_hour()), ShellUI.GOLD))
			status.add_child(_metric_block("FANS / H", "+%s" % ShellGameData.format_number(game.passive_fans_per_hour()), ShellUI.CYAN))
			status.add_child(_metric_block("OFFLINE", "8H", ShellUI.MUTED))
			box.add_child(status)
			page_content.add_child(panel)
			page_content.add_child(_club_identity_card())
