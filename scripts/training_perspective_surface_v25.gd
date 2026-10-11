extends "res://scripts/training_perspective_surface_v242.gd"

const V25_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 470.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 470.0)

func _v241_project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth: float = clampf(p.x, 0.0, 1.0)
	var eased: float = pow(depth, 0.88)
	var near_y: float = arena.end.y - 7.0
	var far_y: float = arena.position.y + 68.0
	var half_width: float = lerpf(arena.size.x * 0.515, arena.size.x * 0.19, eased)
	var camera_sway: float = (float(ball_position.y) - 0.5) * arena.size.x * -0.04
	return Vector2(
		arena.get_center().x + camera_sway + (p.y - 0.5) * 2.0 * half_width,
		lerpf(near_y, far_y, eased)
	)

func _v241_depth_scale(p: Vector2) -> float:
	return lerpf(1.46, 0.57, pow(clampf(p.x, 0.0, 1.0), 0.82))

func _v241_draw_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("020408"), true)
	for i in range(14):
		var t: float = float(i) / 13.0
		var c: Color = Color("101923").lerp(Color("020408"), t)
		draw_rect(Rect2(0.0, float(i) * size.y / 14.0, size.x, size.y / 14.0 + 1.0), c, true)

	var bowl := PackedVector2Array([
		Vector2(-14.0, arena.position.y + 1.0),
		Vector2(size.x + 14.0, arena.position.y + 1.0),
		Vector2(size.x * 0.88, arena.position.y + 78.0),
		Vector2(size.x * 0.12, arena.position.y + 78.0),
	])
	draw_colored_polygon(bowl, Color(0.028, 0.045, 0.062, 0.98))

	for row in range(4):
		var y: float = arena.position.y + 14.0 + float(row) * 12.0
		var count: int = 24 - row * 2
		for i in range(count):
			var x: float = 10.0 + float(i) * (size.x - 20.0) / float(maxi(1, count - 1))
			var a: float = 0.045 + 0.025 * sin(animation_time * 0.85 + float(i) * 1.33 + float(row))
			var c: Color = accent if (i + row) % 10 == 0 else Color(0.72, 0.80, 0.88, 1.0)
			draw_circle(Vector2(x, y), 0.95 if row < 2 else 0.75, Color(c.r, c.g, c.b, a))

	for i in range(7):
		var x: float = 17.0 + float(i) * (size.x - 34.0) / 6.0
		draw_circle(Vector2(x, arena.position.y + 5.0), 2.5, Color(0.90, 0.97, 1.0, 0.24))
		var beam := PackedVector2Array([
			Vector2(x - 3.0, arena.position.y + 7.0),
			Vector2(x + 3.0, arena.position.y + 7.0),
			Vector2(x + 48.0, arena.end.y),
			Vector2(x - 48.0, arena.end.y),
		])
		draw_colored_polygon(beam, Color(accent.r, accent.g, accent.b, 0.009))

	draw_circle(Vector2(size.x * 0.78, arena.position.y + 48.0), size.x * 0.28, Color(accent.r, accent.g, accent.b, 0.030))

