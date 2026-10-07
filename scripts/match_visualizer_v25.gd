class_name MatchVisualizerV25
extends "res://scripts/match_visualizer_v23.gd"

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")
const TEAM_CAR: Texture2D = preload("res://assets/game/car_team.svg")
const OPP_CAR: Texture2D = preload("res://assets/game/car_opponent.svg")
const BALL_TEX: Texture2D = preload("res://assets/game/ball.svg")

const BG := Color("05080C")
const FIELD := Color("081821")
const FIELD_ALT := Color("0B202A")
const LINE := Color(0.66, 0.82, 0.90, 0.16)

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 448.0)

func _arena_v25() -> Rect2:
	return Rect2(Vector2(12, 78), Vector2(maxf(1.0, size.x - 24), maxf(1.0, size.y - 116)))

func _p(p: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(p.x * arena.size.x, p.y * arena.size.y)

func _draw() -> void:
	var arena := _arena_v25()
	_draw_backdrop_v25(arena)
	_draw_pitch_v25(arena)
	_draw_rotation_paths_v25(arena)
	_draw_ball_prediction_v25(arena)
	_draw_players_v25(arena)
	_draw_ball_v25(arena)
	_draw_header_v25()
	_draw_footer_v25()

	if phase == "mechanic_fail":
		draw_rect(Rect2(12, 54, size.x - 24, 20), Color(0.42, 0.05, 0.07, 0.82), true)
		draw_string(FONT, Vector2(20, 69), "PLAY VERLOREN  ·  RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 9, Color(1.0, 0.82, 0.84, 0.96))

	if goal_flash > 0.01:
		var c := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(arena, Color(c.r, c.g, c.b, goal_flash * 0.08), true)
		var goal_x := arena.end.x if goal_side > 0 else arena.position.x
		for r in [24.0, 40.0, 58.0]:
			draw_arc(Vector2(goal_x, arena.get_center().y), r, -PI * 0.5, PI * 0.5, 30, Color(c.r, c.g, c.b, goal_flash * 0.24), 2.0)

func _draw_backdrop_v25(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	for i in range(10):
		var t := float(i) / 9.0
		var c := Color("0B1118").lerp(BG, t)
		draw_rect(Rect2(0, float(i) * size.y / 10.0, size.x, size.y / 10.0 + 1.0), c, true)

	# Stadium-light atmosphere without fake perspective.
	for i in range(9):
		var x := 18.0 + float(i) * (size.x - 36.0) / 8.0
		var a := 0.12 + 0.04 * sin(time_alive * 1.2 + float(i) * 0.8)
		draw_circle(Vector2(x, 69), 1.8, Color(0.90, 0.96, 1.0, a))

	var glow := 0.020 + 0.006 * sin(time_alive * 0.8)
	draw_circle(Vector2(size.x * 0.28, arena.get_center().y), size.x * 0.34, Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, glow))
	draw_circle(Vector2(size.x * 0.78, arena.get_center().y), size.x * 0.28, Color(THEIR_COLOR.r, THEIR_COLOR.g, THEIR_COLOR.b, 0.014))

func _draw_pitch_v25(arena: Rect2) -> void:
	# Physical broadcast frame.
	draw_rect(arena.grow(7), Color("101821"), true)
	draw_rect(arena.grow(5), Color(0.56, 0.74, 0.84, 0.13), false, 1.3)
	draw_rect(arena, FIELD, true)

	var stripe_w := arena.size.x / 10.0
	for i in range(10):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(float(i) * stripe_w, 0), Vector2(stripe_w, arena.size.y)), FIELD_ALT, true)

	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), LINE, 1.4)
	draw_arc(center, arena.size.y * 0.16, 0.0, TAU, 40, LINE, 1.3)
	draw_circle(center, 2.4, Color(0.74, 0.88, 0.94, 0.38))

	# Soft thirds improve orientation without looking like a debug grid.
	for x_ratio in [0.25, 0.75]:
		var x := arena.position.x + arena.size.x * x_ratio
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(0.60, 0.76, 0.84, 0.055), 1.0)

	# Boost pads.
	for pos in [Vector2(0.14,0.18),Vector2(0.14,0.82),Vector2(0.36,0.33),Vector2(0.36,0.67),Vector2(0.64,0.33),Vector2(0.64,0.67),Vector2(0.86,0.18),Vector2(0.86,0.82)]:
		var point := _p(pos, arena)
		draw_circle(point, 6.0, Color(0.90, 0.72, 0.38, 0.07))
		draw_circle(point, 2.3, Color(0.93, 0.74, 0.40, 0.78))

	_draw_goal_v25(true, arena, OUR_COLOR)
	_draw_goal_v25(false, arena, THEIR_COLOR)

