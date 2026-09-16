extends Control

const GameDataRef = preload("res://scripts/game_data.gd")
const EmpireStateRef = preload("res://scripts/game_state.gd")
const RankedDataRef = preload("res://scripts/ranked_data.gd")
const RankEmblemRef = preload("res://scripts/rank_emblem.gd")
const TitleDataRef = preload("res://scripts/title_data.gd")
const DevelopmentDataRef = preload("res://scripts/development_data.gd")
const MMRGraphRef = preload("res://scripts/mmr_graph.gd")
const UI = preload("res://scripts/ui_kit.gd")

var game: EmpireStateRef
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
var ranked_view := "overview"

var match_overlay: Control
var match_timer: Timer
var match_result: Dictionary = {}
var match_event_index := 0
var match_speed := 1
var match_score_label: Label
var match_clock_label: Label
var match_event_label: Label
var match_progress: ProgressBar
var match_boost_label: Label
var match_boost_bar: ProgressBar
var match_log_box: VBoxContainer
var match_log_scroll: ScrollContainer
var match_result_box: VBoxContainer
var match_continue_button: Button
var match_finished := false
var match_session: Dictionary = {}
var match_interactive := false
var match_decision_box: VBoxContainer
var match_decision_locked := false


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
	page_scroll.scroll_deadzone = 8
	page_scroll.scroll_vertical_custom_step = 72.0
	page_scroll.follow_focus = false
	page_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
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

	var version_badge := UI.badge("ALPHA 0.4.8", UI.PURPLE)
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
			child.mouse_filter = Control.MOUSE_FILTER_PASS
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
	if mode == "Rocket League":
		var emblem_rank := rank if game.placements_complete(mode) else RankedDataRef.unranked_data(game.mode_mmr(mode))
		top.add_child(_rank_emblem(emblem_rank, 76.0))
	else:
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
	details.add_child(UI.overline("ACTIVE PLAYLIST" if mode == "Rocket League" else "ACTIVE DIVISION", accent))
	details.add_child(UI.heading("%s  •  %s" % [mode, game.selected_rl_playlist()] if mode == "Rocket League" else mode, 18 if mode == "Rocket League" else 20))
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
	var rating_hidden := mode == "Rocket League" and int(record.get("placements", 0)) < 10
	var rating_value := UI.label("HIDDEN" if rating_hidden else str(record["mmr"]), 15 if rating_hidden else 19, UI.TEXT, 800)
	rating_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rating_cap := UI.label("PLACEMENTS" if rating_hidden else "MMR", 9 if rating_hidden else 10, accent, 800)
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
	var recovery_ready := game.can_rest_team(mode)
	var recovery_note := UI.label(
		"Development is paid from club cash and limited to one program every three in-game weeks. Every stat directly shapes match performance.",
		11,
		UI.MUTED
	)
	summary_box.add_child(recovery_note)
	summary_box.add_child(
		UI.label(
			"Fund development through community cups, sponsors and occasional virtual stream donations.",
			10,
			UI.DIM
		)
	)
	var rest := UI.button(
		"RECOVERY SESSION  •  3-WEEK COOLDOWN" if recovery_ready else "RECOVERY ON COOLDOWN",
		UI.GREEN,
		recovery_ready
	)
	rest.disabled = not recovery_ready
	rest.pressed.connect(_rest_team.bind(mode))
	summary_box.add_child(rest)
	page_content.add_child(summary)
	page_content.add_child(_development_impact_card())
	page_content.add_child(_section_title("STARTING ROSTER", "%s competitive division" % mode))
	for player in game.roster_for(mode):
		page_content.add_child(_player_card(player, accent))


func _development_impact_card() -> Control:
	var panel := UI.card(UI.PURPLE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UI.overline("WHY EVERY STAT MATTERS", UI.PURPLE))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.add_child(_development_impact_cell("MECH + SHOT", "Creates stronger attacking chances.", UI.CYAN))
	grid.add_child(_development_impact_cell("ROT + DEF", "Reduces dangerous opponent chances.", UI.GREEN))
	grid.add_child(_development_impact_cell("SENSE + BOOST", "Improves calls and starting boost.", UI.PURPLE))
	grid.add_child(_development_impact_cell("CONS + MENTAL", "Stabilizes form and overtime plays.", UI.GOLD))
	box.add_child(grid)
	return panel


func _development_impact_cell(title: String, detail: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.08),
			13,
			Color(accent.r, accent.g, accent.b, 0.24),
			1
		)
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.add_child(UI.label(title, 11, accent, 800))
	box.add_child(UI.label(detail, 9, UI.MUTED))
	panel.add_child(box)
	return panel


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
	var equipped := game.equipped_title() if str(player.get("id", "")) == "captain" else {}
	if not equipped.is_empty():
		identity.add_child(
			UI.label(
				str(equipped.get("label", "")),
				10,
				TitleDataRef.color_for(equipped),
				800
			)
		)
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

	box.add_child(_development_stat_grid(player))
	box.add_child(_mechanics_arsenal(player, accent))
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
	var training_history: Array = player.get("training_history", [])
	if not training_history.is_empty():
		var latest: Dictionary = training_history[0]
		var latest_program := DevelopmentDataRef.program(str(latest.get("program", "")))
		var latest_gains: Dictionary = latest.get("gains", {})
		var gain_parts: Array[String] = []
		for stat_key in latest_gains:
			var definition := DevelopmentDataRef.stat_definition(str(stat_key))
			gain_parts.append(
				"+%d %s"
				% [int(latest_gains[stat_key]), str(definition.get("short", stat_key)).to_upper()]
			)
		box.add_child(
			UI.label(
				"LAST SESSION  •  %s  •  %s"
				% [str(latest_program.get("label", "Development")), " / ".join(gain_parts)],
				10,
				UI.DIM,
				700
			)
		)
	var training_ready := game.can_train_player(player)
	if training_ready:
		box.add_child(UI.overline("CHOOSE ONE PAID PROGRAM  •  3-WEEK CYCLE", UI.MUTED))
		box.add_child(_training_program_grid(player))
	else:
		var cooldown := UI.button(
			"DEVELOPMENT RETURNS IN %d WEEK(S)" % game.training_weeks_left(player),
			accent,
			false,
			true
		)
		cooldown.disabled = true
		box.add_child(cooldown)
	return panel


func _development_stat_grid(player: Dictionary) -> Control:
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 9)
	for row_index in range(2):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		for column_index in range(4):
			var definition_index := row_index * 4 + column_index
			var definition: Dictionary = DevelopmentDataRef.PLAYER_STATS[definition_index]
			var stat_key := str(definition.get("key", ""))
			row.add_child(
				_mini_stat(
					str(definition.get("short", stat_key)),
					int(player.get(stat_key, 50)),
					Color(str(definition.get("color", "2de2ff")))
				)
			)
		rows.add_child(row)
	return rows


