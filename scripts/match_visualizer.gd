class_name MatchVisualizer
extends Control

const FIELD := Color("061522")
const FIELD_ALT := Color("082033")
const BOARD := Color("3a5d7e")
const OUR_COLOR := Color("2de2ff")
const THEIR_COLOR := Color("ff647c")
const BALL_COLOR := Color("f5f7ff")
const BOOST_COLOR := Color("ffbf69")
const WHITE_DIM := Color("9eb3c9")

var format := "1v1"
var our_positions: Array[Vector2] = []
var their_positions: Array[Vector2] = []
var our_velocities: Array[Vector2] = []
var their_velocities: Array[Vector2] = []
var our_targets: Array[Vector2] = []
var their_targets: Array[Vector2] = []
var our_boost: Array[float] = []
var their_boost: Array[float] = []

var ball_position := Vector2(0.5, 0.5)
var ball_start := Vector2(0.5, 0.5)
var ball_target := Vector2(0.5, 0.5)
var ball_height := 0.0
var ball_target_height := 0.0
var ball_velocity := Vector2.ZERO

var phase := "kickoff"
var action_key := "control"
var event_type := "neutral"
var momentum := 0
var sequence := 0
var event_progress := 1.0
var camera_kick := 0.0
var goal_flash := 0.0
var goal_side := 0
var time_alive := 0.0

var boost_particles: Array[Dictionary] = []
var ball_trail: Array[Vector2] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 336.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	if our_positions.is_empty():
		configure({"format": "1v1"})


func configure(session: Dictionary) -> void:
	format = str(session.get("format", "1v1"))
	var count := 1
	if format == "2v2":
		count = 2
	elif format == "3v3":
		count = 3
	our_positions.clear()
	their_positions.clear()
	our_velocities.clear()
	their_velocities.clear()
	our_targets.clear()
	their_targets.clear()
	our_boost.clear()
	their_boost.clear()
	for index in range(count):
		var lane := float(index + 1) / float(count + 1)
		our_positions.append(Vector2(0.25, lane))
		their_positions.append(Vector2(0.75, 1.0 - lane))
		our_velocities.append(Vector2.ZERO)
		their_velocities.append(Vector2.ZERO)
		our_targets.append(our_positions[index])
		their_targets.append(their_positions[index])
		our_boost.append(0.35)
		their_boost.append(0.35)
	ball_position = Vector2(0.5, 0.5)
	ball_start = ball_position
	ball_target = ball_position
	ball_height = 0.0
	ball_target_height = 0.0
	ball_velocity = Vector2.ZERO
	momentum = int(session.get("momentum", 0))
	phase = "kickoff"
	event_progress = 1.0
	goal_flash = 0.0
	goal_side = 0
	boost_particles.clear()
	ball_trail.clear()
	queue_redraw()


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	action_key = action
	event_type = str(event.get("type", "neutral"))
	phase = str(event.get("phase", "reset"))
	momentum = clampi(new_momentum, -100, 100)
	sequence += 1
	event_progress = 0.0
	ball_start = ball_position

	var lane_a := 0.18 + float((sequence * 31) % 64) / 100.0
	var lane_b := 0.18 + float((sequence * 47 + 13) % 64) / 100.0
	match phase:
		"buildup":
			ball_target = Vector2(0.56 if action != "counter" else 0.44, lane_a)
			ball_target_height = 0.08
		"challenge":
			ball_target = Vector2(0.56 if quality >= 0 else 0.44, lane_b)
			ball_target_height = 0.28
		"goal_ours":
			ball_target = Vector2(0.985, lane_a)
			ball_target_height = 0.22
			goal_flash = 1.0
			goal_side = 1
			camera_kick = 1.0
		"goal_theirs":
			ball_target = Vector2(0.015, lane_a)
			ball_target_height = 0.22
			goal_flash = 1.0
			goal_side = -1
			camera_kick = 1.0
		"chance_ours":
			ball_target = Vector2(0.84, lane_a)
			ball_target_height = 0.55
		"chance_theirs":
			ball_target = Vector2(0.16, lane_a)
			ball_target_height = 0.55
		_:
			ball_target = Vector2(0.5, lane_a)
			ball_target_height = 0.04

	_set_team_targets(quality)
	queue_redraw()


