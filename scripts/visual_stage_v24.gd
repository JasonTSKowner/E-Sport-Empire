class_name VisualStageV24
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "home") -> VisualStageV24:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = 286.0 if variant == "home" else 248.0
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
	# Deep broadcast gradient instead of a flat card.
	for i in range(12):
		var t := float(i) / 11.0
		var c := Color("0D1219").lerp(Color("040609"), t)
		draw_rect(Rect2(0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1.0), c, true)

	var glow := 0.050 + sin(pulse * 1.25) * 0.008
	draw_circle(Vector2(size.x * 0.80, size.y * 0.16), size.x * 0.46, Color(accent.r, accent.g, accent.b, glow))
	draw_circle(Vector2(size.x * 0.12, size.y * 0.94), size.x * 0.48, Color(accent.r, accent.g, accent.b, 0.020))

	# Stadium roof / crowd line.
	var roof_y := size.y * 0.25
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, roof_y - 18), Vector2(size.x, roof_y - 18),
		Vector2(size.x * 0.91, roof_y + 24), Vector2(size.x * 0.09, roof_y + 24)
	]), Color(0.035, 0.050, 0.066, 0.90))
	for i in range(13):
		var x := 14.0 + float(i) * (size.x - 28.0) / 12.0
		var light_alpha := 0.12 + 0.05 * sin(pulse * 1.5 + float(i) * 0.7)
		draw_circle(Vector2(x, roof_y - 4), 1.6, Color(0.90, 0.96, 1.0, light_alpha))

	if variant in ["home", "rank"]:
		_draw_rank_arena()
	elif variant == "player":
		_draw_player_stage()

	# Angled broadcast trims give the surface identity without card borders.
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.70, 0), Vector2(size.x, 0),
		Vector2(size.x, size.y * 0.32), Vector2(size.x * 0.93, size.y * 0.28)
	]), Color(accent.r, accent.g, accent.b, 0.025))
	draw_line(Vector2(size.x * 0.73, 0), Vector2(size.x, size.y * 0.30), Color(accent.r, accent.g, accent.b, 0.10), 1.0)

	# Grounding fade.
	draw_rect(Rect2(0, size.y - 52, size.x, 52), Color(0.008, 0.012, 0.018, 0.76), true)
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r, accent.g, accent.b, 0.19), 1.2)

func _draw_rank_arena() -> void:
	# Perspective Rocket-League-like pitch in the background.
	var near_l := Vector2(size.x * 0.10, size.y * 0.91)
	var near_r := Vector2(size.x * 0.96, size.y * 0.91)
	var far_l := Vector2(size.x * 0.39, size.y * 0.38)
	var far_r := Vector2(size.x * 0.91, size.y * 0.38)
	var arena := PackedVector2Array([near_l, near_r, far_r, far_l])
	draw_colored_polygon(arena, Color(0.025, 0.075, 0.092, 0.84))
	draw_polyline(PackedVector2Array([near_l, near_r, far_r, far_l, near_l]), Color(accent.r, accent.g, accent.b, 0.16), 1.4)

	# Alternating field depth bands.
	for i in range(6):
		var t0 := float(i) / 6.0
		var t1 := float(i + 1) / 6.0
		if i % 2 == 0:
			var a0 := near_l.lerp(far_l, t0)
			var b0 := near_r.lerp(far_r, t0)
			var a1 := near_l.lerp(far_l, t1)
			var b1 := near_r.lerp(far_r, t1)
			draw_colored_polygon(PackedVector2Array([a0, b0, b1, a1]), Color(0.06, 0.15, 0.17, 0.23))

	var center_near := near_l.lerp(near_r, 0.5)
	var center_far := far_l.lerp(far_r, 0.5)
	draw_line(center_near, center_far, Color(0.62, 0.80, 0.88, 0.10), 1.0)
	var circle_center := center_near.lerp(center_far, 0.53)
	draw_arc(circle_center, 30.0, 0.0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.09), 1.2)

	# Goal frame and a subtle car silhouette create an actual game-world cue.
	var goal_center := far_l.lerp(far_r, 0.52)
	var goal := Rect2(goal_center.x - 42, goal_center.y - 11, 84, 22)
	draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.035), true)
	draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.13), false, 1.2)

	var car_center := Vector2(size.x * 0.70, size.y * 0.74)
	var dir := Vector2(0.82, -0.57).normalized()
	var side := Vector2(-dir.y, dir.x)
	var body := PackedVector2Array([
		car_center + dir * 23,
		car_center + dir * 5 + side * 10,
		car_center - dir * 16 + side * 7,
		car_center - dir * 16 - side * 7,
		car_center + dir * 5 - side * 10,
	])
	draw_circle(car_center + Vector2(3, 5), 18, Color(0,0,0,0.22))
	draw_colored_polygon(body, Color(accent.r * 0.24, accent.g * 0.24, accent.b * 0.24, 0.44))
	draw_polyline(body, Color(accent.r, accent.g, accent.b, 0.16), 1.4, true)
	draw_line(car_center - dir * 16, car_center - dir * 32, Color(accent.r, accent.g, accent.b, 0.08), 4.0)

func _draw_player_stage() -> void:
	# Locker-room / profile lighting behind the player portrait.
	for i in range(5):
		var x := size.x * (0.12 + float(i) * 0.21)
		draw_line(Vector2(x, size.y * 0.30), Vector2(x - 24, size.y), Color(1,1,1,0.018), 1.0)
	var spotlight_center := Vector2(size.x * 0.28, size.y * 0.48)
	draw_circle(spotlight_center, size.x * 0.26, Color(accent.r, accent.g, accent.b, 0.028))
