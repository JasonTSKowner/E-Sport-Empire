class_name TrainingVisualizer
extends Control

const BG := Color("02050c")
const FIELD := Color("071827")
const FIELD_ALT := Color("0a2033")
const LINE := Color("355879")
const BALL := Color("f3f6ff")
const BOOST := Color("ffbf69")
const TARGET := Color("58e39b")
const DANGER := Color("ff647c")

var accent := Color("2de2ff")
var fatigue := 0
var focus_remaining := 3
var focus_limit := 3
var animation_time := 0.0
var intensity := 0.62
var last_session_age := 999999
var drill_id := "mechanics_lab"
var drill_label := "MECHANIK-LABOR"
var drill_phase := 0.0
var car_position := Vector2(0.22, 0.68)
var car_velocity := Vector2.ZERO
var ball_position := Vector2(0.55, 0.46)
var ball_height := 0.0
var target_position := Vector2(0.84, 0.50)
var boost_particles: Array[Dictionary] = []
var ball_trail: Array[Vector2] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 270.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	accent = color
	fatigue = int(player.get("fatigue", 0))
	focus_remaining = int(readiness.get("slots_remaining", 0))
	focus_limit = maxi(1, int(readiness.get("limit", 3)))
	intensity = clampf(0.88 - float(fatigue) / 170.0, 0.30, 0.88)
	var history: Array = player.get("training_history", [])
	if not history.is_empty():
		var latest: Dictionary = history[0]
		last_session_age = maxi(0, int(Time.get_unix_time_from_system()) - int(latest.get("timestamp", 0)))
		drill_id = str(latest.get("program", "mechanics_lab"))
		drill_label = str(latest.get("label", drill_id)).to_upper()
	else:
		drill_id = "mechanics_lab"
		drill_label = "MECHANIK-LABOR"
	_reset_drill()
	queue_redraw()


func _reset_drill() -> void:
	match drill_id:
		"rotation_review":
			car_position = Vector2(0.20, 0.24)
			ball_position = Vector2(0.52, 0.50)
			target_position = Vector2(0.30, 0.76)
		"finishing_pack":
			car_position = Vector2(0.28, 0.72)
			ball_position = Vector2(0.56, 0.53)
			target_position = Vector2(0.92, 0.50)
		"defensive_reads":
			car_position = Vector2(0.20, 0.50)
			ball_position = Vector2(0.72, 0.28)
			target_position = Vector2(0.08, 0.50)
		"boost_routes":
			car_position = Vector2(0.18, 0.78)
			ball_position = Vector2(0.54, 0.46)
			target_position = Vector2(0.83, 0.22)
		"mental_coaching":
			car_position = Vector2(0.32, 0.50)
			ball_position = Vector2(0.52, 0.50)
			target_position = Vector2(0.74, 0.50)
		_:
			car_position = Vector2(0.22, 0.68)
			ball_position = Vector2(0.52, 0.44)
			target_position = Vector2(0.84, 0.32)
	car_velocity = Vector2.ZERO
	ball_trail.clear()


func snapshot_state() -> Dictionary:
	return {
		"drill_id": drill_id,
		"focus_remaining": focus_remaining,
		"focus_limit": focus_limit,
		"fatigue": fatigue,
		"intensity": intensity,
	}


