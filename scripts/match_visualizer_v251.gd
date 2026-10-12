class_name MatchVisualizerV251
extends "res://scripts/match_visualizer_v25.gd"

const V251_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 520.0)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.62, 0.52, pow(clampf(p.x, 0.0, 1.0), 0.80))

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center: Vector2 = _project_field(p, arena)
	var next_p: Vector2 = p + (velocity.normalized() * 0.05 if velocity.length() > 0.02 else Vector2(0.05, 0.0))
	var next: Vector2 = _project_field(next_p, arena)
	var dir: Vector2 = (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s: float = _depth_scale(p)

	# Ground shadow anchors the car to the pitch.
	var shadow_center := center + Vector2(3.0 * s, 5.5 * s)
	var shadow := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		shadow.append(shadow_center + Vector2(cos(a) * 17.0 * s, sin(a) * 6.2 * s))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.34))

	if active:
		draw_circle(center, 27.0 * s, Color(color.r, color.g, color.b, 0.055))
		draw_arc(center, 23.0 * s, 0, TAU, 36, Color(color.r, color.g, color.b, 0.28), 1.4 * s)
	elif support:
		draw_arc(center, 19.0 * s, 0, TAU, 32, Color(color.r, color.g, color.b, 0.18), 1.2 * s)

	# Four wheels sit under the body and sell the car silhouette.
	var wheel_offsets := [Vector2(-7,-7), Vector2(-7,7), Vector2(8,-7), Vector2(8,7)]
	for off in wheel_offsets:
		var wp := center + dir * off.x * s + side * off.y * s
		draw_circle(wp, 3.5 * s, Color("07090D"))
		draw_circle(wp, 2.0 * s, Color("303945"))

	# Lower chassis.
	var chassis := PackedVector2Array([
		center + dir * 18.0 * s,
		center + dir * 8.0 * s + side * 9.0 * s,
		center - dir * 12.0 * s + side * 8.0 * s,
		center - dir * 15.0 * s,
		center - dir * 12.0 * s - side * 8.0 * s,
		center + dir * 8.0 * s - side * 9.0 * s,
	])
	var body_dark := Color(color.r * 0.34, color.g * 0.34, color.b * 0.34, 1.0)
	var body_mid := Color(color.r * 0.64, color.g * 0.64, color.b * 0.64, 1.0)
	draw_colored_polygon(chassis, body_dark)
	draw_polyline(PackedVector2Array([chassis[0],chassis[1],chassis[2],chassis[3],chassis[4],chassis[5],chassis[0]]), Color(color.r,color.g,color.b,0.94), 1.6 * s)

	# Raised roof/cabin.
	var cabin_center := center + dir * 2.0 * s - Vector2(0, 4.0 * s)
	var cabin := PackedVector2Array([
		cabin_center + dir * 8.0 * s,
		cabin_center + side * 5.8 * s,
		cabin_center - dir * 7.0 * s + side * 4.6 * s,
		cabin_center - dir * 7.0 * s - side * 4.6 * s,
		cabin_center - side * 5.8 * s,
	])
	draw_colored_polygon(cabin, body_mid)
	draw_polyline(PackedVector2Array([cabin[0],cabin[1],cabin[2],cabin[3],cabin[4],cabin[0]]), Color(0.88,0.95,1.0,0.26), 1.0 * s)

	# Windshield + lights.
	var glass_a := cabin_center + dir * 5.0 * s + side * 4.0 * s
	var glass_b := cabin_center + dir * 5.0 * s - side * 4.0 * s
	draw_line(glass_a, glass_b, Color(0.76,0.90,1.0,0.42), 2.3 * s)
	var front := center + dir * 14.0 * s
	draw_circle(front + side * 4.0 * s, 1.6 * s, Color(0.92,0.97,1.0,0.86))
	draw_circle(front - side * 4.0 * s, 1.6 * s, Color(0.92,0.97,1.0,0.86))

	# Boost plume uses multiple layers instead of one line.
	if velocity.length() > 0.055:
		var rear := center - dir * 15.0 * s
		var plume := 14.0 * s if active else 10.0 * s
		draw_line(rear, rear - dir * plume, Color(color.r,color.g,color.b,0.20), 7.0 * s)
		draw_line(rear, rear - dir * plume * 1.18, Color(color.r,color.g,color.b,0.48), 3.2 * s)
		draw_line(rear, rear - dir * plume * 0.78, Color(0.95,0.98,1.0,0.55), 1.3 * s)

	if not role.is_empty():
		var role_alpha := 0.98 if active else 0.76 if support else 0.40
		var tag_w := 42.0 * s
		var tag_pos := center + Vector2(-tag_w * 0.5, -28.0 * s)
		draw_rect(Rect2(tag_pos, Vector2(tag_w, 13.0 * s)), Color(0.015,0.025,0.035,0.80), true)
		draw_rect(Rect2(tag_pos, Vector2(tag_w, 13.0 * s)), Color(color.r,color.g,color.b,0.26), false, 1.0)
		draw_string(V251_FONT, tag_pos + Vector2(0, 9.5 * s), role, HORIZONTAL_ALIGNMENT_CENTER, tag_w, maxi(6, int(8.0 * s)), Color(0.92,0.97,1.0,role_alpha))

func _draw_projected_ball(arena: Rect2) -> void:
	var ground: Vector2 = _project_field(ball_position, arena)
	var s: float = _depth_scale(ball_position)
	var lift: float = ball_height * 58.0 * s
	var visual := ground - Vector2(0.0, lift)

	# Height line makes aerials instantly readable.
	if ball_height > 0.10:
		draw_line(ground, visual, Color(0.78,0.90,0.98,0.10), maxf(1.0, 1.1 * s))
		draw_circle(ground, 10.0 * s, Color(0,0,0,0.12))
		draw_circle(ground, 5.2 * s, Color(0,0,0,0.28))
	else:
		draw_circle(ground + Vector2(2.5,4.0) * s, 7.0 * s, Color(0,0,0,0.30))

	var radius := 9.2 * s
	draw_circle(visual, radius * 1.9, Color(0.82,0.94,1.0,0.04))
	draw_circle(visual, radius, Color("F1F4F7"))
	# Soccer-ball panel hints.
	var panel_color := Color("8794A4")
	var panel_center := visual + Vector2(-1.0,-1.5) * s
	draw_circle(panel_center, 2.6 * s, panel_color)
	for a in [0.0, TAU/3.0, 2.0*TAU/3.0]:
		var p := visual + Vector2(cos(a), sin(a)) * radius * 0.58
		draw_circle(p, 1.5 * s, Color(0.55,0.60,0.67,0.72))
	# Highlight moves slightly with time for a polished broadcast feel.
	var sparkle := 0.66 + 0.16 * sin(time_alive * 2.1)
	draw_circle(visual + Vector2(-radius * 0.34, -radius * 0.38), 1.8 * s, Color(1,1,1,sparkle))
