class_name MatchVisualizerV22
extends "res://scripts/match_visualizer.gd"

var active_actor := 0
var support_actor := -1
var mechanic_label := ""
var combo_id := ""


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 382.0)


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	active_actor = int(event.get("actor_index", 0))
	support_actor = int(event.get("support_index", -1))
	mechanic_label = str(event.get("mechanic_label", ""))
	combo_id = str(event.get("combo_id", ""))
	super.play_turn(event, action, quality, new_momentum)
	_apply_v22_ball_path()
	queue_redraw()


func _apply_v22_ball_path() -> void:
	match phase:
		"rotation_switch":
			ball_target = Vector2(0.56, 0.50)
			ball_target_height = 0.08
		"wall_setup":
			ball_target = Vector2(0.31, 0.10)
			ball_target_height = 0.18
		"control_setup":
			ball_target = Vector2(0.58, 0.52)
			ball_target_height = 0.05
		"air_carry":
			ball_target = Vector2(0.53, 0.28)
			ball_target_height = 0.56
		"air_carry_2":
			ball_target = Vector2(0.68, 0.38)
			ball_target_height = 0.72
		"air_pass":
			ball_target = Vector2(0.73, 0.68)
			ball_target_height = 0.62
		"musty_load":
			ball_target = Vector2(0.61, 0.46)
			ball_target_height = 0.32
		"musty_release":
			ball_target = Vector2(0.84, 0.42)
			ball_target_height = 0.56
		"reset_contact":
			ball_target = Vector2(0.58, 0.30)
			ball_target_height = 0.74
		"reset_delay":
			ball_target = Vector2(0.66, 0.34)
			ball_target_height = 0.78
		"second_reset":
			ball_target = Vector2(0.72, 0.40)
			ball_target_height = 0.82
		"third_reset":
			ball_target = Vector2(0.78, 0.44)
			ball_target_height = 0.84
		"finish_touch":
			ball_target = Vector2(0.91, 0.50)
			ball_target_height = 0.46
		"psycho_setup":
			ball_target = Vector2(0.25, 0.12)
			ball_target_height = 0.18
		"own_wall_carry":
			ball_target = Vector2(0.09, 0.26)
			ball_target_height = 0.56
		"backwall_musty":
			ball_target = Vector2(0.18, 0.50)
			ball_target_height = 0.78
		"psycho_contact":
			ball_target = Vector2(0.72, 0.48)
			ball_target_height = 0.72
		"teammate_prejump":
			ball_target = Vector2(0.80, 0.62)
			ball_target_height = 0.64
		"redirect_finish":
			ball_target = Vector2(0.96, 0.50)
			ball_target_height = 0.42


func _set_team_targets(quality: int) -> void:
	var count := our_positions.size()
	our_targets.clear()
	their_targets.clear()
	for index in range(count):
		var target := Vector2(0.34, 0.50)
		var opponent_target := Vector2(0.68, 0.50)
		if index == 0:
			target = Vector2(0.50, 0.50)
		elif index == 1:
			target = Vector2(0.38, 0.68)
		else:
			target = Vector2(0.24, 0.34)

		match phase:
			"buildup":
				target = [Vector2(0.48, 0.47), Vector2(0.34, 0.67), Vector2(0.22, 0.30)][mini(index, 2)]
			"challenge":
				target = [Vector2(0.58, 0.46), Vector2(0.43, 0.64), Vector2(0.25, 0.32)][mini(index, 2)]
			"rotation_switch":
				target = [Vector2(0.24, 0.78), Vector2(0.56, 0.50), Vector2(0.32, 0.28)][mini(index, 2)]
			"wall_setup", "psycho_setup":
				target = [Vector2(0.30, 0.12), Vector2(0.48, 0.62), Vector2(0.23, 0.38)][mini(index, 2)]
			"own_wall_carry", "backwall_musty":
				target = [Vector2(0.12, 0.26), Vector2(0.46, 0.60), Vector2(0.22, 0.38)][mini(index, 2)]
			"psycho_contact":
				target = [Vector2(0.56, 0.42), Vector2(0.70, 0.64), Vector2(0.30, 0.30)][mini(index, 2)]
			"teammate_prejump":
				target = [Vector2(0.34, 0.78), Vector2(0.78, 0.62), Vector2(0.33, 0.30)][mini(index, 2)]
			"redirect_finish":
				target = [Vector2(0.40, 0.76), Vector2(0.89, 0.52), Vector2(0.34, 0.30)][mini(index, 2)]
			"air_carry", "air_carry_2", "reset_contact", "reset_delay", "second_reset", "third_reset":
				target = [Vector2(0.64, 0.38), Vector2(0.48, 0.68), Vector2(0.26, 0.30)][mini(index, 2)]
			"air_pass":
				target = [Vector2(0.64, 0.38), Vector2(0.76, 0.67), Vector2(0.30, 0.30)][mini(index, 2)]
			"goal_ours", "chance_ours", "finish_touch":
				target = [Vector2(0.76, 0.48), Vector2(0.66, 0.66), Vector2(0.34, 0.30)][mini(index, 2)]
			"goal_theirs", "chance_theirs":
				target = [Vector2(0.23, 0.48), Vector2(0.31, 0.67), Vector2(0.18, 0.30)][mini(index, 2)]
		if quality < 0 and phase == "challenge":
			target.x -= 0.08
		our_targets.append(target)
		their_targets.append(opponent_target + Vector2(float(index) * 0.04, (float(index) - 1.0) * 0.18))


func _draw() -> void:
	super._draw()
	var arena := _arena_rect()
	var font := ThemeDB.fallback_font
	for index in range(our_positions.size()):
		var from := _field_point(our_positions[index], arena)
		var to := _field_point(our_targets[index], arena)
		var path_color := Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, 0.22 if index != active_actor else 0.44)
		draw_dashed_line(from, to, path_color, 1.2 if index != active_actor else 2.0, 7.0)
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		if index == active_actor:
			role += " • BALL"
		elif index == support_actor:
			role += " • READ"
		draw_string(font, from + Vector2(-15, 22), role, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.78, 0.90, 0.98, 0.72))

	if not mechanic_label.is_empty():
		var label := mechanic_label.to_upper()
		if not combo_id.is_empty():
			label += "  →  TEAM COMBO"
		draw_rect(Rect2(14, 26, size.x - 28, 18), Color(0.02, 0.03, 0.04, 0.76), true)
		draw_string(font, Vector2(20, 39), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 9, Color(0.84, 0.96, 1.0, 0.92))
