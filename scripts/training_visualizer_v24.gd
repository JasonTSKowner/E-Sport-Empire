class_name TrainingVisualizerV24
extends "res://scripts/training_visualizer_v23.gd"

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 388.0)


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 388.0)


func _draw() -> void:
	var arena := Rect2(Vector2(8, 64), Vector2(maxf(1.0, size.x - 16), maxf(1.0, size.y - 88)))
	_draw_training_backdrop(arena)
	_draw_training_field(arena)
	_draw_training_path(arena)
	_draw_training_car(_field_point(car_position, arena))
	_draw_training_ball(arena)
	_draw_training_header()


func _draw_training_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("04070B"), true)
	for i in range(10):
		var t := float(i) / 9.0
		var c := Color("0C1219").lerp(Color("05080C"), t)
		draw_rect(Rect2(0, float(i) * size.y / 10.0, size.x, size.y / 10.0 + 1.0), c, true)
	var glow := 0.030 + sin(animation_time * 0.8) * 0.007
	draw_circle(Vector2(size.x * 0.74, 42), size.x * 0.34, Color(accent.r,accent.g,accent.b,glow))
	for i in range(7):
		var x := 18.0 + float(i) * (size.x - 36.0) / 6.0
		draw_circle(Vector2(x, 56), 1.7, Color(0.90,0.95,1.0,0.16))


func _draw_training_field(arena: Rect2) -> void:
	draw_rect(arena.grow(7), Color("0C1218"), true)
	draw_rect(arena.grow(5), Color(accent.r,accent.g,accent.b,0.10), false, 1.3)
	draw_rect(arena, Color("07131A"), true)

	var stripe := arena.size.x / 8.0
	for i in range(8):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(float(i) * stripe, 0), Vector2(stripe, arena.size.y)), Color(0.05,0.13,0.16,0.50), true)

	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), Color(0.52,0.70,0.80,0.22), 1.3)
	draw_arc(center, arena.size.y * 0.17, 0.0, TAU, 40, Color(0.52,0.70,0.80,0.17), 1.2)

	for p in [Vector2(0.15,0.20),Vector2(0.15,0.80),Vector2(0.38,0.34),Vector2(0.38,0.66),Vector2(0.62,0.34),Vector2(0.62,0.66),Vector2(0.85,0.20),Vector2(0.85,0.80)]:
		var point := _field_point(p, arena)
		draw_circle(point, 5.4, Color(0.90,0.72,0.40,0.07))
		draw_circle(point, 2.0, Color(0.91,0.73,0.42,0.76))

	var goal_h := arena.size.y * 0.36
	for left in [true, false]:
		var x := arena.position.x - 7.0 if left else arena.end.x - 2.0
		var goal := Rect2(x, center.y - goal_h * 0.5, 9, goal_h)
		draw_rect(goal, Color(accent.r,accent.g,accent.b,0.06), true)
		draw_rect(goal, Color(accent.r,accent.g,accent.b,0.27), false, 1.6)


func _draw_training_path(arena: Rect2) -> void:
	var car := _field_point(car_position, arena)
	var future_car := _field_point(_car_target_for_drill(minf(0.999, drill_phase + 0.14)), arena)
	draw_dashed_line(car, future_car, Color(accent.r,accent.g,accent.b,0.24), 1.8, 8.0)

	var ball := _field_point(ball_position, arena) - Vector2(0, ball_height * 24.0)
	var future_t := minf(0.999, drill_phase + 0.14)
	var future_ball_height := _ball_height_for_drill(future_t)
	var future_ball := _field_point(_ball_target_for_drill(future_t), arena) - Vector2(0, future_ball_height * 24.0)
	var control := (ball + future_ball) * 0.5 - Vector2(0, 25.0 + maxf(ball_height, future_ball_height) * 22.0)
	var previous := ball
	for i in range(1, 11):
		var t := float(i) / 10.0
		var a := ball.lerp(control, t)
		var b := control.lerp(future_ball, t)
		var p := a.lerp(b, t)
		if i % 2 == 0:
			draw_line(previous, p, Color(0.93,0.97,1.0,0.22), 1.5)
		previous = p

	# Target zone, only one strong target instead of many debug guides.
	var target := _field_point(target_position, arena)
	draw_arc(target, 19.0, 0.0, TAU, 32, Color(accent.r,accent.g,accent.b,0.24), 1.7)
	draw_arc(target, 10.0, 0.0, TAU, 32, Color(accent.r,accent.g,accent.b,0.12), 1.2)


func _draw_training_car(center: Vector2) -> void:
	var dir := car_velocity.normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	var body := PackedVector2Array([
		center + dir * 17.0,
		center + dir * 4.0 + side * 8.5,
		center - dir * 11.0 + side * 6.0,
		center - dir * 11.0 - side * 6.0,
		center + dir * 4.0 - side * 8.5,
	])
	draw_circle(center, 19.0, Color(accent.r,accent.g,accent.b,0.07))
	draw_colored_polygon(body, Color(accent.r*0.55,accent.g*0.55,accent.b*0.55,1.0))
	draw_polyline(body, Color(accent.r,accent.g,accent.b,0.95), 1.8, true)
	draw_line(center+dir*2.0+side*4.0, center+dir*8.0+side*2.5, Color(0.92,0.97,1.0,0.50), 2.0)
	draw_line(center+dir*2.0-side*4.0, center+dir*8.0-side*2.5, Color(0.92,0.97,1.0,0.50), 2.0)
	if car_velocity.length() > 0.04:
		var rear := center - dir * 12.0
		draw_line(rear, rear-dir*10.0, Color(accent.r,accent.g,accent.b,0.46), 3.2)


func _draw_training_ball(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.18
		draw_circle(_field_point(ball_trail[i], arena), 3.8, Color(0.95,0.98,1.0,alpha))
	var ground := _field_point(ball_position, arena)
	var visual := ground - Vector2(0, ball_height * 24.0)
	draw_circle(ground + Vector2(3,5), 7.0-ball_height*1.8, Color(0,0,0,0.34))
	draw_circle(visual, 15.0, Color(0.86,0.95,1.0,0.05))
	draw_circle(visual, 8.2, Color("F4F7FB"))
	draw_circle(visual+Vector2(-2,-2), 2.3, Color("AAB7C8"))


func _draw_training_header() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(FONT, Vector2(12, 24), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color(0.94,0.97,1.0,0.96))
	draw_string(FONT, Vector2(12, 43), "%s  ·  %s" % [category, step_label], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.60,0.72,0.82,0.84))

	var focus_ratio := float(focus_remaining) / float(maxi(1, focus_limit))
	draw_rect(Rect2(12, 50, size.x - 24, 3), Color(1,1,1,0.06), true)
	draw_rect(Rect2(12, 50, (size.x - 24) * focus_ratio, 3), accent, true)

	var footer := "FOKUS %d/%d   ·   MÜDIGKEIT %d" % [focus_remaining, focus_limit, fatigue]
	draw_string(FONT, Vector2(12, size.y - 9), footer, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.62,0.72,0.80,0.70))