func _process(delta: float) -> void:
	animation_time += delta
	drill_phase = fmod(drill_phase + delta * (0.28 + intensity * 0.30), 1.0)

	var desired_car := _car_target_for_drill(drill_phase)
	var previous := car_position
	car_position = car_position.lerp(desired_car, minf(1.0, delta * (2.7 + intensity * 2.1)))
	car_velocity = (car_position - previous) / maxf(delta, 0.001)

	var desired_ball := _ball_target_for_drill(drill_phase)
	var old_ball := ball_position
	ball_position = ball_position.lerp(desired_ball, minf(1.0, delta * (2.4 + intensity * 1.7)))
	ball_height = _ball_height_for_drill(drill_phase)
	if old_ball.distance_to(ball_position) > 0.0015:
		ball_trail.push_front(ball_position)
		while ball_trail.size() > 10:
			ball_trail.pop_back()

	if car_velocity.length() > 0.035 and randf() < 0.38:
		boost_particles.append({
			"position": car_position,
			"velocity": -car_velocity.normalized() * randf_range(0.05, 0.14),
			"life": randf_range(0.18, 0.40),
			"max_life": 0.40,
		})
	while boost_particles.size() > 46:
		boost_particles.pop_front()
	for particle in boost_particles:
		particle["life"] = float(particle.get("life", 0.0)) - delta
		var particle_position: Vector2 = particle.get("position", Vector2.ZERO)
		var particle_velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		particle["position"] = particle_position + particle_velocity * delta
	for i in range(boost_particles.size() - 1, -1, -1):
		if float(boost_particles[i].get("life", 0.0)) <= 0.0:
			boost_particles.remove_at(i)
	queue_redraw()


func _car_target_for_drill(t: float) -> Vector2:
	match drill_id:
		"rotation_review":
			if t < 0.33:
				return Vector2(0.28, 0.22).lerp(Vector2(0.52, 0.18), t / 0.33)
			if t < 0.66:
				return Vector2(0.52, 0.18).lerp(Vector2(0.68, 0.58), (t - 0.33) / 0.33)
			return Vector2(0.68, 0.58).lerp(Vector2(0.28, 0.76), (t - 0.66) / 0.34)
		"finishing_pack":
			return Vector2(0.26, 0.70).lerp(Vector2(0.76, 0.48), _ease(t))
		"defensive_reads":
			if t < 0.55:
				return Vector2(0.18, 0.50).lerp(Vector2(0.34, 0.50), t / 0.55)
			return Vector2(0.34, 0.50).lerp(Vector2(0.18, 0.68), (t - 0.55) / 0.45)
		"boost_routes":
			var a := TAU * t
			return Vector2(0.50 + cos(a) * 0.30, 0.50 + sin(a * 1.7) * 0.27)
		"mental_coaching":
			return Vector2(0.34 + sin(t * TAU) * 0.07, 0.50 + cos(t * TAU * 2.0) * 0.08)
		_:
			var a := TAU * t
			return Vector2(0.44 + cos(a) * 0.23, 0.55 + sin(a * 1.4) * 0.24)


func _ball_target_for_drill(t: float) -> Vector2:
	match drill_id:
		"finishing_pack":
			return Vector2(0.54, 0.52).lerp(Vector2(0.94, 0.50), _ease(clampf((t - 0.34) / 0.66, 0.0, 1.0)))
		"defensive_reads":
			return Vector2(0.78, 0.22).lerp(Vector2(0.16, 0.50), _ease(t))
		"rotation_review":
			return Vector2(0.52 + sin(t * TAU) * 0.12, 0.50 + cos(t * TAU) * 0.12)
		"boost_routes":
			return Vector2(0.55 + sin(t * TAU * 0.8) * 0.12, 0.48 + cos(t * TAU * 0.9) * 0.10)
		"mental_coaching":
			return Vector2(0.50 + sin(t * TAU * 3.0) * 0.04, 0.50 + cos(t * TAU * 2.0) * 0.04)
		_:
			return Vector2(0.52 + sin(t * TAU * 0.7) * 0.18, 0.43 + cos(t * TAU) * 0.16)


func _ball_height_for_drill(t: float) -> float:
	if drill_id in ["finishing_pack", "defensive_reads", "mechanics_lab"]:
		return maxf(0.0, sin(t * PI * 2.0)) * 0.72
	return maxf(0.0, sin(t * PI * 2.0)) * 0.18


func _ease(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 2.4)


