extends Control

const GameDataRef = preload("res://scripts/game_data.gd")
const EmpireStateRef = preload("res://scripts/game_state.gd")
const UI = preload("res://scripts/ui_kit.gd")

var game: EmpireState
var current_page := "home"
var shell: VBoxContainer
var page_scroll: ScrollContainer
var page_content: VBoxContainer
var cash_label: Label
var fans_label: Label
var energy_label: Label
var season_label: Label
var nav_buttons: Dictionary = {}
var toast_panel: PanelContainer
var toast_label: Label
var toast_token := 0

var match_overlay: Control
var match_timer: Timer
var match_result: Dictionary = {}
var match_event_index := 0
var match_speed := 1
var match_score_label: Label
var match_clock_label: Label
var match_event_label: Label
var match_progress: ProgressBar
var match_log_box: VBoxContainer
var match_log_scroll: ScrollContainer
var match_result_box: VBoxContainer
var match_continue_button: Button


func _ready() -> void:
	game = EmpireStateRef.new()
	var offline: Dictionary = game.load_game()
	_build_shell()
	_show_page("home", false)
	if int(offline.get("seconds", 0)) >= 60 and (int(offline.get("cash", 0)) > 0 or int(offline.get("fans", 0)) > 0):
		call_deferred("_show_offline_message", offline)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if game != null:
			game.save_game()


func _build_shell() -> void:
	shell = VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)

	var top_bar := _build_top_bar()
	shell.add_child(top_bar)

	page_scroll = ScrollContainer.new()
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page_scroll.scroll_deadzone = 4
	page_scroll.follow_focus = false
	shell.add_child(page_scroll)

	page_content = VBoxContainer.new()
	page_content.mouse_filter = Control.MOUSE_FILTER_PASS
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_content.add_theme_constant_override("separation", 14)
	var page_margin := UI.margin(page_content, 18, 18, 18, 28)
	page_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(page_margin)

	shell.add_child(_build_bottom_navigation())
	_build_toast()
	_refresh_top_bar()


func _build_top_bar() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.y = 132.0
	outer.add_theme_stylebox_override(
		"panel", UI.box(Color(0.025, 0.04, 0.105, 0.98), 0, Color(0.18, 0.34, 0.65, 0.18), 0)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(margin)
	var vertical := VBoxContainer.new()
	vertical.add_theme_constant_override("separation", 12)
	margin.add_child(vertical)

	var brand_row := HBoxContainer.new()
	brand_row.add_theme_constant_override("separation", 11)
	vertical.add_child(brand_row)
	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(42, 42)
	mark.add_theme_stylebox_override(
		"panel", UI.box(Color(0.18, 0.82, 1.0, 0.12), 13, Color(0.18, 0.88, 1.0, 0.72), 1)
	)
	var mark_text := UI.label("EE", 15, UI.CYAN, 800)
	mark_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(mark_text)
	brand_row.add_child(mark)

	var brand_text := VBoxContainer.new()
	brand_text.add_theme_constant_override("separation", 0)
	brand_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UI.label(str(game.data.get("club_name", "TSK ESPORTS")), 17, UI.TEXT, 800)
	season_label = UI.label("", 11, UI.MUTED)
	brand_text.add_child(title)
	brand_text.add_child(season_label)
	brand_row.add_child(brand_text)

	var version_badge := UI.badge("ALPHA 0.4.4", UI.PURPLE)
	version_badge.custom_minimum_size.x = 84
	brand_row.add_child(version_badge)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	vertical.add_child(stats)
	var cash_chip := _header_chip("CASH", UI.CYAN)
	cash_label = cash_chip.get_meta("value_label")
	stats.add_child(cash_chip)
	var fans_chip := _header_chip("FANS", UI.PURPLE)
	fans_label = fans_chip.get_meta("value_label")
	stats.add_child(fans_chip)
	var energy_chip := _header_chip("ENERGY", UI.GREEN)
	energy_label = energy_chip.get_meta("value_label")
	stats.add_child(energy_chip)
	return outer


func _header_chip(caption: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		UI.box(Color(0.07, 0.10, 0.22, 0.92), 13, Color(accent.r, accent.g, accent.b, 0.23), 1)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var dot := UI.label("•", 16, accent, 800)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 0)
	var cap := UI.label(caption, 9, UI.MUTED, 800)
	var value := UI.label("—", 13, UI.TEXT, 800)
	text_box.add_child(cap)
	text_box.add_child(value)
	row.add_child(dot)
	row.add_child(text_box)
	panel.add_child(row)
	panel.set_meta("value_label", value)
	return panel


func _build_bottom_navigation() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.y = 88.0
	outer.add_theme_stylebox_override(
		"panel", UI.box(Color(0.025, 0.04, 0.105, 0.99), 0, Color(0.22, 0.38, 0.72, 0.2), 0)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)
	var entries := [
		["home", "HOME", "01"],
		["team", "TEAM", "02"],
		["play", "PLAY", "03"],
		["market", "SCOUT", "04"],
		["empire", "EMPIRE", "05"],
	]
	for entry in entries:
		var button := Button.new()
		button.text = "%s\n%s" % [entry[2], entry[1]]
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 64
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_show_page.bind(entry[0], true))
		row.add_child(button)
		nav_buttons[entry[0]] = button
	return outer


func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_panel.anchor_left = 0.06
	toast_panel.anchor_right = 0.94
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_top = -164.0
	toast_panel.offset_bottom = -101.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override(
		"panel", UI.box(Color(0.06, 0.095, 0.20, 0.98), 17, Color(0.18, 0.86, 1.0, 0.42), 1)
	)
	toast_label = UI.label("", 14, UI.TEXT, 700)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	toast_panel.visible = false
	add_child(toast_panel)


func _refresh_top_bar() -> void:
	cash_label.text = GameDataRef.format_cash(int(game.data.get("cash", 0)))
	fans_label.text = GameDataRef.format_number(int(game.data.get("fans", 0)))
	energy_label.text = "%d%%" % int(game.data.get("energy", 0))
	season_label.text = (
		"SEASON %d  •  WEEK %d/12  •  ROAD TO PRO"
		% [int(game.data.get("season", 1)), int(game.data.get("week", 1))]
	)