func _draw_goal_v25(left: bool, arena: Rect2, color: Color) -> void:
	var h := arena.size.y * 0.34
	var x := arena.position.x - 8.0 if left else arena.end.x
	var goal := Rect2(x, arena.get_center().y - h * 0.5, 8, h)
	draw_rect(goal, Color(color.r, color.g, color.b, 0.08), true)
	draw_rect(goal, Color(color.r, color.g, color.b, 0.36), false, 1.6)
	for i in range(1, 5):
		var y := goal.position.y + goal.size.y * float(i) / 5.0
		draw_line(Vector2(goal.position.x, y), Vector2(goal.end.x, y), Color(color.r, color.g, color.b, 0.10), 1.0)

func _draw_rotation_paths_v25(arena: Rect2) -> void:
	for index in range(our_positions.size()):
		if index >= our_targets.size():
			continue
		var from := _p(our_positions[index], arena)
		var to := _p(our_targets[index], arena)
		var alpha := 0.42 if index == active_actor else 0.20 if index == support_actor else 0.09
		var width := 2.4 if index == active_actor else 1.3
		draw_dashed_line(from, to, Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, alpha), width, 9.0)
		if index == active_actor and from.distance_to(to) > 12.0:
			var dir := (to - from).normalized()
			var side := Vector2(-dir.y, dir.x)
			var tip := to - dir * 3.0
			draw_colored_polygon(PackedVector2Array([tip, tip - dir * 10.0 + side * 5.0, tip - dir * 10.0 - side * 5.0]), Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, 0.38))

func _draw_ball_prediction_v25(arena: Rect2) -> void:
	var from := _p(ball_position, arena) - Vector2(0, ball_height * 24.0)
	var to := _p(ball_target, arena) - Vector2(0, ball_target_height * 24.0)
	if from.distance_to(to) < 8.0:
		return
	var control := (from + to) * 0.5 - Vector2(0, 18.0 + maxf(ball_height, ball_target_height) * 26.0)
	var previous := from
	for i in range(1, 15):
		var t := float(i) / 14.0
		var a := from.lerp(control, t)
		var b := control.lerp(to, t)
		var p := a.lerp(b, t)
		if i % 2 == 0:
			draw_line(previous, p, Color(0.94, 0.98, 1.0, 0.22), 1.5)
		previous = p

	# Landing / target marker.
	draw_arc(_p(ball_target, arena), 10.0, 0.0, TAU, 24, Color(0.92, 0.97, 1.0, 0.13), 1.2)

func _draw_players_v25(arena: Rect2) -> void:
	for index in range(their_positions.size()):
		_draw_car_sprite_v25(_p(their_positions[index], arena), their_velocities[index], OPP_CAR, THEIR_COLOR, "", false, false, false)

	for index in range(our_positions.size()):
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		_draw_car_sprite_v25(
			_p(our_positions[index], arena),
			our_velocities[index],
			TEAM_CAR,
			OUR_COLOR,
			role,
			index == active_actor,
			index == support_actor,
			true
		)

