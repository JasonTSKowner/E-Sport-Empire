extends Control

var time_value := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("070A0F"))

	# Large matte light fields instead of obvious neon glows.
	var pulse := 0.5 + 0.5 * sin(time_value * 0.38)
	draw_circle(
		Vector2(viewport_size.x * 0.82, viewport_size.y * 0.08),
		viewport_size.x * (0.62 + pulse * 0.03),
		Color(0.11, 0.18, 0.24, 0.11)
	)
	draw_circle(
		Vector2(viewport_size.x * 0.10, viewport_size.y * 0.62),
		viewport_size.x * (0.54 + (1.0 - pulse) * 0.025),
		Color(0.12, 0.10, 0.18, 0.065)
	)

	# Subtle editorial grid.
	var spacing := 72.0
	var drift := fmod(time_value * 2.2, spacing)
	var x := -spacing + drift
	while x < viewport_size.x + spacing:
		draw_line(
			Vector2(x, 0),
			Vector2(x - viewport_size.y * 0.11, viewport_size.y),
			Color(0.55, 0.64, 0.73, 0.025),
			1.0
		)
		x += spacing

	var y := -spacing + drift * 0.55
	while y < viewport_size.y + spacing:
		draw_line(
			Vector2(0, y),
			Vector2(viewport_size.x, y - viewport_size.x * 0.05),
			Color(0.55, 0.64, 0.73, 0.018),
			1.0
		)
		y += spacing

	# Fine dot field adds texture without reading as FX.
	for row in range(9):
		for column in range(5):
			var dot := Vector2(
				viewport_size.x * (0.08 + float(column) * 0.21),
				viewport_size.y * (0.08 + float(row) * 0.115)
			)
			draw_circle(dot, 1.0, Color(0.70, 0.78, 0.86, 0.045))
