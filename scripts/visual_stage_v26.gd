class_name VisualStageV26
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "home") -> VisualStageV26:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = 500.0 if variant == "home" else 330.0
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("05080C"), true)
	for i in range(12):
		var t := float(i) / 11.0
		var band := Color("101822").lerp(Color("05080C"), t)
		draw_rect(Rect2(0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), band, true)

	var glow := 0.050 + sin(pulse * 1.15) * 0.009
	draw_circle(Vector2(size.x * 0.76, size.y * 0.20), size.x * 0.52, Color(accent.r, accent.g, accent.b, glow))
	draw_circle(Vector2(size.x * 0.16, size.y * 0.90), size.x * 0.54, Color(accent.r, accent.g, accent.b, 0.020))

	for i in range(9):
		var x := 18.0 + float(i) * (size.x - 36.0) / 8.0
		var a := 0.14 + 0.05 * sin(pulse * 0.8 + float(i))
		draw_circle(Vector2(x, 14.0), 2.0, Color(0.88, 0.96, 1.0, a))
		var beam := PackedVector2Array([
			Vector2(x - 2.0, 18.0), Vector2(x + 2.0, 18.0),
			Vector2(x + 42.0, size.y * 0.72), Vector2(x - 42.0, size.y * 0.72)
		])
		draw_colored_polygon(beam, Color(0.75, 0.90, 1.0, 0.006))

	var near_l := Vector2(-26.0, size.y * 0.94)
	var near_r := Vector2(size.x + 26.0, size.y * 0.94)
	var far_l := Vector2(size.x * 0.35, size.y * 0.49)
	var far_r := Vector2(size.x * 0.79, size.y * 0.49)
	var pitch := PackedVector2Array([near_l, near_r, far_r, far_l])
	draw_colored_polygon(pitch, Color(0.025, 0.095, 0.115, 0.82))
	for i in range(8):
		var t0 := float(i) / 8.0
		var t1 := float(i + 1) / 8.0
		if i % 2 == 0:
			var l0 := near_l.lerp(far_l, t0)
			var r0 := near_r.lerp(far_r, t0)
			var l1 := near_l.lerp(far_l, t1)
			var r1 := near_r.lerp(far_r, t1)
			draw_colored_polygon(PackedVector2Array([l0, r0, r1, l1]), Color(0.04,0.14,0.16,0.28))
	draw_polyline(PackedVector2Array([near_l, near_r, far_r, far_l, near_l]), Color(accent.r,accent.g,accent.b,0.16), 1.5)
	var mid_l := near_l.lerp(far_l, 0.54)
	var mid_r := near_r.lerp(far_r, 0.54)
	draw_line(mid_l, mid_r, Color(0.74,0.88,0.94,0.08), 1.2)

	if variant == "home":
		_draw_home_gameplay_scene()

	var ribbon_y := size.y * 0.46
	for i in range(28):
		var x := 8.0 + float(i) * (size.x - 16.0) / 27.0
		var c := accent if i % 9 == 2 else Color(0.72,0.82,0.90)
		draw_rect(Rect2(x, ribbon_y + float(i % 3), 7.0, 1.2), Color(c.r,c.g,c.b,0.10), true)

	draw_rect(Rect2(0, size.y - 60.0, size.x, 60.0), Color(0.01,0.015,0.022,0.50), true)
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r,accent.g,accent.b,0.18), 1.0)

func _draw_home_gameplay_scene() -> void:
	var car_center := Vector2(size.x * 0.73, size.y * 0.76)
	var dir := Vector2(-0.30, -0.95).normalized()
	var side := Vector2(-dir.y, dir.x)
	var s := clampf(size.x / 412.0, 0.82, 1.18)

	# Motion streaks and contact shadow.
	for lane in [-1.0, 1.0]:
		var streak: Vector2 = car_center - dir * 12.0 * s + side * float(lane) * 7.0 * s
		draw_line(streak, streak - dir * 34.0 * s, Color(accent.r,accent.g,accent.b,0.10), 2.2 * s)
	var shadow := PackedVector2Array()
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		shadow.append(car_center + Vector2(cos(angle) * 24.0 * s, sin(angle) * 9.0 * s) + Vector2(3,7))
	draw_colored_polygon(shadow, Color(0,0,0,0.34))

	# Stylized premium car silhouette matching the match renderer language.
	var nose := car_center + dir * 28.0 * s
	var rear := car_center - dir * 18.0 * s
	var body := PackedVector2Array([
		nose,
		car_center + dir * 16.0 * s + side * 11.0 * s,
		car_center + dir * 4.0 * s + side * 15.0 * s,
		car_center - dir * 11.0 * s + side * 12.0 * s,
		rear + side * 7.0 * s,
		rear - side * 7.0 * s,
		car_center - dir * 11.0 * s - side * 12.0 * s,
		car_center + dir * 4.0 * s - side * 15.0 * s,
		car_center + dir * 16.0 * s - side * 11.0 * s,
	])
	draw_circle(car_center, 40.0 * s, Color(accent.r,accent.g,accent.b,0.035))
	draw_colored_polygon(body, Color(accent.r * 0.22, accent.g * 0.28, accent.b * 0.32, 0.94))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[7],body[8],body[0]]), Color(accent.r,accent.g,accent.b,0.48), 1.8 * s)
	var glass := PackedVector2Array([
		car_center + dir * 14.0 * s + side * 7.0 * s,
		car_center + dir * 15.0 * s - side * 7.0 * s,
		car_center + dir * 1.0 * s - side * 8.0 * s,
		car_center + dir * 1.0 * s + side * 8.0 * s,
	])
	draw_colored_polygon(glass, Color(0.58,0.80,0.91,0.24))
	for wheel_offset in [Vector2(-8,-13),Vector2(10,-13),Vector2(-8,13),Vector2(10,13)]:
		var wheel: Vector2 = car_center + dir * wheel_offset.x * s + side * wheel_offset.y * s
		draw_circle(wheel, 4.0 * s, Color(0.01,0.015,0.022,0.82))
		draw_circle(wheel, 1.5 * s, Color(0.62,0.72,0.80,0.44))
	draw_line(rear + side * 8.0 * s, rear - side * 8.0 * s, Color(accent.r,accent.g,accent.b,0.42), 2.0 * s)
	draw_line(rear, rear - dir * 30.0 * s, Color(accent.r,accent.g,accent.b,0.22), 4.0 * s)

	# Ball + implied attacking line.
	var ball := Vector2(size.x * 0.50, size.y * 0.65)
	draw_circle(ball + Vector2(3,6), 9.0 * s, Color(0,0,0,0.28))
	draw_circle(ball, 15.0 * s, Color(0.88,0.96,1.0,0.035))
	draw_circle(ball, 8.2 * s, Color(0.88,0.92,0.96,0.62))
	draw_arc(ball, 5.0 * s, -0.4, 1.4, 14, Color(0.18,0.24,0.30,0.52), 1.0 * s)
	draw_dashed_line(car_center - dir * 10.0 * s, ball, Color(accent.r,accent.g,accent.b,0.075), 1.2 * s, 9.0)