func _refresh_nav() -> void:
	for key in nav_buttons:
		var button: Button = nav_buttons[key]
		var selected: bool = str(key) == current_page
		button.add_theme_color_override("font_color", UI.CYAN if selected else UI.MUTED)
		button.add_theme_color_override("font_hover_color", UI.TEXT)
		button.add_theme_stylebox_override(
			"normal",
			UI.box(
				Color(0.16, 0.70, 1.0, 0.13) if selected else Color.TRANSPARENT,
				14,
				Color(0.18, 0.86, 1.0, 0.35) if selected else Color.TRANSPARENT,
				1 if selected else 0
			)
		)
		button.add_theme_stylebox_override("hover", UI.box(Color(0.14, 0.24, 0.45, 0.35), 14))
		button.add_theme_stylebox_override("pressed", UI.box(Color(0.15, 0.65, 0.95, 0.20), 14))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _show_page(page: String, animate: bool = true) -> void:
	if match_overlay != null and is_instance_valid(match_overlay):
		return
	current_page = page
	for child in page_content.get_children():
		page_content.remove_child(child)
		child.queue_free()
	page_scroll.scroll_vertical = 0
	match current_page:
		"home":
			_build_home_page()
		"team":
			_build_team_page()
		"play":
			_build_play_page()
		"market":
			_build_market_page()
		"empire":
			_build_empire_page()
		_:
			_build_home_page()
	_apply_scroll_passthrough(page_content)
	_refresh_top_bar()
	_refresh_nav()
	if animate:
		page_content.modulate.a = 0.0
		page_content.position.x = 12.0
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(page_content, "modulate:a", 1.0, 0.18)
		tween.tween_property(page_content, "position:x", 0.0, 0.22)


func _apply_scroll_passthrough(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
		elif child is ScrollContainer:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
		elif child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_apply_scroll_passthrough(child)


func _page_header(kicker: String, title: String, subtitle: String) -> void:
	page_content.add_child(UI.overline(kicker, UI.CYAN))
	page_content.add_child(UI.heading(title, 27))
	var sub := UI.label(subtitle, 14, UI.MUTED)
	sub.custom_minimum_size.y = 38
	page_content.add_child(sub)


func _mode_switch() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var selected: String = game.selected_mode()
	for mode in GameDataRef.MODES:
		var active: bool = str(mode) == selected
		var accent: Color = GameDataRef.MODE_COLORS[mode]
		var button := UI.button(GameDataRef.MODE_SHORT[mode], accent, active, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = mode
		button.pressed.connect(_select_mode.bind(mode))
		row.add_child(button)
	page_content.add_child(row)


func _select_mode(mode: String) -> void:
	game.set_selected_mode(mode)
	_show_page(current_page, false)


func _build_home_page() -> void:
	_page_header(
		"Origin Story",
		"You are the captain",
		"One player. Zero cash. Zero fans. Earn attention first — the organization comes later."
	)
	page_content.add_child(_origin_card())
	page_content.add_child(_club_hero())
	if not game.data.get("contacts", []).is_empty():
		page_content.add_child(_section_title("PEOPLE NOTICING YOU", "Real contacts can become your first teammates."))
		for contact in game.data.get("contacts", []):
			page_content.add_child(_contact_card(contact))
	page_content.add_child(_sponsor_card())
	page_content.add_child(_section_title("DIVISION STATUS", "Rocket League starts solo. Other divisions need players."))
	for mode in GameDataRef.MODES:
		page_content.add_child(_division_row(mode))
	page_content.add_child(_section_title("RECENT FORM", "Your latest organization results."))
	_build_history_list(page_content, 4)

func _origin_card() -> Control:
	var panel := UI.card(UI.CYAN)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UI.overline("FROM ZERO", UI.CYAN))
	box.add_child(UI.label("You are player #1 and the captain.", 19, UI.TEXT, 800))
	box.add_child(UI.label(
		"Ranked pays €0. Your first job is simple: play, improve and get noticed.",
		12,
		UI.MUTED
	))
	var row := HBoxContainer.new()
	row.add_child(_metric_block("CASH", GameDataRef.format_cash(int(game.data.get("cash", 0))), UI.GOLD))
	row.add_child(_metric_block("ATTENTION", str(int(game.data.get("attention", 0))), UI.PURPLE))
	row.add_child(_metric_block("FORMAT", game.match_format("Rocket League"), UI.CYAN))
	box.add_child(row)
	return panel


func _contact_card(contact: Dictionary) -> Control:
	var mode := str(contact.get("mode", "Rocket League"))
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var panel := UI.card(accent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.overline(str(contact.get("source", "MATCH CONTACT")), accent))
	info.add_child(UI.label(str(contact.get("name", "Unknown")), 17, UI.TEXT, 800))
	info.add_child(UI.label(
		"%s  •  OVR %d  •  POT %d"
		% [mode, game.player_overall(contact), int(contact.get("potential", 70))],
		11,
		UI.MUTED
	))
	row.add_child(info)
	var accept := UI.button("QUEUE
TOGETHER", accent, true, true)
	accept.custom_minimum_size.x = 116
	accept.pressed.connect(_accept_contact.bind(str(contact.get("id", ""))))
	row.add_child(accept)
	return panel


func _club_hero() -> Control:
	var mode: String = game.selected_mode()
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var rank: Dictionary = game.rank_data(mode)
	var next_rank: Dictionary = game.next_rank_data(mode)
	var visible_rank := game.visible_rank_name(mode)
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)
	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(66, 66)
	emblem.add_theme_stylebox_override(
		"panel", UI.box(Color(accent.r, accent.g, accent.b, 0.15), 20, accent, 1)
	)
	var initials := UI.label("TSK", 19, accent, 800)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.add_child(initials)
	top.add_child(emblem)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 3)
	details.add_child(UI.overline("ACTIVE DIVISION", accent))
	details.add_child(UI.heading(mode, 20))
	details.add_child(
		UI.label("OVR %d  •  %s" % [game.team_overall(mode), visible_rank], 13, UI.MUTED, 700)
	)
	top.add_child(details)

	var mmr_box := VBoxContainer.new()
	var mmr_title := UI.label(str(game.mode_mmr(mode)), 25, UI.TEXT, 800)
	mmr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var mmr_cap := UI.label("MMR", 10, accent, 800)
	mmr_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mmr_box.add_child(mmr_title)
	mmr_box.add_child(mmr_cap)
	top.add_child(mmr_box)

	var progress_labels := HBoxContainer.new()
	if mode == "Rocket League" and not game.placements_complete(mode):
		var record := game.mode_record(mode)
		var placed := int(record.get("placements", 0))
		var target := game.placement_target(mode)
		var current_label := UI.label("UNRANKED", 12, UI.TEXT, 700)
		current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_labels.add_child(current_label)
		var next_label := UI.label("%d/%d PLACEMENTS" % [placed, target], 11, UI.MUTED)
		next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_labels.add_child(next_label)
		box.add_child(progress_labels)
		box.add_child(UI.progress(placed, target, accent, 8))
	else:
		var current_min := int(rank["minimum"])
		var next_min := int(next_rank["minimum"])
		var progress_value: int = game.mode_mmr(mode) - current_min
		var progress_max := maxi(1, next_min - current_min)
		var current_label := UI.label(str(rank["name"]), 12, UI.TEXT, 700)
		current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_labels.add_child(current_label)
		var next_label := UI.label(
			"MAX RANK" if next_min == current_min else "%s  %d" % [next_rank["name"], next_min],
			11,
			UI.MUTED
		)
		next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_labels.add_child(next_label)
		box.add_child(progress_labels)
		box.add_child(UI.progress(progress_value, progress_max, accent, 8))

	var manage := UI.button("MANAGE %s DIVISION" % GameDataRef.MODE_SHORT[mode], accent, true)
	manage.pressed.connect(_show_page.bind("team", true))
	box.add_child(manage)
	return panel