func _draw_car_sprite_v25(center: Vector2, velocity: Vector2, texture: Texture2D, color: Color, role: String, active: bool, support: bool, our_team: bool) -> void:
	var dir := velocity.normalized()
	if dir.length() < 0.05:
		dir = Vector2.RIGHT if our_team else Vector2.LEFT
	var angle := dir.angle()
	var scale := 0.50 if active else 0.43
	var tex_size := texture.get_size() * scale

	# Grounding + selection state.
	draw_circle(center + Vector2(2, 4), 16.0 if active else 13.0, Color(0, 0, 0, 0.24))
	if active:
		draw_circle(center, 22.0, Color(color.r, color.g, color.b, 0.08))
		draw_arc(center, 22.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.36), 1.7)
	elif support:
		draw_arc(center, 18.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.22), 1.3)

	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-tex_size * 0.5, tex_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if velocity.length() > 0.10:
		var rear := center - dir * (18.0 if active else 15.0)
		draw_line(rear, rear - dir * (10.0 if active else 7.0), Color(color.r, color.g, color.b, 0.42), 3.0)

	if not role.is_empty():
		var label_color := Color(0.92, 0.97, 1.0, 0.92) if active else Color(0.72, 0.82, 0.90, 0.66)
		draw_string(FONT, center + Vector2(-18, -22), role, HORIZONTAL_ALIGNMENT_CENTER, 36, 8, label_color)

func _draw_ball_v25(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.14
		draw_circle(_p(ball_trail[i], arena), 3.2, Color(0.95, 0.98, 1.0, alpha))

	var ground := _p(ball_position, arena)
	var lift := ball_height * 24.0
	var visual := ground - Vector2(0, lift)
	draw_circle(ground + Vector2(2, 4), 7.0 - ball_height * 1.4, Color(0, 0, 0, 0.28))
	var ball_size := 28.0
	draw_texture_rect(BALL_TEX, Rect2(visual - Vector2(ball_size, ball_size) * 0.5, Vector2(ball_size, ball_size)), false)

func _draw_header_v25() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_label_v25(phase)
	var subtitle := "TEAM COMBO" if not combo_id.is_empty() else _phase_label_v25(phase)
	draw_string(FONT, Vector2(14, 24), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 16, Color(0.95, 0.98, 1.0, 0.98))
	draw_string(FONT, Vector2(14, 43), subtitle, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 8, Color(0.58, 0.70, 0.80, 0.82))

	var pressure := clampf((float(momentum) + 100.0) / 200.0, 0.0, 1.0)
	draw_rect(Rect2(14, 50, size.x - 28, 3), Color(1, 1, 1, 0.06), true)
	draw_rect(Rect2(14, 50, (size.x - 28) * pressure, 3), OUR_COLOR if momentum >= 0 else THEIR_COLOR, true)

func _draw_footer_v25() -> void:
	if mechanic_components.is_empty():
		return
	var labels := [
		["SET", int(mechanic_components.get("setup", 0))],
		["CTRL", int(mechanic_components.get("control", 0))],
		["READ", int(mechanic_components.get("read", 0))],
		["FIN", int(mechanic_components.get("finish", 0))],
	]
	var cell := (size.x - 24.0) / 4.0
	var x := 12.0
	for pair in labels:
		var text := "%s %d" % [str(pair[0]), int(pair[1])]
		draw_string(FONT, Vector2(x, size.y - 12), text, HORIZONTAL_ALIGNMENT_CENTER, cell - 3.0, 8, Color(0.68, 0.78, 0.86, 0.70))
		x += cell

func _phase_label_v25(value: String) -> String:
	var labels := {
		"buildup":"AUFBAU",
		"challenge":"CHALLENGE",
		"rotation_switch":"ROTATION",
		"wall_setup":"WALL SETUP",
		"air_carry":"AIR CARRY",
		"air_carry_2":"AIR CARRY",
		"reset_contact":"RESET CONTACT",
		"reset_delay":"RESET CONTROL",
		"second_reset":"2. RESET",
		"third_reset":"3. RESET",
		"reset_4":"4. RESET",
		"psycho_setup":"PSYCHO SETUP",
		"own_wall_carry":"OWN WALL CARRY",
		"backwall_musty":"BACKWALL MUSTY",
		"psycho_contact":"PSYCHO",
		"teammate_prejump":"PREJUMP READ",
		"redirect_finish":"REDIRECT",
		"goal_ours":"TOR",
		"goal_theirs":"GEGENTOR",
		"mechanic_fail":"RECOVERY",
	}
	return str(labels.get(value, value.replace("_", " ").to_upper()))
