extends Control

var time_value := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()

func _draw() -> void:
	var s := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color("05080D"), true)

	# Vertical editorial gradient bands.
	for i in range(16):
		var t := float(i) / 15.0
		var c := Color("0B1219").lerp(Color("05080D"), t)
		draw_rect(Rect2(0, s.y * t, s.x, s.y / 15.0 + 1), c, true)

	# Stadium ceiling light line.
	var light_y := 66.0
	for i in range(9):
		var x := 18.0 + float(i) * (s.x - 36.0) / 8.0
		var pulse := 0.12 + 0.035 * sin(time_value * 0.7 + float(i) * 0.45)
		draw_circle(Vector2(x, light_y), 2.0, Color(0.84, 0.93, 1.0, pulse))
		draw_line(Vector2(x, light_y + 4), Vector2(x - 14, light_y + 40), Color(0.62, 0.83, 0.94, pulse * 0.15), 1.0)

	# Large brand glow and off-axis composition.
	var breathe := 0.038 + 0.006 * sin(time_value * 0.45)
	draw_circle(Vector2(s.x * 0.88, s.y * 0.20), s.x * 0.50, Color(0.20, 0.39, 0.49, breathe))
	draw_circle(Vector2(s.x * 0.05, s.y * 0.72), s.x * 0.58, Color(0.08, 0.18, 0.24, 0.045))

	# Broadcast slash geometry.
	var slash1 := PackedVector2Array([
		Vector2(s.x * 0.58, 0), Vector2(s.x * 0.70, 0),
		Vector2(s.x * 0.39, s.y), Vector2(s.x * 0.29, s.y)
	])
	draw_colored_polygon(slash1, Color(0.40, 0.70, 0.82, 0.018))
	var slash2 := PackedVector2Array([
		Vector2(s.x * 0.78, 0), Vector2(s.x * 0.85, 0),
		Vector2(s.x * 0.58, s.y), Vector2(s.x * 0.52, s.y)
	])
	draw_colored_polygon(slash2, Color(1, 1, 1, 0.012))

	# Perspective floor / arena horizon fills otherwise dead lower space.
	var horizon := s.y * 0.62
	draw_line(Vector2(0, horizon), Vector2(s.x, horizon), Color(0.65, 0.82, 0.90, 0.035), 1.0)
	for i in range(1, 7):
		var y := horizon + (s.y - horizon) * pow(float(i) / 6.0, 1.65)
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(0.65, 0.82, 0.90, 0.022), 1.0)
	for i in range(7):
		var x := -s.x * 0.08 + float(i) * s.x * 0.19
		draw_line(Vector2(s.x * 0.50, horizon), Vector2(x, s.y), Color(0.65, 0.82, 0.90, 0.020), 1.0)

	# Sparse precision marks.
	for i in range(7):
		var y := 118.0 + float(i) * 92.0
		if y < s.y:
			draw_line(Vector2(14, y), Vector2(25, y), Color(0.72, 0.80, 0.86, 0.07), 1.0)
			draw_circle(Vector2(s.x - 20, y + 24), 1.0, Color(0.72, 0.80, 0.86, 0.06))

	# Slow broadcast sweep.
	var sweep := fmod(time_value * 9.0, s.y + 280.0) - 140.0
	draw_line(Vector2(-40, sweep), Vector2(s.x + 40, sweep - 44), Color(0.45, 0.86, 0.96, 0.020), 1.0)

	# Soft vignette bars.
	draw_rect(Rect2(0, 0, s.x, 18), Color(0, 0, 0, 0.20), true)
	draw_rect(Rect2(0, s.y - 90, s.x, 90), Color(0, 0, 0, 0.13), true)
