extends "res://scripts/cinematic_shell_v25.gd"

const FlatUIV251 = preload("res://scripts/ui_kit.gd")
const FlatGameDataV251 = preload("res://scripts/game_data.gd")
const FlatRankedV251 = preload("res://scripts/ranked_data.gd")
const FlatFontV251 = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _flat_tab_v251(text: String, selected: bool, accent: Color = FlatUIV251.CYAN) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 38
	button.add_theme_font_override("font", FlatFontV251)
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", FlatUIV251.TEXT if selected else FlatUIV251.DIM)
	button.add_theme_color_override("font_hover_color", FlatUIV251.TEXT)
	button.add_theme_color_override("font_pressed_color", FlatUIV251.TEXT)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.content_margin_left = 7
	normal.content_margin_right = 7
	normal.content_margin_top = 6
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.025)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var indicator := ColorRect.new()
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.color = Color(accent.r, accent.g, accent.b, 0.92 if selected else 0.0)
	indicator.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	indicator.offset_left = 10
	indicator.offset_right = -10
	indicator.offset_top = -2
	indicator.offset_bottom = 0
	button.add_child(indicator)

	if selected:
		var glow := ColorRect.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = Color(accent.r, accent.g, accent.b, 0.045)
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.show_behind_parent = true
		button.add_child(glow)
	return button

func _flat_nav_divider_v251() -> HSeparator:
	var line := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.82, 0.90, 0.075)
	style.content_margin_top = 0.5
	style.content_margin_bottom = 0.5
	line.add_theme_stylebox_override("separator", style)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _mode_switch() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var selected := game.selected_mode()
	for mode in FlatGameDataV251.MODES:
		var active := str(mode) == selected
		var accent: Color = FlatGameDataV251.MODE_COLORS[mode]
		var button := _flat_tab_v251(str(FlatGameDataV251.MODE_SHORT[mode]), active, accent)
		button.tooltip_text = str(mode)
		button.pressed.connect(_select_mode.bind(mode))
		row.add_child(button)
	wrap.add_child(row)
	wrap.add_child(_flat_nav_divider_v251())
	page_content.add_child(wrap)

func _team_view_switch() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for entry in [["roster", "KADER"], ["training", "TRAINING"], ["coaching", "COACH"], ["scouting", "SCOUT"]]:
		var target := str(entry[0])
		var button := _flat_tab_v251(str(entry[1]), team_view == target, FlatUIV251.CYAN)
		button.pressed.connect(_select_team_view.bind(target))
		row.add_child(button)
	wrap.add_child(row)
	wrap.add_child(_flat_nav_divider_v251())
	page_content.add_child(wrap)

func _playlist_switch() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var selected := game.selected_rl_playlist()
	var roster_size := game.roster_for("Rocket League").size()
	for playlist in FlatRankedV251.PLAYLISTS:
		var required := game.playlist_required_players(playlist)
		var label := "%s   %d/%d" % [playlist, mini(roster_size, required), required]
		var button := _flat_tab_v251(label, str(playlist) == selected, FlatUIV251.CYAN)
		button.pressed.connect(_select_rl_playlist.bind(str(playlist)))
		row.add_child(button)
	wrap.add_child(row)
	wrap.add_child(_flat_nav_divider_v251())
	page_content.add_child(wrap)

func _ranked_view_switch() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for entry in [["overview", "SPIELEN"], ["circuit", "TURNIER"], ["ladder", "RANGLISTE"], ["titles", "TITEL"]]:
		var target := str(entry[0])
		var button := _flat_tab_v251(str(entry[1]), ranked_view == target, FlatUIV251.CYAN)
		button.pressed.connect(_select_ranked_view.bind(target))
		row.add_child(button)
	wrap.add_child(row)
	wrap.add_child(_flat_nav_divider_v251())
	page_content.add_child(wrap)
