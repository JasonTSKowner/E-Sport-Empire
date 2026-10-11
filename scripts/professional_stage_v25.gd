class_name ProfessionalStageV25
extends PanelContainer

var accent := Color("74DFF7")
var variant := "hero"
var pulse := 0.0

func configure(color: Color, stage_variant: String = "hero") -> ProfessionalStageV25:
	accent = color
	variant = stage_variant
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.y = 300.0 if variant in ["hero", "rank"] else 230.0
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_draw_background(rect)
	_draw_brand_geometry(rect)
	_draw_stadium_depth(rect)
	_draw_edge_details(rect)

func _draw_background(rect: Rect2) -> void:
	draw_rect(rect, Color("05080D"), true)
	var bands := 14
	for i in range(bands):
		var t := float(i) / float(maxi(1, bands - 1))
		var y := rect.size.y * t
		var c := Color("0D151D").lerp(Color("05080D"), t)
		draw_rect(Rect2(0, y, rect.size.x, rect.size.y / float(bands) + 1.0), c, true)
	var breathing := 0.036 + sin(pulse * 0.9) * 0.006
	draw_circle(Vector2(rect.size.x * 0.78, rect.size.y * 0.20), rect.size.x * 0.46, Color(accent.r, accent.g, accent.b, breathing))
	draw_circle(Vector2(rect.size.x * 0.05, rect.size.y * 0.95), rect.size.x * 0.54, Color(accent.r, accent.g, accent.b, 0.018))

func _draw_brand_geometry(rect: Rect2) -> void:
	var right := rect.size.x
	var bottom := rect.size.y
	var slash_a := PackedVector2Array([
		Vector2(right * 0.74, 0), Vector2(right * 0.90, 0),
		Vector2(right * 0.58, bottom), Vector2(right * 0.43, bottom)
	])
	draw_colored_polygon(slash_a, Color(accent.r, accent.g, accent.b, 0.035))
	var slash_b := PackedVector2Array([
		Vector2(right * 0.91, 0), Vector2(right, 0),
		Vector2(right * 0.72, bottom), Vector2(right * 0.64, bottom)
	])
	draw_colored_polygon(slash_b, Color(1, 1, 1, 0.018))
	for i in range(7):
		var x := 22.0 + float(i) * 19.0
		var alpha := 0.055 - float(i) * 0.004
		draw_circle(Vector2(x, rect.size.y * 0.31), 1.2, Color(0.82, 0.91, 0.96, alpha))

func _draw_stadium_depth(rect: Rect2) -> void:
	if variant not in ["hero", "rank", "club"]:
		return
	var horizon := rect.size.y * 0.58
	for i in range(5):
		var y := horizon + float(i) * rect.size.y * 0.075
		draw_line(Vector2(0, y), Vector2(rect.size.x, y - rect.size.x * 0.13), Color(0.80, 0.90, 0.96, 0.035), 1.0)
	var arena := PackedVector2Array([
		Vector2(rect.size.x * 0.21, rect.size.y * 0.60),
		Vector2(rect.size.x * 0.96, rect.size.y * 0.50),
		Vector2(rect.size.x * 0.96, rect.size.y * 0.95),
		Vector2(rect.size.x * 0.08, rect.size.y * 0.96)
	])
	draw_colored_polygon(arena, Color(0.025, 0.075, 0.090, 0.50))
	draw_polyline(arena, Color(accent.r, accent.g, accent.b, 0.10), 1.2, true)

func _draw_edge_details(rect: Rect2) -> void:
	draw_line(Vector2(0, 1), Vector2(rect.size.x, 1), Color(accent.r, accent.g, accent.b, 0.30), 1.0)
	draw_line(Vector2(0, rect.size.y - 1), Vector2(rect.size.x, rect.size.y - 1), Color(1, 1, 1, 0.025), 1.0)
	draw_rect(Rect2(rect.size.x - 4, 0, 4, rect.size.y), Color(accent.r, accent.g, accent.b, 0.035), true)
