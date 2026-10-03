class_name MatchVisualizer
extends Control

const FIELD := Color("07182b")
const FIELD_ALT := Color("0a2038")
const BOARD := Color("36577a")
const OUR_COLOR := Color("2de2ff")
const THEIR_COLOR := Color("ff647c")
const BALL_COLOR := Color("f3f6ff")
const BOOST_COLOR := Color("ffbf69")

var our_positions: Array[Vector2] = []
var their_positions: Array[Vector2] = []
var our_targets: Array[Vector2] = []
var their_targets: Array[Vector2] = []
var ball_position := Vector2(0.5, 0.5)
var ball_start := Vector2(0.5, 0.5)
var ball_target := Vector2(0.5, 0.5)
var action_key := "control"
var event_type := "neutral"
var momentum := 0
var animation_progress := 1.0
var flash_strength := 0.0
var goal_pulse := 0.0
var sequence := 0


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 286.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	if our_positions.is_empty():
		configure({"format": "1v1"})


func configure(session: Dictionary) -> void:
	var format := str(session.get("format", "1v1"))
	var count := 1
	if format == "2v2":
		count = 2
	elif format == "3v3":
		count = 3
	our_positions.clear()
	their_positions.clear()
	for index in range(count):
		var lane := float(index + 1) / float(count + 1)
		our_positions.append(Vector2(0.28, lane))
		their_positions.append(Vector2(0.72, 1.0 - lane))
	our_targets = our_positions.duplicate()
	their_targets = their_positions.duplicate()
	ball_position = Vector2(0.5, 0.5)
	ball_start = ball_position
	ball_target = ball_position
	momentum = int(session.get("momentum", 0))
	animation_progress = 1.0
	goal_pulse = 0.0
	queue_redraw()


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	action_key = action
	event_type = str(event.get("type", "neutral"))
	momentum = clampi(new_momentum, -100, 100)
	sequence += 1
	ball_start = ball_position
	var lane_seed := 0.16 + float((sequence * 37) % 68) / 100.0

	if event_type == "good":
		ball_target = Vector2(0.96, lane_seed)
		goal_pulse = 1.0
	elif event_type == "bad":
		ball_target = Vector2(0.04, 1.0 - lane_seed)
		goal_pulse = -1.0
	elif quality > 0:
		ball_target = Vector2(0.76, lane_seed)
	elif quality < 0:
		ball_target = Vector2(0.24, 1.0 - lane_seed)
	else:
		ball_target = Vector2(0.50, lane_seed)

	our_targets.clear()
	their_targets.clear()
	for index in range(our_positions.size()):
		var lane := float(index + 1) / float(our_positions.size() + 1)
		var push := 0.57
		if action == "press":
			push = 0.70
		elif action == "counter":
			push = 0.62 if quality >= 0 else 0.42
		elif action == "control":
			push = 0.54
		var spread := float(index) * 0.045
		our_targets.append(Vector2(push - spread, clampf(lane + sin(float(sequence + index)) * 0.07, 0.10, 0.90)))
		their_targets.append(Vector2(1.0 - push + spread, clampf(1.0 - lane + cos(float(sequence + index)) * 0.07, 0.10, 0.90)))

	animation_progress = 0.0
	flash_strength = 1.0 if event_type in ["good", "bad"] else 0.30
	queue_redraw()


func snapshot_state() -> Dictionary:
	return {
		"cars": our_positions.size() + their_positions.size(),
		"momentum": momentum,
		"action": action_key,
		"event_type": event_type,
		"sequence": sequence,
	}


func _process(delta: float) -> void:
	if animation_progress < 1.0:
		animation_progress = minf(1.0, animation_progress + delta * 2.45)
		var eased := 1.0 - pow(1.0 - animation_progress, 3.0)
		ball_position = ball_start.lerp(ball_target, eased)
		for index in range(our_positions.size()):
			our_positions[index] = our_positions[index].lerp(our_targets[index], minf(1.0, delta * 6.2))
			their_positions[index] = their_positions[index].lerp(their_targets[index], minf(1.0, delta * 6.2))
	if flash_strength > 0.0:
		flash_strength = maxf(0.0, flash_strength - delta * 1.7)
	if absf(goal_pulse) > 0.0:
		goal_pulse = move_toward(goal_pulse, 0.0, delta * 0.85)
	queue_redraw()