func _sponsor_card() -> Control:
	var panel := UI.card(UI.GOLD)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.overline("SPONSORS", UI.GOLD))
	text.add_child(UI.label("No fake money printer", 18, UI.TEXT, 800))
	var subtitle := ""
	if not game.sponsor_eligible():
		subtitle = "Locked — build reputation plus 100 fans or 120 stream followers."
	elif game.sponsor_ready():
		subtitle = "A small brand activation is ready."
	else:
		subtitle = "Next activation in %s" % _format_duration(game.sponsor_seconds_left())
	text.add_child(UI.label(subtitle, 12, UI.MUTED))
	row.add_child(text)
	var button := UI.button("COLLECT" if game.sponsor_ready() else "LOCKED", UI.GOLD, true, true)
	button.disabled = not game.sponsor_ready()
	button.custom_minimum_size.x = 112
	button.pressed.connect(_collect_sponsor)
	row.add_child(button)
	return panel

func _division_row(mode: String) -> Control:
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var record: Dictionary = game.mode_record(mode)
	var rank: Dictionary = game.rank_data(mode)
	var panel := UI.card(accent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var mode_mark := PanelContainer.new()
	mode_mark.custom_minimum_size = Vector2(48, 48)
	mode_mark.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.13),
			15,
			Color(accent.r, accent.g, accent.b, 0.36),
			1
		)
	)
	var short := UI.label(GameDataRef.MODE_SHORT[mode], 14, accent, 800)
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	short.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_mark.add_child(short)
	row.add_child(mode_mark)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 2)
	center.add_child(UI.label(mode, 16, UI.TEXT, 800))
	center.add_child(
		UI.label("%s  •  OVR %d" % [game.visible_rank_name(mode), game.team_overall(mode)], 12, UI.MUTED)
	)
	center.add_child(
		UI.label(
			(
				"%dW  %dL  •  %d/%d placements"
				% [int(record["wins"]), int(record["losses"]), int(record["placements"]), game.placement_target(mode)]
			),
			11,
			UI.DIM
		)
	)
	row.add_child(center)
	var rating := VBoxContainer.new()
	var rating_value := UI.label(str(record["mmr"]), 19, UI.TEXT, 800)
	rating_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rating_cap := UI.label("MMR", 10, accent, 800)
	rating_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating.add_child(rating_value)
	rating.add_child(rating_cap)
	row.add_child(rating)
	return panel


func _build_team_page() -> void:
	_page_header(
		"Performance",
		"Team Center",
		"Develop players, manage fatigue and build a roster that can survive the climb."
	)
	_mode_switch()
	var mode: String = game.selected_mode()
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var summary := UI.card(accent)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 10)
	summary.add_child(summary_box)
	var summary_row := HBoxContainer.new()
	summary_row.add_child(_metric_block("TEAM OVR", str(game.team_overall(mode)), accent))
	summary_row.add_child(_metric_block("FORM", "%d%%" % _team_average(mode, "form"), UI.GREEN))
	summary_row.add_child(
		_metric_block("FATIGUE", "%d%%" % _team_average(mode, "fatigue"), UI.GOLD)
	)
	summary_box.add_child(summary_row)
	var rest := UI.button("RECOVERY SESSION  •  FREE", UI.GREEN, false)
	rest.pressed.connect(_rest_team.bind(mode))
	summary_box.add_child(rest)
	page_content.add_child(summary)
	page_content.add_child(_section_title("STARTING ROSTER", "%s competitive division" % mode))
	for player in game.roster_for(mode):
		page_content.add_child(_player_card(player, accent))


