class_name PremiumStageV25
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "home") -> PremiumStageV25:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = _height_for_variant(stage_variant)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_process(true)
	queue_redraw()
	return self

func _height_for_variant(value: String) -> float:
	match value:
		"home": return 382.0
		"rank": return 310.0
		"player": return 292.0
		"scout": return 300.0
		"club": return 318.0
	return 260.0

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_draw_gradient(rect)
	_draw_atmosphere(rect)
	match variant:
		"home", "rank": _draw_arena(rect)
		"player", "scout": _draw_player_backdrop(rect)
		"club": _draw_club_backdrop(rect)
	_draw_editorial_frame(rect)

func _draw_gradient(rect: Rect2) -> void:
	for i in range(18):
		var t := float(i) / 17.0
		var top := Color("0B1118")
		var bottom := Color("020408")
		var c := top.lerp(bottom, t)
		c = c.lerp(Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 1.0), (1.0 - t) * 0.055)
		draw_rect(Rect2(0, float(i) * rect.size.y / 18.0, rect.size.x, rect.size.y / 18.0 + 1.0), c, true)

func _draw_atmosphere(rect: Rect2) -> void:
	var breathe := 0.025 + sin(pulse * 0.85) * 0.006
	draw_circle(Vector2(rect.size.x * 0.82, rect.size.y * 0.16), rect.size.x * 0.46, Color(accent.r, accent.g, accent.b, breathe))
	draw_circle(Vector2(rect.size.x * 0.08, rect.size.y * 0.90), rect.size.x * 0.52, Color(accent.r, accent.g, accent.b, 0.015))
	for i in range(7):
		var x := 18.0 + float(i) * (rect.size.x - 36.0) / 6.0
		draw_circle(Vector2(x, 12), 2.3, Color(0.90, 0.96, 1.0, 0.16))
		var beam := PackedVector2Array([
			Vector2(x - 3, 15), Vector2(x + 3, 15),
			Vector2(x + 58, rect.size.y), Vector2(x - 58, rect.size.y),
		])
		draw_colored_polygon(beam, Color(accent.r, accent.g, accent.b, 0.007))

func _draw_arena(rect: Rect2) -> void:
	var horizon := rect.size.y * 0.47
	for row in range(4):
		var y := horizon - 40.0 + float(row) * 10.0
		var count := 24 - row * 2
		for i in range(count):
			var x := 10.0 + float(i) * (rect.size.x - 20.0) / float(maxi(1, count - 1))
			var a := 0.045 + 0.02 * sin(pulse * 1.2 + float(i) * 0.91 + float(row))
			draw_circle(Vector2(x, y), 0.9, Color(0.80, 0.88, 0.94, a))

	var near_l := Vector2(rect.size.x * 0.04, rect.size.y * 0.97)
	var near_r := Vector2(rect.size.x * 0.96, rect.size.y * 0.97)
	var far_l := Vector2(rect.size.x * 0.31, horizon)
	var far_r := Vector2(rect.size.x * 0.78, horizon)
	var field := PackedVector2Array([near_l, near_r, far_r, far_l])
	draw_colored_polygon(field, Color(0.025, 0.105, 0.112, 0.90))
	draw_polyline(PackedVector2Array([near_l, near_r, far_r, far_l, near_l]), Color(accent.r, accent.g, accent.b, 0.20), 1.5)

	for i in range(1, 6):
		var t := float(i) / 6.0
		var y := lerpf(horizon, near_l.y, t)
		var lx := lerpf(far_l.x, near_l.x, t)
		var rx := lerpf(far_r.x, near_r.x, t)
		draw_line(Vector2(lx, y), Vector2(rx, y), Color(0.70, 0.84, 0.90, 0.048), 1.0)

	var center := Vector2(rect.size.x * 0.55, lerpf(horizon, near_l.y, 0.52))
	draw_arc(center, 31, 0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.11), 1.2)
	for x_ratio in [0.38, 0.50, 0.62, 0.74]:
		draw_line(Vector2(rect.size.x * x_ratio, horizon), Vector2(rect.size.x * (0.50 + (x_ratio - 0.50) * 1.9), near_l.y), Color(0.70, 0.84, 0.90, 0.04), 1.0)

func _draw_player_backdrop(rect: Rect2) -> void:
	var wedge := PackedVector2Array([
		Vector2(rect.size.x * 0.50, 0), Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y * 0.74), Vector2(rect.size.x * 0.66, rect.size.y * 0.56),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.07))
	for i in range(5):
		var y := rect.size.y * (0.58 + float(i) * 0.07)
		draw_line(Vector2(0, y), Vector2(rect.size.x, y - 28), Color(1, 1, 1, 0.025 + float(i) * 0.006), 1.0)
	var halo := Vector2(rect.size.x * 0.24, rect.size.y * 0.52)
	draw_circle(halo, rect.size.x * 0.23, Color(accent.r, accent.g, accent.b, 0.028))
	draw_arc(halo, rect.size.x * 0.20, 0, TAU, 64, Color(accent.r, accent.g, accent.b, 0.08), 1.2)

func _draw_club_backdrop(rect: Rect2) -> void:
	var floor := PackedVector2Array([
		Vector2(rect.size.x * 0.10, rect.size.y * 0.84),
		Vector2(rect.size.x * 0.45, rect.size.y * 0.45),
		Vector2(rect.size.x * 0.95, rect.size.y * 0.67),
		Vector2(rect.size.x * 0.58, rect.size.y),
	])
	draw_colored_polygon(floor, Color(0.03, 0.07, 0.085, 0.86))
	draw_polyline(PackedVector2Array([floor[0], floor[1], floor[2], floor[3], floor[0]]), Color(accent.r, accent.g, accent.b, 0.12), 1.3)
	for i in range(4):
		var offset := Vector2(float(i) * 36.0, -float(i) * 14.0)
		var room := Rect2(Vector2(42, rect.size.y * 0.62) + offset, Vector2(62, 34))
		draw_rect(room, Color(0.08, 0.11, 0.14, 0.88), true)
		draw_rect(room, Color(accent.r, accent.g, accent.b, 0.13), false, 1.0)
		draw_rect(Rect2(room.position + Vector2(5, 7), Vector2(room.size.x - 10, 3)), Color(accent.r, accent.g, accent.b, 0.11), true)

func _draw_editorial_frame(rect: Rect2) -> void:
	draw_line(Vector2(0, 1), Vector2(rect.size.x, 1), Color(accent.r, accent.g, accent.b, 0.24), 1.0)
	draw_rect(Rect2(0, rect.size.y - 72, rect.size.x, 72), Color(0.005, 0.008, 0.012, 0.74), true)
	var slash := PackedVector2Array([
		Vector2(rect.size.x * 0.84, 0), Vector2(rect.size.x * 0.90, 0),
		Vector2(rect.size.x * 0.73, rect.size.y), Vector2(rect.size.x * 0.68, rect.size.y),
	])
	draw_colored_polygon(slash, Color(accent.r, accent.g, accent.b, 0.045))