func _draw() -> void:
	var arena := Rect2(Vector2(9, 42), Vector2(maxf(1.0, size.x - 18), maxf(1.0, size.y - 52)))
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	draw_rect(arena.grow(6), Color("0b1020"), true)
	draw_rect(arena, FIELD, true)

	var stripe_w := arena.size.x / 10.0
	for i in range(10):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(stripe_w * i, 0), Vector2(stripe_w, arena.size.y)), FIELD_ALT, true)

	_draw_pitch(arena)
	_draw_drill_guides(arena)
	_draw_focus_header()

	for particle in boost_particles:
		var alpha := clampf(float(particle.get("life", 0.0)) / float(particle.get("max_life", 0.4)), 0.0, 1.0)
		var particle_position: Vector2 = particle.get("position", Vector2.ZERO)
		draw_circle(_field_point(particle_position, arena), 3.0, Color(accent.r, accent.g, accent.b, alpha * 0.35))

	_draw_car(_field_point(car_position, arena))
	_draw_ball(arena)

	if last_session_age < 10:
		var pulse := 0.5 + 0.5 * sin(animation_time * 6.5)
		draw_rect(arena, Color(accent.r, accent.g, accent.b, 0.025 + pulse * 0.055), true)
		draw_rect(arena, Color(accent.r, accent.g, accent.b, 0.22 + pulse * 0.18), false, 2.0)


func _draw_focus_header() -> void:
	var focus_ratio := float(focus_remaining) / float(focus_limit)
	draw_rect(Rect2(11, 10, size.x - 22, 8), Color("151f39"), true)
	draw_rect(Rect2(11, 10, (size.x - 22) * focus_ratio, 8), accent, true)
	var font := ThemeDB.fallback_font
	var label := "%s  •  FOKUS %d/%d  •  MÜDIGKEIT %d" % [drill_label, focus_remaining, focus_limit, fatigue]
	draw_string(font, Vector2(12, 34), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, Color("aebbd1"))


func _draw_pitch(arena: Rect2) -> void:
	draw_rect(arena, Color(LINE.r, LINE.g, LINE.b, 0.56), false, 2.0)
	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), Color(LINE.r, LINE.g, LINE.b, 0.36), 1.2)
	draw_arc(center, arena.size.y * 0.17, 0.0, TAU, 36, Color(LINE.r, LINE.g, LINE.b, 0.36), 1.2)

	var goal_h := arena.size.y * 0.34
	for left in [true, false]:
		var x := arena.position.x - 6 if left else arena.end.x - 1
		var goal := Rect2(x, center.y - goal_h * 0.5, 8, goal_h)
		draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.10), true)
		draw_rect(goal, Color(accent.r, accent.g, accent.b, 0.30), false, 1.5)

	for px in [0.16, 0.34, 0.50, 0.66, 0.84]:
		for py in [0.22, 0.78]:
			var pad := _field_point(Vector2(px, py), arena)
			draw_circle(pad, 4.5, Color(BOOST.r, BOOST.g, BOOST.b, 0.10))
			draw_circle(pad, 1.8, BOOST)


