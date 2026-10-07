class_name TrainingVisualizerV25
extends "res://scripts/training_visualizer_v23.gd"

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")
const TEAM_CAR: Texture2D = preload("res://assets/game/car_team.svg")
const BALL_TEX: Texture2D = preload("res://assets/game/ball.svg")

const V25_BG := Color("05080C")
const V25_FIELD := Color("081821")
const V25_FIELD_ALT := Color("0B202A")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 410.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 410.0)

func _arena_v25() -> Rect2:
	return Rect2(Vector2(12, 70), Vector2(maxf(1.0, size.x - 24), maxf(1.0, size.y - 108)))

func _p(p: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(p.x * arena.size.x, p.y * arena.size.y)

func _draw() -> void:
	var arena := _arena_v25()
	_draw_backdrop_v25(arena)
	_draw_pitch_v25(arena)
	_draw_guides_v25(arena)
	_draw_car_v25(arena)
	_draw_ball_v25(arena)
	_draw_header_v25()
	_draw_footer_v25()

func _draw_backdrop_v25(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), V25_BG, true)
	for i in range(10):
		var t := float(i) / 9.0
		var c := Color("0B1118").lerp(V25_BG, t)
		draw_rect(Rect2(0, float(i) * size.y / 10.0, size.x, size.y / 10.0 + 1.0), c, true)
	for i in range(8):
		var light_x := 20.0 + float(i) * (size.x - 40.0) / 7.0
		var a := 0.10 + 0.035 * sin(animation_time * 1.1 + float(i))
		draw_circle(Vector2(light_x, 62), 1.8, Color(0.90, 0.96, 1.0, a))
	var pulse := 0.018 + 0.006 * sin(animation_time * 0.8)
	draw_circle(Vector2(size.x * 0.72, arena.get_center().y), size.x * 0.30, Color(accent.r, accent.g, accent.b, pulse))

func _draw_pitch_v25(arena: Rect2) -> void:
	draw_rect(arena.grow(7), Color("101821"), true)
	draw_rect(arena.grow(5), Color(accent.r, accent.g, accent.b, 0.10), false, 1.3)
	draw_rect(arena, V25_FIELD, true)

	var stripe_w := arena.size.x / 10.0
	for i in range(10):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(float(i) * stripe_w, 0), Vector2(stripe_w, arena.size.y)), V25_FIELD_ALT, true)

	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), Color(0.64, 0.80, 0.88, 0.16), 1.3)
	draw_arc(center, arena.size.y * 0.16, 0.0, TAU, 40, Color(0.64, 0.80, 0.88, 0.14), 1.2)

	for pos in [Vector2(0.14,0.18),Vector2(0.14,0.82),Vector2(0.36,0.33),Vector2(0.36,0.67),Vector2(0.64,0.33),Vector2(0.64,0.67),Vector2(0.86,0.18),Vector2(0.86,0.82)]:
		var point := _p(pos, arena)
		draw_circle(point, 5.8, Color(0.90, 0.72, 0.38, 0.07))
		draw_circle(point, 2.2, Color(0.93, 0.74, 0.40, 0.76))

	var goal_h := arena.size.y * 0.34
	for left in [true, false]:
		var goal_x: float = arena.position.x - 8.0 if bool(left) else arena.end.x
		var goal := Rect2(goal_x, arena.get_center().y - goal_h * 0.5, 8, goal_h)
		draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.06), true)
		draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.28), false, 1.5)