func _v241_draw_pitch(arena: Rect2) -> void:
	var near_l: Vector2 = _v241_project_field(Vector2(0.0, 0.0), arena)
	var near_r: Vector2 = _v241_project_field(Vector2(0.0, 1.0), arena)
	var far_l: Vector2 = _v241_project_field(Vector2(1.0, 0.0), arena)
	var far_r: Vector2 = _v241_project_field(Vector2(1.0, 1.0), arena)
	var pitch := PackedVector2Array([near_l, near_r, far_r, far_l])

	var shadow := PackedVector2Array([
		near_l + Vector2(-5.0, 11.0), near_r + Vector2(5.0, 11.0),
		far_r + Vector2(4.0, 7.0), far_l + Vector2(-4.0, 7.0),
	])
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(pitch, Color("06161D"))

	for i in range(10):
		var x0: float = float(i) / 10.0
		var x1: float = float(i + 1) / 10.0
		if i % 2 == 0:
			var band := PackedVector2Array([
				_v241_project_field(Vector2(x0, 0.0), arena), _v241_project_field(Vector2(x0, 1.0), arena),
				_v241_project_field(Vector2(x1, 1.0), arena), _v241_project_field(Vector2(x1, 0.0), arena),
			])
			draw_colored_polygon(band, Color(0.035, 0.13, 0.16, 0.46))

	draw_polyline(PackedVector2Array([near_l, near_r, far_r, far_l, near_l]), Color(accent.r, accent.g, accent.b, 0.42), 2.1)

	# Raised glass walls.
	var wall_h_near: float = 19.0
	var wall_h_far: float = 12.0
	var left_wall := PackedVector2Array([near_l, far_l, far_l - Vector2(0, wall_h_far), near_l - Vector2(0, wall_h_near)])
	var right_wall := PackedVector2Array([near_r, far_r, far_r - Vector2(0, wall_h_far), near_r - Vector2(0, wall_h_near)])
	draw_colored_polygon(left_wall, Color(accent.r, accent.g, accent.b, 0.045))
	draw_colored_polygon(right_wall, Color(accent.r, accent.g, accent.b, 0.045))
	draw_polyline(PackedVector2Array([near_l - Vector2(0, wall_h_near), far_l - Vector2(0, wall_h_far)]), Color(accent.r, accent.g, accent.b, 0.16), 1.1)
	draw_polyline(PackedVector2Array([near_r - Vector2(0, wall_h_near), far_r - Vector2(0, wall_h_far)]), Color(accent.r, accent.g, accent.b, 0.16), 1.1)

	draw_line(_v241_project_field(Vector2(0.5, 0.0), arena), _v241_project_field(Vector2(0.5, 1.0), arena), Color(0.62, 0.82, 0.90, 0.23), 1.5)
	var circle_points := PackedVector2Array()
	for i in range(33):
		var a: float = TAU * float(i) / 32.0
		circle_points.append(_v241_project_field(Vector2(0.5 + cos(a) * 0.095, 0.5 + sin(a) * 0.17), arena))
	draw_polyline(circle_points, Color(0.62, 0.82, 0.90, 0.17), 1.3)

	for p in [Vector2(0.12,0.18),Vector2(0.12,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.88,0.18),Vector2(0.88,0.82)]:
		var s: float = _v241_depth_scale(p)
		var point: Vector2 = _v241_project_field(p, arena)
		draw_circle(point, 7.0 * s, Color(0.95, 0.70, 0.28, 0.055))
		draw_circle(point, 2.9 * s, Color(0.98, 0.74, 0.30, 0.88))
		draw_circle(point, 1.15 * s, Color(1.0, 0.93, 0.66, 0.92))

	_v241_draw_goal(Vector2(0.0, 0.5), arena, true)
	_v241_draw_goal(Vector2(1.0, 0.5), arena, false)

	var board_y: float = near_l.y + 10.0
	draw_line(Vector2(near_l.x + 22.0, board_y), Vector2(near_r.x - 22.0, board_y), Color(accent.r, accent.g, accent.b, 0.13), 3.0)
	draw_string(V25_FONT, Vector2(near_l.x + 28.0, board_y + 13.0), "PERFORMANCE LAB  //  LIVE DRILL", HORIZONTAL_ALIGNMENT_LEFT, near_r.x - near_l.x - 56.0, 7, Color(0.70, 0.82, 0.88, 0.24))

func _v241_draw_goal(pos: Vector2, arena: Rect2, near_goal: bool) -> void:
	var center: Vector2 = _v241_project_field(pos, arena)
	var s: float = _v241_depth_scale(pos)
	var w: float = 104.0 * s
	var h: float = 36.0 * s
	var front_y: float = center.y + (9.0 if near_goal else -8.0)
	var front := Rect2(center.x - w * 0.5, front_y - h * 0.5, w, h)
	var back_size := front.size * Vector2(0.78, 0.80)
	var back_y: float = front.position.y + (12.0 * s if near_goal else -9.0 * s)
	var back := Rect2(Vector2(center.x - back_size.x * 0.5, back_y), back_size)
	draw_rect(back, Color(accent.r, accent.g, accent.b, 0.03), true)
	draw_rect(front, Color(accent.r, accent.g, accent.b, 0.035), true)
	draw_rect(front, Color(accent.r, accent.g, accent.b, 0.40), false, 2.0)
	draw_rect(back, Color(accent.r, accent.g, accent.b, 0.15), false, 1.2)
	for i in range(1, 7):
		var fx: float = front.position.x + front.size.x * float(i) / 7.0
		var bx: float = back.position.x + back.size.x * float(i) / 7.0
		draw_line(Vector2(fx, front.position.y), Vector2(bx, back.position.y), Color(accent.r, accent.g, accent.b, 0.09), 1.0)

