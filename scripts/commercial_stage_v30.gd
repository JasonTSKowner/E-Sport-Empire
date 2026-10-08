class_name CommercialStageV30
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var time_alive := 0.0

func configure(color: Color, stage_variant: String = "home") -> CommercialStageV30:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = 360.0 if variant == "home" else 304.0 if variant == "rank" else 286.0
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
	_draw_gradient(rect)
	_draw_stadium(rect)
	_draw_light_rigs(rect)
	_draw_floor(rect)
	_draw_variant_art(rect)
	_draw_vignette(rect)

func _draw_gradient(rect: Rect2) -> void:
	for i in range(18):
		var t := float(i) / 17.0
		var c := Color("111822").lerp(Color("040608"), t)
		draw_rect(Rect2(0, rect.size.y * t, rect.size.x, rect.size.y / 17.0 + 2.0), c, true)
	var pulse := 0.5 + 0.5 * sin(time_alive * 0.55)
	draw_circle(Vector2(size.x * 0.82, size.y * 0.16), size.x * 0.48, Color(accent.r, accent.g, accent.b, 0.035 + pulse * 0.012))
	draw_circle(Vector2(size.x * 0.08, size.y * 0.86), size.x * 0.56, Color(accent.r, accent.g, accent.b, 0.018))

func _draw_stadium(rect: Rect2) -> void:
	var horizon := size.y * 0.31
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon - 34), Vector2(size.x, horizon - 34), Vector2(size.x * 0.92, horizon + 26), Vector2(size.x * 0.08, horizon + 26)
	]), Color(0.035, 0.048, 0.065, 0.96))
	for row in range(4):
		var y := horizon - 20 + row * 11
		var count := 28 - row * 3
		for i in range(count):
			var x := 10.0 + float(i) * (size.x - 20.0) / float(maxi(1, count - 1))
			var flicker := 0.05 + 0.035 * sin(time_alive * 0.8 + i * 1.37 + row)
			var c := accent if (i + row) % 9 == 0 else Color(0.74, 0.80, 0.86, 1.0)
			draw_circle(Vector2(x, y), 1.0, Color(c.r, c.g, c.b, 0.08 + flicker))

func _draw_light_rigs(rect: Rect2) -> void:
	for i in range(7):
		var x := 18.0 + float(i) * (size.x - 36.0) / 6.0
		draw_circle(Vector2(x, 22), 2.1, Color(0.90, 0.96, 1.0, 0.24))
		var beam := PackedVector2Array([
			Vector2(x - 5, 25), Vector2(x + 5, 25),
			Vector2(x + 55, size.y * 0.78), Vector2(x - 55, size.y * 0.78),
		])
		draw_colored_polygon(beam, Color(0.82, 0.93, 1.0, 0.010))

func _draw_floor(rect: Rect2) -> void:
	var top_y := size.y * 0.42
	var floor := PackedVector2Array([
		Vector2(size.x * 0.12, top_y), Vector2(size.x * 0.88, top_y),
		Vector2(size.x * 1.08, size.y), Vector2(-size.x * 0.08, size.y),
	])
	draw_colored_polygon(floor, Color(0.025, 0.080, 0.095, 0.92))
	for i in range(1, 6):
		var t := float(i) / 6.0
		var y := lerpf(top_y, size.y, pow(t, 1.45))
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.55, 0.74, 0.82, 0.055), 1.0)
	for i in range(9):
		var x_top := lerpf(size.x * 0.12, size.x * 0.88, float(i) / 8.0)
		var x_bottom := lerpf(-size.x * 0.08, size.x * 1.08, float(i) / 8.0)
		draw_line(Vector2(x_top, top_y), Vector2(x_bottom, size.y), Color(0.55, 0.74, 0.82, 0.035), 1.0)

