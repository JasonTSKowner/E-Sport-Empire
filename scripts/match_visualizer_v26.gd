class_name MatchVisualizerV26
extends "res://scripts/match_visualizer_v25.gd"

const V26_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 548.0)

func _project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var eased := pow(depth, 0.78)
	var near_y := arena.end.y - 5.0
	var far_y := arena.position.y + 82.0
	var half_width := lerpf(arena.size.x * 0.555, arena.size.x * 0.145, eased)
	var camera_sway := (float(ball_position.y) - 0.5) * arena.size.x * -0.07
	var screen_y := lerpf(near_y, far_y, eased)
	var screen_x := arena.get_center().x + camera_sway + (p.y - 0.5) * 2.0 * half_width
	return Vector2(screen_x, screen_y)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.66, 0.48, pow(clampf(p.x, 0.0, 1.0), 0.76))

func _draw_broadcast_backdrop(arena: Rect2) -> void:
	super._draw_broadcast_backdrop(arena)
	var horizon_y := arena.position.y + 72.0
	draw_rect(Rect2(0.0, horizon_y - 2.0, size.x, 4.0), Color(0.62, 0.86, 0.96, 0.035), true)
	for i in range(22):
		var x := 6.0 + float(i) * (size.x - 12.0) / 21.0
		var c := OUR_COLOR if i % 8 == 1 else THEIR_COLOR if i % 11 == 4 else Color(0.75, 0.84, 0.91, 1.0)
		draw_rect(Rect2(x, horizon_y + 8.0 + float(i % 3) * 2.0, 7.0, 1.3), Color(c.r, c.g, c.b, 0.12), true)
	var top_fade := PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, 72), Vector2(0, 48)])
	draw_colored_polygon(top_fade, Color(0.0, 0.0, 0.0, 0.16))
	draw_rect(Rect2(0, 0, 8, size.y), Color(0,0,0,0.20), true)
	draw_rect(Rect2(size.x - 8, 0, 8, size.y), Color(0,0,0,0.20), true)

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center := _project_field(p, arena)
	var next_p := p + (velocity.normalized() * 0.055 if velocity.length() > 0.02 else Vector2(0.055, 0.0))
	var next := _project_field(next_p, arena)
	var dir := (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s := _depth_scale(p) * (1.26 if active else 1.12)
	var shadow := PackedVector2Array()
	for i in range(29):
		var a := TAU * float(i) / 28.0
		shadow.append(center + Vector2(cos(a) * 15.5 * s, sin(a) * 6.2 * s) + Vector2(2.0, 5.0 * s))
	draw_colored_polygon(shadow, Color(0,0,0,0.38))
	if velocity.length() > 0.10:
		for lane in [-1.0, 1.0]:
			var streak_from: Vector2 = center - dir * 14.0 * s + side * float(lane) * 7.5 * s
			draw_line(streak_from, streak_from - dir * 23.0 * s, Color(color.r,color.g,color.b,0.12), 2.0 * s)
	for wheel_offset in [Vector2(-6.5,-9.5), Vector2(7.0,-9.5), Vector2(-6.5,9.5), Vector2(7.0,9.5)]:
		var wp: Vector2 = center + dir * wheel_offset.x * s + side * wheel_offset.y * s
		draw_circle(wp, 3.8 * s, Color(0.008,0.011,0.015,0.99))
		draw_circle(wp, 2.15 * s, Color(0.16,0.20,0.25,0.98))
		draw_circle(wp, 0.85 * s, Color(0.72,0.82,0.88,0.66))
	var nose := center + dir * 20.0 * s
	var rear := center - dir * 13.0 * s
	var body := PackedVector2Array([nose,center + dir * 12.0 * s + side * 7.4 * s,center + dir * 5.0 * s + side * 9.6 * s,center - dir * 6.0 * s + side * 8.2 * s,rear + side * 5.6 * s,rear - side * 5.6 * s,center - dir * 6.0 * s - side * 8.2 * s,center + dir * 5.0 * s - side * 9.6 * s,center + dir * 12.0 * s - side * 7.4 * s])
	if active:
		draw_circle(center, 28.0 * s, Color(color.r,color.g,color.b,0.060))
		draw_arc(center, 24.0 * s, -2.5, -0.5, 22, Color(color.r,color.g,color.b,0.34), 1.6)
	elif support:
		draw_arc(center, 22.0 * s, 0.0, TAU, 30, Color(color.r,color.g,color.b,0.20), 1.3)
	draw_colored_polygon(body, Color(color.r * 0.24, color.g * 0.29, color.b * 0.33, 1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[7],body[8],body[0]]), Color(color.r,color.g,color.b,0.96), 2.1)
	var upper := PackedVector2Array([center + dir * 11.0 * s + side * 5.2 * s,center + dir * 12.2 * s - side * 5.2 * s,center + dir * 1.0 * s - side * 6.0 * s,center - dir * 4.0 * s - side * 4.7 * s,center - dir * 4.0 * s + side * 4.7 * s,center + dir * 1.0 * s + side * 6.0 * s])
	draw_colored_polygon(upper, Color(color.r * 0.43, color.g * 0.50, color.b * 0.55, 0.96))
	var glass := PackedVector2Array([center + dir * 8.5 * s + side * 4.3 * s,center + dir * 9.0 * s - side * 4.3 * s,center + dir * 0.6 * s - side * 4.8 * s,center + dir * 0.6 * s + side * 4.8 * s])
	draw_colored_polygon(glass, Color(0.58,0.80,0.91,0.46))
	draw_line(center + dir * 9.0 * s, nose - dir * 2.0 * s, Color(0.86,0.95,1.0,0.20), 1.0 * s)
	draw_line(rear + side * 7.0 * s, rear - side * 7.0 * s, Color(color.r,color.g,color.b,0.72), 2.1 * s)
	draw_line(rear + dir * 2.0 * s + side * 5.5 * s, rear + dir * 2.0 * s - side * 5.5 * s, Color(1.0,0.20,0.28,0.68), 1.8 * s)
	draw_circle(center + dir * 16.3 * s + side * 4.9 * s, 1.45 * s, Color(0.92,0.99,1.0,0.96))
	draw_circle(center + dir * 16.3 * s - side * 4.9 * s, 1.45 * s, Color(0.92,0.99,1.0,0.96))
	if velocity.length() > 0.07:
		var boost_len := (20.0 if active else 13.0) * s
		for offset in [-2.8, 2.8]:
			var jet := rear + side * float(offset) * s
			draw_line(jet, jet - dir * boost_len, Color(color.r,color.g,color.b,0.68), 3.3 * s)
			draw_line(jet - dir * boost_len, jet - dir * (boost_len + 7.0 * s), Color(0.92,0.98,1.0,0.24), 1.4 * s)
	if not role.is_empty():
		var role_alpha := 0.98 if active else 0.70 if support else 0.36
		draw_string(V26_FONT, center + Vector2(-25.0, -28.0 * s), role, HORIZONTAL_ALIGNMENT_CENTER, 50.0, 9, Color(0.92,0.98,1.0,role_alpha))

