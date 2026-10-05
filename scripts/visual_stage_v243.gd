class_name VisualStageV243
extends "res://scripts/visual_stage_v24.gd"

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("04070B"), true)

	# Deep broadcast gradient bands.
	for i in range(12):
		var t := float(i) / 11.0
		var c := Color("0B1118").lerp(Color("04070B"), t)
		draw_rect(Rect2(0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), c, true)

	# Stadium light cones / atmosphere.
	var pulse_alpha := 0.035 + 0.008 * sin(pulse * 1.2)
	var cone_left := PackedVector2Array([
		Vector2(size.x * 0.02, 0),
		Vector2(size.x * 0.30, 0),
		Vector2(size.x * 0.56, size.y),
		Vector2(size.x * 0.15, size.y),
	])
	draw_colored_polygon(cone_left, Color(accent.r, accent.g, accent.b, pulse_alpha * 0.48))
	var cone_right := PackedVector2Array([
		Vector2(size.x * 0.68, 0),
		Vector2(size.x * 0.97, 0),
		Vector2(size.x * 0.86, size.y),
		Vector2(size.x * 0.54, size.y),
	])
	draw_colored_polygon(cone_right, Color(accent.r, accent.g, accent.b, pulse_alpha * 0.38))

	# Distant arena / crowd row.
	for row in range(3):
		var y := size.y * (0.20 + float(row) * 0.045)
		for i in range(18):
			var x := 10.0 + float(i) * (size.x - 20.0) / 17.0
			var a := 0.07 + 0.025 * sin(pulse * 1.5 + float(i) * 0.7 + float(row))
			draw_circle(Vector2(x, y), 1.2, Color(0.78, 0.88, 0.95, a))

	# Perspective field, not a flat card.
	if variant in ["home", "rank"]:
		var field := PackedVector2Array([
			Vector2(size.x * 0.28, size.y * 0.47),
			Vector2(size.x * 0.83, size.y * 0.43),
			Vector2(size.x * 1.04, size.y * 0.98),
			Vector2(size.x * 0.03, size.y * 0.98),
		])
		draw_colored_polygon(field, Color(0.025, 0.095, 0.105, 0.74))
		draw_polyline(field, Color(accent.r, accent.g, accent.b, 0.18), 1.4, true)
		var horizon_y := size.y * 0.47
		for i in range(1, 5):
			var t := float(i) / 5.0
			var y := lerpf(horizon_y, size.y * 0.97, t)
			var left := lerpf(size.x * 0.28, size.x * 0.03, t)
			var right := lerpf(size.x * 0.83, size.x * 1.04, t)
			draw_line(Vector2(left, y), Vector2(right, y), Color(0.72, 0.86, 0.92, 0.055), 1.0)
		for x_ratio in [0.38, 0.50, 0.62, 0.74]:
			draw_line(Vector2(size.x * x_ratio, horizon_y), Vector2(size.x * (0.50 + (x_ratio - 0.50) * 1.9), size.y * 0.97), Color(0.72, 0.86, 0.92, 0.05), 1.0)
		var center := Vector2(size.x * 0.56, size.y * 0.73)
		draw_arc(center, 31.0, 0.0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.11), 1.2)

	# Broadcast slashes anchor the composition.
	var slash := PackedVector2Array([
		Vector2(size.x * 0.78, 0),
		Vector2(size.x * 0.83, 0),
		Vector2(size.x * 0.68, size.y),
		Vector2(size.x * 0.63, size.y),
	])
	draw_colored_polygon(slash, Color(accent.r, accent.g, accent.b, 0.055))

	# Edge treatment and grounding fade.
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r, accent.g, accent.b, 0.22), 1.0)
	draw_rect(Rect2(0, size.y - 70, size.x, 70), Color(0.008, 0.012, 0.018, 0.78), true)
