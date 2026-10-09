extends "res://scripts/cinematic_shell_v25.gd"

const ReleaseUIV25 = preload("res://scripts/ui_kit.gd")

func _home_competitive_stage_v25() -> Control:
	var stage := super._home_competitive_stage_v25()
	var placements := int(game.playlist_record(game.selected_rl_playlist()).get("placements", 0))
	if placements < 10:
		stage.set("accent", ReleaseUIV25.CYAN)
		stage.queue_redraw()
	_apply_active_cyan_v25(stage, ["MATCH STARTEN"])
	return stage

func _ranked_competitive_stage_v25() -> Control:
	var stage := super._ranked_competitive_stage_v25()
	var placements := int(game.playlist_record(game.selected_rl_playlist()).get("placements", 0))
	if placements < 10:
		stage.set("accent", ReleaseUIV25.CYAN)
		stage.queue_redraw()
	_apply_active_cyan_v25(stage, ["MATCH SUCHEN"])
	return stage

func _apply_active_cyan_v25(node: Node, labels: Array[String]) -> void:
	if node is Button:
		var button := node as Button
		if button.text in labels and not button.disabled:
			_style_primary_cyan_v25(button)
	for child in node.get_children():
		_apply_active_cyan_v25(child, labels)

func _style_primary_cyan_v25(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("071018"))
	button.add_theme_color_override("font_hover_color", Color("071018"))
	button.add_theme_color_override("font_pressed_color", Color("071018"))

	var normal := ReleaseUIV25.box(Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.92), 9, Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.32), 1)
	normal.shadow_size = 4
	normal.shadow_color = Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.10)
	var hover := ReleaseUIV25.box(Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 1.0), 9, Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.48), 1)
	hover.shadow_size = 0
	var pressed := ReleaseUIV25.box(Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.78), 8, Color(ReleaseUIV25.CYAN.r, ReleaseUIV25.CYAN.g, ReleaseUIV25.CYAN.b, 0.52), 1)
	pressed.shadow_size = 0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
