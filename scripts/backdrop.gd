extends Control

var time_value := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()

func _draw() -> void:
	var viewport_size: Vector2 = get_rect().size

	# Layered near-black gradient keeps empty states from becoming dead black space.
	for i in range(14):
		var t: float = float(i) / 13.0
		var c := Color("0D131B").lerp(Color("05080D"), t)
		draw_rect(Rect2(0, float(i) * viewport_size.y / 14.0, viewport_size.x, viewport_size.y / 14.0 + 1.0), c, true)

	# Large off-center club watermark.
	var mark_origin := Vector2(viewport_size.x * 0.56, viewport_size.y * 0.14)
	var mark_size: float = viewport_size.x * 0.72
	var watermark := Color(0.45,0.63,0.72,0.028)
	draw_line(mark_origin, mark_origin + Vector2(0, mark_size), watermark, 18)
	draw_line(mark_origin, mark_origin + Vector2(mark_size*0.62, 0), watermark, 18)
	draw_line(mark_origin + Vector2(0, mark_size*0.50), mark_origin + Vector2(mark_size*0.52, mark_size*0.50), watermark, 18)
	draw_line(mark_origin + Vector2(0, mark_size), mark_origin + Vector2(mark_size*0.62, mark_size), watermark, 18)

	# Soft stadium light fields behind content.
	var pulse: float = 0.5 + 0.5 * sin(time_value * 0.42)
	draw_circle(Vector2(viewport_size.x*0.96, viewport_size.y*0.10), viewport_size.x*(0.43+pulse*0.018), Color(0.18,0.37,0.44,0.070))
	draw_circle(Vector2(viewport_size.x*0.08, viewport_size.y*0.62), viewport_size.x*0.40, Color(0.06,0.20,0.25,0.045))

	# Broadcast spotlights, extremely low opacity so text remains clean.
	var beam_left := PackedVector2Array([
		Vector2(viewport_size.x*0.06,0),
		Vector2(viewport_size.x*0.12,0),
		Vector2(viewport_size.x*0.48,viewport_size.y),
		Vector2(viewport_size.x*0.20,viewport_size.y),
	])
	var beam_right := PackedVector2Array([
		Vector2(viewport_size.x*0.82,0),
		Vector2(viewport_size.x*0.89,0),
		Vector2(viewport_size.x*0.70,viewport_size.y),
		Vector2(viewport_size.x*0.48,viewport_size.y),
	])
	draw_colored_polygon(beam_left, Color(0.45,0.84,0.94,0.010))
	draw_colored_polygon(beam_right, Color(0.45,0.84,0.94,0.008))

	# Faint lower stadium bowl / floor perspective fills long mobile empty states.
	var horizon_y: float = viewport_size.y * 0.69
	draw_arc(Vector2(viewport_size.x*0.50,horizon_y+170), viewport_size.x*0.72, PI*1.08, PI*1.92, 50, Color(0.46,0.66,0.75,0.045), 1.0)
	draw_arc(Vector2(viewport_size.x*0.50,horizon_y+190), viewport_size.x*0.88, PI*1.10, PI*1.90, 50, Color(0.46,0.66,0.75,0.025), 1.0)
	for i in range(1,6):
		var t: float = float(i)/6.0
		var y: float = lerpf(horizon_y, viewport_size.y+10.0, t)
		draw_line(Vector2(viewport_size.x*0.10*t,y), Vector2(viewport_size.x*(1.0-0.10*t),y), Color(0.60,0.74,0.82,0.018+0.006*t), 1.0)
	for i in range(7):
		var x: float = viewport_size.x * float(i) / 6.0
		draw_line(Vector2(viewport_size.x*0.5,horizon_y), Vector2(x,viewport_size.y), Color(0.58,0.74,0.82,0.014), 1.0)

	# Slow editorial sweep.
	var sweep: float = fmod(time_value * 8.0, viewport_size.y + 240.0) - 120.0
	draw_line(Vector2(-40,sweep),Vector2(viewport_size.x+40,sweep-48),Color(0.45,0.87,0.97,0.026),1.0)

	# Sparse technical anchors.
	var spacing := 88.0
	for i in range(9):
		var y := 70.0 + float(i) * spacing
		if y < viewport_size.y:
			draw_line(Vector2(18,y),Vector2(30,y),Color(0.62,0.72,0.80,0.075),1)
			draw_circle(Vector2(viewport_size.x-22,y+18),1.1,Color(0.62,0.72,0.80,0.065))
