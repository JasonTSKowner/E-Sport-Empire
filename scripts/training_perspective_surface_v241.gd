extends "res://scripts/training_visualizer_v24.gd"

const V241_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 408.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 408.0)

func _draw() -> void:
	var arena := Rect2(Vector2(7, 64), Vector2(maxf(1.0, size.x - 14.0), maxf(1.0, size.y - 92.0)))
	_v241_draw_backdrop(arena)
	_v241_draw_pitch(arena)
	_v241_draw_guides(arena)
	_v241_draw_car(arena)
	_v241_draw_ball(arena)
	_v241_draw_header()

func _v241_project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var near_y := arena.end.y - 18.0
	var far_y := arena.position.y + 28.0
	var screen_y := lerpf(near_y, far_y, depth)
	var half_width := lerpf(arena.size.x * 0.47, arena.size.x * 0.24, depth)
	var screen_x := arena.get_center().x + (p.y - 0.5) * 2.0 * half_width
	return Vector2(screen_x, screen_y)

func _v241_depth_scale(p: Vector2) -> float:
	return lerpf(1.18, 0.62, clampf(p.x, 0.0, 1.0))

func _v241_draw_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("030509"), true)
	for i in range(12):
		var t := float(i) / 11.0
		var c := Color("10151C").lerp(Color("030509"), t)
		draw_rect(Rect2(0.0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), c, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, arena.position.y - 8.0), Vector2(size.x, arena.position.y - 8.0),
		Vector2(size.x * 0.86, arena.position.y + 40.0), Vector2(size.x * 0.14, arena.position.y + 40.0)
	]), Color(0.035, 0.048, 0.062, 0.95))
	for i in range(9):
		var x := 18.0 + float(i) * (size.x - 36.0) / 8.0
		var light_alpha := 0.14 + 0.04 * sin(animation_time * 1.4 + float(i) * 0.6)
		draw_circle(Vector2(x, arena.position.y + 2.0), 2.0, Color(0.90, 0.95, 1.0, light_alpha))
	draw_circle(Vector2(size.x * 0.80, 76.0), size.x * 0.31, Color(accent.r, accent.g, accent.b, 0.028))

func _v241_draw_pitch(arena: Rect2) -> void:
	var near_l := _v241_project_field(Vector2(0, 0), arena)
	var near_r := _v241_project_field(Vector2(0, 1), arena)
	var far_l := _v241_project_field(Vector2(1, 0), arena)
	var far_r := _v241_project_field(Vector2(1, 1), arena)
	var pitch := PackedVector2Array([near_l, near_r, far_r, far_l])
	draw_colored_polygon(pitch, Color("07171D"))
	draw_polyline(PackedVector2Array([near_l, near_r, far_r, far_l, near_l]), Color(accent.r, accent.g, accent.b, 0.22), 1.8)

	for i in range(8):
		var x0 := float(i) / 8.0
		var x1 := float(i + 1) / 8.0
		if i % 2 == 0:
			var band := PackedVector2Array([
				_v241_project_field(Vector2(x0, 0), arena), _v241_project_field(Vector2(x0, 1), arena),
				_v241_project_field(Vector2(x1, 1), arena), _v241_project_field(Vector2(x1, 0), arena)
			])
			draw_colored_polygon(band, Color(0.04, 0.12, 0.15, 0.48))

	var c1 := _v241_project_field(Vector2(0.5, 0.0), arena)
	var c2 := _v241_project_field(Vector2(0.5, 1.0), arena)
	draw_line(c1, c2, Color(0.56, 0.76, 0.84, 0.20), 1.3)
	var center := _v241_project_field(Vector2(0.5, 0.5), arena)
	draw_arc(center, 23.0, 0.0, TAU, 40, Color(0.56, 0.76, 0.84, 0.16), 1.2)

	for p in [Vector2(0.12, 0.18), Vector2(0.12, 0.82), Vector2(0.36, 0.34), Vector2(0.36, 0.66), Vector2(0.64, 0.34), Vector2(0.64, 0.66), Vector2(0.88, 0.18), Vector2(0.88, 0.82)]:
		var s := _v241_depth_scale(p)
		var point := _v241_project_field(p, arena)
		draw_circle(point, 4.8 * s, Color(0.94, 0.72, 0.35, 0.08))
		draw_circle(point, 1.9 * s, Color(0.94, 0.73, 0.36, 0.80))

	_v241_draw_goal(Vector2(0.0, 0.5), arena, true)
	_v241_draw_goal(Vector2(1.0, 0.5), arena, false)

func _v241_draw_goal(pos: Vector2, arena: Rect2, near_goal: bool) -> void:
	var center := _v241_project_field(pos, arena)
	var s := _v241_depth_scale(pos)
	var w := 90.0 * s
	var h := 30.0 * s
	var y := center.y + (8.0 if near_goal else -7.0)
	var box := Rect2(center.x - w * 0.5, y - h * 0.5, w, h)
	draw_rect(box, Color(accent.r, accent.g, accent.b, 0.05), true)
	draw_rect(box, Color(accent.r, accent.g, accent.b, 0.28), false, 1.5)

