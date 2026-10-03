class_name TrainingVisualizer
extends Control

const BG := Color("050817")
const FIELD := Color("081b31")
const FIELD_ALT := Color("0b223c")
const LINE := Color("355879")
const BALL := Color("f3f6ff")
const BOOST := Color("ffbf69")

var accent := Color("2de2ff")
var fatigue := 0
var focus_remaining := 3
var focus_limit := 3
var animation_time := 0.0
var intensity := 0.62
var last_session_age := 999999


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 190.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	accent = color
	fatigue = int(player.get("fatigue", 0))
	focus_remaining = int(readiness.get("slots_remaining", 0))
	focus_limit = maxi(1, int(readiness.get("limit", 3)))
	intensity = clampf(0.82 - float(fatigue) / 180.0, 0.28, 0.82)
	var history: Array = player.get("training_history", [])
	if not history.is_empty():
		last_session_age = maxi(0, int(Time.get_unix_time_from_system()) - int(history[0].get("timestamp", 0)))
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta * (0.65 + intensity)
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	var arena := Rect2(Vector2(8, 28), Vector2(maxf(1.0, size.x - 16), maxf(1.0, size.y - 38)))
	draw_rect(outer, BG, true)
	draw_rect(arena, FIELD, true)

	var stripe_h := arena.size.y / 6.0
	for i in range(6):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(0, stripe_h * i), Vector2(arena.size.x, stripe_h)), FIELD_ALT, true)

	draw_rect(arena, Color(accent.r, accent.g, accent.b, 0.22), false, 2.0)
	var center := arena.get_center()
	draw_line(Vector2(arena.position.x, center.y), Vector2(arena.end.x, center.y), Color(LINE.r, LINE.g, LINE.b, 0.55), 1.5)
	draw_arc(center, arena.size.y * 0.17, 0.0, TAU, 40, Color(LINE.r, LINE.g, LINE.b, 0.55), 1.5)

	var goal_w := arena.size.x * 0.28
	draw_rect(Rect2(center.x - goal_w * 0.5, arena.position.y - 3, goal_w, 7), Color(accent.r, accent.g, accent.b, 0.16), true)
	draw_rect(Rect2(center.x - goal_w * 0.5, arena.end.y - 4, goal_w, 7), Color(accent.r, accent.g, accent.b, 0.16), true)

	for px in [0.18, 0.5, 0.82]:
		for py in [0.22, 0.78]:
			var pad := arena.position + Vector2(arena.size.x * px, arena.size.y * py)
			draw_circle(pad, 5.0, Color(BOOST.r, BOOST.g, BOOST.b, 0.12))
			draw_circle(pad, 2.2, BOOST)

	var phase := fmod(animation_time, TAU)
	var car_norm := Vector2(0.5 + sin(phase) * 0.28, 0.60 + cos(phase * 1.35) * 0.22)
	var ball_norm := Vector2(0.5 + sin(phase * 0.72 + 0.8) * 0.18, 0.36 + cos(phase * 0.90) * 0.14)
	var car := arena.position + Vector2(arena.size.x * car_norm.x, arena.size.y * car_norm.y)
	var ball := arena.position + Vector2(arena.size.x * ball_norm.x, arena.size.y * ball_norm.y)
	var trail := car - Vector2(sin(phase + 0.6), cos(phase + 0.6)).normalized() * 28.0

	draw_line(trail, car, Color(accent.r, accent.g, accent.b, 0.32), 5.0)
	draw_circle(car + Vector2(2, 4), 10, Color(0, 0, 0, 0.28))
	_draw_car(car)
	draw_line(car, ball, Color(accent.r, accent.g, accent.b, 0.12), 2.0)
	draw_circle(ball + Vector2(2, 3), 6.5, Color(0, 0, 0, 0.25))
	draw_circle(ball, 6.0, BALL)
	draw_circle(ball + Vector2(-1.5, -1.5), 2.0, Color("a9bad2"))

	var focus_ratio := float(focus_remaining) / float(focus_limit)
	draw_rect(Rect2(12, 10, size.x - 24, 7), Color("172140"), true)
	draw_rect(Rect2(12, 10, (size.x - 24) * focus_ratio, 7), accent, true)

	if last_session_age < 8:
		var pulse := 0.5 + 0.5 * sin(animation_time * 6.0)
		draw_rect(arena, Color(accent.r, accent.g, accent.b, 0.04 + pulse * 0.05), true)


func _draw_car(center: Vector2) -> void:
	var angle := animation_time + PI * 0.5
	var forward := Vector2(cos(angle), sin(angle))
	var side := Vector2(-forward.y, forward.x)
	var nose := center + forward * 13.0
	var rear := center - forward * 10.0
	var points := PackedVector2Array([
		nose,
		rear + side * 7.0,
		rear - side * 7.0,
	])
	draw_colored_polygon(points, accent)
	draw_circle(rear - forward * 3.0, 5.0, Color(accent.r, accent.g, accent.b, 0.20))
