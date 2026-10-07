class_name VisualStageV25
extends "res://scripts/visual_stage_v243.gd"

const TEAM_CAR: Texture2D = preload("res://assets/game/car_team.svg")
const BALL_TEX: Texture2D = preload("res://assets/game/ball.svg")

func _draw() -> void:
	super._draw()
	if variant not in ["home", "rank"]:
		return

	# Real game assets in the hero instead of another abstract card background.
	var car_center := Vector2(size.x * 0.74, size.y * 0.76)
	var car_size := TEAM_CAR.get_size() * (0.78 if variant == "home" else 0.66)
	var car_angle := -0.18

	# Motion streak and grounding shadow.
	draw_circle(car_center + Vector2(4, 13), 34.0, Color(0, 0, 0, 0.20))
	for i in range(4):
		var offset := float(i) * 12.0
		draw_line(
			car_center - Vector2(38 + offset, -10 + float(i) * 3.0),
			car_center - Vector2(7 + offset * 0.25, -10 + float(i) * 3.0),
			Color(accent.r, accent.g, accent.b, 0.08 - float(i) * 0.012),
			3.0 - float(i) * 0.35
		)

	draw_set_transform(car_center, car_angle, Vector2.ONE)
	draw_texture_rect(TEAM_CAR, Rect2(-car_size * 0.5, car_size), false, Color(1, 1, 1, 0.86 if variant == "home" else 0.68))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var ball_center := Vector2(size.x * 0.88, size.y * 0.59)
	var ball_size := 36.0 if variant == "home" else 31.0
	draw_circle(ball_center + Vector2(2, 5), ball_size * 0.34, Color(0, 0, 0, 0.22))
	draw_texture_rect(BALL_TEX, Rect2(ball_center - Vector2(ball_size, ball_size) * 0.5, Vector2(ball_size, ball_size)), false, Color(1, 1, 1, 0.80))

	# Small ball trajectory makes the scene feel in-motion without visual noise.
	var trail_start := car_center + Vector2(22, -6)
	var previous := trail_start
	for i in range(1, 8):
		var t := float(i) / 7.0
		var mid := trail_start.lerp(ball_center, t) - Vector2(0, sin(t * PI) * 18.0)
		if i % 2 == 0:
			draw_line(previous, mid, Color(0.92, 0.97, 1.0, 0.10), 1.2)
		previous = mid