func _v241_draw_guides(arena: Rect2) -> void:
	var car: Vector2 = _v241_project_field(car_position, arena)
	var future_t: float = minf(0.999, drill_phase + 0.16)
	var future_car: Vector2 = _v241_project_field(_car_target_for_drill(future_t), arena)
	var car_dir: Vector2 = (future_car - car).normalized()
	draw_dashed_line(car, future_car, Color(accent.r, accent.g, accent.b, 0.36), 2.2, 9.0)
	if car_dir.length() > 0.1:
		var side := Vector2(-car_dir.y, car_dir.x)
		var tip: Vector2 = future_car - car_dir * 3.0
		draw_colored_polygon(PackedVector2Array([tip, tip - car_dir * 10.0 + side * 5.0, tip - car_dir * 10.0 - side * 5.0]), Color(accent.r, accent.g, accent.b, 0.34))

	var ball: Vector2 = _v241_project_field(ball_position, arena) - Vector2(0.0, ball_height * 48.0 * _v241_depth_scale(ball_position))
	var future_pos: Vector2 = _ball_target_for_drill(future_t)
	var future_h: float = _ball_height_for_drill(future_t)
	var future_ball: Vector2 = _v241_project_field(future_pos, arena) - Vector2(0.0, future_h * 48.0 * _v241_depth_scale(future_pos))
	var control: Vector2 = (ball + future_ball) * 0.5 - Vector2(0.0, 38.0 + maxf(ball_height, future_h) * 34.0)
	var previous: Vector2 = ball
	for i in range(1, 25):
		var t: float = float(i) / 24.0
		var a: Vector2 = ball.lerp(control, t)
		var b: Vector2 = control.lerp(future_ball, t)
		var p: Vector2 = a.lerp(b, t)
		var fade: float = lerpf(0.42, 0.15, t)
		draw_line(previous, p, Color(0.94, 0.98, 1.0, fade), 1.8 if i < 13 else 1.4)
		if i % 4 == 0:
			draw_circle(p, 2.0, Color(0.92, 0.98, 1.0, fade * 0.9))
		previous = p

	var target: Vector2 = _v241_project_field(target_position, arena)
	var s: float = _v241_depth_scale(target_position)
	draw_arc(target, 15.0 * s, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.30), 1.7)
	draw_arc(target, 6.5 * s, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.16), 1.2)

