class_name EmpireMark
extends Control

var accent := Color("74DFF7")


func _ready() -> void:
	custom_minimum_size = Vector2(36, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("0A0F15"), true)
	draw_rect(r, Color(0.72,0.78,0.86,0.10), false, 1.0)

	var pad := minf(r.size.x, r.size.y) * 0.20
	var x0 := pad
	var x1 := r.size.x - pad
	var y0 := pad
	var y1 := r.size.y - pad
	var mid := (y0 + y1) * 0.5

	# stylized double-E / competition lanes
	draw_line(Vector2(x0, y0), Vector2(x0, y1), accent, 2.2)
	draw_line(Vector2(x0, y0), Vector2(x1, y0), accent, 2.2)
	draw_line(Vector2(x0, mid), Vector2(x1*0.86, mid), accent, 2.2)
	draw_line(Vector2(x0, y1), Vector2(x1, y1), accent, 2.2)

	var shift := r.size.x * 0.16
	draw_line(Vector2(x0+shift, y0+4), Vector2(x0+shift, y1-4), Color(0.90,0.94,0.98,0.64), 1.2)
	draw_circle(Vector2(x1-1.5, y0+1.5), 1.6, Color(0.90,0.94,0.98,0.80))