func _draw() -> void:
	var arena := Rect2(Vector2(9.0, 35.0), Vector2(maxf(1.0, size.x - 18.0), maxf(1.0, size.y - 46.0)))
	draw_rect(Rect2(Vector2.ZERO, size), Color("030611"), true)

	# outer broadcast frame
	draw_rect(arena.grow(5.0), Color("0b1022"), true)
	draw_rect(arena, FIELD, true)
	var stripe_width := arena.size.x / 10.0
	for stripe in range(10):
		if stripe % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(stripe_width * stripe, 0.0), Vector2(stripe_width, arena.size.y)), FIELD_ALT, true)

	draw_rect(arena, Color(BOARD.r, BOARD.g, BOARD.b, 0.76), false, 2.5)
	var middle_x := arena.position.x + arena.size.x * 0.5
	draw_line(Vector2(middle_x, arena.position.y), Vector2(middle_x, arena.end.y), Color(0.42, 0.63, 0.80, 0.46), 1.5)
	draw_arc(Vector2(middle_x, arena.get_center().y), arena.size.y * 0.17, 0.0, TAU, 48, Color(0.42, 0.63, 0.80, 0.50), 1.5)
	draw_circle(arena.get_center(), 2.5, Color(0.55, 0.72, 0.88, 0.62))

	_draw_goal(arena, true)
	_draw_goal(arena, false)
	_draw_boost_pads(arena)

	# broadcast momentum strip
	var momentum_center := size.x * 0.5
	var momentum_width := size.x - 30.0
	draw_rect(Rect2(15.0, 12.0, momentum_width, 8.0), Color("111a35"), true)
	if momentum >= 0:
		draw_rect(Rect2(momentum_center, 12.0, momentum_width * 0.5 * float(momentum) / 100.0, 8.0), OUR_COLOR, true)
	else:
		var width := momentum_width * 0.5 * float(-momentum) / 100.0
		draw_rect(Rect2(momentum_center - width, 12.0, width, 8.0), THEIR_COLOR, true)
	draw_line(Vector2(momentum_center, 9.0), Vector2(momentum_center, 23.0), BALL_COLOR, 2.0)

	var ball_from := _field_point(ball_start, arena)
	var ball_now := _field_point(ball_position, arena)
	draw_line(ball_from, ball_now, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.13), 4.0)
	draw_line(ball_from, ball_now, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.28), 1.5)

	for index in range(our_positions.size()):
		_draw_car(_field_point(our_positions[index], arena), OUR_COLOR, 1.0, index)
	for index in range(their_positions.size()):
		_draw_car(_field_point(their_positions[index], arena), THEIR_COLOR, -1.0, index)

	draw_circle(ball_now + Vector2(2.5, 4.0), 7.0, Color(0, 0, 0, 0.34))
	draw_circle(ball_now, 11.0, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.08))
	draw_circle(ball_now, 6.2, BALL_COLOR)
	draw_circle(ball_now + Vector2(-1.7, -1.7), 2.0, Color("a8b9d1"))

	if absf(goal_pulse) > 0.02:
		var pulse_color := OUR_COLOR if goal_pulse > 0.0 else THEIR_COLOR
		var pulse_alpha := absf(goal_pulse) * 0.18
		draw_rect(arena, Color(pulse_color.r, pulse_color.g, pulse_color.b, pulse_alpha), true)
		var ring_radius := 20.0 + (1.0 - absf(goal_pulse)) * 80.0
		var goal_center := Vector2(arena.end.x - 4.0, arena.get_center().y) if goal_pulse > 0.0 else Vector2(arena.position.x + 4.0, arena.get_center().y)
		draw_arc(goal_center, ring_radius, 0.0, TAU, 40, Color(pulse_color.r, pulse_color.g, pulse_color.b, absf(goal_pulse) * 0.55), 3.0)

	if flash_strength > 0.0:
		var flash_color := OUR_COLOR if event_type == "good" else THEIR_COLOR if event_type == "bad" else BOOST_COLOR
		draw_rect(arena, Color(flash_color.r, flash_color.g, flash_color.b, flash_strength * 0.055), true)
		draw_rect(arena, Color(flash_color.r, flash_color.g, flash_color.b, flash_strength * 0.40), false, 3.0)


func _draw_goal(arena: Rect2, left: bool) -> void:
	var goal_height := arena.size.y * 0.38
	var goal_y := arena.get_center().y - goal_height * 0.5
	var x := arena.position.x - 7.0 if left else arena.end.x - 1.0
	var goal_rect := Rect2(x, goal_y, 9.0, goal_height)
	var color := OUR_COLOR if left else THEIR_COLOR
	draw_rect(goal_rect, Color(color.r, color.g, color.b, 0.14), true)
	draw_rect(goal_rect, Color(color.r, color.g, color.b, 0.48), false, 2.0)
	for i in range(1, 4):
		var yy := goal_y + goal_height * float(i) / 4.0
		draw_line(Vector2(goal_rect.position.x, yy), Vector2(goal_rect.end.x, yy), Color(color.r, color.g, color.b, 0.22), 1.0)


func _draw_boost_pads(arena: Rect2) -> void:
	for pad in [
		Vector2(0.18, 0.18), Vector2(0.18, 0.82),
		Vector2(0.38, 0.32), Vector2(0.38, 0.68),
		Vector2(0.62, 0.32), Vector2(0.62, 0.68),
		Vector2(0.82, 0.18), Vector2(0.82, 0.82)
	]:
		var point := _field_point(pad, arena)
		draw_circle(point, 5.0, Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.10))
		draw_circle(point, 2.0, BOOST_COLOR)


func _field_point(normalized: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(
		clampf(normalized.x, 0.02, 0.98) * arena.size.x,
		clampf(normalized.y, 0.04, 0.96) * arena.size.y
	)


func _draw_car(center: Vector2, color: Color, direction: float, index: int) -> void:
	var length := 13.0
	var width := 7.5
	var wobble := sin(float(sequence + index) * 0.8) * 1.5
	var nose := center + Vector2(length * direction, wobble)
	var rear_top := center + Vector2(-length * 0.72 * direction, -width)
	var rear_bottom := center + Vector2(-length * 0.72 * direction, width)
	draw_circle(center + Vector2(2.0, 4.0), 10.0, Color(0, 0, 0, 0.28))
	draw_colored_polygon(PackedVector2Array([nose, rear_top, rear_bottom]), color)
	draw_line(center + Vector2(-length * 0.92 * direction, 0.0), center + Vector2(-length * 1.55 * direction, 0.0), Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.58), 4.0)
	draw_circle(center, 3.0, Color(0.80, 0.92, 1.0, 0.55))
