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

	# Broadcast gradient bands.
	for i in range(12):
		var t := float(i) / 11.0
		var band := Color("101822").lerp(Color("05080C"), t)
		draw_rect(Rect2(0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), band, true)

	var glow := 0.050 + sin(pulse * 1.15) * 0.009
	draw_circle(Vector2(size.x * 0.76, size.y * 0.20), size.x * 0.52, Color(accent.r, accent.g, accent.b, glow))
	draw_circle(Vector2(size.x * 0.16, size.y * 0.90), size.x * 0.54, Color(accent.r, accent.g, accent.b, 0.020))

	# Stadium light rig.
	for i in range(9):
		var x := 18.0 + float(i) * (size.x - 36.0) / 8.0
		var a := 0.14 + 0.05 * sin(pulse * 0.8 + float(i))
		draw_circle(Vector2(x, 14.0), 2.0, Color(0.88, 0.96, 1.0, a))
		var beam := PackedVector2Array([
			Vector2(x - 2.0, 18.0), Vector2(x + 2.0, 18.0),
			Vector2(x + 42.0, size.y * 0.72), Vector2(x - 42.0, size.y * 0.72)
		])
		draw_colored_polygon(beam, Color(0.75, 0.90, 1.0, 0.006))

	# Perspective pitch occupies the lower half and visually fills the screen.
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

	# Crowd/LED band adds life without becoming noisy.
	var ribbon_y := size.y * 0.46
	for i in range(28):
		var x := 8.0 + float(i) * (size.x - 16.0) / 27.0
		var c := accent if i % 9 == 2 else Color(0.72,0.82,0.90)
		draw_rect(Rect2(x, ribbon_y + float(i % 3), 7.0, 1.2), Color(c.r,c.g,c.b,0.10), true)

	# Grounding fade and edge framing.
	draw_rect(Rect2(0, size.y - 60.0, size.x, 60.0), Color(0.01,0.015,0.022,0.50), true)
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r,accent.g,accent.b,0.18), 1.0)
