class_name ClubHQV25
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var accent := Color("D6B16B")
var levels: Dictionary = {}
var cash_per_hour := 0
var fans_per_hour := 0
var pulse := 0.0

func configure(color: Color, facility_levels: Dictionary, income: int, fans: int) -> ClubHQV25:
	accent = color
	levels = facility_levels.duplicate(true)
	cash_per_hour = income
	fans_per_hour = fans
	custom_minimum_size = Vector2(0, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	for i in range(16):
		var t := float(i) / 15.0
		var c := Color("10151C").lerp(Color("030609"), t)
		draw_rect(Rect2(0, r.size.y * t, r.size.x, r.size.y / 15.0 + 2), c, true)
	draw_circle(Vector2(r.size.x * 0.78, r.size.y * 0.20), r.size.x * 0.42, Color(accent.r, accent.g, accent.b, 0.026 + sin(pulse) * 0.004))
	draw_line(Vector2(0, 1), Vector2(r.size.x, 1), Color(accent.r, accent.g, accent.b, 0.22), 1.0)

	draw_string(FONT, Vector2(16, 26), "TSK ESPORTS  /  CLUB HQ", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, 8, Color(accent.r, accent.g, accent.b, 0.90))
	draw_string(FONT, Vector2(16, 54), "ORGANISATION", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, 24, Color(0.95, 0.97, 1.0, 0.98))
	draw_string(FONT, Vector2(16, 72), "DEIN VEREIN WÄCHST SICHTBAR MIT JEDEM AUSBAU", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, 8, Color(0.59, 0.67, 0.75, 0.82))

	var base_y := r.size.y * 0.79
	var center_x := r.size.x * 0.52
	var floor := PackedVector2Array([
		Vector2(r.size.x * 0.08, base_y),
		Vector2(r.size.x * 0.38, r.size.y * 0.38),
		Vector2(r.size.x * 0.93, r.size.y * 0.56),
		Vector2(r.size.x * 0.61, r.size.y * 0.94),
	])
	draw_colored_polygon(floor, Color(0.032, 0.072, 0.088, 0.92))
	draw_polyline(PackedVector2Array([floor[0], floor[1], floor[2], floor[3], floor[0]]), Color(accent.r, accent.g, accent.b, 0.14), 1.3)

	var modules := [
		{"key":"hq", "label":"HEADQUARTER", "pos":Vector2(-86,-8)},
		{"key":"coaching", "label":"PERF LAB", "pos":Vector2(-20,-42)},
		{"key":"scouting", "label":"SCOUT HUB", "pos":Vector2(48,-13)},
		{"key":"analytics", "label":"ANALYTICS", "pos":Vector2(-5,28)},
	]
	for module in modules:
		var key := str(module["key"])
		var level := int(levels.get(key, 0))
		var pos: Vector2 = Vector2(center_x, base_y - 36) + module["pos"]
		_draw_module(pos, str(module["label"]), level)

	var studio_level := int(levels.get("studio", 0))
	var studio_pos := Vector2(center_x + 92, base_y - 18)
	_draw_module(studio_pos, "CONTENT", studio_level)

	var footer_y := r.size.y - 30.0
	draw_rect(Rect2(0, footer_y - 14, r.size.x, 44), Color(0.006, 0.010, 0.015, 0.86), true)
	draw_string(FONT, Vector2(16, footer_y + 4), "€%d/H" % cash_per_hour, HORIZONTAL_ALIGNMENT_LEFT, 90, 11, Color(0.94, 0.79, 0.45, 0.95))
	draw_string(FONT, Vector2(112, footer_y + 4), "+%d FANS/H" % fans_per_hour, HORIZONTAL_ALIGNMENT_LEFT, 110, 11, Color(0.47, 0.86, 0.95, 0.95))
	draw_string(FONT, Vector2(r.size.x - 126, footer_y + 4), "OFFLINE 8H", HORIZONTAL_ALIGNMENT_RIGHT, 110, 8, Color(0.58, 0.66, 0.74, 0.76))

func _draw_module(pos: Vector2, label: String, level: int) -> void:
	var lvl := maxi(0, level)
	var width := 70.0
	var height := 31.0 + float(mini(5, lvl)) * 2.4
	var top := PackedVector2Array([
		pos + Vector2(-width * 0.50, -height),
		pos + Vector2(-width * 0.10, -height - 16),
		pos + Vector2(width * 0.50, -height - 5),
		pos + Vector2(width * 0.12, -height + 12),
	])
	var front := PackedVector2Array([
		top[3], top[2], pos + Vector2(width * 0.50, 0), pos + Vector2(width * 0.12, 11),
	])
	var side := PackedVector2Array([
		top[0], top[3], pos + Vector2(width * 0.12, 11), pos + Vector2(-width * 0.50, 0),
	])
	draw_colored_polygon(top, Color(0.12, 0.16, 0.20, 0.98).lerp(Color(accent.r, accent.g, accent.b, 1.0), 0.06 + float(lvl) * 0.012))
	draw_colored_polygon(front, Color(0.055, 0.080, 0.105, 0.98))
	draw_colored_polygon(side, Color(0.040, 0.060, 0.080, 0.98))
	draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), Color(accent.r, accent.g, accent.b, 0.28), 1.1)
	for i in range(3):
		var win_pos := pos + Vector2(-18 + float(i) * 14.0, -height + 11)
		draw_rect(Rect2(win_pos, Vector2(8, 5)), Color(accent.r, accent.g, accent.b, 0.10 + float(lvl) * 0.025), true)
	var label_pos := pos + Vector2(-34, 24)
	draw_string(FONT, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, 68, 7, Color(0.75, 0.82, 0.88, 0.82))
	draw_string(FONT, label_pos + Vector2(0, 11), "LV %d" % lvl, HORIZONTAL_ALIGNMENT_CENTER, 68, 8, Color(accent.r, accent.g, accent.b, 0.88))