func _draw_drill_guides(arena: Rect2) -> void:
	match drill_id:
		"finishing_pack":
			var target := _field_point(Vector2(0.96, 0.50), arena)
			for r in [22.0, 14.0, 7.0]:
				draw_arc(target, r, 0, TAU, 32, Color(TARGET.r, TARGET.g, TARGET.b, 0.26), 2.0)
			_draw_path(arena, [Vector2(0.28,0.70), Vector2(0.54,0.54), Vector2(0.96,0.50)], TARGET)
		"defensive_reads":
			_draw_path(arena, [Vector2(0.78,0.22), Vector2(0.52,0.35), Vector2(0.16,0.50)], DANGER)
			draw_rect(Rect2(_field_point(Vector2(0.08,0.34), arena), Vector2(arena.size.x*0.10, arena.size.y*0.32)), Color(TARGET.r,TARGET.g,TARGET.b,0.10), true)
		"rotation_review":
			_draw_path(arena, [Vector2(0.28,0.22), Vector2(0.52,0.18), Vector2(0.68,0.58), Vector2(0.28,0.76)], accent)
			for p in [Vector2(0.28,0.22), Vector2(0.52,0.18), Vector2(0.68,0.58), Vector2(0.28,0.76)]:
				_draw_cone(_field_point(p, arena))
		"boost_routes":
			for p in [Vector2(0.18,0.78), Vector2(0.38,0.24), Vector2(0.62,0.74), Vector2(0.82,0.22)]:
				draw_circle(_field_point(p, arena), 9.0, Color(BOOST.r,BOOST.g,BOOST.b,0.13))
				draw_circle(_field_point(p, arena), 3.0, BOOST)
		"mental_coaching":
			var box := Rect2(_field_point(Vector2(0.27,0.30), arena), Vector2(arena.size.x*0.46, arena.size.y*0.40))
			draw_rect(box, Color(TARGET.r,TARGET.g,TARGET.b,0.055), true)
			draw_rect(box, Color(TARGET.r,TARGET.g,TARGET.b,0.28), false, 1.4)
		_:
			for p in [Vector2(0.36,0.32), Vector2(0.64,0.28), Vector2(0.72,0.68), Vector2(0.38,0.74)]:
				_draw_cone(_field_point(p, arena))
			_draw_path(arena, [Vector2(0.22,0.68), Vector2(0.52,0.44), Vector2(0.84,0.32)], accent)


func _draw_path(arena: Rect2, points: Array, color: Color) -> void:
	for i in range(points.size() - 1):
		var point_a: Vector2 = points[i]
		var point_b: Vector2 = points[i + 1]
		var a := _field_point(point_a, arena)
		var b := _field_point(point_b, arena)
		draw_dashed_line(a, b, Color(color.r,color.g,color.b,0.38), 1.5, 6.0)


func _draw_cone(p: Vector2) -> void:
	var points := PackedVector2Array([p + Vector2(0,-6), p + Vector2(5,5), p + Vector2(-5,5)])
	draw_colored_polygon(points, Color(BOOST.r,BOOST.g*0.75,BOOST.b*0.4,0.72))


func _draw_car(center: Vector2) -> void:
	var dir := car_velocity.normalized()
	if dir.length() < 0.1:
		dir = Vector2(1,0)
	var side := Vector2(-dir.y, dir.x)
	var nose := center + dir * 13
	var rear := center - dir * 9
	var body := PackedVector2Array([
		nose,
		center + side * 7,
		rear + side * 5,
		rear - side * 5,
		center - side * 7,
	])
	draw_circle(center + Vector2(2,4), 10, Color(0,0,0,0.30))
	draw_colored_polygon(body, Color(accent.r*0.72,accent.g*0.72,accent.b*0.72,1))
	draw_polyline(body, accent, 1.4, true)
	draw_circle(center, 2.2, Color(1,1,1,0.64))


func _draw_ball(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.16
		draw_circle(_field_point(ball_trail[i], arena), 3.0, Color(BALL.r,BALL.g,BALL.b,alpha))
	var base := _field_point(ball_position, arena)
	var lift := ball_height * 18.0
	draw_ellipse(base + Vector2(2,4), Vector2(7.0 - ball_height*1.8, 3.2 - ball_height*0.8), Color(0,0,0,0.34))
	var visual := base - Vector2(0,lift)
	draw_circle(visual, 10.0, Color(BALL.r,BALL.g,BALL.b,0.07))
	draw_circle(visual, 6.0, BALL)
	draw_circle(visual + Vector2(-1.5,-1.5), 1.8, Color("a9bad2"))


func _field_point(normalized: Vector2, arena: Rect2) -> Vector2:
	return arena.position + Vector2(clampf(normalized.x,0.0,1.0)*arena.size.x, clampf(normalized.y,0.0,1.0)*arena.size.y)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
