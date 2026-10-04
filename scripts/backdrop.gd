extends Control

var time_value := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("080B10"))

	# Large off-center brand watermark.
	var mark_origin := Vector2(viewport_size.x * 0.56, viewport_size.y * 0.15)
	var mark_size := viewport_size.x * 0.72
	var watermark := Color(0.45,0.55,0.66,0.022)
	draw_line(mark_origin, mark_origin + Vector2(0, mark_size), watermark, 22)
	draw_line(mark_origin, mark_origin + Vector2(mark_size*0.62, 0), watermark, 22)
	draw_line(mark_origin + Vector2(0, mark_size*0.50), mark_origin + Vector2(mark_size*0.52, mark_size*0.50), watermark, 22)
	draw_line(mark_origin + Vector2(0, mark_size), mark_origin + Vector2(mark_size*0.62, mark_size), watermark, 22)

	# Slow editorial sweep.
	var sweep := fmod(time_value * 8.0, viewport_size.y + 240.0) - 120.0
	draw_line(
		Vector2(-40, sweep),
		Vector2(viewport_size.x + 40, sweep - 48),
		Color(0.45,0.87,0.97,0.022),
		1.0
	)

	# Sparse technical coordinate system.
	var spacing := 88.0
	for i in range(7):
		var y := 70.0 + float(i) * spacing
		if y < viewport_size.y:
			draw_line(Vector2(18, y), Vector2(30, y), Color(0.62,0.68,0.76,0.08), 1)
			draw_circle(Vector2(viewport_size.x-22, y+18), 1.1, Color(0.62,0.68,0.76,0.07))
	for i in range(4):
		var x := viewport_size.x * (0.18 + float(i) * 0.22)
		draw_line(Vector2(x, viewport_size.y*0.76), Vector2(x+38, viewport_size.y), Color(0.62,0.68,0.76,0.018), 1)

	# One controlled brand field, not multicolor neon.
	var pulse := 0.5 + 0.5 * sin(time_value * 0.45)
	draw_circle(
		Vector2(viewport_size.x*0.94, viewport_size.y*0.07),
		viewport_size.x * (0.42 + pulse*0.015),
		Color(0.16,0.27,0.34,0.055)
	)