func _player_card(player: Dictionary, accent: Color) -> Control:
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 11)
	box.add_child(top)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(52, 52)
	avatar.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.13),
			17,
			Color(accent.r, accent.g, accent.b, 0.34),
			1
		)
	)
	var avatar_text := UI.label(str(player["name"]).left(2), 15, accent, 800)
	avatar_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_text)
	top.add_child(avatar)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	identity.add_child(UI.label(str(player["name"]), 18, UI.TEXT, 800))
	identity.add_child(
		UI.label(
			(
				"%s  •  %s  •  AGE %d"
				% [str(player["role"]).to_upper(), player["region"], int(player["age"])]
			),
			11,
			UI.MUTED,
			700
		)
	)
	identity.add_child(UI.label("Potential %d" % int(player["potential"]), 11, accent))
	top.add_child(identity)
	var ovr := VBoxContainer.new()
	var ovr_value := UI.label(str(game.player_overall(player)), 25, UI.TEXT, 800)
	ovr_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var ovr_cap := UI.label("OVR", 10, accent, 800)
	ovr_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ovr.add_child(ovr_value)
	ovr.add_child(ovr_cap)
	top.add_child(ovr)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 7)
	stat_row.add_child(_mini_stat("MECH", int(player["mechanics"]), accent))
	stat_row.add_child(_mini_stat("SENSE", int(player["game_sense"]), UI.PURPLE))
	stat_row.add_child(_mini_stat("TEAM", int(player["teamwork"]), UI.GREEN))
	stat_row.add_child(_mini_stat("MENTAL", int(player["mentality"]), UI.GOLD))
	box.add_child(stat_row)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status_row.add_child(UI.badge("FORM %d" % int(player["form"]), UI.GREEN))
	status_row.add_child(
		UI.badge(
			"FATIGUE %d" % int(player["fatigue"]),
			UI.GOLD if int(player["fatigue"]) < 65 else UI.RED
		)
	)
	status_row.add_child(Control.new())
	status_row.get_child(status_row.get_child_count() - 1).size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	box.add_child(status_row)
	var cost: int = game.training_cost(player)
	var train := UI.button(
		"TRAIN PLAYER  •  %s" % GameDataRef.format_cash(cost), accent, false, true
	)
	train.pressed.connect(_train_player.bind(str(player["id"])))
	box.add_child(train)
	return panel


func _mini_stat(caption: String, value: int, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	var value_label := UI.label(str(value), 15, UI.TEXT, 800)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cap := UI.label(caption, 8, UI.MUTED, 700)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)
	box.add_child(cap)
	box.add_child(UI.progress(value, 100, accent, 4))
	return box


func _build_play_page() -> void:
	_page_header(
		"Competition",
		"Ranked Grind",
		"Ranked matches pay €0. Climb, stream and build attention."
	)
	_mode_switch()
	var mode: String = game.selected_mode()
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var record: Dictionary = game.mode_record(mode)
	var rank: Dictionary = game.rank_data(mode)
	var format := game.match_format(mode)
	var locked := format == "LOCKED"
	page_content.add_child(_streaming_card())

	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var live_row := HBoxContainer.new()
	live_row.add_child(UI.badge(("%s RANKED" % format) if not locked else "NO ROSTER", accent))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_row.add_child(spacer)
	live_row.add_child(UI.label("PLACEMENT %d/%d" % [mini(game.placement_target(mode), int(record["placements"]) + 1), game.placement_target(mode)], 11, UI.MUTED, 700))
	box.add_child(live_row)

	var versus := HBoxContainer.new()
	versus.add_theme_constant_override("separation", 8)
	var our_name := "KESHI" if format == "1v1" else "TSK"
	versus.add_child(_versus_team(our_name, "OVR %d" % game.team_overall(mode), accent))
	var versus_label := UI.label("VS", 14, UI.MUTED, 800)
	versus_label.custom_minimum_size.x = 38
	versus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	versus.add_child(versus_label)
	versus.add_child(_versus_team("MATCHMAKING" if not locked else "LOCKED", "RATING %d" % int(record["mmr"]), UI.PURPLE))
	box.add_child(versus)
	box.add_child(UI.separator())

	var ranked_info := HBoxContainer.new()
	ranked_info.add_child(_metric_block("CURRENT", game.visible_rank_name(mode), accent))
	ranked_info.add_child(_metric_block("RATING", str(record["mmr"]), UI.TEXT))
	ranked_info.add_child(_metric_block("CASH / WIN", "€0", UI.GOLD))
	box.add_child(ranked_info)

	var queue := UI.button("QUEUE %s RANKED  •  €0" % format if not locked else "RECRUIT A PLAYER FIRST", accent, not locked)
	queue.disabled = locked
	queue.pressed.connect(_start_match.bind(mode))
	box.add_child(queue)
	page_content.add_child(panel)

	if not locked:
		page_content.add_child(_section_title("MATCH PREP", "Form and skill affect every match."))
		page_content.add_child(_match_prep_card(mode))
		page_content.add_child(_cup_card(mode))

	page_content.add_child(_section_title("RECENT RESULTS", "%s match history" % mode))
	_build_history_list(page_content, 5, mode)