func _mechanics_arsenal(player: Dictionary, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var unlocked: Array = game.unlocked_mechanics(player)
	box.add_child(
		UI.overline(
			"MECHANICS ARSENAL  •  %d/%d" % [unlocked.size(), DevelopmentDataRef.MECHANIC_ARSENAL.size()],
			accent
		)
	)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	if unlocked.is_empty():
		flow.add_child(UI.badge("FOUNDATIONS", UI.MUTED))
	else:
		for move_value in unlocked:
			var move: Dictionary = move_value
			flow.add_child(UI.badge(str(move.get("label", "MECHANIC")), accent))
	box.add_child(flow)
	var next_move := game.next_mechanic(player)
	if next_move.is_empty():
		box.add_child(UI.label("Complete arsenal mastered.", 10, UI.GREEN, 700))
	else:
		var progress := DevelopmentDataRef.mechanic_progress(player, next_move)
		box.add_child(
			UI.label(
				"NEXT: %s  •  %s"
				% [str(next_move.get("label", "")), DevelopmentDataRef.requirement_text(next_move)],
				10,
				UI.MUTED,
				700
			)
		)
		box.add_child(UI.progress(progress, 100, accent, 4))
	return box


func _training_program_grid(player: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var cost := game.training_cost(player, program_id)
		var color := Color(str(program.get("color", "2de2ff")))
		var affordable := int(game.data.get("cash", 0)) >= cost
		var button := UI.button(
			"%s\n%s  •  %s"
			% [
				str(program.get("short", "TRAIN")),
				str(program.get("button_detail", "STAT GAINS")),
				GameDataRef.format_cash(cost),
			],
			color,
			affordable,
			true
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 66
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		grid.add_child(button)
	return grid


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
		"COMPETITIVE",
		"Ranked Command",
		"Three independent ladders. Ten placements. Every result matters."
	)
	_mode_switch()
	var mode: String = game.selected_mode()
	if mode != "Rocket League":
		_build_legacy_play_page(mode)
		return
	_playlist_switch()
	_ranked_view_switch()
	match ranked_view:
		"ladder":
			_build_ranked_ladder()
		"ranks":
			_build_all_ranks()
		"titles":
			_build_title_locker()
		_:
			_build_ranked_overview()


func _playlist_switch() -> void:
	var panel := UI.card(UI.CYAN)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UI.overline("ROCKET LEAGUE PLAYLIST", UI.CYAN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var selected := game.selected_rl_playlist()
	var roster_size := game.roster_for("Rocket League").size()
	for playlist in RankedDataRef.PLAYLISTS:
		var required := game.playlist_required_players(playlist)
		var button := UI.button(
			"%s\n%d/%d PLAYERS" % [playlist, mini(roster_size, required), required],
			UI.CYAN,
			str(playlist) == selected,
			true
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_rl_playlist.bind(str(playlist)))
		row.add_child(button)
	box.add_child(row)
	page_content.add_child(panel)


func _select_rl_playlist(playlist: String) -> void:
	game.set_selected_rl_playlist(playlist)
	_show_page("play", false)


func _ranked_view_switch() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	for entry in [
		["overview", "OVERVIEW"], ["ladder", "LADDER"],
		["ranks", "RANKS"], ["titles", "TITLES"]
	]:
		var active := ranked_view == str(entry[0])
		var button := UI.button(str(entry[1]), UI.PURPLE, active, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_ranked_view.bind(str(entry[0])))
		row.add_child(button)
	page_content.add_child(row)


func _select_ranked_view(view: String) -> void:
	ranked_view = view if view in ["overview", "ladder", "ranks", "titles"] else "overview"
	_show_page("play", false)


func _build_ranked_overview() -> void:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	page_content.add_child(_rank_profile_card(playlist))
	page_content.add_child(_rank_stats_card(playlist))
	page_content.add_child(_mmr_graph_card(playlist))
	page_content.add_child(_ranked_queue_card(playlist))
	page_content.add_child(_section_title("RECENT MATCHES", "%s ranked results" % playlist))
	_build_playlist_history(page_content, playlist, 6)
	page_content.add_child(_streaming_card())
	if int(record.get("played", 0)) >= 3:
		page_content.add_child(_cup_card("Rocket League"))


func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedDataRef.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedDataRef.unranked_data(mmr)
	var accent := RankedDataRef.color_for_family(str(shown_rank["family"]))
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 13)
	header.add_child(_rank_emblem(shown_rank, 100.0))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 3)
	identity.add_child(UI.overline("%s RANKED" % playlist, accent))
	identity.add_child(UI.heading("UNRANKED" if not placed else str(actual_rank["tier_name"]), 22))
	var equipped_title := game.equipped_title()
	if not equipped_title.is_empty():
		identity.add_child(
			UI.label(
				str(equipped_title.get("label", "")),
				9,
				TitleDataRef.color_for(equipped_title),
				800
			)
		)
	identity.add_child(
		UI.label(
			"%d / 10 placements" % placements if not placed else "Division %s" % str(actual_rank["division_roman"]),
			13,
			UI.MUTED,
			700
		)
	)
	header.add_child(identity)
	var rating := VBoxContainer.new()
	var rating_value := UI.label(str(mmr) if placed else "HIDDEN", 24 if not placed else 28, UI.TEXT, 800)
	rating_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rating_cap := UI.label("MMR AFTER REVEAL" if not placed else "MMR", 9 if not placed else 10, accent, 800)
	rating_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating.add_child(rating_value)
	rating.add_child(rating_cap)
	header.add_child(rating)
	box.add_child(header)
	box.add_child(UI.separator(Color(accent.r, accent.g, accent.b, 0.28)))
	if not placed:
		var placement_labels := HBoxContainer.new()
		var left := UI.label("RANK HIDDEN", 12, UI.TEXT, 800)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		placement_labels.add_child(left)
		placement_labels.add_child(UI.label("%d MATCHES LEFT" % (10 - placements), 11, UI.MUTED, 700))
		box.add_child(placement_labels)
		box.add_child(UI.progress(placements, 10, accent, 9))
	else:
		var next_rank := RankedDataRef.next_rank_for_mmr(mmr, playlist)
		var progress := RankedDataRef.progress_for_mmr(mmr, playlist)
		var progress_labels := HBoxContainer.new()
		var current := UI.label(str(actual_rank["compact_name"]), 12, UI.TEXT, 800)
		current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_labels.add_child(current)
		var target_text := "MAX RANK" if str(actual_rank["family"]) == "Supersonic Legend" else "%s  •  %d" % [str(next_rank["compact_name"]), int(actual_rank["next_minimum"])]
		progress_labels.add_child(UI.label(target_text, 11, UI.MUTED, 700))
		box.add_child(progress_labels)
		box.add_child(UI.progress(float(progress["value"]), float(progress["maximum"]), accent, 9))
	var footer := HBoxContainer.new()
	footer.add_child(_metric_block("W / L", "%d / %d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], UI.GREEN))
	footer.add_child(_metric_block("WINRATE", "%.1f%%" % RankedDataRef.win_rate(record), accent))
	footer.add_child(
		_metric_block(
			"EST. LADDER",
			"HIDDEN" if not placed else "#%s" % GameDataRef.format_number(RankedDataRef.estimated_position(mmr, playlist)),
			UI.PURPLE
		)
	)
	box.add_child(footer)
	return panel


func _rank_stats_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var panel := UI.card(UI.PURPLE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	box.add_child(UI.overline("SEASON PERFORMANCE", UI.PURPLE))
	var row_one := HBoxContainer.new()
	row_one.add_child(_metric_block("SEASON", "%d-%d" % [int(record.get("season_wins", 0)), int(record.get("season_losses", 0))], UI.TEXT))
	row_one.add_child(_metric_block("WINRATE", "%.1f%%" % RankedDataRef.win_rate(record, true), UI.GREEN))
	var streak := int(record.get("streak", 0))
	row_one.add_child(_metric_block("STREAK", "%s%d" % ["W" if streak > 0 else "L" if streak < 0 else "—", abs(streak)] if streak != 0 else "—", UI.GOLD))
	box.add_child(row_one)
	var row_two := HBoxContainer.new()
	var placements_complete := int(record.get("placements", 0)) >= 10
	row_two.add_child(_metric_block("PEAK MMR", str(int(record.get("peak_mmr", 100))) if placements_complete else "HIDDEN", UI.CYAN))
	row_two.add_child(_metric_block("SEASON PEAK", str(int(record.get("season_peak_mmr", 100))) if placements_complete else "HIDDEN", UI.PURPLE))
	row_two.add_child(_metric_block("PLAYLIST", playlist, UI.TEXT))
	box.add_child(row_two)
	var last_results: Array = record.get("last_results", [])
	var last_text := "NO MATCHES YET" if last_results.is_empty() else "  ".join(last_results)
	var last := UI.label(last_text, 13, UI.MUTED, 800)
	last.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last.custom_minimum_size.y = 30
	box.add_child(UI.overline("LAST 10", UI.MUTED))
	box.add_child(last)
	return panel


func _mmr_graph_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var actual_rank := RankedDataRef.rank_for_mmr(int(record.get("mmr", 100)), playlist)
	var accent := RankedDataRef.color_for_family(str(actual_rank["family"]))
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(UI.overline("MMR TREND  •  LAST 30", accent))
	box.add_child(MMRGraphRef.new().configure(record.get("mmr_history", []), accent))
	return panel


func _ranked_queue_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var available := game.can_queue_playlist(playlist)
	var required := game.playlist_required_players(playlist)
	var roster_size := game.roster_for("Rocket League").size()
	var accent := UI.CYAN
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	var top := HBoxContainer.new()
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.overline("MATCHMAKING", accent))
	text.add_child(UI.heading("%s Competitive" % playlist, 20))
	text.add_child(UI.label("Close-MMR opponent  •  Ranked reward €0", 12, UI.MUTED))
	top.add_child(text)
	top.add_child(UI.badge("READY" if available else "%d/%d PLAYERS" % [roster_size, required], UI.GREEN if available else UI.GOLD))
	box.add_child(top)
	var placement_mode := int(record.get("placements", 0)) < 10
	box.add_child(
		UI.label(
			"Seed starts at 100 MMR. The live estimate stays hidden until match 10; placement swings are about ±20–30." if placement_mode else "Standard match: about ±9–11 MMR, adjusted by opponent rating.",
			11,
			UI.DIM
		)
	)
	var queue := UI.button("QUEUE %s RANKED" % playlist if available else "RECRUIT %d MORE PLAYER%s" % [required - roster_size, "S" if required - roster_size != 1 else ""], accent, available)
	queue.disabled = not available
	queue.pressed.connect(_start_match.bind("Rocket League"))
	box.add_child(queue)
	return panel


func _build_ranked_ladder() -> void:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	page_content.add_child(_rank_profile_card(playlist))
	page_content.add_child(_section_title("GLOBAL TOP 12", "%s simulated competitive ladder" % playlist))
	for entry in RankedDataRef.top_ladder(playlist):
		page_content.add_child(_ladder_row(entry))
	if int(record.get("placements", 0)) < 10:
		page_content.add_child(_section_title("AROUND YOU", "Your position unlocks with the rank reveal after placement 10."))
		var locked := UI.card(UI.GOLD)
		var locked_text := UI.label("UNRANKED  •  %d / 10 PLACEMENTS" % int(record.get("placements", 0)), 14, UI.GOLD, 800)
		locked_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.add_child(locked_text)
		page_content.add_child(locked)
	else:
		page_content.add_child(_section_title("AROUND YOU", "Your estimated position updates with every MMR change."))
		for entry in RankedDataRef.around_player(int(record.get("mmr", 100)), playlist):
			page_content.add_child(_ladder_row(entry))


func _ladder_row(entry: Dictionary) -> Control:
	var rank: Dictionary = entry.get("rank", {})
	var is_player := bool(entry.get("is_player", false))
	var accent := UI.CYAN if is_player else RankedDataRef.color_for_family(str(rank.get("family", "Unranked")))
	var panel := UI.card(accent if is_player else Color.TRANSPARENT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var position := UI.label("#%s" % GameDataRef.format_number(int(entry.get("position", 0))), 13, accent, 800)
	position.custom_minimum_size.x = 58
	position.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(position)
	row.add_child(_rank_emblem(rank, 46.0))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.label(str(entry.get("name", "PLAYER")), 15, UI.TEXT, 800))
	var equipped_title := game.equipped_title() if is_player else {}
	if not equipped_title.is_empty():
		identity.add_child(
			UI.label(
				str(equipped_title.get("label", "")),
				8,
				TitleDataRef.color_for(equipped_title),
				800
			)
		)
	identity.add_child(UI.label(str(rank.get("compact_name", "UNRANKED")), 10, UI.MUTED, 700))
	row.add_child(identity)
	var rating := VBoxContainer.new()
	var value := UI.label(str(int(entry.get("mmr", 0))), 17, UI.TEXT, 800)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var cap := UI.label("MMR", 9, accent, 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating.add_child(value)
	rating.add_child(cap)
	row.add_child(rating)
	return panel


func _build_all_ranks() -> void:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var placements_complete := int(record.get("placements", 0)) >= 10
	var current_rank := RankedDataRef.rank_for_mmr(int(record.get("mmr", 100)), playlist)
	var intro := UI.card(UI.GOLD)
	var intro_box := VBoxContainer.new()
	intro_box.add_theme_constant_override("separation", 8)
	intro.add_child(intro_box)
	intro_box.add_child(UI.overline("ALL RANKS  •  %s" % playlist, UI.GOLD))
	intro_box.add_child(UI.heading("MMR Table", 22))
	intro_box.add_child(UI.label("Approximate playlist thresholds. Every tier has Divisions I–IV; SSL begins at the final open-ended threshold.", 12, UI.MUTED))
	page_content.add_child(intro)
	for tier_data in RankedDataRef.tier_rows(playlist):
		page_content.add_child(_rank_tier_card(tier_data, current_rank, placements_complete))


func _build_title_locker() -> void:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var equipped := game.equipped_title()
	var intro := UI.card(UI.GOLD if not equipped.is_empty() else UI.PURPLE)
	var intro_box := VBoxContainer.new()
	intro_box.add_theme_constant_override("separation", 9)
	intro.add_child(intro_box)
	intro_box.add_child(UI.overline("PLAYER IDENTITY  •  TITLE LOCKER", UI.GOLD))
	intro_box.add_child(UI.heading("KESHI", 25))
	if equipped.is_empty():
		intro_box.add_child(UI.label("NO TITLE EQUIPPED", 13, UI.MUTED, 800))
		intro_box.add_child(
			UI.label(
				"Titles are never participation rewards. Reach the elite ranks or finish a season among the world's best.",
				11,
				UI.DIM
			)
		)
	else:
		var equipped_accent := TitleDataRef.color_for(equipped)
		intro_box.add_child(UI.label(str(equipped.get("label", "")), 16, equipped_accent, 800))
		intro_box.add_child(
			UI.label(
				"%s  •  %s" % [str(equipped.get("category", "TITLE")), str(equipped.get("rarity", "RARE"))],
				10,
				equipped_accent,
				800
			)
		)
	page_content.add_child(intro)

	var progress_panel := UI.card(UI.PURPLE)
	var progress_box := VBoxContainer.new()
	progress_box.add_theme_constant_override("separation", 10)
	progress_panel.add_child(progress_box)
	progress_box.add_child(UI.overline("SEASON %d RANK REWARDS  •  %s" % [int(game.data.get("season", 1)), playlist], UI.PURPLE))
	progress_box.add_child(
		_title_reward_progress(
			"GRAND CHAMPION TITLE",
			int(record.get("gc_reward_wins", 0)),
			RankedDataRef.color_for_family("Grand Champion")
		)
	)
	progress_box.add_child(
		_title_reward_progress(
			"SUPERSONIC LEGEND TITLE",
			int(record.get("ssl_reward_wins", 0)),
			Color(0.75, 0.64, 1.0)
		)
	)
	progress_box.add_child(
		UI.label(
			"Only wins earned while ranked GC or SSL count. Top 100, Top 10 and World #1 titles require at least ten matches and a qualifying final leaderboard position.",
			10,
			UI.DIM
		)
	)
	page_content.add_child(progress_panel)

	var titles := game.earned_titles()
	page_content.add_child(_section_title("EARNED TITLES", "%d permanent unlock%s" % [titles.size(), "" if titles.size() == 1 else "s"]))
	if titles.is_empty():
		var locked := UI.card()
		var locked_box := VBoxContainer.new()
		locked_box.add_theme_constant_override("separation", 5)
		locked.add_child(locked_box)
		var locked_heading := UI.label("LOCKER EMPTY", 15, UI.MUTED, 800)
		locked_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_box.add_child(locked_heading)
		var locked_copy := UI.label("No filler titles. The first one must be earned.", 11, UI.DIM)
		locked_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_box.add_child(locked_copy)
		page_content.add_child(locked)
	else:
		for title in titles:
			page_content.add_child(_title_card(title))


func _title_reward_progress(label_text: String, wins: int, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	var label := UI.label(label_text, 11, UI.TEXT, 800)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(UI.label("%d / %d WINS" % [wins, TitleDataRef.RANK_REWARD_WINS], 10, accent, 800))
	box.add_child(row)
	box.add_child(UI.progress(wins, TitleDataRef.RANK_REWARD_WINS, accent, 7))
	return box


func _title_card(title: Dictionary) -> Control:
	var accent := TitleDataRef.color_for(title)
	var is_equipped := str(game.data.get("equipped_title_id", "")) == str(title.get("id", ""))
	var panel := UI.card(accent if is_equipped else Color.TRANSPARENT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading_row := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.label(str(title.get("label", "TITLE")), 16, accent, 800))
	identity.add_child(
		UI.label(
			"%s  •  %s" % [str(title.get("category", "TITLE")), str(title.get("rarity", "RARE"))],
			9,
			UI.MUTED,
			800
		)
	)
	heading_row.add_child(identity)
	heading_row.add_child(UI.badge("EQUIPPED" if is_equipped else "OWNED", accent))
	box.add_child(heading_row)
	box.add_child(UI.label(str(title.get("source", "Earned achievement")), 10, UI.DIM))
	var action := UI.button("UNEQUIP" if is_equipped else "EQUIP TITLE", accent, not is_equipped, true)
	if is_equipped:
		action.pressed.connect(_clear_title)
	else:
		action.pressed.connect(_equip_title.bind(str(title.get("id", ""))))
	box.add_child(action)
	return panel


func _rank_tier_card(tier_data: Dictionary, current_rank: Dictionary, placements_complete: bool) -> Control:
	var family := str(tier_data.get("family", "Unranked"))
	var accent := RankedDataRef.color_for_family(family)
	var is_current_tier := placements_complete and str(current_rank.get("tier_name", "")) == str(tier_data.get("tier_name", ""))
	var panel := UI.card(accent if is_current_tier else Color.TRANSPARENT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 11)
	var emblem_data := {
		"family": family,
		"tier": int(tier_data.get("tier", 0)),
		"division": 0,
	}
	header.add_child(_rank_emblem(emblem_data, 58.0))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.label(str(tier_data.get("tier_name", "Rank")), 17, UI.TEXT, 800))
	identity.add_child(UI.label("Approximate MMR range", 10, UI.MUTED))
	header.add_child(identity)
	if is_current_tier:
		header.add_child(UI.badge("YOU", UI.CYAN))
	box.add_child(header)
	for division_data in tier_data.get("divisions", []):
		var exact_current := is_current_tier and str(division_data.get("division", "")) == str(current_rank.get("division_roman", ""))
		box.add_child(_rank_division_row(division_data, accent, exact_current, family == "Supersonic Legend"))
	return panel


func _rank_division_row(division_data: Dictionary, accent: Color, is_current: bool, is_ssl: bool) -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override(
		"panel",
		UI.box(
			Color(accent.r, accent.g, accent.b, 0.15) if is_current else Color(0.08, 0.11, 0.22, 0.65),
			12,
			Color(accent.r, accent.g, accent.b, 0.48) if is_current else Color(0.30, 0.38, 0.56, 0.16),
			1
		)
	)
	var row := HBoxContainer.new()
	var title := "SSL" if is_ssl else "DIVISION %s" % str(division_data.get("division", "I"))
	var left := UI.label(title, 12, accent if is_current else UI.MUTED, 800)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var minimum := int(division_data.get("minimum", 0))
	var maximum := int(division_data.get("maximum", 0))
	row.add_child(UI.label("%d+ MMR" % minimum if is_ssl else "%d–%d MMR" % [minimum, maximum], 12, UI.TEXT, 700))
	panel.add_child(row)
	return panel


func _build_playlist_history(parent: VBoxContainer, playlist: String, limit: int) -> void:
	var count := 0
	for entry in game.data.get("history", []):
		if str(entry.get("mode", "")) != "Rocket League" or str(entry.get("format", "")) != playlist:
			continue
		parent.add_child(_history_row(entry))
		count += 1
		if count >= limit:
			break
	if count == 0:
		var empty := UI.card()
		var message := UI.label("No %s matches yet. Queue when you are ready." % playlist, 13, UI.MUTED)
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(message)
		parent.add_child(empty)


func _build_legacy_play_page(mode: String) -> void:
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var record: Dictionary = game.mode_record(mode)
	var format := game.match_format(mode)
	var locked := format == "LOCKED"
	page_content.add_child(_streaming_card())
	var panel := UI.card(accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.badge("%s RANKED" % format if not locked else "NO ROSTER", accent))
	box.add_child(UI.heading("%s Competitive" % mode, 21))
	var stats := HBoxContainer.new()
	stats.add_child(_metric_block("RATING", str(int(record.get("mmr", 600))), accent))
	stats.add_child(_metric_block("RECORD", "%d-%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], UI.GREEN))
	stats.add_child(_metric_block("REWARD", "€0", UI.GOLD))
	box.add_child(stats)
	var queue := UI.button("QUEUE RANKED" if not locked else "RECRUIT A PLAYER FIRST", accent, not locked)
	queue.disabled = locked
	queue.pressed.connect(_start_match.bind(mode))
	box.add_child(queue)
	page_content.add_child(panel)
	if not locked:
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
		"Build a real audience. Viewers can sometimes leave small virtual donations after streamed matches.",
		11,
		UI.MUTED
	))
	top.add_child(info)
	var live_badge := UI.badge("ARMED" if enabled else "OFF", UI.GREEN if enabled else UI.MUTED)
	top.add_child(live_badge)
	box.add_child(top)
	var audience_stats := HBoxContainer.new()
	audience_stats.add_child(_metric_block("FOLLOWERS", str(followers), UI.PURPLE))
	audience_stats.add_child(_metric_block("PEAK VIEWERS", str(int(stream.get("peak_viewers", 0))), UI.CYAN))
	box.add_child(audience_stats)
	var revenue_stats := HBoxContainer.new()
	revenue_stats.add_child(_metric_block("TOTAL VIEWS", str(int(stream.get("total_views", 0))), UI.GREEN))
	revenue_stats.add_child(
		_metric_block(
			"STREAM DONATIONS",
			GameDataRef.format_cash(int(stream.get("total_donation_cash", 0))),
			UI.GOLD
		)
	)
	box.add_child(revenue_stats)
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
		"Creator tools slightly improve discovery and donation chance. Nothing is guaranteed and all earnings stay inside the game.",
		10,
		UI.DIM
	))
	var recent_comments: Array = stream.get("last_comments", [])
	var recent_donations: Array = stream.get("last_donations", [])
	if not recent_donations.is_empty():
		box.add_child(UI.overline("LATEST SUPPORT", UI.GOLD))
		for donation in recent_donations:
			box.add_child(
				UI.label(
					"@%s  +%s  •  %s"
					% [
						str(donation.get("user", "viewer")),
						GameDataRef.format_cash(int(donation.get("amount", 0))),
						str(donation.get("message", "great stream")),
					],
					10,
					UI.GOLD,
					700
				)
			)
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
	var snapshot := game.team_development_snapshot(mode, game.match_format(mode))
	var attack_rating := int(round(
		(float(snapshot.get("mechanics", 50)) + float(snapshot.get("shooting", 50))) / 2.0
	))
	var rotation_rating := int(round(
		(float(snapshot.get("rotation", 50)) + float(snapshot.get("game_sense", 50))) / 2.0
	))
	var defense_rating := int(round(
		(float(snapshot.get("defense", 50)) + float(snapshot.get("boost_control", 50))) / 2.0
	))
	box.add_child(_prep_line("Team form", form, UI.GREEN, "Sharp" if form >= 58 else "Average"))
	box.add_child(
		_prep_line(
			"Freshness", 100 - fatigue, UI.CYAN, "Ready" if fatigue < 40 else "Needs recovery"
		)
	)
	box.add_child(_prep_line("Attack package", attack_rating, UI.GOLD, "Mechanics + shooting"))
	box.add_child(_prep_line("Rotation discipline", rotation_rating, UI.PURPLE, "Rotation + sense"))
	box.add_child(_prep_line("Defensive control", defense_rating, UI.CYAN, "Defense + boost"))
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
	box.add_child(_development_stat_grid(player))
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


func _rank_emblem(rank_data: Dictionary, size: float = 72.0) -> Control:
	var emblem := RankEmblemRef.new()
	emblem.custom_minimum_size = Vector2(size, size)
	emblem.configure(rank_data)
	return emblem


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


func _equip_title(title_id: String) -> void:
	_handle_action(game.equip_title(title_id), "play")


func _clear_title() -> void:
	_handle_action(game.clear_equipped_title(), "play")


func _enter_cup(mode: String) -> void:
	_handle_action(game.play_community_cup(mode), "play")


func _collect_sponsor() -> void:
	_handle_action(game.collect_sponsor(), "home")


func _train_player(player_id: String, program_id: String) -> void:
	_handle_action(game.train_player(player_id, program_id), "team")


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
	match_interactive = mode == "Rocket League"
	match_session = {}
	match_result = {}
	if match_interactive:
		match_session = game.prepare_match(mode)
		if match_session.is_empty() or not bool(match_session.get("ok", false)):
			_show_message(str(match_session.get("message", "Matchmaking failed. Try again.")), false)
			return
	else:
		match_result = game.create_match(mode)
		if match_result.is_empty() or not bool(match_result.get("ok", false)):
			_show_message(str(match_result.get("message", "Matchmaking failed. Try again.")), false)
			return
		var events: Array = match_result.get("events", [])
		if events.is_empty():
			_show_message("Match data did not load. Try again.", false)
			return
	match_event_index = 0
	match_speed = 1
	match_finished = false
	match_decision_locked = false
	_build_match_overlay()
	_refresh_top_bar()
	if match_interactive:
		call_deferred("_present_match_decision")
	else:
		call_deferred("_begin_match_playback")


func _begin_match_playback() -> void:
	if match_timer == null or not is_instance_valid(match_timer):
		return
	_advance_match()
	if match_event_index < int(match_result.get("events", []).size()):
		match_timer.start()


func _build_match_overlay() -> void:
	var source: Dictionary = match_session if match_interactive else match_result
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
	match_log_scroll = ScrollContainer.new()
	match_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	match_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	match_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	match_log_scroll.scroll_deadzone = 8
	match_log_scroll.scroll_vertical_custom_step = 72.0
	match_log_scroll.follow_focus = false
	margin.add_child(match_log_scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 13)
	match_log_scroll.add_child(layout)
	var mode := str(source["mode"])
	var accent: Color = GameDataRef.MODE_COLORS[mode]
	var header_row := HBoxContainer.new()
	var live_label := "TACTICAL MATCH" if match_interactive else "STREAM LIVE" if bool(source.get("streaming", false)) else "LIVE MATCH"
	header_row.add_child(UI.overline(("%s  •  %s" % [live_label, str(source.get("format", "RANKED"))]), accent))
	var head_spacer := Control.new()
	head_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(head_spacer)
	header_row.add_child(
		UI.badge(
			"MAKE THE CALL" if match_interactive else ("%d VIEWERS" % int(source.get("stream_viewers", 0))) if bool(source.get("streaming", false)) else "RANKED",
			accent
		)
	)
	layout.add_child(header_row)
	layout.add_child(UI.heading(("%s vs %s" % ["KESHI" if str(source.get("format", "")) == "1v1" else "TSK", str(source["opponent"])]), 24))

	var scoreboard := UI.card(accent)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 9)
	scoreboard.add_child(score_box)
	match_clock_label = UI.overline("CONNECTING", UI.MUTED)
	match_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_score_label = UI.label("0 - 0", 43, UI.TEXT, 800)
	match_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var team_names := UI.label(
		"TSK                    %s" % str(source["opponent"]).to_upper(), 10, accent, 800
	)
	team_names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var progress_max := 6 if match_interactive else int(source.get("events", []).size())
	match_progress = UI.progress(0, progress_max, accent, 7)
	score_box.add_child(match_clock_label)
	score_box.add_child(match_score_label)
	score_box.add_child(team_names)
	score_box.add_child(match_progress)
	if match_interactive:
		match_boost_label = UI.label("TACTICAL BOOST  •  %d / 100" % int(source.get("boost", 45)), 10, UI.CYAN, 800)
		match_boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		match_boost_bar = UI.progress(int(source.get("boost", 45)), 100, UI.CYAN, 5)
		score_box.add_child(match_boost_label)
		score_box.add_child(match_boost_bar)
	layout.add_child(scoreboard)

	var event_panel := UI.card()
	event_panel.custom_minimum_size.y = 94
	match_event_label = UI.label("The teams are entering the server...", 15, UI.TEXT, 700)
	match_event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_panel.add_child(match_event_label)
	layout.add_child(event_panel)

	if match_interactive:
		match_decision_box = VBoxContainer.new()
		match_decision_box.add_theme_constant_override("separation", 8)
		layout.add_child(match_decision_box)
	else:
		var speed_row := HBoxContainer.new()
		speed_row.add_theme_constant_override("separation", 8)
		for speed in [1, 2, 4]:
			var speed_button := UI.button("%dx" % speed, accent, speed == 1, true)
			speed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			speed_button.pressed.connect(_set_match_speed.bind(speed))
			speed_row.add_child(speed_button)
		layout.add_child(speed_row)
	layout.add_child(UI.overline("MATCH FEED", UI.MUTED))
	var feed_panel := UI.card()
	match_log_box = VBoxContainer.new()
	match_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match_log_box.custom_minimum_size.y = 128.0
	match_log_box.add_theme_constant_override("separation", 7)
	feed_panel.add_child(match_log_box)
	layout.add_child(feed_panel)

	match_result_box = VBoxContainer.new()
	match_result_box.add_theme_constant_override("separation", 8)
	match_result_box.visible = false
	layout.add_child(match_result_box)
	match_continue_button = UI.button("CONTINUE", accent, true)
	match_continue_button.visible = false
	match_continue_button.pressed.connect(_close_match)
	layout.add_child(match_continue_button)

	match_timer = null
	if not match_interactive:
		match_timer = Timer.new()
		match_timer.wait_time = 0.72
		match_timer.one_shot = false
		match_timer.process_callback = Timer.TIMER_PROCESS_IDLE
		match_timer.timeout.connect(_advance_match)
		match_overlay.add_child(match_timer)
	_apply_scroll_passthrough(layout)
	var tween := create_tween()
	tween.tween_property(match_overlay, "modulate:a", 1.0, 0.22)


func _present_match_decision() -> void:
	if not match_interactive or match_finished or match_decision_box == null:
		return
	for child in match_decision_box.get_children():
		match_decision_box.remove_child(child)
		child.queue_free()
	var situation: Dictionary = game.current_match_situation(match_session)
	if situation.is_empty():
		_show_message("The next match situation could not be loaded.", false)
		return
	var turn := int(situation.get("turn", 0))
	var phase := "OVERTIME" if bool(situation.get("overtime", false)) else "DECISION %d / 6" % (turn + 1)
	match_decision_box.add_child(UI.overline(phase, UI.GOLD if bool(situation.get("overtime", false)) else UI.CYAN))
	var read_card := UI.card(UI.GOLD if bool(situation.get("overtime", false)) else UI.CYAN)
	var read_box := VBoxContainer.new()
	read_box.add_theme_constant_override("separation", 5)
	read_card.add_child(read_box)
	read_box.add_child(UI.label(str(situation.get("title", "READ THE PLAY")), 16, UI.TEXT, 800))
	read_box.add_child(UI.label(str(situation.get("read", "Choose the response that fits the situation.")), 12, UI.MUTED))
	match_decision_box.add_child(read_card)
	match_decision_box.add_child(UI.label("Choose the counter-call. Your read changes the scoring chance; rating still changes only from the final win or loss.", 11, UI.DIM))
	match_decision_box.add_child(UI.badge("BOOST %d  •  REPEATED CALLS BECOME READABLE" % int(match_session.get("boost", 0)), UI.CYAN))
	var definitions: Array = game.match_action_definitions()
	for definition_value in definitions:
		var definition: Dictionary = definition_value
		var action_key := str(definition.get("key", ""))
		var action_available := game.can_play_match_action(match_session, action_key)
		var boost_delta := int(definition.get("boost_delta", 0))
		var boost_text := "+%d BOOST" % boost_delta if boost_delta >= 0 else "%d BOOST" % boost_delta
		var action_button := UI.button(
			"%s  •  %s" % [str(definition.get("label", "MAKE CALL")), boost_text]
			if action_available
			else "%s  •  NEED %d BOOST" % [str(definition.get("label", "MAKE CALL")), int(definition.get("minimum_boost", 0))],
			UI.CYAN,
			action_available,
			true
		)
		action_button.disabled = not action_available
		action_button.pressed.connect(_choose_match_action.bind(action_key))
		match_decision_box.add_child(action_button)
		match_decision_box.add_child(UI.label(str(definition.get("detail", "")), 10, UI.MUTED))
	match_decision_locked = false
	_apply_scroll_passthrough(match_decision_box)


func _choose_match_action(action: String) -> void:
	if not match_interactive or match_finished or match_decision_locked:
		return
	match_decision_locked = true
	for child in match_decision_box.get_children():
		if child is Button:
			child.disabled = true
	var turn_result: Dictionary = game.play_match_turn(match_session, action)
	if not bool(turn_result.get("ok", false)):
		match_decision_locked = false
		_show_message(str(turn_result.get("message", "The tactical call failed.")), false)
		call_deferred("_present_match_decision")
		return
	var event: Dictionary = turn_result.get("event", {})
	if event.is_empty():
		match_decision_locked = false
		_show_message("The match event did not load.", false)
		return
	var session_events: Array = match_session.get("events", [])
	match_event_index = session_events.size()
	if bool(turn_result.get("overtime", false)):
		match_progress.max_value = 8
	_append_match_event(event, str(turn_result.get("feedback", "")))
	match_progress.value = match_event_index
	if match_boost_label != null:
		match_boost_label.text = "TACTICAL BOOST  •  %d / 100" % int(turn_result.get("boost_after", 0))
	if match_boost_bar != null:
		match_boost_bar.value = int(turn_result.get("boost_after", 0))
	if bool(turn_result.get("finished", false)):
		match_result = game.finalize_match(match_session)
		if match_result.is_empty() or not bool(match_result.get("ok", false)):
			match_decision_locked = false
			_show_message(str(match_result.get("message", "The match result could not be saved.")), false)
			return
		for child in match_decision_box.get_children():
			match_decision_box.remove_child(child)
			child.queue_free()
		match_decision_box.add_child(UI.badge("FINAL WHISTLE", UI.GOLD))
		_refresh_top_bar()
		_finish_match_animation()
		return
	call_deferred("_present_match_decision")


func _set_match_speed(speed: int) -> void:
	if match_finished or match_interactive:
		return
	match_speed = speed
	if match_timer != null:
		match_timer.wait_time = 0.72 / float(speed)
		match_timer.start()


func _advance_match() -> void:
	if match_finished or match_interactive:
		return
	var events: Array = match_result["events"]
	if match_event_index >= events.size():
		_finish_match_animation()
		return
	var event: Dictionary = events[match_event_index]
	_append_match_event(event)
	match_progress.value = match_event_index + 1

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


func _append_match_event(event: Dictionary, feedback: String = "") -> void:
	match_clock_label.text = str(event["time"])
	match_score_label.text = str(event["score"])
	match_event_label.text = str(event["text"])
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
	if not feedback.is_empty():
		feed_row.add_child(UI.badge(feedback, accent))
	match_log_box.add_child(feed_row)
	feed_row.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feed_row, "modulate:a", 1.0, 0.12)



