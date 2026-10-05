class_name VisualStageV24
extends PanelContainer

var accent := Color("74DFF7")
var variant := "home"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "home") -> VisualStageV24:
	accent = color
	variant = stage_variant
	custom_minimum_size.y = 260.0 if variant == "home" else 232.0
	mouse_filter = Control.MOUSE_FILTER_PASS
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty)
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var bg := Color("070A0F")
	draw_rect(rect, bg, true)

	# Stadium / broadcast depth without card borders.
	var glow := 0.045 + sin(pulse * 1.4) * 0.01
	draw_circle(Vector2(size.x * 0.78, size.y * 0.18), size.x * 0.44, Color(accent.r, accent.g, accent.b, glow))
	draw_circle(Vector2(size.x * 0.14, size.y * 0.95), size.x * 0.50, Color(accent.r, accent.g, accent.b, 0.022))

	for i in range(7):
		var y := size.y * (0.55 + float(i) * 0.07)
		var a := 0.022 + float(i) * 0.004
		draw_line(Vector2(0, y), Vector2(size.x, y - size.x * 0.16), Color(1, 1, 1, a), 1.0)

	if variant in ["home", "rank"]:
		var arena := PackedVector2Array([
			Vector2(size.x * 0.34, size.y * 0.36),
			Vector2(size.x * 0.98, size.y * 0.23),
			Vector2(size.x * 0.98, size.y * 0.88),
			Vector2(size.x * 0.20, size.y * 0.93),
		])
		draw_colored_polygon(arena, Color(0.035, 0.065, 0.085, 0.80))
		draw_polyline(arena, Color(accent.r, accent.g, accent.b, 0.13), 1.2, true)
		var center := Vector2(size.x * 0.65, size.y * 0.62)
		draw_arc(center, 34, 0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.10), 1.2)
		draw_line(Vector2(size.x * 0.62, size.y * 0.35), Vector2(size.x * 0.62, size.y * 0.88), Color(1,1,1,0.055), 1.0)

	# Strong bottom fade / grounding.
	draw_rect(Rect2(0, size.y - 48, size.x, 48), Color(0.01, 0.015, 0.022, 0.72), true)
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color(accent.r, accent.g, accent.b, 0.16), 1.0)
