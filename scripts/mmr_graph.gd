class_name MMRGraph
extends Control

var values: Array = []
var accent := Color("2de2ff")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 150.0)
	queue_redraw()


func configure(history: Array, line_color: Color) -> MMRGraph:
	values = history.duplicate()
	accent = line_color
	queue_redraw()
	return self


func _draw() -> void:
	var size := get_rect().size
	var plot := Rect2(Vector2(14.0, 14.0), Vector2(maxf(1.0, size.x - 28.0), maxf(1.0, size.y - 32.0)))
	for index in range(4):
		var y := plot.position.y + plot.size.y * float(index) / 3.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(0.42, 0.52, 0.72, 0.12), 1.0)
	if values.is_empty():
		draw_line(plot.position + Vector2(0.0, plot.size.y * 0.5), Vector2(plot.end.x, plot.position.y + plot.size.y * 0.5), Color(accent.r, accent.g, accent.b, 0.35), 2.0)
		return

	var plot_values: Array = values.duplicate()
	if plot_values.size() == 1:
		plot_values.append(plot_values[0])
	var minimum := int(plot_values[0])
	var maximum := int(plot_values[0])
	for value in plot_values:
		minimum = mini(minimum, int(value))
		maximum = maxi(maximum, int(value))
	minimum -= 12
	maximum += 12
	var span := maxi(1, maximum - minimum)
	var points := PackedVector2Array()
	for index in range(plot_values.size()):
		var x := plot.position.x + plot.size.x * float(index) / float(plot_values.size() - 1)
		var normalized := float(int(plot_values[index]) - minimum) / float(span)
		var y := plot.end.y - normalized * plot.size.y
		points.append(Vector2(x, y))
	if points.size() >= 2:
		draw_polyline(points, Color(accent.r, accent.g, accent.b, 0.20), 7.0, true)
		draw_polyline(points, accent, 2.4, true)
	for point in points:
		draw_circle(point, 3.2, accent.lightened(0.18))
		draw_circle(point, 1.3, Color.WHITE)
