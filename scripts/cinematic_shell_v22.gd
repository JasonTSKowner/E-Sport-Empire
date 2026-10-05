extends "res://scripts/cinematic_shell.gd"

const StateV22Ref = preload("res://scripts/game_state_v22.gd")
const MatchVizV22Ref = preload("res://scripts/match_visualizer_v22.gd")
const TrainingVizV22Ref = preload("res://scripts/training_visualizer_v22.gd")
const SetupV22Ref = preload("res://scripts/setup_data.gd")
const ChangelogV22Ref = preload("res://scripts/changelog_data.gd")
const UIV22 = preload("res://scripts/ui_kit.gd")
const SurfaceV22 = preload("res://scripts/cinematic_surface.gd")
const GameDataV22 = preload("res://scripts/game_data.gd")
const AppConfigV22 = preload("res://scripts/app_config.gd")

var backup_input: TextEdit


func _ready() -> void:
	game = StateV22Ref.new()
	var offline: Dictionary = game.load_game()
	_build_shell()
	_show_page(AppConfigV22.DEFAULT_PAGE, false)
	if int(offline.get("seconds", 0)) >= 60 and (int(offline.get("cash", 0)) > 0 or int(offline.get("fans", 0)) > 0):
		call_deferred("_show_offline_message", offline)


func _v22() -> EmpireStateV22:
	return game as EmpireStateV22


func _build_match_overlay() -> void:
	super._build_match_overlay()
	if match_visualizer != null and is_instance_valid(match_visualizer):
		var old := match_visualizer
		var parent := old.get_parent()
		var index := old.get_index()
		if parent != null:
			parent.remove_child(old)
			old.queue_free()
			var replacement := MatchVizV22Ref.new()
			replacement.configure(match_result)
			parent.add_child(replacement)
			parent.move_child(replacement, index)
			match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.05


func _set_match_speed(speed: int) -> void:
	if match_finished:
		return
	match_speed = speed
	if match_timer != null:
		match_timer.wait_time = 1.05 / float(maxi(1, speed))
		match_timer.start()


func _advance_match() -> void:
	if match_finished:
		return
	var events: Array = match_result.get("broadcast_events", match_result.get("events", []))
	var phase := "reset"
	if match_event_index < events.size():
		phase = str(events[match_event_index].get("phase", "reset"))
	super._advance_match()
	if match_timer != null and not match_finished:
		var base_delay := 0.92
		if phase in ["psycho_setup", "own_wall_carry", "backwall_musty", "psycho_contact", "teammate_prejump", "redirect_finish"]:
			base_delay = 1.28
		elif phase in ["wall_setup", "air_carry", "air_carry_2", "reset_contact", "reset_delay", "second_reset", "third_reset", "finish_touch"]:
			base_delay = 1.16
		elif phase in ["rotation_switch", "challenge"]:
			base_delay = 1.02
		elif phase in ["goal_ours", "goal_theirs"]:
			base_delay = 1.34
		match_timer.wait_time = base_delay / float(maxi(1, match_speed))


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v22()
	var readiness := state.training_readiness(player)
	var panel := SurfaceV22.new().configure(accent, "training", 0.90)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var header := HBoxContainer.new()
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(UIV22.label("PERFORMANCE LAB", 7, UIV22.DIM, 800))
	title.add_child(UIV22.label(str(player.get("name", "SPIELER")).to_upper(), 20, UIV22.TEXT, 800))
	header.add_child(title)
	header.add_child(UIV22.badge("TRAINING GRATIS", UIV22.GREEN))
	box.add_child(header)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV22.CYAN))
	status.add_child(_metric_block("MÜDIGKEIT", "%d" % int(player.get("fatigue", 0)), UIV22.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV22.PURPLE))
	box.add_child(status)

	var training_view := TrainingVizV22Ref.new()
	training_view.configure(player, readiness, accent)
	box.add_child(training_view)

	var signature := ShellDevelopment.signature_move(player)
	if not signature.is_empty():
		var mechanic_id := str(signature.get("id", ""))
		var mastery := state.mechanic_mastery(player, mechanic_id)
		var mastery_row := HBoxContainer.new()
		var mechanic_name := UIV22.label(str(signature.get("label", "MECHANIK")).to_upper(), 10, UIV22.TEXT, 800)
		mechanic_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mechanic_name)
		mastery_row.add_child(UIV22.badge("%d%% MASTERY" % mastery, accent))
		box.add_child(mastery_row)
		box.add_child(UIV22.progress(mastery, 100, accent, 5))

	var training_title := HBoxContainer.new()
	training_title.add_child(UIV22.label("DRILL WÄHLEN", 8, UIV22.DIM, 800))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training_title.add_child(spacer)
	training_title.add_child(UIV22.label("Kein Geld · Müdigkeit limitiert", 7, UIV22.MUTED, 700))
	box.add_child(training_title)
	box.add_child(_training_program_grid(player))
	return panel


