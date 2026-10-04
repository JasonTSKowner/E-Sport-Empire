class_name StatRadar
extends Control

var values: Array[float] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
var labels: Array[String] = ["MECH", "SHOT", "ROT", "DEF", "SENSE", "MENT"]
var accent := Color("7FE7FF")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 168)
	queue_redraw()


func configure(new_values: Array, new_labels: Array, new_accent: Color) -> StatRadar:
	values.clear()
	for item in new_values:
		values.append(clampf(float(item) / 100.0, 0.0, 1.0))
	labels.clear()
	for item in new_labels:
		labels.append(str(item))
	accent = new_accent
	queue_redraw()
	return self


func _point(center: Vector2, radius: float, index: int, count: int, scale: float = 1.0) -> Vector2:
	var angle := -PI / 2.0 + TAU * float(index) / float(count)
	return center + Vector2(cos(angle), sin(angle)) * radius * scale


func _draw() -> void:
	var count := mini(values.size(), labels.size())
	if count < 3:
		return
	var center := Vector2(size.x * 0.5, size.y * 0.50)
	var radius := minf(size.x * 0.29, size.y * 0.34)

	for ring in range(1, 5):
		var scale := float(ring) / 4.0
		var pts := PackedVector2Array()
		for i in range(count):
			pts.append(_point(center, radius, i, count, scale))
		pts.append(pts[0])
		draw_polyline(pts, Color(0.55, 0.62, 0.70, 0.11), 1.0, true)

	for i in range(count):
		draw_line(center, _point(center, radius, i, count), Color(0.55, 0.62, 0.70, 0.10), 1.0)

	var value_pts := PackedVector2Array()
	for i in range(count):
		value_pts.append(_point(center, radius, i, count, values[i]))
	draw_colored_polygon(value_pts, Color(accent.r, accent.g, accent.b, 0.14))
	var closed := PackedVector2Array(value_pts)
	closed.append(value_pts[0])
	draw_polyline(closed, Color(accent.r, accent.g, accent.b, 0.72), 2.0, true)
	for p in value_pts:
		draw_circle(p, 2.5, accent)

	var font := ThemeDB.fallback_font
	for i in range(count):
		var p := _point(center, radius + 14.0, i, count)
		var label := labels[i]
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_string(font, p - Vector2(text_size.x * 0.5, -3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("98A3B3"))