func _scroll_match_feed_to_bottom() -> void:
	if match_log_scroll == null or not is_instance_valid(match_log_scroll):
		return
	var bar := match_log_scroll.get_v_scroll_bar()
	match_log_scroll.scroll_vertical = int(bar.max_value)


func _finish_match_animation() -> void:
	if match_finished:
		return
	match_finished = true
	if match_timer != null:
		match_timer.stop()
	var won := bool(match_result["won"])
	var accent := UI.GREEN if won else UI.RED
	var rank_reveal := bool(match_result.get("rank_revealed", false))
	match_event_label.text = "PLACEMENT COMPLETE — YOUR RANK IS READY" if rank_reveal else "Victory recorded. Rating updated." if won else "Defeat recorded. Rating updated."
	match_result_box.visible = true
	for child in match_result_box.get_children():
		match_result_box.remove_child(child)
		child.queue_free()
	match_result_box.add_child(UI.separator(Color(accent.r, accent.g, accent.b, 0.35)))

	var result_panel := UI.card(UI.GOLD if rank_reveal else accent)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 10)
	result_panel.add_child(result_box)
	result_box.add_child(
		UI.badge(
			"PLACEMENT COMPLETE  •  RANK REVEAL" if rank_reveal else "MATCH COMPLETE",
			UI.GOLD if rank_reveal else accent
		)
	)
	result_box.add_child(UI.heading("VICTORY" if won else "DEFEAT", 28))
	var is_rocket_league := str(match_result.get("mode", "")) == "Rocket League"
	var placement_complete := int(match_result.get("placements_after", 0)) >= 10
	var show_rating := not is_rocket_league or placement_complete
	var result_row := HBoxContainer.new()
	result_row.add_child(_metric_block("BEFORE", str(int(match_result.get("mmr_before", 0))) if show_rating else "HIDDEN", UI.MUTED))
	result_row.add_child(_metric_block("CHANGE", "%+d" % int(match_result["mmr_delta"]) if show_rating else "PLACEMENT", accent))
	result_row.add_child(_metric_block("AFTER", str(int(match_result.get("mmr_after", 0))) if show_rating else "HIDDEN", UI.TEXT))
	result_box.add_child(result_row)
	var opponent_row := HBoxContainer.new()
	opponent_row.add_child(_metric_block("OPPONENT", str(match_result.get("opponent", "Unknown")), UI.PURPLE))
	opponent_row.add_child(_metric_block("OPP MMR", str(int(match_result.get("opponent_mmr", 0))) if show_rating else "HIDDEN", UI.PURPLE))
	result_box.add_child(opponent_row)
	if is_rocket_league:
		var tactical_row := HBoxContainer.new()
		tactical_row.add_child(_metric_block("TACTICAL GRADE", str(match_result.get("tactical_grade", "C")), UI.CYAN))
		tactical_row.add_child(_metric_block("READ SCORE", "%+d" % int(match_result.get("decision_score", 0)), UI.GOLD))
		result_box.add_child(tactical_row)
	match_result_box.add_child(result_panel)

	if is_rocket_league:
		match_result_box.add_child(_post_match_rank_card())
		var unlocked_titles: Array = match_result.get("unlocked_titles", [])
		for title in unlocked_titles:
			var title_accent := TitleDataRef.color_for(title)
			var title_panel := UI.card(title_accent)
			var title_box := VBoxContainer.new()
			title_box.add_theme_constant_override("separation", 5)
			title_panel.add_child(title_box)
			title_box.add_child(UI.overline("TITLE UNLOCKED", title_accent))
			var title_name := UI.label(str(title.get("label", "NEW TITLE")), 18, title_accent, 800)
			title_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_box.add_child(title_name)
			title_box.add_child(UI.label(str(title.get("source", "Elite achievement")), 10, UI.MUTED))
			match_result_box.add_child(title_panel)

	var profile: Dictionary = match_result.get("opponent_profile", {})
	var profile_badge := UI.badge("LOBBY READ  •  %s" % str(profile.get("label", "NORMAL MATCH")), UI.PURPLE)
	profile_badge.custom_minimum_size.y = 38
	match_result_box.add_child(profile_badge)

	var attention: Dictionary = match_result.get("attention", {})
	var attention_text := str(attention.get("text", "No unusual attention after this match."))
	match_result_box.add_child(UI.label(attention_text, 11, UI.MUTED))

	if bool(match_result.get("streaming", false)):
		var audience_row := HBoxContainer.new()
		audience_row.add_child(_metric_block("VIEWERS", str(int(match_result.get("stream_viewers", 0))), UI.PURPLE))
		audience_row.add_child(_metric_block("NEW FOLLOWS", "+%d" % int(match_result.get("stream_followers", 0)), UI.GREEN))
		match_result_box.add_child(audience_row)
		var stream_money_row := HBoxContainer.new()
		stream_money_row.add_child(
			_metric_block(
				"DONATIONS",
				"+%s" % GameDataRef.format_cash(int(match_result.get("stream_donation_cash", 0))),
				UI.GOLD
			)
		)
		stream_money_row.add_child(_metric_block("PLAN", game.stream_plan(), UI.CYAN))
		match_result_box.add_child(stream_money_row)
		var donations: Array = match_result.get("stream_donations", [])
		if not donations.is_empty():
			match_result_box.add_child(UI.overline("STREAM SUPPORT", UI.GOLD))
			for donation in donations:
				match_result_box.add_child(
					UI.label(
						"@%s  +%s  •  %s"
						% [
							str(donation.get("user", "viewer")),
							GameDataRef.format_cash(int(donation.get("amount", 0))),
							str(donation.get("message", "great stream")),
						],
						10,
						UI.GOLD,
						700
					)
				)
		var comments: Array = match_result.get("comments", [])
		if not comments.is_empty():
			match_result_box.add_child(UI.overline("POST-STREAM COMMENTS", UI.MUTED))
			for comment in comments:
				match_result_box.add_child(UI.label(
					"@%s  %s" % [str(comment.get("user", "user")), str(comment.get("text", ""))],
					10,
					UI.MUTED
				))

	match_continue_button.visible = true
	match_continue_button.text = "CONTINUE TO RANKED"
	_apply_scroll_passthrough(match_result_box)
	var tween := create_tween().set_parallel(true)
	match_result_box.modulate.a = 0.0
	match_continue_button.modulate.a = 0.0
	tween.tween_property(match_result_box, "modulate:a", 1.0, 0.2)
	tween.tween_property(match_continue_button, "modulate:a", 1.0, 0.2)
	call_deferred("_scroll_match_feed_to_bottom")