func _set_team_targets(quality: int) -> void:
	var count := our_positions.size()
	our_targets.clear()
	their_targets.clear()
	for index in range(count):
		var role_lane := float(index + 1) / float(count + 1)
		var our_x := 0.38
		var their_x := 0.62
		if phase == "buildup":
			our_x = 0.50 if action != "counter" else 0.35
			their_x = 0.67
		elif phase == "challenge":
			our_x = 0.54 if quality >= 0 else 0.43
			their_x = 0.46 if quality < 0 else 0.57
		elif phase in ["goal_ours", "chance_ours"]:
			our_x = 0.72 - float(index) * 0.07
			their_x = 0.80 - float(index) * 0.05
		elif phase in ["goal_theirs", "chance_theirs"]:
			our_x = 0.20 + float(index) * 0.05
			their_x = 0.28 + float(index) * 0.07
		var lane_offset := sin(float(sequence + index) * 1.73) * 0.075
		our_targets.append(Vector2(clampf(our_x, 0.08, 0.92), clampf(role_lane + lane_offset, 0.10, 0.90)))
		their_targets.append(Vector2(clampf(their_x, 0.08, 0.92), clampf(1.0 - role_lane - lane_offset, 0.10, 0.90)))


func snapshot_state() -> Dictionary:
	return {
		"cars": our_positions.size() + their_positions.size(),
		"momentum": momentum,
		"action": action_key,
		"event_type": event_type,
		"sequence": sequence,
		"phase": phase,
	}


func _process(delta: float) -> void:
	time_alive += delta
	event_progress = minf(1.0, event_progress + delta * 1.65)
	var move_strength := 3.6 if event_progress < 0.85 else 2.0

	for index in range(our_positions.size()):
		var before := our_positions[index]
		var wanted := our_targets[index] - before
		our_velocities[index] = our_velocities[index].lerp(wanted * 5.5, minf(1.0, delta * 5.0))
		our_positions[index] += our_velocities[index] * delta * move_strength
		our_positions[index].x = clampf(our_positions[index].x, 0.04, 0.96)
		our_positions[index].y = clampf(our_positions[index].y, 0.05, 0.95)
		our_boost[index] = lerpf(our_boost[index], 1.0 if wanted.length() > 0.12 else 0.18, minf(1.0, delta * 3.0))
		if our_boost[index] > 0.52:
			_spawn_boost_particle(our_positions[index], OUR_COLOR, our_velocities[index])

	for index in range(their_positions.size()):
		var before := their_positions[index]
		var wanted := their_targets[index] - before
		their_velocities[index] = their_velocities[index].lerp(wanted * 5.5, minf(1.0, delta * 5.0))
		their_positions[index] += their_velocities[index] * delta * move_strength
		their_positions[index].x = clampf(their_positions[index].x, 0.04, 0.96)
		their_positions[index].y = clampf(their_positions[index].y, 0.05, 0.95)
		their_boost[index] = lerpf(their_boost[index], 1.0 if wanted.length() > 0.12 else 0.18, minf(1.0, delta * 3.0))
		if their_boost[index] > 0.52:
			_spawn_boost_particle(their_positions[index], THEIR_COLOR, their_velocities[index])

	var old_ball := ball_position
	var smooth := 1.0 - pow(1.0 - event_progress, 2.4)
	ball_position = ball_start.lerp(ball_target, smooth)
	ball_velocity = (ball_position - old_ball) / maxf(delta, 0.001)
	ball_height = lerpf(ball_height, ball_target_height * sin(event_progress * PI), minf(1.0, delta * 8.0))
	if old_ball.distance_to(ball_position) > 0.002:
		ball_trail.push_front(ball_position)
		while ball_trail.size() > 12:
			ball_trail.pop_back()

	for particle in boost_particles:
		particle["life"] = float(particle.get("life", 0.0)) - delta
		particle["position"] = Vector2(particle.get("position", Vector2.ZERO)) + Vector2(particle.get("velocity", Vector2.ZERO)) * delta
	for index in range(boost_particles.size() - 1, -1, -1):
		if float(boost_particles[index].get("life", 0.0)) <= 0.0:
			boost_particles.remove_at(index)

	camera_kick = move_toward(camera_kick, 0.0, delta * 2.8)
	goal_flash = move_toward(goal_flash, 0.0, delta * 1.45)
	queue_redraw()


