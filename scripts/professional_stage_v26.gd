class_name ProfessionalStageV26
extends PanelContainer

var accent := Color("6DD7F0")
var variant := "hero"
var energy := 0.0

func configure(color: Color, stage_variant: String = "hero") -> ProfessionalStageV26:
	accent = color
	variant = stage_variant
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size.y <= 0.0:
		custom_minimum_size.y = 260.0 if variant in ["hero", "rank", "club"] else 210.0
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty)
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	energy += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return

	# Deep broadcast-grade background.
	for i in range(18):
		var t := float(i) / 17.0
		var c := Color("0C1219").lerp(Color("05080D"), t)
		draw_rect(Rect2(0, rect.size.y * t, rect.size.x, rect.size.y / 17.0 + 1.0), c, true)

	# Controlled accent lighting, never neon everywhere.
	var pulse := 0.80 + sin(energy * 0.7) * 0.04
	draw_circle(Vector2(rect.size.x * 0.84, rect.size.y * 0.18), rect.size.x * 0.40, Color(accent.r, accent.g, accent.b, 0.055 * pulse))
	draw_circle(Vector2(rect.size.x * 0.12, rect.size.y * 0.92), rect.size.x * 0.48, Color(accent.r, accent.g, accent.b, 0.018))

	# Editorial geometry makes the layout feel authored instead of panel-based.
	var wedge := PackedVector2Array([
		Vector2(rect.size.x * 0.56, 0),
		Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y * 0.56),
		Vector2(rect.size.x * 0.76, rect.size.y * 0.48),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.045))

	if variant in ["hero", "rank", "club"]:
		var horizon := rect.size.y * 0.56
		for i in range(6):
			var y := horizon + float(i) * rect.size.y * 0.075
			draw_line(Vector2(0, y), Vector2(rect.size.x, y - rect.size.x * 0.12), Color(1,1,1,0.026 + float(i) * 0.004), 1.0)
		var center := Vector2(rect.size.x * 0.63, rect.size.y * 0.68)
		draw_arc(center, minf(rect.size.x, rect.size.y) * 0.12, 0, TAU, 48, Color(accent.r,accent.g,accent.b,0.10), 1.2)

	if variant in ["player", "scout"]:
		var split_x := rect.size.x * 0.31
		draw_rect(Rect2(0, 0, split_x, rect.size.y), Color(accent.r,accent.g,accent.b,0.035), true)
		draw_line(Vector2(split_x, 0), Vector2(split_x, rect.size.y), Color(accent.r,accent.g,accent.b,0.12), 1.0)

	# Fine framing only; no heavy rounded-card outline.
	draw_line(Vector2(0, 0), Vector2(rect.size.x, 0), Color(accent.r,accent.g,accent.b,0.34), 1.2)
	draw_line(Vector2(0, rect.size.y - 1), Vector2(rect.size.x, rect.size.y - 1), Color(1,1,1,0.045), 1.0)
	draw_rect(Rect2(0, rect.size.y - 54, rect.size.x, 54), Color(0.015,0.020,0.027,0.62), true)