func _post_match_rank_card() -> Control:
	var placements_after := int(match_result.get("placements_after", 0))
	var placed := placements_after >= 10
	var actual_rank: Dictionary = match_result.get("new_rank_data", RankedDataRef.unranked_data())
	var shown_rank := actual_rank if placed else RankedDataRef.unranked_data(int(match_result.get("mmr_after", 100)))
	var accent := RankedDataRef.color_for_family(str(shown_rank.get("family", "Unranked")))
	var panel := UI.card(UI.GOLD if bool(match_result.get("rank_revealed", false)) else accent)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	var transition := "UNRANKED  →  %s" % str(match_result.get("new_rank", "UNRANKED")) if bool(match_result.get("rank_revealed", false)) else "%s  →  %s" % [str(match_result.get("old_rank", "UNRANKED")), str(match_result.get("new_rank", "UNRANKED"))]
	box.add_child(UI.overline("RANK REVEAL" if bool(match_result.get("rank_revealed", false)) else "RATING UPDATE", UI.GOLD if bool(match_result.get("rank_revealed", false)) else accent))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	row.add_child(_rank_emblem(shown_rank, 94.0))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI.heading("UNRANKED" if not placed else str(actual_rank.get("tier_name", "UNRANKED")), 21))
	identity.add_child(UI.label("%d / 10 PLACEMENTS" % placements_after if not placed else "DIVISION %s" % str(actual_rank.get("division_roman", "")), 12, UI.MUTED, 800))
	identity.add_child(UI.label(str(match_result.get("format", "1v1")), 11, accent, 800))
	row.add_child(identity)
	box.add_child(row)
	var transition_label := UI.label(transition, 12, UI.TEXT, 700)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(transition_label)
	if not placed:
		box.add_child(UI.progress(placements_after, 10, accent, 9))
		box.add_child(UI.label("%d placement%s remaining" % [10 - placements_after, "s" if 10 - placements_after != 1 else ""], 11, UI.MUTED))
	else:
		var progress: Dictionary = match_result.get("division_progress", {"value": 1, "maximum": 1})
		box.add_child(UI.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 9))
		var status := "DIVISION PROGRESS"
		if bool(match_result.get("rank_revealed", false)):
			status = "PLACEMENT COMPLETE  •  %s" % str(actual_rank.get("compact_name", ""))
		elif bool(match_result.get("promoted", false)):
			status = "PROMOTED  •  %s" % str(match_result.get("new_rank", ""))
		elif bool(match_result.get("demoted", false)):
			status = "DEMOTED  •  %s" % str(match_result.get("new_rank", ""))
		box.add_child(UI.badge(status, UI.GOLD if bool(match_result.get("rank_revealed", false)) or bool(match_result.get("promoted", false)) else UI.RED if bool(match_result.get("demoted", false)) else accent))
	return panel

func _close_match() -> void:
	if match_overlay == null or not is_instance_valid(match_overlay):
		return
	var overlay := match_overlay
	match_overlay = null
	match_timer = null
	match_session = {}
	match_interactive = false
	match_decision_box = null
	match_boost_label = null
	match_boost_bar = null
	match_decision_locked = false
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.16)
	await tween.finished
	overlay.queue_free()
	_show_page("play", false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if match_overlay != null and is_instance_valid(match_overlay):
			if match_interactive or (match_timer != null and match_timer.is_stopped()):
				_close_match()
			get_viewport().set_input_as_handled()