func _v241_draw_car(arena: Rect2) -> void:
	var center: Vector2 = _v241_project_field(car_position, arena)
	var next_pos: Vector2 = car_position + (car_velocity.normalized() * 0.05 if car_velocity.length() > 0.02 else Vector2(0.05, 0.0))
	var next: Vector2 = _v241_project_field(next_pos, arena)
	var dir: Vector2 = (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s: float = _v241_depth_scale(car_position) * 1.18

	var shadow := PackedVector2Array()
	for i in range(25):
		var a: float = TAU * float(i) / 24.0
		shadow.append(center + Vector2(cos(a) * 14.0 * s, sin(a) * 6.0 * s) + Vector2(2.0, 4.0 * s))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.30))

	for wheel_offset in [Vector2(-5.5,-8.6), Vector2(6.2,-8.6), Vector2(-5.5,8.6), Vector2(6.2,8.6)]:
		var wp: Vector2 = center + dir * float(wheel_offset.x) * s + side * float(wheel_offset.y) * s
		draw_circle(wp, 3.2 * s, Color(0.012, 0.016, 0.021, 0.98))
		draw_circle(wp, 1.35 * s, Color(0.38, 0.46, 0.54, 0.82))

	var nose: Vector2 = center + dir * 18.0 * s
	var rear: Vector2 = center - dir * 12.5 * s
	var body := PackedVector2Array([
		nose,
		center + dir * 8.0 * s + side * 8.7 * s,
		center - dir * 5.0 * s + side * 8.0 * s,
		rear + side * 5.5 * s,
		rear - side * 5.5 * s,
		center - dir * 5.0 * s - side * 8.0 * s,
		center + dir * 8.0 * s - side * 8.7 * s,
	])
	draw_circle(center, 24.0 * s, Color(accent.r, accent.g, accent.b, 0.07))
	draw_colored_polygon(body, Color(accent.r * 0.34, accent.g * 0.38, accent.b * 0.42, 1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]), Color(accent.r, accent.g, accent.b, 0.98), 2.0)

	var hood := PackedVector2Array([
		center + dir * 15.0 * s + side * 4.6 * s,
		center + dir * 17.0 * s,
		center + dir * 15.0 * s - side * 4.6 * s,
		center + dir * 9.0 * s - side * 5.3 * s,
		center + dir * 9.0 * s + side * 5.3 * s,
	])
	draw_colored_polygon(hood, Color(accent.r * 0.58, accent.g * 0.62, accent.b * 0.66, 0.92))
	var glass := PackedVector2Array([
		center + dir * 8.5 * s + side * 4.4 * s,
		center + dir * 9.0 * s - side * 4.4 * s,
		center - dir * 2.0 * s - side * 5.0 * s,
		center - dir * 2.0 * s + side * 5.0 * s,
	])
	draw_colored_polygon(glass, Color(0.58, 0.80, 0.91, 0.38))
	draw_line(center - dir * 7.8 * s + side * 5.0 * s, center - dir * 7.8 * s - side * 5.0 * s, Color(accent.r, accent.g, accent.b, 0.58), 2.2 * s)

	draw_circle(center + dir * 15.6 * s + side * 4.7 * s, 1.35 * s, Color(0.90, 0.98, 1.0, 0.92))
	draw_circle(center + dir * 15.6 * s - side * 4.7 * s, 1.35 * s, Color(0.90, 0.98, 1.0, 0.92))
	draw_line(rear + side * 3.7 * s, rear - side * 3.7 * s, Color(1.0, 0.24, 0.30, 0.70), 1.7 * s)

	if car_velocity.length() > 0.04:
		for offset in [-2.5, 2.5]:
			var jet: Vector2 = rear + side * float(offset) * s
			draw_line(jet, jet - dir * (14.0 * s), Color(accent.r, accent.g, accent.b, 0.58), 3.0 * s)
			draw_line(jet - dir * (14.0 * s), jet - dir * (20.0 * s), Color(0.90, 0.97, 1.0, 0.20), 1.4 * s)

func _v241_draw_ball(arena: Rect2) -> void:
	var ground: Vector2 = _v241_project_field(ball_position, arena)
	var s: float = _v241_depth_scale(ball_position)
	var lift: float = ball_height * 50.0 * s
	var visual: Vector2 = ground - Vector2(0.0, lift)
	var shadow_scale: float = clampf(1.0 - ball_height * 0.35, 0.55, 1.0)

	var shadow := PackedVector2Array()
	for i in range(25):
		var a: float = TAU * float(i) / 24.0
		shadow.append(ground + Vector2(cos(a) * 9.5 * s * shadow_scale, sin(a) * 4.0 * s * shadow_scale) + Vector2(2.0, 3.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.42))

	draw_line(ground, visual, Color(0.82, 0.93, 1.0, 0.08), 1.0)
	draw_circle(visual, 18.5 * s, Color(0.84, 0.95, 1.0, 0.055))
	draw_circle(visual, 10.4 * s, Color("F5F8FB"))
	draw_arc(visual, 6.3 * s, -0.25, 1.35, 14, Color(0.26, 0.33, 0.40, 0.76), 1.2 * s)
	draw_arc(visual, 5.5 * s, 2.05, 4.15, 14, Color(0.26, 0.33, 0.40, 0.66), 1.1 * s)
	draw_arc(visual, 4.6 * s, 4.45, 5.95, 12, Color(0.26, 0.33, 0.40, 0.52), 1.0 * s)
	draw_circle(visual + Vector2(-2.8, -3.1) * s, 2.1 * s, Color(1.0, 1.0, 1.0, 0.80))