func _training_program_grid(player: Dictionary) -> Control:
	var state := _v22()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var readiness := state.training_readiness(player)
	var can_train := bool(readiness.get("ok", false))
	for program_value in state.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var color := Color(str(program.get("color", "7FE7FF")))
		var button := UIV22.button("%s\nGRATIS" % str(program.get("short", "TRAIN")), color, can_train, true)
		button.disabled = not can_train
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 9)
		button.tooltip_text = str(program.get("detail", "Training"))
		if not can_train:
			button.tooltip_text = "Training pausiert: Müdigkeit muss unter %d fallen." % int(readiness.get("fatigue_limit", 80))
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		grid.add_child(button)
	return grid


func _empire_view_switch() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	for entry in [
		["overview", "STATUS"],
		["setup", "SETUP"],
		["staff", "STAFF"],
		["facilities", "ANLAGEN"],
		["system", "SYSTEM"],
	]:
		var target := str(entry[0])
		var button := UIV22.tab(str(entry[1]), empire_view == target, UIV22.GOLD)
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_select_empire_view.bind(target))
		grid.add_child(button)
	page_content.add_child(grid)


func _build_empire_page() -> void:
	_page_header("VEREINSZENTRALE", "Verein", "")
	_empire_view_switch()
	match empire_view:
		"setup":
			_build_setup_page()
		"system":
			_build_system_page()
		"staff":
			page_content.add_child(_staff_hq_card())
		"facilities":
			page_content.add_child(_section_title("ANLAGEN", ""))
			for key in GameDataV22.FACILITIES:
				page_content.add_child(_facility_card(key))
		_:
			var panel := SurfaceV22.new().configure(UIV22.GOLD, "club", 0.75)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 7)
			panel.add_child(box)
			box.add_child(UIV22.label("VEREINSSTATUS", 7, UIV22.DIM, 800))
			box.add_child(UIV22.label(str(game.data.get("club_name", "TSK ESPORTS")), 24, UIV22.TEXT, 800))
			var status := HBoxContainer.new()
			status.add_theme_constant_override("separation", 5)
			status.add_child(_metric_block("€ / H", GameDataV22.format_cash(game.passive_income_per_hour()), UIV22.GOLD))
			status.add_child(_metric_block("FANS / H", "+%s" % GameDataV22.format_number(game.passive_fans_per_hour()), UIV22.CYAN))
			status.add_child(_metric_block("SETUP", "%d%%" % _v22().setup_rating(), UIV22.PURPLE))
			box.add_child(status)
			page_content.add_child(panel)
			page_content.add_child(_club_identity_card())


func _build_setup_page() -> void:
	var state := _v22()
	var hero := SurfaceV22.new().configure(UIV22.CYAN, "club", 0.82)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 7)
	hero.add_child(hero_box)
	hero_box.add_child(UIV22.label("DEIN GAMING-SETUP", 7, UIV22.DIM, 800))
	hero_box.add_child(UIV22.label("Bedroom Grinder → Pro Station", 22, UIV22.TEXT, 800))
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 4)
	metrics.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV22.CYAN))
	metrics.add_child(_metric_block("PING", "%d ms" % state.connection_ping(), UIV22.GREEN))
	metrics.add_child(_metric_block("STABIL", "%d%%" % int(round(state.connection_stability() * 100.0)), UIV22.PURPLE))
	hero_box.add_child(metrics)
	page_content.add_child(hero)

	for key in SetupV22Ref.CATEGORIES:
		page_content.add_child(_setup_upgrade_card(key))


func _setup_upgrade_card(key: String) -> Control:
	var state := _v22()
	var definition := SetupV22Ref.definition(key)
	var level := state.setup_level(key)
	var tier := state.setup_tier(key)
	var maxed := level >= SetupV22Ref.max_level(key)
	var panel := UIV22.card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var row := HBoxContainer.new()
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UIV22.label(str(definition.get("name", key)).to_upper(), 8, UIV22.DIM, 800))
	info.add_child(UIV22.label(str(tier.get("name", "Starter")), 15, UIV22.TEXT, 800))
	row.add_child(info)
	row.add_child(UIV22.badge("LV %d/%d" % [level, SetupV22Ref.max_level(key)], UIV22.CYAN if not maxed else UIV22.GREEN))
	box.add_child(row)
	var detail := ""
	if key == "internet":
		detail = "%d ms · %d%% Stabilität" % [int(tier.get("ping", 46)), int(round(float(tier.get("stability", 0.88)) * 100.0))]
	elif key == "desk":
		detail = "-%d Müdigkeit nach Training" % int(tier.get("fatigue_relief", 0))
	elif key in ["controller", "display"]:
		detail = "Training +%d%% · Konstanz +%d%%" % [int(round(float(tier.get("training", 0.0)) * 100.0)), int(round(float(tier.get("consistency", 0.0)) * 100.0))]
	else:
		detail = "Match-Read +%d%%" % int(round(float(tier.get("sense", 0.0)) * 100.0))
	box.add_child(UIV22.label(detail, 9, UIV22.MUTED, 700))
	var button := UIV22.button("MAXIMAL" if maxed else "UPGRADE  ·  %s" % GameDataV22.format_cash(state.setup_upgrade_cost(key)), UIV22.CYAN, not maxed)
	button.disabled = maxed or int(game.data.get("cash", 0)) < state.setup_upgrade_cost(key)
	button.pressed.connect(_buy_setup.bind(key))
	box.add_child(button)
	return panel