func _streaming_card() -> Control:
	var stream: Dictionary = game.data.get("streaming", {})
	var enabled := game.streaming_enabled()
	var plan := game.stream_plan()
	var followers := int(stream.get("followers", 0))
	var panel := UI.card(UI.PURPLE if enabled else UI.CYAN)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var top := HBoxContainer.new()
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.overline("PULSELIVE  •  %s" % plan.to_upper(), UI.PURPLE))
	info.add_child(UI.label("Stream your ranked grind", 18, UI.TEXT, 800))
	info.add_child(UI.label(
		"Attention first. Early streams can genuinely sit at 0–3 viewers.",
		11,
		UI.MUTED
	))
	top.add_child(info)
	var live_badge := UI.badge("ARMED" if enabled else "OFF", UI.GREEN if enabled else UI.MUTED)
	top.add_child(live_badge)
	box.add_child(top)
	var stats := HBoxContainer.new()
	stats.add_child(_metric_block("FOLLOWERS", str(followers), UI.PURPLE))
	stats.add_child(_metric_block("PEAK", str(int(stream.get("peak_viewers", 0))), UI.CYAN))
	stats.add_child(_metric_block("TOTAL VIEWS", str(int(stream.get("total_views", 0))), UI.GREEN))
	box.add_child(stats)
	var toggle := UI.button(
		"STREAM NEXT MATCH: ON" if enabled else "GO LIVE NEXT MATCH",
		UI.PURPLE,
		enabled
	)
	toggle.pressed.connect(_toggle_stream)
	box.add_child(toggle)
	if plan == "Free":
		var upgrade := UI.button("CREATOR PLAN  •  €8 / 30 DAYS", UI.GOLD, false, true)
		upgrade.pressed.connect(_buy_stream_plan.bind("Creator"))
		box.add_child(upgrade)
	elif plan == "Creator":
		var upgrade := UI.button("PRO PLAN  •  €20 / 30 DAYS", UI.GOLD, false, true)
		upgrade.pressed.connect(_buy_stream_plan.bind("Pro"))
		box.add_child(upgrade)
	box.add_child(UI.label(
		"Paid plans slightly improve tools/discovery. They never guarantee viewers.",
		10,
		UI.DIM
	))
	var recent_comments: Array = stream.get("last_comments", [])
	if not recent_comments.is_empty():
		box.add_child(UI.overline("LATEST COMMENTS", UI.MUTED))
		for comment in recent_comments:
			box.add_child(UI.label("@%s  %s" % [str(comment.get("user", "user")), str(comment.get("text", ""))], 10, UI.MUTED))
	return panel


func _cup_card(mode: String) -> Control:
	var played := int(game.mode_record(mode).get("played", 0))
	var unlocked := played >= 3
	var panel := UI.card(UI.GOLD)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UI.overline("COMMUNITY EVENTS", UI.GOLD))
	box.add_child(UI.label("Small online cup", 18, UI.TEXT, 800))
	box.add_child(UI.label(
		"Ranked pays nothing. Small cups are your first realistic shot at €12–€35 prize money.",
		11,
		UI.MUTED
	))
	var enter := UI.button(
		"ENTER COMMUNITY CUP" if unlocked else "%d / 3 RANKED MATCHES" % played,
		UI.GOLD,
		unlocked
	)
	enter.disabled = not unlocked
	enter.pressed.connect(_enter_cup.bind(mode))
	box.add_child(enter)
	return panel


func _versus_team(title: String, subtitle: String, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.y = 86
	var mark := PanelContainer.new()
	mark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mark.custom_minimum_size.y = 56
	mark.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.11),
			16,
			Color(accent.r, accent.g, accent.b, 0.34),
			1
		)
	)
	var name_label := UI.label(title, 14, UI.TEXT, 800)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(name_label)
	box.add_child(mark)
	var sub := UI.label(subtitle, 10, accent, 700)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	return box


func _match_prep_card(mode: String) -> Control:
	var panel := UI.card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	var form := _team_average(mode, "form")
	var fatigue := _team_average(mode, "fatigue")
	box.add_child(_prep_line("Team form", form, UI.GREEN, "Sharp" if form >= 58 else "Average"))
	box.add_child(
		_prep_line(
			"Freshness", 100 - fatigue, UI.CYAN, "Ready" if fatigue < 40 else "Needs recovery"
		)
	)
	box.add_child(
		_prep_line(
			"Analytics",
			game.facility_level("analytics") * 10,
			UI.PURPLE,
			"Level %d" % game.facility_level("analytics")
		)
	)
	return panel


func _prep_line(title: String, value: int, accent: Color, status: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	var label_left := UI.label(title, 13, UI.TEXT, 700)
	label_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label_left)
	row.add_child(UI.label(status, 11, accent, 700))
	box.add_child(row)
	box.add_child(UI.progress(value, 100, accent, 5))
	return box


func _build_market_page() -> void:
	_page_header(
		"Recruitment",
		"Scouting Network",
		"Discover rising players and make decisive roster upgrades."
	)
	_mode_switch()
	var mode: String = game.selected_mode()
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var info := UI.card(UI.GREEN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	info.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.overline("GLOBAL NETWORK", UI.GREEN))
	text.add_child(
		UI.label("Scouting level %d" % game.facility_level("scouting"), 17, UI.TEXT, 800)
	)
	text.add_child(UI.label("Higher levels reveal stronger potential.", 11, UI.MUTED))
	row.add_child(text)
	var refresh := UI.button("REFRESH\n€5", UI.GREEN, true, true)
	refresh.custom_minimum_size.x = 106
	refresh.pressed.connect(_refresh_market)
	row.add_child(refresh)
	page_content.add_child(info)
	page_content.add_child(
		_section_title(
			"%s PROSPECTS" % mode.to_upper(), "A new signing replaces the lowest-rated starter."
		)
	)
	var found := 0
	for prospect in game.data.get("market", []):
		if str(prospect.get("mode", "")) == mode:
			page_content.add_child(_prospect_card(prospect, accent))
			found += 1
	if found == 0:
		var empty := UI.card()
		empty.add_child(
			UI.label(
				"No %s prospects remain. Refresh the board for new reports." % mode, 14, UI.MUTED
			)
		)
		page_content.add_child(empty)


