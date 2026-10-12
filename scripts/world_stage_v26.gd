class_name WorldStageV26
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "home") -> WorldStageV26:
	accent = color
	variant = stage_variant
	mouse_filter = Control.MOUSE_FILTER_PASS
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty)
	match variant:
		"home": custom_minimum_size.y = 404.0
		"rank": custom_minimum_size.y = 318.0
		"player": custom_minimum_size.y = 286.0
		"scout": custom_minimum_size.y = 208.0
		"club": custom_minimum_size.y = 228.0
		_: custom_minimum_size.y = 250.0
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_draw_base(rect)
	match variant:
		"home", "rank": _draw_stadium(rect)
		"player", "scout": _draw_player_bay(rect)
		"club": _draw_hq(rect)
		_: _draw_stadium(rect)
	_draw_frame(rect)

func _draw_base(rect: Rect2) -> void:
	draw_rect(rect, Color("04070B"), true)
	for i in range(12):
		var t := float(i) / 11.0
		var c := Color("111923").lerp(Color("03060A"), t)
		draw_rect(Rect2(0.0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), c, true)
	var breathing := 0.030 + sin(pulse * 0.72) * 0.006
	draw_circle(Vector2(size.x * 0.80, size.y * 0.18), size.x * 0.45, Color(accent.r, accent.g, accent.b, breathing))
	draw_circle(Vector2(size.x * 0.10, size.y * 0.90), size.x * 0.52, Color(accent.r, accent.g, accent.b, 0.015))
	for i in range(22):
		var x := fmod(float(i * 47 + 23), maxf(1.0, size.x - 16.0)) + 8.0
		var y := fmod(float(i * 71 + 37), maxf(1.0, size.y - 22.0)) + 11.0
		var a := 0.025 + 0.016 * sin(pulse * 0.55 + float(i))
		draw_circle(Vector2(x, y), 0.8, Color(0.80, 0.91, 0.98, a))

func _draw_stadium(rect: Rect2) -> void:
	var horizon := size.y * (0.36 if variant == "home" else 0.39)
	var bowl := PackedVector2Array([
		Vector2(-18, horizon - 44), Vector2(size.x + 18, horizon - 44),
		Vector2(size.x * 0.86, horizon + 44), Vector2(size.x * 0.14, horizon + 44)
	])
	draw_colored_polygon(bowl, Color(0.035, 0.055, 0.074, 0.92))
	for row in range(4):
		var y := horizon - 30.0 + float(row) * 13.0
		var count := 24 - row * 2
		for i in range(count):
			var x := 10.0 + float(i) * (size.x - 20.0) / float(maxi(1, count - 1))
			var flicker := 0.055 + 0.025 * sin(pulse * 0.8 + float(i) * 1.27 + float(row))
			var c := accent if (i + row) % 10 == 0 else Color(0.76,0.84,0.91)
			draw_circle(Vector2(x, y), 0.9, Color(c.r,c.g,c.b,flicker))

	for i in range(7):
		var x := 18.0 + float(i) * (size.x - 36.0) / 6.0
		draw_circle(Vector2(x, horizon - 40), 2.1, Color(0.90,0.97,1.0,0.26))
		draw_circle(Vector2(x, horizon - 40), 7.0, Color(0.80,0.92,1.0,0.025))

	var top_y := horizon + 34.0
	var near_y := size.y - 18.0
	var far_half := size.x * 0.19
	var near_half := size.x * 0.58
	var center := size.x * 0.55
	var pitch := PackedVector2Array([
		Vector2(center - far_half, top_y), Vector2(center + far_half, top_y),
		Vector2(center + near_half, near_y), Vector2(center - near_half, near_y)
	])
	draw_colored_polygon(pitch, Color(0.018,0.080,0.098,0.82))
	for i in range(8):
		var t0 := float(i) / 8.0
		var t1 := float(i + 1) / 8.0
		if i % 2 == 0:
			var l0 := Vector2(center - lerpf(far_half, near_half, t0), lerpf(top_y, near_y, t0))
			var r0 := Vector2(center + lerpf(far_half, near_half, t0), lerpf(top_y, near_y, t0))
			var l1 := Vector2(center - lerpf(far_half, near_half, t1), lerpf(top_y, near_y, t1))
			var r1 := Vector2(center + lerpf(far_half, near_half, t1), lerpf(top_y, near_y, t1))
			draw_colored_polygon(PackedVector2Array([l0,r0,r1,l1]), Color(0.05,0.16,0.18,0.24))
	draw_polyline(PackedVector2Array([pitch[0],pitch[1],pitch[2],pitch[3],pitch[0]]), Color(accent.r,accent.g,accent.b,0.18), 1.3)
	for i in range(1,5):
		var t := float(i) / 5.0
		var half := lerpf(far_half, near_half, t)
		var y := lerpf(top_y, near_y, t)
		draw_line(Vector2(center-half,y), Vector2(center+half,y), Color(0.72,0.88,0.94,0.055), 1.0)
	var mid_half := lerpf(far_half, near_half, 0.50)
	var mid_y := lerpf(top_y, near_y, 0.50)
	draw_line(Vector2(center-mid_half,mid_y), Vector2(center+mid_half,mid_y), Color(0.72,0.88,0.94,0.13), 1.0)
	draw_arc(Vector2(center,mid_y), 24.0, 0, TAU, 36, Color(0.72,0.88,0.94,0.10), 1.0)

	# Near LED board grounds the stage like a broadcast scene.
	draw_rect(Rect2(0, size.y - 24, size.x, 24), Color(0.012,0.020,0.028,0.96), true)
	draw_line(Vector2(16,size.y-24), Vector2(size.x-16,size.y-24), Color(accent.r,accent.g,accent.b,0.19), 2.0)