func _draw_projected_ball(arena: Rect2) -> void:
	var ground := _project_field(ball_position, arena)
	var s := _depth_scale(ball_position)
	var lift := ball_height * 54.0 * s
	var visual := ground - Vector2(0.0, lift)
	var shadow_scale := clampf(1.0 - ball_height * 0.38, 0.52, 1.0)
	var shadow := PackedVector2Array()
	for i in range(29):
		var a := TAU * float(i) / 28.0
		shadow.append(ground + Vector2(cos(a) * 10.5 * s * shadow_scale, sin(a) * 4.2 * s * shadow_scale) + Vector2(2.0,3.5))
	draw_colored_polygon(shadow, Color(0,0,0,0.46))
	draw_line(ground, visual, Color(0.82,0.94,1.0,0.09), 1.0)
	draw_circle(visual, 21.0 * s, Color(0.82,0.95,1.0,0.050))
	draw_circle(visual, 11.2 * s, Color("F6F8FB"))
	draw_arc(visual, 6.9 * s, -0.3, 1.35, 16, Color(0.21,0.27,0.34,0.78), 1.3 * s)
	draw_arc(visual, 5.9 * s, 2.0, 4.15, 16, Color(0.21,0.27,0.34,0.68), 1.2 * s)
	draw_arc(visual, 5.0 * s, 4.4, 6.0, 14, Color(0.21,0.27,0.34,0.56), 1.0 * s)
	draw_circle(visual + Vector2(-3.0,-3.4) * s, 2.25 * s, Color(1,1,1,0.86))
