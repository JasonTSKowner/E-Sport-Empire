extends "res://scripts/cinematic_shell_v26.gd"

const UIV261 = preload("res://scripts/ui_kit.gd")

func _home_world_v26() -> Control:
	var stage := super._home_world_v26()
	var old_button := _find_button_v261(stage, "MATCH STARTEN")
	if old_button != null:
		var parent := old_button.get_parent()
		var index := old_button.get_index()
		parent.remove_child(old_button)
		old_button.queue_free()
		var replacement := UIV261.button("MATCH STARTEN", UIV261.CYAN, true)
		replacement.custom_minimum_size.y = 52
		replacement.pressed.connect(_show_page.bind("play", true))
		parent.add_child(replacement)
		parent.move_child(replacement, index)
	return stage

func _team_view_switch() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for entry in [
		["roster", "KADER"],
		["training", "TRAINING"],
		["coaching", "COACH"],
		["scouting", "SCOUT"],
	]:
		var target := str(entry[0])
		var active := team_view == target
		var button := Button.new()
		button.text = str(entry[1])
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 38
		button.add_theme_font_override("font", UIV261.APP_FONT)
		button.add_theme_font_size_override("font_size", 9)
		button.add_theme_color_override("font_color", UIV261.TEXT if active else UIV261.DIM)
		button.add_theme_color_override("font_hover_color", UIV261.TEXT)
		button.add_theme_color_override("font_pressed_color", UIV261.TEXT)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(UIV261.CYAN.r, UIV261.CYAN.g, UIV261.CYAN.b, 0.055) if active else Color.TRANSPARENT
		normal.border_width_bottom = 2 if active else 1
		normal.border_color = Color(UIV261.CYAN.r, UIV261.CYAN.g, UIV261.CYAN.b, 0.62) if active else Color(0.70,0.78,0.84,0.07)
		normal.content_margin_top = 8
		normal.content_margin_bottom = 8
		var hover := normal.duplicate()
		hover.bg_color = Color(UIV261.CYAN.r, UIV261.CYAN.g, UIV261.CYAN.b, 0.075)
		var pressed := normal.duplicate()
		pressed.bg_color = Color(UIV261.CYAN.r, UIV261.CYAN.g, UIV261.CYAN.b, 0.10)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_team_view.bind(target))
		row.add_child(button)
	page_content.add_child(row)

func _find_button_v261(node: Node, target_text: String) -> Button:
	if node is Button:
		var candidate := node as Button
		if candidate.text == target_text:
			return candidate
	for child in node.get_children():
		var found := _find_button_v261(child, target_text)
		if found != null:
			return found
	return null
