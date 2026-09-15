extends Control

var drift := 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	drift = fmod(drift + delta * 7.0, 120.0)
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("050817"))
	for i in range(9):
		var y := fmod(float(i) * 118.0 + drift, size.y + 118.0) - 118.0
		var alpha := 0.022 + float(i % 3) * 0.008
		draw_line(Vector2(0.0, y), Vector2(size.x, y - 72.0), Color(0.20, 0.74, 1.0, alpha), 1.0)
	for i in range(5):
		var x := float(i) * size.x / 4.0
		draw_line(Vector2(x, 0.0), Vector2(x - 140.0, size.y), Color(0.55, 0.34, 1.0, 0.025), 1.0)
	var pulse := (sin(Time.get_ticks_msec() / 1200.0) + 1.0) * 0.5
	draw_circle(
		Vector2(size.x * 0.88, size.y * 0.12), 120.0 + pulse * 12.0, Color(0.20, 0.72, 1.0, 0.045)
	)
	draw_circle(
		Vector2(size.x * 0.06, size.y * 0.72), 155.0 + pulse * 16.0, Color(0.56, 0.30, 1.0, 0.04)
	)