func _draw_player_bay(rect: Rect2) -> void:
	var left := size.x * 0.56
	var bay := PackedVector2Array([
		Vector2(left, 0), Vector2(size.x, 0), Vector2(size.x, size.y),
		Vector2(size.x * 0.43, size.y), Vector2(size.x * 0.52, size.y * 0.48)
	])
	draw_colored_polygon(bay, Color(0.035,0.085,0.108,0.58))
	for i in range(5):
		var x := size.x * (0.60 + float(i) * 0.09)
		draw_line(Vector2(x,0), Vector2(x-28,size.y), Color(accent.r,accent.g,accent.b,0.04), 1.0)
	# Locker / display shelf silhouettes.
	for i in range(3):
		var x := size.x * 0.60 + float(i) * 54.0
		draw_rect(Rect2(x, size.y * 0.20, 40, size.y * 0.58), Color(0.02,0.03,0.04,0.22), true)
		draw_line(Vector2(x,size.y*0.20), Vector2(x+40,size.y*0.20), Color(1,1,1,0.05), 1.0)
	var floor_y := size.y * 0.82
	draw_line(Vector2(0,floor_y), Vector2(size.x,floor_y), Color(0.70,0.86,0.94,0.07), 1.0)
	for i in range(6):
		var y := floor_y + float(i) * 13.0
		draw_line(Vector2(0,y), Vector2(size.x,y), Color(1,1,1,0.02), 1.0)

func _draw_hq(rect: Rect2) -> void:
	# Abstract esports HQ / operations room instead of a settings-card background.
	var skyline_y := size.y * 0.42
	for i in range(8):
		var w := 30.0 + float((i * 17) % 24)
		var h := 34.0 + float((i * 31) % 70)
		var x := float(i) * size.x / 7.2 - 4.0
		draw_rect(Rect2(x, skyline_y - h, w, h), Color(0.035,0.055,0.074,0.56), true)
		if i % 2 == 0:
			draw_rect(Rect2(x+5, skyline_y-h+8, w-10, 2), Color(accent.r,accent.g,accent.b,0.10), true)
	var table := PackedVector2Array([
		Vector2(size.x*0.26,size.y*0.55), Vector2(size.x*0.82,size.y*0.50),
		Vector2(size.x*0.95,size.y*0.86), Vector2(size.x*0.10,size.y*0.90)
	])
	draw_colored_polygon(table, Color(0.025,0.055,0.070,0.76))
	draw_polyline(PackedVector2Array([table[0],table[1],table[2],table[3],table[0]]), Color(accent.r,accent.g,accent.b,0.12), 1.2)
	for i in range(3):
		var sx := size.x * (0.38 + float(i)*0.17)
		draw_rect(Rect2(sx,size.y*0.30,46,29), Color(0.025,0.04,0.052,0.88), true)
		draw_rect(Rect2(sx+4,size.y*0.34,38,2), Color(accent.r,accent.g,accent.b,0.16), true)

func _draw_frame(rect: Rect2) -> void:
	draw_line(Vector2(0,1), Vector2(size.x,1), Color(accent.r,accent.g,accent.b,0.20), 1.0)
	draw_line(Vector2(0,size.y-1), Vector2(size.x,size.y-1), Color(1,1,1,0.035), 1.0)
	# Small broadcast corner brackets.
	var l := 14.0
	var c := Color(accent.r,accent.g,accent.b,0.22)
	draw_line(Vector2(8,8), Vector2(8+l,8), c, 1.4)
	draw_line(Vector2(8,8), Vector2(8,8+l), c, 1.4)
	draw_line(Vector2(size.x-8,8), Vector2(size.x-8-l,8), c, 1.4)
	draw_line(Vector2(size.x-8,8), Vector2(size.x-8,8+l), c, 1.4)
