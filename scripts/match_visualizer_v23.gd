class_name MatchVisualizerV23
extends "res://scripts/match_visualizer_v22.gd"

var mechanic_components: Dictionary = {}
var mechanic_family := ""


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	mechanic_components = event.get("mechanic_components", {}).duplicate(true)
	mechanic_family = str(event.get("mechanic_family", ""))
	super.play_turn(event, action, quality, new_momentum)


func _apply_v22_ball_path() -> void:
	super._apply_v22_ball_path()
	match phase:
		"recovery_setup":
			ball_target = Vector2(0.42, 0.50)
			ball_target_height = 0.05
		"recovery_dash", "dash_chain":
			ball_target = Vector2(0.58, 0.50)
			ball_target_height = 0.04
		"flick_load":
			ball_target = Vector2(0.58, 0.50)
			ball_target_height = 0.10
		"flick_release":
			ball_target = Vector2(0.80, 0.44)
			ball_target_height = 0.44
		"bump_route":
			ball_target = Vector2(0.84, 0.50)
			ball_target_height = 0.52
		"backboard_shot", "backboard_pass":
			ball_target = Vector2(0.94, 0.34)
			ball_target_height = 0.64
		"backboard_read", "teammate_read":
			ball_target = Vector2(0.84, 0.52)
			ball_target_height = 0.58
		"double_tap_finish":
			ball_target = Vector2(0.97, 0.50)
			ball_target_height = 0.32
		"redirect_read":
			ball_target = Vector2(0.68, 0.32)
			ball_target_height = 0.58
		"prejump":
			ball_target = Vector2(0.78, 0.45)
			ball_target_height = 0.62
		"ceiling_setup":
			ball_target = Vector2(0.52, 0.10)
			ball_target_height = 0.86
		"ceiling_drop":
			ball_target = Vector2(0.67, 0.34)
			ball_target_height = 0.66
		"reset_control":
			ball_target = Vector2(0.70, 0.38)
			ball_target_height = 0.74
		"reset_1":
			ball_target = Vector2(0.57, 0.28)
			ball_target_height = 0.78
		"reset_2":
			ball_target = Vector2(0.66, 0.33)
			ball_target_height = 0.82
		"reset_3":
			ball_target = Vector2(0.75, 0.39)
			ball_target_height = 0.84
		"reset_4":
			ball_target = Vector2(0.82, 0.44)
			ball_target_height = 0.82
		"reset_pass":
			ball_target = Vector2(0.76, 0.66)
			ball_target_height = 0.66
		"pinch_setup":
			ball_target = Vector2(0.52, 0.74)
			ball_target_height = 0.06
		"pinch_contact", "team_sync":
			ball_target = Vector2(0.64, 0.68)
			ball_target_height = 0.04
		"pinch_release":
			ball_target = Vector2(0.96, 0.50)
			ball_target_height = 0.18
		"air_setup":
			ball_target = Vector2(0.58, 0.30)
			ball_target_height = 0.66
		"pogo_drop":
			ball_target = Vector2(0.68, 0.68)
			ball_target_height = 0.30
		"pogo_bounce":
			ball_target = Vector2(0.78, 0.36)
			ball_target_height = 0.72
		"defense_read":
			ball_target = Vector2(0.30, 0.36)
			ball_target_height = 0.54
		"save_line":
			ball_target = Vector2(0.15, 0.50)
			ball_target_height = 0.30
		"clear_touch":
			ball_target = Vector2(0.55, 0.28)
			ball_target_height = 0.46
		"freestyle_transition":
			ball_target = Vector2(0.70, 0.38)
			ball_target_height = 0.78
		"mechanic_fail":
			ball_target = Vector2(0.58, 0.58)
			ball_target_height = 0.14


func _set_team_targets(quality: int) -> void:
	super._set_team_targets(quality)
	if our_targets.is_empty():
		return
	match phase:
		"recovery_setup", "recovery_dash", "dash_chain":
			our_targets[0] = Vector2(0.32, 0.76)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.54, 0.52)
		"flick_load", "flick_release":
			our_targets[0] = Vector2(0.62, 0.50)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.46, 0.68)
		"backboard_shot", "backboard_read", "double_tap_finish":
			our_targets[0] = Vector2(0.84, 0.40)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.62, 0.68)
		"redirect_read", "prejump":
			our_targets[0] = Vector2(0.76, 0.42)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.52, 0.64)
		"ceiling_setup", "ceiling_drop":
			our_targets[0] = Vector2(0.60, 0.22)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.46, 0.66)
		"reset_1", "reset_2", "reset_3", "reset_4", "reset_control":
			our_targets[0] = Vector2(0.70, 0.38)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.50, 0.68)
		"reset_pass":
			our_targets[0] = Vector2(0.68, 0.42)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.78, 0.66)
		"pinch_setup", "pinch_contact":
			our_targets[0] = Vector2(0.58, 0.70)
			if our_targets.size() > 1 and mechanic_family == "team_pinch": our_targets[1] = Vector2(0.64, 0.66)
		"team_sync":
			our_targets[0] = Vector2(0.61, 0.66)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.65, 0.66)
		"defense_read", "save_line":
			our_targets[0] = Vector2(0.20, 0.48)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.28, 0.68)
		"clear_touch":
			our_targets[0] = Vector2(0.42, 0.36)
		"mechanic_fail":
			our_targets[0] = Vector2(0.44, 0.70)
			if our_targets.size() > 1: our_targets[1] = Vector2(0.48, 0.50)


func _draw() -> void:
	super._draw()
	if mechanic_label.is_empty() or mechanic_components.is_empty():
		return
	var font := ThemeDB.fallback_font
	var labels := [
		["SET", int(mechanic_components.get("setup", 0))],
		["CTRL", int(mechanic_components.get("control", 0))],
		["READ", int(mechanic_components.get("read", 0))],
		["FIN", int(mechanic_components.get("finish", 0))],
	]
	var y := size.y - 18.0
	var x := 16.0
	for pair in labels:
		var text := "%s %d" % [str(pair[0]), int(pair[1])]
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.72, 0.82, 0.90, 0.72))
		x += 74.0
	if phase == "mechanic_fail":
		draw_rect(Rect2(12, 48, size.x - 24, 22), Color(0.30, 0.05, 0.07, 0.82), true)
		draw_string(font, Vector2(20, 63), "MECHANIC LOST • RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 9, Color(1.0, 0.72, 0.74, 0.96))
