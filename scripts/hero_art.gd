class_name HeroArt
extends Control

var accent := Color("7FE7FF")
var variant := "default"
var time_value := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func configure(new_accent: Color, new_variant: String = "default") -> HeroArt:
	accent = new_accent
	variant = new_variant
	queue_redraw()
	return self


func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var pulse := 0.5 + sin(time_value * 0.55) * 0.5

	draw_rect(rect, Color(0.035, 0.045, 0.060, 0.20), true)
	draw_circle(Vector2(size.x * 0.84, size.y * 0.18), size.x * 0.38, Color(accent.r, accent.g, accent.b, 0.025 + pulse * 0.012))
	draw_circle(Vector2(size.x * 0.94, size.y * 0.10), size.x * 0.19, Color(accent.r, accent.g, accent.b, 0.045))

	for i in range(5):
		var x := size.x * (0.57 + float(i) * 0.085)
		draw_line(Vector2(x, 0), Vector2(x - 58, size.y), Color(accent.r, accent.g, accent.b, 0.035), 1.0)

	if variant == "ranked":
		var c := Vector2(size.x * 0.84, size.y * 0.53)
		for r in [48.0, 36.0, 24.0]:
			draw_arc(c, r, -PI * 0.85, PI * 0.85, 48, Color(accent.r, accent.g, accent.b, 0.08), 1.2)
	elif variant == "team":
		for i in range(3):
			var p := Vector2(size.x * (0.72 + i * 0.08), size.y * (0.36 + (i % 2) * 0.22))
			draw_circle(p, 15, Color(accent.r, accent.g, accent.b, 0.06))
			draw_arc(p, 15, 0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.12), 1.2)
	elif variant == "scout":
		var c := Vector2(size.x * 0.84, size.y * 0.47)
		draw_arc(c, 34, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.10), 1.4)
		draw_line(c + Vector2(24,24), c + Vector2(49,49), Color(accent.r, accent.g, accent.b, 0.10), 2.0)