func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.overline("SCOUT REPORT", accent))
	identity.add_child(UI.label(str(player["name"]), 20, UI.TEXT, 800))
	identity.add_child(
		UI.label(
			(
				"%s  •  %s  •  AGE %d"
				% [str(player["role"]).to_upper(), player["region"], int(player["age"])]
			),
			11,
			UI.MUTED,
			700
		)
	)
	top.add_child(identity)
	var ratings := VBoxContainer.new()
	var ovr := UI.label(str(game.player_overall(player)), 25, UI.TEXT, 800)
	ovr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var pot := UI.label("POT %d" % int(player["potential"]), 10, UI.GREEN, 800)
	pot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ratings.add_child(ovr)
	ratings.add_child(pot)
	top.add_child(ratings)
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 7)
	stat_row.add_child(_mini_stat("MECH", int(player["mechanics"]), accent))
	stat_row.add_child(_mini_stat("SENSE", int(player["game_sense"]), UI.PURPLE))
	stat_row.add_child(_mini_stat("TEAM", int(player["teamwork"]), UI.GREEN))
	stat_row.add_child(_mini_stat("MENTAL", int(player["mentality"]), UI.GOLD))
	box.add_child(stat_row)
	var price := int(player.get("contract", 0))
	var sign := UI.button("SIGN PLAYER  •  %s" % GameDataRef.format_cash(price), accent, true)
	sign.disabled = int(game.data["cash"]) < price
	sign.pressed.connect(_sign_player.bind(str(player["id"])))
	box.add_child(sign)
	return panel


func _build_empire_page() -> void:
	_page_header(
		"Organization",
		"Build the Empire",
		"Upgrade the infrastructure behind every player, match and future trophy."
	)
	var economy := UI.card(UI.GOLD)
	var economy_box := VBoxContainer.new()
	economy_box.add_theme_constant_override("separation", 11)
	economy.add_child(economy_box)
	economy_box.add_child(UI.overline("PASSIVE ECONOMY", UI.GOLD))
	var economy_row := HBoxContainer.new()
	economy_row.add_child(
		_metric_block(
			"INCOME / H", GameDataRef.format_cash(game.passive_income_per_hour()), UI.GOLD
		)
	)
	economy_row.add_child(
		_metric_block(
			"FANS / H", "+%s" % GameDataRef.format_number(game.passive_fans_per_hour()), UI.PURPLE
		)
	)
	economy_row.add_child(_metric_block("OFFLINE CAP", "8 HOURS", UI.CYAN))
	economy_box.add_child(economy_row)
	economy_box.add_child(
		UI.label("Offline rewards are added automatically when you return.", 12, UI.MUTED)
	)
	page_content.add_child(economy)
	page_content.add_child(
		_section_title("FACILITIES", "Permanent upgrades for the entire organization.")
	)
	for key in GameDataRef.FACILITIES:
		page_content.add_child(_facility_card(key))


func _facility_card(key: String) -> Control:
	var definition: Dictionary = GameDataRef.FACILITIES[key]
	var accent := Color(str(definition["color"]))
	var level: int = game.facility_level(key)
	var cost: int = game.facility_cost(key)
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 11)
	box.add_child(top)
	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(50, 50)
	mark.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.13),
			16,
			Color(accent.r, accent.g, accent.b, 0.35),
			1
		)
	)
	var mark_label := UI.label(str(definition["tag"]), 14, accent, 800)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(mark_label)
	top.add_child(mark)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.label(str(definition["name"]), 17, UI.TEXT, 800))
	identity.add_child(UI.label(str(definition["description"]), 12, UI.MUTED))
	top.add_child(identity)
	top.add_child(UI.badge("LV %d" % level, accent))
	box.add_child(UI.progress(level, 10, accent, 6))
	var upgrade := UI.button(
		"MAX LEVEL" if level >= 10 else "UPGRADE  •  %s" % GameDataRef.format_cash(cost),
		accent,
		level < 10
	)
	upgrade.disabled = level >= 10 or int(game.data["cash"]) < cost
	upgrade.pressed.connect(_upgrade_facility.bind(key))
	box.add_child(upgrade)
	return panel