func _spawn_boost_particle(position: Vector2, color: Color, velocity: Vector2) -> void:
	if boost_particles.size() > 70 or randf() > 0.34:
		return
	var backward := -velocity.normalized() if velocity.length() > 0.01 else Vector2(-1, 0)
	boost_particles.append({
		"position": position,
		"velocity": backward * randf_range(0.08, 0.20) + Vector2(randf_range(-0.02, 0.02), randf_range(-0.02, 0.02)),
		"life": randf_range(0.18, 0.38),
		"max_life": 0.38,
		"color": color,
	})


func _arena_rect() -> Rect2:
	var kick := sin(time_alive * 45.0) * camera_kick * 2.6
	return Rect2(Vector2(10.0 + kick, 38.0), Vector2(maxf(1.0, size.x - 20.0), maxf(1.0, size.y - 50.0)))


func _draw() -> void:
	var arena := _arena_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color("02050c"), true)

	# broadcast frame / stadium depth
	draw_rect(arena.grow(8.0), Color("0a1020"), true)
	draw_rect(arena.grow(5.0), Color("111b30"), false, 2.0)
	draw_rect(arena, FIELD, true)

	var stripe_width := arena.size.x / 12.0
	for stripe in range(12):
		if stripe % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(stripe_width * stripe, 0), Vector2(stripe_width, arena.size.y)), FIELD_ALT, true)

	# soft stadium glow
	draw_circle(Vector2(arena.position.x + arena.size.x * 0.5, arena.position.y - 50), arena.size.x * 0.55, Color(0.08, 0.38, 0.62, 0.055))
	draw_circle(Vector2(arena.position.x + arena.size.x * 0.5, arena.end.y + 60), arena.size.x * 0.5, Color(0.45, 0.18, 0.55, 0.035))

	_draw_field_lines(arena)
	_draw_goals(arena)
	_draw_boost_pads(arena)
	_draw_momentum_bar()

	for particle in boost_particles:
		_draw_boost_particle(particle, arena)

	for index in range(our_positions.size()):
		_draw_car(_field_point(our_positions[index], arena), our_velocities[index], OUR_COLOR, index, true)
	for index in range(their_positions.size()):
		_draw_car(_field_point(their_positions[index], arena), their_velocities[index], THEIR_COLOR, index, false)

	_draw_ball(arena)

	if goal_flash > 0.01:
		var flash_color := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(arena, Color(flash_color.r, flash_color.g, flash_color.b, goal_flash * 0.12), true)
		var goal_center := Vector2(arena.end.x - 3.0, arena.get_center().y) if goal_side > 0 else Vector2(arena.position.x + 3.0, arena.get_center().y)
		for ring in range(3):
			var radius := 26.0 + float(ring) * 22.0 + (1.0 - goal_flash) * 45.0
			draw_arc(goal_center, radius, 0.0, TAU, 40, Color(flash_color.r, flash_color.g, flash_color.b, goal_flash * (0.52 - float(ring) * 0.12)), 3.0)


func _draw_field_lines(arena: Rect2) -> void:
	draw_rect(arena, Color(BOARD.r, BOARD.g, BOARD.b, 0.78), false, 2.2)
	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), Color(0.42, 0.63, 0.80, 0.46), 1.5)
	draw_arc(center, arena.size.y * 0.17, 0.0, TAU, 48, Color(0.42, 0.63, 0.80, 0.45), 1.5)
	draw_circle(center, 2.5, Color(0.55, 0.72, 0.88, 0.58))
	# penalty / goal areas for visual depth
	var box_w := arena.size.x * 0.12
	var box_h := arena.size.y * 0.52
	draw_rect(Rect2(arena.position.x, center.y - box_h * 0.5, box_w, box_h), Color(0.45, 0.65, 0.82, 0.18), false, 1.2)
	draw_rect(Rect2(arena.end.x - box_w, center.y - box_h * 0.5, box_w, box_h), Color(0.45, 0.65, 0.82, 0.18), false, 1.2)


func _draw_goals(arena: Rect2) -> void:
	var h := arena.size.y * 0.36
	for left in [true, false]:
		var color := OUR_COLOR if left else THEIR_COLOR
		var x := arena.position.x - 8.0 if left else arena.end.x - 1.0
		var goal := Rect2(x, arena.get_center().y - h * 0.5, 10.0, h)
		draw_rect(goal, Color(color.r, color.g, color.b, 0.10), true)
		draw_rect(goal, Color(color.r, color.g, color.b, 0.48), false, 2.0)
		for i in range(1, 5):
			var yy := goal.position.y + h * float(i) / 5.0
			draw_line(Vector2(goal.position.x, yy), Vector2(goal.end.x, yy), Color(color.r, color.g, color.b, 0.18), 1.0)