func _v241_draw_guides(arena: Rect2) -> void:
	var car := _v241_project_field(car_position, arena)
	var future_t := minf(0.999, drill_phase + 0.14)
	var future_car := _v241_project_field(_car_target_for_drill(future_t), arena)
	draw_dashed_line(car, future_car, Color(accent.r, accent.g, accent.b, 0.28), 1.8, 8.0)

	var ball := _v241_project_field(ball_position, arena) - Vector2(0, ball_height * 36.0 * _v241_depth_scale(ball_position))
	var future_pos := _ball_target_for_drill(future_t)
	var future_h := _ball_height_for_drill(future_t)
	var future_ball := _v241_project_field(future_pos, arena) - Vector2(0, future_h * 36.0 * _v241_depth_scale(future_pos))
	var control := (ball + future_ball) * 0.5 - Vector2(0, 30.0 + maxf(ball_height, future_h) * 24.0)
	var previous := ball
	for i in range(1, 13):
		var t := float(i) / 12.0
		var a := ball.lerp(control, t)
		var b := control.lerp(future_ball, t)
		var p := a.lerp(b, t)
		if i % 2 == 0:
			draw_line(previous, p, Color(0.94, 0.98, 1.0, 0.22), 1.5)
		previous = p

	var target := _v241_project_field(target_position, arena)
	var s := _v241_depth_scale(target_position)
	draw_arc(target, 19.0 * s, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.28), 1.8)
	draw_arc(target, 10.0 * s, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.13), 1.2)

func _v241_draw_car(arena: Rect2) -> void:
	var center := _v241_project_field(car_position, arena)
	var next_pos := car_position + (car_velocity.normalized() * 0.04 if car_velocity.length() > 0.02 else Vector2(0.04, 0.0))
	var next := _v241_project_field(next_pos, arena)
	var dir := (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s := _v241_depth_scale(car_position) * 1.08
	var nose := center + dir * 15.0 * s
	var rear := center - dir * 10.0 * s
	var body := PackedVector2Array([
		nose,
		center + dir * 3.0 * s + side * 7.5 * s,
		rear + side * 5.2 * s,
		rear - side * 5.2 * s,
		center + dir * 3.0 * s - side * 7.5 * s
	])
	draw_circle(center, 20.0 * s, Color(accent.r, accent.g, accent.b, 0.07))
	draw_colored_polygon(body, Color(accent.r * 0.48, accent.g * 0.48, accent.b * 0.48, 1.0))
	draw_polyline(body, Color(accent.r, accent.g, accent.b, 0.96), 1.8, true)
	var glass := PackedVector2Array([
		center + dir * 6.0 * s + side * 3.0 * s,
		center + dir * 8.0 * s - side * 3.0 * s,
		center + dir * 1.0 * s - side * 3.5 * s,
		center + dir * 1.0 * s + side * 3.5 * s
	])
	draw_colored_polygon(glass, Color(0.72, 0.88, 0.96, 0.30))
	if car_velocity.length() > 0.04:
		draw_line(rear, rear - dir * (10.0 * s), Color(accent.r, accent.g, accent.b, 0.48), 3.1 * s)

func _v241_draw_ball(arena: Rect2) -> void:
	var ground := _v241_project_field(ball_position, arena)
	var s := _v241_depth_scale(ball_position)
	var visual := ground - Vector2(0, ball_height * 36.0 * s)
	draw_circle(ground + Vector2(2, 4), 7.0 * s * (1.0 - ball_height * 0.18), Color(0, 0, 0, 0.38))
	draw_circle(visual, 14.5 * s, Color(0.88, 0.95, 1.0, 0.05))
	draw_circle(visual, 8.0 * s, Color("F4F7FB"))
	draw_circle(visual + Vector2(-2, -2) * s, 2.2 * s, Color("AAB7C8"))

func _v241_draw_header() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(V241_FONT, Vector2(12, 24), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color(0.94, 0.97, 1.0, 0.96))
	draw_string(V241_FONT, Vector2(12, 43), "%s  ·  %s" % [category, step_label], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.60, 0.72, 0.82, 0.84))
	var ratio := float(focus_remaining) / float(maxi(1, focus_limit))
	draw_rect(Rect2(12, 50, size.x - 24, 3), Color(1, 1, 1, 0.06), true)
	draw_rect(Rect2(12, 50, (size.x - 24) * ratio, 3), accent, true)
	var footer := "FOKUS %d/%d   ·   MÜDIGKEIT %d" % [focus_remaining, focus_limit, fatigue]
	draw_string(V241_FONT, Vector2(12, size.y - 9), footer, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.62, 0.72, 0.80, 0.70))
