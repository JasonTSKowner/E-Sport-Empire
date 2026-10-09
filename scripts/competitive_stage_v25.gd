class_name CompetitiveStageV25
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var time_alive := 0.0

func configure(color: Color, stage_variant: String = "home") -> CompetitiveStageV25:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = 652.0 if variant == "home" else 570.0
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	time_alive += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("030609"), true)

	# Deep broadcast gradient.
	for i in range(14):
		var t := float(i) / 13.0
		var band := Color("101720").lerp(Color("030609"), t)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 13.0 + 2.0), band, true)

	# Arena crowd and floodlights.
	var horizon := size.y * 0.31
	var bowl := PackedVector2Array([
		Vector2(0, horizon - 72), Vector2(size.x, horizon - 72),
		Vector2(size.x * 0.93, horizon + 42), Vector2(size.x * 0.07, horizon + 42),
	])
	draw_colored_polygon(bowl, Color(0.04, 0.052, 0.067, 0.92))
	for row in range(5):
		var y := horizon - 52.0 + float(row) * 19.0
		var count := 27 - row * 2
		for index in range(count):
			var x := 10.0 + float(index) * (size.x - 20.0) / float(maxi(1, count - 1))
			var bright := 0.08 + 0.035 * sin(time_alive * 0.65 + float(index) * 1.4 + float(row))
			var c := accent if (index + row * 3) % 13 == 0 else Color(0.72, 0.79, 0.88, 1.0)
			draw_circle(Vector2(x, y), 1.05, Color(c.r, c.g, c.b, bright))

	for index in range(6):
		var light_x := 20.0 + float(index) * (size.x - 40.0) / 5.0
		draw_circle(Vector2(light_x, horizon - 64.0), 2.4, Color(0.94, 0.98, 1.0, 0.34))
		var beam := PackedVector2Array([
			Vector2(light_x - 5, horizon - 60), Vector2(light_x + 5, horizon - 60),
			Vector2(light_x + 92, size.y), Vector2(light_x - 92, size.y),
		])
		draw_colored_polygon(beam, Color(accent.r, accent.g, accent.b, 0.007))

	# Perspective pitch anchors the screen in a game world instead of a card.
	var near_left := Vector2(10, size.y - 16)
	var near_right := Vector2(size.x - 10, size.y - 16)
	var far_left := Vector2(size.x * 0.30, horizon + 24)
	var far_right := Vector2(size.x * 0.70, horizon + 24)
	var field := PackedVector2Array([near_left, near_right, far_right, far_left])
	draw_colored_polygon(field, Color("06151B"))

	for index in range(8):
		var t0 := float(index) / 8.0
		var t1 := float(index + 1) / 8.0
		if index % 2 == 0:
			var left0 := near_left.lerp(far_left, t0)
			var right0 := near_right.lerp(far_right, t0)
			var left1 := near_left.lerp(far_left, t1)
			var right1 := near_right.lerp(far_right, t1)
			draw_colored_polygon(PackedVector2Array([left0, right0, right1, left1]), Color(0.03, 0.11, 0.14, 0.48))

	for index in range(1, 5):
		var t := float(index) / 5.0
		draw_line(near_left.lerp(far_left, t), near_right.lerp(far_right, t), Color(0.60, 0.76, 0.84, 0.075), 1.0)

	var center_near := (near_left + near_right) * 0.5
	var center_far := (far_left + far_right) * 0.5
	draw_line(center_near, center_far, Color(0.60, 0.78, 0.88, 0.12), 1.2)
	var circle_center := center_near.lerp(center_far, 0.58)
	draw_arc(circle_center, 34.0, 0, TAU, 42, Color(0.60, 0.78, 0.88, 0.10), 1.2)

	# Rank halo / broadcast light on the right.
	var halo_center := Vector2(size.x * 0.76, size.y * (0.25 if variant == "home" else 0.30))
	var pulse := 0.5 + 0.5 * sin(time_alive * 1.1)
	for ring in range(4):
		var radius := 62.0 + float(ring) * 23.0
		draw_arc(halo_center, radius, -1.9, 1.7, 54, Color(accent.r, accent.g, accent.b, 0.055 + pulse * 0.012 - float(ring) * 0.008), 1.2)
	draw_circle(halo_center, 94.0, Color(accent.r, accent.g, accent.b, 0.025))

	# Clean broadcast framing, no floating card border.
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r, accent.g, accent.b, 0.28), 1.0)
	draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(1, 1, 1, 0.045), 1.0)