func _buy_setup(key: String) -> void:
	var result := _v22().buy_setup_upgrade(key)
	_v22_notice(str(result.get("message", "Upgrade abgeschlossen.")), UIV22.GREEN if bool(result.get("ok", false)) else UIV22.RED)
	_show_page("empire", false)


func _build_system_page() -> void:
	var state := _v22()
	var backup_panel := SurfaceV22.new().configure(UIV22.CYAN, "club", 0.72)
	var backup_box := VBoxContainer.new()
	backup_box.add_theme_constant_override("separation", 8)
	backup_panel.add_child(backup_box)
	var title_row := HBoxContainer.new()
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(UIV22.label("EMPIRE BACKUP", 8, UIV22.CYAN, 800))
	title.add_child(UIV22.label("Spielstand nach Neuinstallation zurückholen", 16, UIV22.TEXT, 800))
	title_row.add_child(title)
	title_row.add_child(UIV22.badge("AKTIV" if state.backup_enabled() else "OPTIONAL", UIV22.GREEN if state.backup_enabled() else UIV22.MUTED))
	backup_box.add_child(title_row)
	backup_box.add_child(UIV22.label("Der Recovery-Code enthält deinen Spielstand. Kopiere ihn außerhalb der App; dann kannst du ihn nach einer Deinstallation wieder einfügen.", 9, UIV22.MUTED))
	backup_input = TextEdit.new()
	backup_input.custom_minimum_size.y = 92
	backup_input.placeholder_text = "Recovery-Code hier einfügen oder Backup erstellen …"
	backup_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	backup_input.add_theme_font_size_override("font_size", 8)
	backup_box.add_child(backup_input)
	var backup_actions := HBoxContainer.new()
	backup_actions.add_theme_constant_override("separation", 5)
	var create := UIV22.button("BACKUP ERSTELLEN", UIV22.CYAN, true, true)
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.pressed.connect(_create_backup)
	backup_actions.add_child(create)
	var restore := UIV22.button("WIEDERHERSTELLEN", UIV22.GREEN, false, true)
	restore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore.pressed.connect(_restore_backup)
	backup_actions.add_child(restore)
	backup_box.add_child(backup_actions)
	page_content.add_child(backup_panel)

	var latest := ChangelogV22Ref.latest()
	var change_panel := UIV22.card(UIV22.PURPLE)
	var change_box := VBoxContainer.new()
	change_box.add_theme_constant_override("separation", 6)
	change_panel.add_child(change_box)
	change_box.add_child(UIV22.label("NEU  ·  V%s" % str(latest.get("version", "2.2.0")), 8, UIV22.PURPLE, 800))
	change_box.add_child(UIV22.label(str(latest.get("title", "UPDATE")), 20, UIV22.TEXT, 800))
	change_box.add_child(UIV22.label(str(latest.get("date", "")), 8, UIV22.DIM, 700))
	for item in latest.get("items", []):
		change_box.add_child(UIV22.label("•  %s" % str(item), 9, UIV22.MUTED))
	page_content.add_child(change_panel)


func _create_backup() -> void:
	var result := _v22().create_backup_code()
	if bool(result.get("ok", false)):
		var code := str(result.get("code", ""))
		backup_input.text = code
		DisplayServer.clipboard_set(code)
	_v22_notice(str(result.get("message", "Backup erstellt.")), UIV22.GREEN if bool(result.get("ok", false)) else UIV22.RED)


func _restore_backup() -> void:
	if backup_input == null or backup_input.text.strip_edges().is_empty():
		_v22_notice("Füge zuerst einen Recovery-Code ein.", UIV22.RED)
		return
	var result := _v22().restore_backup_code(backup_input.text)
	_v22_notice(str(result.get("message", "Backup geprüft.")), UIV22.GREEN if bool(result.get("ok", false)) else UIV22.RED)
	if bool(result.get("ok", false)):
		_show_page("empire", false)


func _v22_notice(text: String, accent: Color) -> void:
	if toast_panel == null or toast_label == null:
		return
	toast_token += 1
	var token := toast_token
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate = Color.WHITE
	var style := UIV22.box(Color(0.055, 0.068, 0.086, 0.99), 14, Color(accent.r, accent.g, accent.b, 0.25), 1)
	toast_panel.add_theme_stylebox_override("panel", style)
	get_tree().create_timer(2.6).timeout.connect(func():
		if token == toast_token and toast_panel != null:
			toast_panel.visible = false
	)
