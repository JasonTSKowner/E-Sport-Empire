class_name TrainingVisualizerV26
extends "res://scripts/training_visualizer_v25.gd"

const V26_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 520.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 520.0)

func _v241_project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var eased := pow(depth, 0.78)
	var near_y := arena.end.y - 5.0
	var far_y := arena.position.y + 80.0
	var half_width := lerpf(arena.size.x * 0.555, arena.size.x * 0.15, eased)
	var camera_sway := (float(ball_position.y) - 0.5) * arena.size.x * -0.065
	return Vector2(
		arena.get_center().x + camera_sway + (p.y - 0.5) * 2.0 * half_width,
		lerpf(near_y, far_y, eased)
	)

func _v241_depth_scale(p: Vector2) -> float:
	return lerpf(1.62, 0.50, pow(clampf(p.x, 0.0, 1.0), 0.76))

func _v241_draw_backdrop(arena: Rect2) -> void:
	super._v241_draw_backdrop(arena)
	var horizon_y := arena.position.y + 70.0
	for i in range(20):
		var x := 8.0 + float(i) * (size.x - 16.0) / 19.0
		var a := 0.07 + 0.035 * sin(animation_time * 0.9 + float(i) * 1.21)
		draw_rect(Rect2(x, horizon_y + float(i % 2) * 2.0, 8.0, 1.4), Color(accent.r,accent.g,accent.b,a), true)
	draw_rect(Rect2(0, 0, 8, size.y), Color(0,0,0,0.20), true)
	draw_rect(Rect2(size.x - 8, 0, 8, size.y), Color(0,0,0,0.20), true)

func _v241_draw_car(arena: Rect2) -> void:
	super._v241_draw_car(arena)
	var center := _v241_project_field(car_position, arena)
	var next_pos := car_position + (car_velocity.normalized() * 0.055 if car_velocity.length() > 0.02 else Vector2(0.055, 0.0))
	var next := _v241_project_field(next_pos, arena)
	var dir := (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s := _v241_depth_scale(car_position) * 1.20
	draw_line(center + dir * 8.0 * s, center + dir * 16.0 * s, Color(0.92,0.98,1.0,0.20), 1.1 * s)
	draw_line(center - dir * 8.5 * s + side * 6.0 * s, center - dir * 8.5 * s - side * 6.0 * s, Color(accent.r,accent.g,accent.b,0.64), 2.0 * s)
	for wheel_offset in [Vector2(-6.0,-9.0), Vector2(6.5,-9.0), Vector2(-6.0,9.0), Vector2(6.5,9.0)]:
		var wp: Vector2 = center + dir * wheel_offset.x * s + side * wheel_offset.y * s
		draw_circle(wp, 1.1 * s, Color(0.76,0.84,0.90,0.66))
	if car_velocity.length() > 0.10:
		for lane in [-1.0, 1.0]:
			var streak: Vector2 = center - dir * 14.0 * s + side * float(lane) * 7.0 * s
			draw_line(streak, streak - dir * 22.0 * s, Color(accent.r,accent.g,accent.b,0.13), 2.0 * s)

func _v241_draw_ball(arena: Rect2) -> void:
	super._v241_draw_ball(arena)
	var ground := _v241_project_field(ball_position, arena)
	var s := _v241_depth_scale(ball_position)
	var visual := ground - Vector2(0.0, ball_height * 50.0 * s)
	draw_arc(visual, 15.0 * s, -0.45, 1.1, 16, Color(1.0,1.0,1.0,0.10), 1.0 * s)

func _v241_draw_header() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(V26_FONT, Vector2(12, 24), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 128, 15, Color(0.94,0.97,1.0,0.96))
	draw_string(V26_FONT, Vector2(12, 43), "%s  ·  %s" % [category, step_label], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.60,0.72,0.82,0.84))
	draw_string(V26_FONT, Vector2(size.x - 116.0, 24.0), "LIVE DRILL", HORIZONTAL_ALIGNMENT_RIGHT, 104.0, 7, Color(accent.r,accent.g,accent.b,0.72))
	var ratio := float(focus_remaining) / float(maxi(1, focus_limit))
	draw_rect(Rect2(12, 50, size.x - 24, 3), Color(1,1,1,0.06), true)
	draw_rect(Rect2(12, 50, (size.x - 24) * ratio, 3), accent, true)