func _draw_boost_pads(arena: Rect2) -> void:
	var pads := [
		Vector2(0.14, 0.16), Vector2(0.14, 0.84),
		Vector2(0.34, 0.31), Vector2(0.34, 0.69),
		Vector2(0.50, 0.12), Vector2(0.50, 0.88),
		Vector2(0.66, 0.31), Vector2(0.66, 0.69),
		Vector2(0.86, 0.16), Vector2(0.86, 0.84),
	]
	for pad in pads:
		var p := _field_point(pad, arena)
		var pulse := 0.78 + sin(time_alive * 4.0 + pad.x * 10.0) * 0.18
		draw_circle(p, 6.0, Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.08 * pulse))
		draw_circle(p, 2.3, Color(BOOST_COLOR.r, BOOST_COLOR.g, BOOST_COLOR.b, 0.85 * pulse))


func _draw_momentum_bar() -> void:
	var width := size.x - 30.0
	var center_x := size.x * 0.5
	draw_rect(Rect2(15, 12, width, 8), Color("101a31"), true)
	if momentum >= 0:
		draw_rect(Rect2(center_x, 12, width * 0.5 * float(momentum) / 100.0, 8), OUR_COLOR, true)
	else:
		var w := width * 0.5 * float(-momentum) / 100.0
		draw_rect(Rect2(center_x - w, 12, w, 8), THEIR_COLOR, true)
	draw_line(Vector2(center_x, 9), Vector2(center_x, 23), BALL_COLOR, 2.0)


func _draw_boost_particle(particle: Dictionary, arena: Rect2) -> void:
	var life := float(particle.get("life", 0.0))
	var max_life := maxf(0.01, float(particle.get("max_life", 0.38)))
	var alpha := clampf(life / max_life, 0.0, 1.0)
	var color: Color = particle.get("color", BOOST_COLOR)
	var p := _field_point(Vector2(particle.get("position", Vector2.ZERO)), arena)
	draw_circle(p, 2.2 + alpha * 1.8, Color(color.r, color.g, color.b, alpha * 0.45))


func _draw_ball(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.18
		draw_circle(_field_point(ball_trail[i], arena), 3.5, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, alpha))
	var p := _field_point(ball_position, arena)
	var lift := ball_height * 20.0
	var shadow_scale := 1.0 - ball_height * 0.35
	draw_ellipse(Vector2(p.x + 3, p.y + 5), Vector2(7.0 * shadow_scale, 3.4 * shadow_scale), Color(0,0,0,0.34))
	var visual := p - Vector2(0, lift)
	draw_circle(visual, 11.5, Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.07))
	draw_circle(visual, 6.4, BALL_COLOR)
	draw_circle(visual + Vector2(-1.8, -1.8), 2.0, Color("a8b8cf"))


func _draw_car(center: Vector2, velocity: Vector2, color: Color, index: int, ours: bool) -> void:
	var dir := velocity.normalized()
	if dir.length() < 0.1:
		dir = Vector2(1, 0) if ours else Vector2(-1, 0)
	var side := Vector2(-dir.y, dir.x)
	var nose := center + dir * 13.0
	var rear := center - dir * 9.5
	var body := PackedVector2Array([
		nose,
		center + side * 6.8,
		rear + side * 5.3,
		rear - side * 5.3,
		center - side * 6.8,
	])
	draw_circle(center + Vector2(2.4, 4.2), 9.5, Color(0,0,0,0.30))
	draw_colored_polygon(body, Color(color.r * 0.72, color.g * 0.72, color.b * 0.72, 1.0))
	draw_polyline(body, color, 1.4, true)
	draw_line(center - dir * 2.0 + side * 4.0, center + dir * 5.0 + side * 3.0, Color(0.80,0.93,1.0,0.48), 2.0)
	draw_line(center - dir * 2.0 - side * 4.0, center + dir * 5.0 - side * 3.0, Color(0.80,0.93,1.0,0.48), 2.0)
	draw_circle(center, 2.0, Color(1,1,1,0.62))

	var tag := "#%d" % (index + 1)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	draw_string(font, center + Vector2(-text_size.x * 0.5, -12), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(color.r, color.g, color.b, 0.80))


func _field_point(normalized: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(
		clampf(normalized.x, 0.0, 1.0) * arena.size.x,
		clampf(normalized.y, 0.0, 1.0) * arena.size.y
	)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