func _section_title(title: String, subtitle: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(UI.overline(title, UI.MUTED))
	box.add_child(UI.label(subtitle, 12, UI.DIM))
	return box


func _metric_block(caption: String, value: String, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	var val := UI.label(value, 15 if value.length() < 11 else 11, UI.TEXT, 800)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cap := UI.label(caption, 9, accent, 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(val)
	box.add_child(cap)
	return box


func _team_average(mode: String, key: String) -> int:
	var roster: Array = game.roster_for(mode)
	if roster.is_empty():
		return 0
	var total := 0
	for player in roster:
		total += int(player.get(key, 0))
	return int(round(float(total) / roster.size()))


func _build_history_list(parent: VBoxContainer, limit: int, mode_filter: String = "") -> void:
	var count := 0
	for entry in game.data.get("history", []):
		if not mode_filter.is_empty() and str(entry.get("mode", "")) != mode_filter:
			continue
		parent.add_child(_history_row(entry))
		count += 1
		if count >= limit:
			break
	if count == 0:
		var empty := UI.card()
		var text := UI.label(
			"No matches played yet. Your first ranked series is waiting.", 13, UI.MUTED
		)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(text)
		parent.add_child(empty)


func _history_row(entry: Dictionary) -> Control:
	var won := bool(entry.get("won", false))
	var accent := UI.GREEN if won else UI.RED
	var panel := UI.card(accent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var result := UI.badge("WIN" if won else "LOSS", accent)
	result.custom_minimum_size.x = 58
	row.add_child(result)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(UI.label("vs %s" % str(entry.get("opponent", "Unknown")), 14, UI.TEXT, 700))
	detail.add_child(UI.label("%s  •  %s" % [str(entry.get("mode", "")), str(entry.get("format", "RANKED"))], 10, UI.MUTED))
	row.add_child(detail)
	var numbers := VBoxContainer.new()
	var score := UI.label(str(entry.get("score", "0 - 0")), 15, UI.TEXT, 800)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var delta := int(entry.get("mmr_delta", 0))
	var mmr := UI.label("%+d MMR" % delta, 10, accent, 800)
	mmr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	numbers.add_child(score)
	numbers.add_child(mmr)
	row.add_child(numbers)
	return panel


func _accept_contact(contact_id: String) -> void:
	_handle_action(game.accept_contact(contact_id), "home")


func _toggle_stream() -> void:
	_handle_action(game.set_streaming_enabled(not game.streaming_enabled()), "play")


func _buy_stream_plan(plan: String) -> void:
	_handle_action(game.buy_stream_plan(plan), "play")


func _enter_cup(mode: String) -> void:
	_handle_action(game.play_community_cup(mode), "play")


func _collect_sponsor() -> void:
	_handle_action(game.collect_sponsor(), "home")


func _train_player(player_id: String) -> void:
	_handle_action(game.train_player(player_id), "team")


func _rest_team(mode: String) -> void:
	_handle_action(game.rest_team(mode), "team")


func _refresh_market() -> void:
	_handle_action(game.generate_market(true), "market")


func _sign_player(player_id: String) -> void:
	_handle_action(game.sign_player(player_id), "market")


func _upgrade_facility(key: String) -> void:
	_handle_action(game.buy_facility(key), "empire")


func _handle_action(result: Dictionary, page: String) -> void:
	_show_message(str(result.get("message", "Done.")), bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_show_page(page, false)
	else:
		_refresh_top_bar()


func _show_message(message: String, positive: bool = true) -> void:
	toast_token += 1
	var token := toast_token
	toast_label.text = message
	var accent := UI.GREEN if positive else UI.RED
	toast_panel.add_theme_stylebox_override(
		"panel",
		UI.box(Color(0.06, 0.095, 0.20, 0.98), 17, Color(accent.r, accent.g, accent.b, 0.55), 1)
	)
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.position.y += 8.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(toast_panel, "position:y", toast_panel.position.y - 8.0, 0.18)
	await get_tree().create_timer(2.7).timeout
	if token != toast_token or not is_instance_valid(toast_panel):
		return
	var out := create_tween()
	out.tween_property(toast_panel, "modulate:a", 0.0, 0.18)
	await out.finished
	if token == toast_token:
		toast_panel.visible = false


func _show_offline_message(offline: Dictionary) -> void:
	_show_message(
		(
			"Welcome back: +%s and +%s fans while offline."
			% [
				GameDataRef.format_cash(int(offline.get("cash", 0))),
				GameDataRef.format_number(int(offline.get("fans", 0))),
			]
		),
		true
	)


func _format_duration(seconds: int) -> String:
	var minutes := maxi(0, seconds / 60)
	if minutes >= 60:
		return "%dh %02dm" % [minutes / 60, minutes % 60]
	return "%dm" % minutes


func _start_match(mode: String) -> void:
	if match_overlay != null and is_instance_valid(match_overlay):
		return
	match_result = game.create_match(mode)
	if match_result.is_empty() or not bool(match_result.get("ok", false)):
		_show_message("Matchmaking failed. Try again.", false)
		return
	var events: Array = match_result.get("events", [])
	if events.is_empty():
		_show_message("Match data did not load. Try again.", false)
		return
	match_event_index = 0
	match_speed = 1
	_build_match_overlay()
	_refresh_top_bar()
	call_deferred("_begin_match_playback")


func _begin_match_playback() -> void:
	if match_timer == null or not is_instance_valid(match_timer):
		return
	_advance_match()
	if match_event_index < int(match_result.get("events", []).size()):
		match_timer.start()


func _build_match_overlay() -> void:
	match_overlay = Control.new()
	match_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	match_overlay.modulate.a = 0.0
	add_child(match_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.045, 0.96)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	match_overlay.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 24)
	match_overlay.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 13)
	margin.add_child(layout)
	var mode := str(match_result["mode"])
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var header_row := HBoxContainer.new()
	header_row.add_child(UI.overline(("%s  •  %s" % ["STREAM LIVE" if bool(match_result.get("streaming", false)) else "LIVE MATCH", str(match_result.get("format", "RANKED"))]), accent))
	var head_spacer := Control.new()
	head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(head_spacer)
	header_row.add_child(UI.badge(("%d VIEWERS" % int(match_result.get("stream_viewers", 0))) if bool(match_result.get("streaming", false)) else "RANKED", accent))
	layout.add_child(header_row)
	layout.add_child(UI.heading(("%s vs %s" % ["KESHI" if str(match_result.get("format", "")) == "1v1" else "TSK", str(match_result["opponent"])]), 24))

	var scoreboard := UI.card(accent)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 9)
	scoreboard.add_child(score_box)
	match_clock_label = UI.overline("CONNECTING", UI.MUTED)
	match_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_score_label = UI.label("0 - 0", 43, UI.TEXT, 800)
	match_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var team_names := UI.label(
		"TSK                    %s" % str(match_result["opponent"]).to_upper(), 10, accent, 800
	)
	team_names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_progress = UI.progress(0, match_result["events"].size(), accent, 7)
	score_box.add_child(match_clock_label)
	score_box.add_child(match_score_label)
	score_box.add_child(team_names)
	score_box.add_child(match_progress)
	layout.add_child(scoreboard)

	var event_panel := UI.card()
	event_panel.custom_minimum_size.y = 94
	match_event_label = UI.label("The teams are entering the server...", 15, UI.TEXT, 700)
	match_event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_panel.add_child(match_event_label)
	layout.add_child(event_panel)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	for speed in [1, 2, 4]:
		var speed_button := UI.button("%dx" % speed, accent, speed == 1, true)
		speed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		speed_button.pressed.connect(_set_match_speed.bind(speed))
		speed_row.add_child(speed_button)
	layout.add_child(speed_row)
	layout.add_child(UI.overline("MATCH FEED", UI.MUTED))
	match_log_scroll = ScrollContainer.new()
	match_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	match_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	match_log_scroll.scroll_deadzone = 2
	match_log_scroll.follow_focus = false
	match_log_box = VBoxContainer.new()
	match_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match_log_box.add_theme_constant_override("separation", 7)
	match_log_scroll.add_child(match_log_box)
	layout.add_child(match_log_scroll)

	match_result_box = VBoxContainer.new()
	match_result_box.add_theme_constant_override("separation", 8)
	match_result_box.visible = false
	layout.add_child(match_result_box)
	match_continue_button = UI.button("CONTINUE", accent, true)
	match_continue_button.visible = false
	match_continue_button.pressed.connect(_close_match)
	layout.add_child(match_continue_button)

	match_timer = Timer.new()
	match_timer.wait_time = 0.72
	match_timer.one_shot = false
	match_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	match_timer.timeout.connect(_advance_match)
	match_overlay.add_child(match_timer)
	_apply_scroll_passthrough(layout)
	var tween := create_tween()
	tween.tween_property(match_overlay, "modulate:a", 1.0, 0.22)


func _set_match_speed(speed: int) -> void:
	match_speed = speed
	if match_timer != null:
		match_timer.wait_time = 0.72 / float(speed)
		match_timer.start()


func _advance_match() -> void:
	var events: Array = match_result["events"]
	if match_event_index >= events.size():
		_finish_match_animation()
		return
	var event: Dictionary = events[match_event_index]
	match_clock_label.text = str(event["time"])
	match_score_label.text = str(event["score"])
	match_event_label.text = str(event["text"])
	match_progress.value = match_event_index + 1
	var accent := UI.MUTED
	if str(event["type"]) == "good":
		accent = UI.GREEN
	elif str(event["type"]) == "bad":
		accent = UI.RED
	var feed_row := HBoxContainer.new()
	feed_row.add_theme_constant_override("separation", 8)
	var time := UI.label(str(event["time"]), 10, accent, 800)
	time.custom_minimum_size.x = 58
	feed_row.add_child(time)
	var text := UI.label(str(event["text"]), 11, UI.MUTED)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_row.add_child(text)
	match_log_box.add_child(feed_row)
	feed_row.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feed_row, "modulate:a", 1.0, 0.12)

	var live_chat: Array = match_result.get("live_chat", [])
	if bool(match_result.get("streaming", false)) and match_event_index < live_chat.size():
		var chat: Dictionary = live_chat[match_event_index]
		var chat_line := UI.label(
			"CHAT  @%s: %s" % [str(chat.get("user", "viewer")), str(chat.get("text", ""))],
			10,
			UI.PURPLE,
			700
		)
		match_log_box.add_child(chat_line)

	match_event_index += 1
	if match_log_scroll != null and is_instance_valid(match_log_scroll):
		call_deferred("_scroll_match_feed_to_bottom")


func _scroll_match_feed_to_bottom() -> void:
	if match_log_scroll == null or not is_instance_valid(match_log_scroll):
		return
	var bar := match_log_scroll.get_v_scroll_bar()
	match_log_scroll.scroll_vertical = int(bar.max_value)


func _finish_match_animation() -> void:
	if match_timer != null:
		match_timer.stop()
	var won := bool(match_result["won"])
	var accent := UI.GREEN if won else UI.RED
	match_event_label.text = (
		"Win recorded. Ranked paid €0 — but the match may have created attention."
		if won
		else "Loss recorded. Ranked paid €0. Review it and queue again."
	)
	match_result_box.visible = true
	match_result_box.add_child(UI.separator(Color(accent.r, accent.g, accent.b, 0.35)))

	var result_row := HBoxContainer.new()
	result_row.add_child(_metric_block("RESULT", "VICTORY" if won else "DEFEAT", accent))
	result_row.add_child(_metric_block("MMR", "%+d" % int(match_result["mmr_delta"]), accent))
	result_row.add_child(_metric_block("OPP MMR", str(int(match_result.get("opponent_mmr", 0))), UI.PURPLE))
	match_result_box.add_child(result_row)

	var profile: Dictionary = match_result.get("opponent_profile", {})
	var profile_badge := UI.badge("POST-MATCH • %s" % str(profile.get("label", "NORMAL MATCH")), UI.PURPLE)
	profile_badge.custom_minimum_size.y = 38
	match_result_box.add_child(profile_badge)

	var attention: Dictionary = match_result.get("attention", {})
	var attention_text := str(attention.get("text", "No unusual attention after this match."))
	match_result_box.add_child(UI.label(attention_text, 11, UI.MUTED))

	if bool(match_result.get("streaming", false)):
		var stream_row := HBoxContainer.new()
		stream_row.add_child(_metric_block("VIEWERS", str(int(match_result.get("stream_viewers", 0))), UI.PURPLE))
		stream_row.add_child(_metric_block("NEW FOLLOWS", "+%d" % int(match_result.get("stream_followers", 0)), UI.GREEN))
		stream_row.add_child(_metric_block("PLAN", game.stream_plan(), UI.CYAN))
		match_result_box.add_child(stream_row)
		var comments: Array = match_result.get("comments", [])
		if not comments.is_empty():
			match_result_box.add_child(UI.overline("POST-STREAM COMMENTS", UI.MUTED))
			for comment in comments:
				match_result_box.add_child(UI.label(
					"@%s  %s" % [str(comment.get("user", "user")), str(comment.get("text", ""))],
					10,
					UI.MUTED
				))

	if bool(match_result.get("rank_revealed", false)):
		var reveal := UI.badge("PLACEMENT RANK  •  %s" % str(match_result["new_rank"]), UI.GOLD)
		reveal.custom_minimum_size.y = 42
		match_result_box.add_child(reveal)
	elif bool(match_result.get("promoted", false)):
		var promotion := UI.badge("PROMOTED TO %s" % str(match_result["new_rank"]), UI.GOLD)
		promotion.custom_minimum_size.y = 42
		match_result_box.add_child(promotion)

	match_continue_button.visible = true
	var tween := create_tween().set_parallel(true)
	match_result_box.modulate.a = 0.0
	match_continue_button.modulate.a = 0.0
	tween.tween_property(match_result_box, "modulate:a", 1.0, 0.2)
	tween.tween_property(match_continue_button, "modulate:a", 1.0, 0.2)

func _close_match() -> void:
	if match_overlay == null or not is_instance_valid(match_overlay):
		return
	var overlay := match_overlay
	match_overlay = null
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.16)
	await tween.finished
	overlay.queue_free()
	_show_page("play", false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if match_overlay != null and is_instance_valid(match_overlay):
			if match_timer != null and match_timer.is_stopped():
				_close_match()
			get_viewport().set_input_as_handled()