func _draw_variant_art(rect: Rect2) -> void:
	match variant:
		"home", "rank":
			_draw_car_silhouette(Vector2(size.x * 0.74, size.y * 0.64), 1.18 if variant == "home" else 1.0)
		"player", "scout":
			_draw_player_silhouette(Vector2(size.x * 0.79, size.y * 0.53), 1.0)
		"club":
			_draw_club_tower(Vector2(size.x * 0.76, size.y * 0.50))

func _draw_car_silhouette(center: Vector2, scale: float) -> void:
	var s := 34.0 * scale
	draw_circle(center + Vector2(0, 14 * scale), s * 0.78, Color(0, 0, 0, 0.24))
	var body := PackedVector2Array([
		center + Vector2(36, 0) * scale,
		center + Vector2(14, -13) * scale,
		center + Vector2(-12, -14) * scale,
		center + Vector2(-31, -5) * scale,
		center + Vector2(-34, 8) * scale,
		center + Vector2(22, 9) * scale,
	])
	draw_colored_polygon(body, Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.96))
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[5], body[0]]), Color(accent.r, accent.g, accent.b, 0.62), 2.0)
	var glass := PackedVector2Array([
		center + Vector2(9, -11) * scale,
		center + Vector2(-10, -11) * scale,
		center + Vector2(-18, -3) * scale,
		center + Vector2(14, -3) * scale,
	])
	draw_colored_polygon(glass, Color(0.62, 0.84, 0.94, 0.24))
	for wheel_x in [-22.0, 22.0]:
		var wp := center + Vector2(wheel_x, 9) * scale
		draw_circle(wp, 8.0 * scale, Color(0.01, 0.015, 0.02, 1.0))
		draw_circle(wp, 3.4 * scale, Color(0.34, 0.42, 0.50, 0.92))
	draw_line(center + Vector2(-34, 1) * scale, center + Vector2(-52, 1) * scale, Color(accent.r, accent.g, accent.b, 0.28), 4.0 * scale)

func _draw_player_silhouette(center: Vector2, scale: float) -> void:
	var head := center + Vector2(0, -54) * scale
	draw_circle(head, 18 * scale, Color(0.06, 0.08, 0.11, 0.98))
	var shoulders := PackedVector2Array([
		center + Vector2(-38, -28) * scale,
		center + Vector2(38, -28) * scale,
		center + Vector2(52, 56) * scale,
		center + Vector2(-52, 56) * scale,
	])
	draw_colored_polygon(shoulders, Color(accent.r * 0.20, accent.g * 0.20, accent.b * 0.20, 0.96))
	draw_polyline(PackedVector2Array([shoulders[0], shoulders[1], shoulders[2], shoulders[3], shoulders[0]]), Color(accent.r, accent.g, accent.b, 0.32), 1.8)
	draw_line(center + Vector2(-30, -13) * scale, center + Vector2(30, -13) * scale, Color(accent.r, accent.g, accent.b, 0.24), 2.0)

func _draw_club_tower(center: Vector2) -> void:
	var base := Rect2(center.x - 46, center.y - 42, 92, 96)
	draw_rect(base, Color(0.055, 0.075, 0.10, 0.95), true)
	draw_rect(base, Color(accent.r, accent.g, accent.b, 0.26), false, 1.5)
	for row in range(5):
		for col in range(4):
			var p := base.position + Vector2(12 + col * 20, 14 + row * 15)
			draw_rect(Rect2(p, Vector2(8, 5)), Color(accent.r, accent.g, accent.b, 0.14 + 0.03 * ((row + col) % 2)), true)

func _draw_vignette(rect: Rect2) -> void:
	draw_rect(Rect2(0, 0, size.x, 2), Color(accent.r, accent.g, accent.b, 0.22), true)
	draw_rect(Rect2(0, size.y - 62, size.x, 62), Color(0.01, 0.012, 0.018, 0.82), true)
	draw_rect(Rect2(0, 0, 18, size.y), Color(0, 0, 0, 0.10), true)
	draw_rect(Rect2(size.x - 18, 0, 18, size.y), Color(0, 0, 0, 0.10), true)
