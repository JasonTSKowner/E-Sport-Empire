class_name MatchVisualizer
extends Control

const FIELD := Color("081a31")
const FIELD_ALT := Color("0b213c")
const BOARD := Color("28496d")
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
var sequence := 0


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 238.0)
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
		our_positions.append(Vector2(0.25, lane))
		their_positions.append(Vector2(0.75, 1.0 - lane))
	our_targets = our_positions.duplicate()
	their_targets = their_positions.duplicate()
	ball_position = Vector2(0.5, 0.5)
	ball_start = ball_position
	ball_target = ball_position
	momentum = int(session.get("momentum", 0))
	animation_progress = 1.0
	queue_redraw()


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	action_key = action
	event_type = str(event.get("type", "neutral"))
	momentum = clampi(new_momentum, -100, 100)
	sequence += 1
	ball_start = ball_position
	var lane_seed := float((sequence * 37) % 67) / 100.0 + 0.16
	if event_type == "good":
		ball_target = Vector2(0.94, lane_seed)
	elif event_type == "bad":
		ball_target = Vector2(0.06, 1.0 - lane_seed)
	elif quality > 0:
		ball_target = Vector2(0.72, lane_seed)
	elif quality < 0:
		ball_target = Vector2(0.28, 1.0 - lane_seed)
	else:
		ball_target = Vector2(0.50, lane_seed)
	our_targets.clear()
	their_targets.clear()
	for index in range(our_positions.size()):
		var lane := float(index + 1) / float(our_positions.size() + 1)
		var push := 0.58
		if action == "press":
			push = 0.72
		elif action == "counter":
			push = 0.64 if quality >= 0 else 0.40
		else:
			push = 0.52
		our_targets.append(Vector2(push - float(index) * 0.055, lane + sin(float(sequence + index)) * 0.08))
		their_targets.append(Vector2(1.0 - push + float(index) * 0.055, 1.0 - lane + cos(float(sequence + index)) * 0.08))
	animation_progress = 0.0
	flash_strength = 1.0 if event_type in ["good", "bad"] else 0.42
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
		animation_progress = minf(1.0, animation_progress + delta * 2.8)
		var eased := 1.0 - pow(1.0 - animation_progress, 3.0)
		ball_position = ball_start.lerp(ball_target, eased)
		for index in range(our_positions.size()):
			our_positions[index] = our_positions[index].lerp(our_targets[index], minf(1.0, delta * 7.0))
			their_positions[index] = their_positions[index].lerp(their_targets[index], minf(1.0, delta * 7.0))
	if flash_strength > 0.0:
		flash_strength = maxf(0.0, flash_strength - delta * 1.9)
	queue_redraw()


func _draw() -> void:
	var arena := Rect2(Vector2(7.0, 28.0), Vector2(maxf(1.0, size.x - 14.0), maxf(1.0, size.y - 36.0)))
	draw_rect(Rect2(Vector2.ZERO, size), Color("050817"), true)
	draw_rect(arena, FIELD, true)
	var stripe_width := arena.size.x / 8.0
	for stripe in range(8):
		if stripe % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(stripe_width * stripe, 0.0), Vector2(stripe_width, arena.size.y)), FIELD_ALT, true)
	draw_rect(arena, BOARD, false, 3.0)
	var middle_x := arena.position.x + arena.size.x * 0.5
	draw_line(Vector2(middle_x, arena.position.y), Vector2(middle_x, arena.end.y), Color(0.35, 0.58, 0.78, 0.48), 2.0)
	draw_arc(Vector2(middle_x, arena.get_center().y), arena.size.y * 0.18, 0.0, TAU, 48, Color(0.35, 0.58, 0.78, 0.50), 2.0)
	var goal_height := arena.size.y * 0.36
	var goal_y := arena.get_center().y - goal_height * 0.5
	draw_rect(Rect2(arena.position.x - 5.0, goal_y, 8.0, goal_height), Color(0.18, 0.88, 1.0, 0.28), true)
	draw_rect(Rect2(arena.end.x - 3.0, goal_y, 8.0, goal_height), Color(1.0, 0.35, 0.48, 0.28), true)
	for pad_x in [0.19, 0.5, 0.81]:
		for pad_y in [0.22, 0.78]:
			var pad := _field_point(Vector2(pad_x, pad_y), arena)
			draw_circle(pad, 4.0, Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.30))
			draw_circle(pad, 2.0, BOOST_COLOR)
	var momentum_center := size.x * 0.5
	var momentum_width := size.x - 28.0
	draw_rect(Rect2(14.0, 10.0, momentum_width, 7.0), Color("172140"), true)
	if momentum >= 0:
		draw_rect(Rect2(momentum_center, 10.0, momentum_width * 0.5 * float(momentum) / 100.0, 7.0), OUR_COLOR, true)
	else:
		var width := momentum_width * 0.5 * float(-momentum) / 100.0
		draw_rect(Rect2(momentum_center - width, 10.0, width, 7.0), THEIR_COLOR, true)
	draw_line(Vector2(momentum_center, 8.0), Vector2(momentum_center, 19.0), BALL_COLOR, 2.0)
	var ball_from := _field_point(ball_start, arena)
	var ball_now := _field_point(ball_position, arena)
	draw_line(ball_from, ball_now, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.25), 3.0)
	for position in our_positions:
		_draw_car(_field_point(position, arena), OUR_COLOR, 1.0)
	for position in their_positions:
		_draw_car(_field_point(position, arena), THEIR_COLOR, -1.0)
	draw_circle(ball_now, 11.0, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.10))
	draw_circle(ball_now, 6.0, BALL_COLOR)
	draw_circle(ball_now + Vector2(-1.5, -1.5), 2.0, Color("b9c9dd"))
	if flash_strength > 0.0:
		var flash_color := OUR_COLOR if event_type == "good" else THEIR_COLOR if event_type == "bad" else BOOST_COLOR
		draw_rect(arena, Color(flash_color.r, flash_color.g, flash_color.b, flash_strength * 0.10), true)
		draw_rect(arena, Color(flash_color.r, flash_color.g, flash_color.b, flash_strength * 0.55), false, 4.0)


func _field_point(normalized: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(
		clampf(normalized.x, 0.02, 0.98) * arena.size.x,
		clampf(normalized.y, 0.04, 0.96) * arena.size.y
	)


func _draw_car(center: Vector2, color: Color, direction: float) -> void:
	var length := 13.0
	var width := 7.0
	var nose := center + Vector2(length * direction, 0.0)
	var rear_top := center + Vector2(-length * 0.65 * direction, -width)
	var rear_bottom := center + Vector2(-length * 0.65 * direction, width)
	draw_colored_polygon(PackedVector2Array([nose, rear_top, rear_bottom]), color)
	draw_circle(center + Vector2(-length * 0.85 * direction, 0.0), 4.0, Color(color.r, color.g, color.b, 0.24))
	draw_line(center + Vector2(-length * 0.9 * direction, 0.0), center + Vector2(-length * 1.45 * direction, 0.0), Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.55), 3.0)