func _draw_guides_v25(arena: Rect2) -> void:
	var car := _p(car_position, arena)
	var future_t := minf(0.999, drill_phase + 0.13)
	var future_car := _p(_car_target_for_drill(future_t), arena)
	if car.distance_to(future_car) > 6.0:
		draw_dashed_line(car, future_car, Color(accent.r, accent.g, accent.b, 0.28), 2.0, 8.0)
		var dir := (future_car - car).normalized()
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([future_car, future_car - dir * 9.0 + side * 4.5, future_car - dir * 9.0 - side * 4.5]), Color(accent.r, accent.g, accent.b, 0.34))

	var ball := _p(ball_position, arena) - Vector2(0, ball_height * 22.0)
	var future_ball_height := _ball_height_for_drill(future_t)
	var future_ball := _p(_ball_target_for_drill(future_t), arena) - Vector2(0, future_ball_height * 22.0)
	var control := (ball + future_ball) * 0.5 - Vector2(0, 16.0 + maxf(ball_height, future_ball_height) * 24.0)
	var previous := ball
	for i in range(1, 13):
		var t := float(i) / 12.0
		var a := ball.lerp(control, t)
		var b := control.lerp(future_ball, t)
		var p := a.lerp(b, t)
		if i % 2 == 0:
			draw_line(previous, p, Color(0.94, 0.98, 1.0, 0.22), 1.5)
		previous = p

	var target := _p(target_position, arena)
	draw_circle(target, 20.0, Color(accent.r, accent.g, accent.b, 0.035))
	draw_arc(target, 18.0, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.28), 1.7)
	draw_arc(target, 9.0, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.13), 1.2)

	if drill_id == "rotation_review":
		var rotation_markers := [
			{"position": Vector2(0.48,0.67), "label": "2ND"},
			{"position": Vector2(0.23,0.31), "label": "3RD"},
		]
		for item in rotation_markers:
			var marker_pos: Vector2 = _p(item["position"], arena)
			draw_circle(marker_pos, 14.0, Color(accent.r, accent.g, accent.b, 0.055))
			draw_arc(marker_pos, 14.0, 0.0, TAU, 24, Color(accent.r, accent.g, accent.b, 0.20), 1.2)
			draw_string(FONT, marker_pos + Vector2(-17, -18), str(item["label"]), HORIZONTAL_ALIGNMENT_CENTER, 34, 8, Color(0.80, 0.91, 0.97, 0.74))

func _draw_car_v25(arena: Rect2) -> void:
	var center := _p(car_position, arena)
	var dir := car_velocity.normalized()
	if dir.length() < 0.05:
		dir = Vector2.RIGHT
	var angle := dir.angle()
	var tex_size := TEAM_CAR.get_size() * 0.50
	draw_circle(center + Vector2(2, 4), 15.5, Color(0, 0, 0, 0.24))
	draw_circle(center, 22.0, Color(accent.r, accent.g, accent.b, 0.07))
	draw_arc(center, 22.0, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.30), 1.5)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(TEAM_CAR, Rect2(-tex_size * 0.5, tex_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if car_velocity.length() > 0.06:
		var rear := center - dir * 18.0
		draw_line(rear, rear - dir * 10.0, Color(accent.r, accent.g, accent.b, 0.42), 3.0)

func _draw_ball_v25(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.14
		draw_circle(_p(ball_trail[i], arena), 3.0, Color(0.95, 0.98, 1.0, alpha))
	var ground := _p(ball_position, arena)
	var visual := ground - Vector2(0, ball_height * 22.0)
	draw_circle(ground + Vector2(2, 4), 6.8 - ball_height * 1.2, Color(0, 0, 0, 0.28))
	var ball_size := 28.0
	draw_texture_rect(BALL_TEX, Rect2(visual - Vector2(ball_size, ball_size) * 0.5, Vector2(ball_size, ball_size)), false)

func _draw_header_v25() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(FONT, Vector2(14, 24), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 16, Color(0.95, 0.98, 1.0, 0.98))
	draw_string(FONT, Vector2(14, 43), "%s  ·  %s" % [category, step_label], HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 8, Color(0.60, 0.72, 0.82, 0.84))
	var focus_ratio := float(focus_remaining) / float(maxi(1, focus_limit))
	draw_rect(Rect2(14, 50, size.x - 28, 3), Color(1, 1, 1, 0.06), true)
	draw_rect(Rect2(14, 50, (size.x - 28) * focus_ratio, 3), accent, true)

func _draw_footer_v25() -> void:
	var footer := "FOKUS %d/%d   ·   MÜDIGKEIT %d   ·   LIVE DRILL" % [focus_remaining, focus_limit, fatigue]
	draw_string(FONT, Vector2(14, size.y - 12), footer, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 8, Color(0.62, 0.72, 0.80, 0.70))
