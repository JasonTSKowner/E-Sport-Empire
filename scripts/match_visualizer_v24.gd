class_name MatchVisualizerV24
extends "res://scripts/match_visualizer_v23.gd"

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 430.0)


func _draw() -> void:
	var arena := Rect2(Vector2(8, 58), Vector2(maxf(1.0, size.x - 16), maxf(1.0, size.y - 82)))
	_draw_backdrop(arena)
	_draw_field(arena)
	_draw_rotation(arena)
	_draw_ball_prediction(arena)

	for index in range(their_positions.size()):
		_draw_car_v24(
			_field_point(their_positions[index], arena),
			their_velocities[index],
			THEIR_COLOR,
			"",
			false,
			false
		)

	for index in range(our_positions.size()):
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		_draw_car_v24(
			_field_point(our_positions[index], arena),
			our_velocities[index],
			OUR_COLOR,
			role,
			index == active_actor,
			index == support_actor
		)

	_draw_ball_v24(arena)
	_draw_header_v24()
	_draw_mastery_strip_v24()

	if phase == "mechanic_fail":
		draw_rect(Rect2(10, 52, size.x - 20, 28), Color(0.35, 0.045, 0.06, 0.88), true)
		draw_string(FONT, Vector2(20, 71), "PLAY VERLOREN  ·  RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 10, Color(1.0, 0.82, 0.84, 0.96))

	if goal_flash > 0.01:
		var c := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(arena, Color(c.r, c.g, c.b, goal_flash * 0.10), true)
		var center := Vector2(arena.end.x - 6.0, arena.get_center().y) if goal_side > 0 else Vector2(arena.position.x + 6.0, arena.get_center().y)
		for ring in range(3):
			draw_arc(center, 34.0 + float(ring) * 24.0, 0.0, TAU, 50, Color(c.r, c.g, c.b, goal_flash * (0.50 - float(ring) * 0.12)), 3.0)


func _draw_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("04070B"), true)
	for i in range(10):
		var t := float(i) / 9.0
		var c := Color("0B1118").lerp(Color("05080C"), t)
		draw_rect(Rect2(0, float(i) * size.y / 10.0, size.x, size.y / 10.0 + 1.0), c, true)
	var pulse := 0.5 + 0.5 * sin(time_alive * 0.7)
	draw_circle(Vector2(size.x * 0.23, 22), size.x * 0.32, Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, 0.025 + pulse * 0.008))
	draw_circle(Vector2(size.x * 0.84, 32), size.x * 0.28, Color(THEIR_COLOR.r, THEIR_COLOR.g, THEIR_COLOR.b, 0.018))
	# Stadium light row.
	for i in range(9):
		var x := 18.0 + float(i) * (size.x - 36.0) / 8.0
		draw_circle(Vector2(x, 50), 1.8, Color(0.86, 0.93, 1.0, 0.18 + 0.06 * sin(time_alive * 1.2 + float(i))))


func _draw_field(arena: Rect2) -> void:
	# Thick broadcast frame gives the arena a physical presence.
	draw_rect(arena.grow(7), Color("0D131B"), true)
	draw_rect(arena.grow(5), Color(0.40, 0.55, 0.68, 0.16), false, 1.4)
	draw_rect(arena, Color("07131A"), true)

	var stripe_w := arena.size.x / 8.0
	for i in range(8):
		if i % 2 == 0:
			draw_rect(Rect2(arena.position + Vector2(float(i) * stripe_w, 0), Vector2(stripe_w, arena.size.y)), Color(0.05, 0.13, 0.16, 0.52), true)

	# Arena perspective bands, much less debug-grid looking than before.
	for i in range(1, 5):
		var y := arena.position.y + arena.size.y * float(i) / 5.0
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(0.54, 0.70, 0.80, 0.055), 1.0)

	var center := arena.get_center()
	draw_line(Vector2(center.x, arena.position.y), Vector2(center.x, arena.end.y), Color(0.55, 0.75, 0.86, 0.24), 1.4)
	draw_arc(center, arena.size.y * 0.17, 0.0, TAU, 44, Color(0.55, 0.75, 0.86, 0.18), 1.3)
	draw_circle(center, 2.3, Color(0.70, 0.86, 0.94, 0.42))

	# Boost pads remain recognizable but quiet.
	for p in [Vector2(0.15,0.18),Vector2(0.15,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.85,0.18),Vector2(0.85,0.82)]:
		var point := _field_point(p, arena)
		draw_circle(point, 5.8, Color(0.88, 0.70, 0.38, 0.08))
		draw_circle(point, 2.2, Color(0.91, 0.73, 0.42, 0.80))

	# Goals are deeper than the old flat rectangles.
	var goal_h := arena.size.y * 0.36
	_draw_goal_v24(Rect2(arena.position.x - 8, center.y - goal_h * 0.5, 10, goal_h), OUR_COLOR)
	_draw_goal_v24(Rect2(arena.end.x - 2, center.y - goal_h * 0.5, 10, goal_h), THEIR_COLOR)


func _draw_goal_v24(goal: Rect2, color: Color) -> void:
	draw_rect(goal, Color(color.r, color.g, color.b, 0.07), true)
	draw_rect(goal, Color(color.r, color.g, color.b, 0.38), false, 1.8)
	for i in range(1, 5):
		var y := goal.position.y + goal.size.y * float(i) / 5.0
		draw_line(Vector2(goal.position.x, y), Vector2(goal.end.x, y), Color(color.r, color.g, color.b, 0.12), 1.0)


func _draw_rotation(arena: Rect2) -> void:
	for index in range(our_positions.size()):
		if index >= our_targets.size():
			continue
		var from := _field_point(our_positions[index], arena)
		var to := _field_point(our_targets[index], arena)
		var a := 0.44 if index == active_actor else 0.18 if index == support_actor else 0.09
		var width := 2.3 if index == active_actor else 1.3
		draw_dashed_line(from, to, Color(OUR_COLOR.r, OUR_COLOR.g, OUR_COLOR.b, a), width, 9.0)
		if index == active_actor:
			var dir := (to - from).normalized()
			if dir.length() > 0.1:
				var tip := to - dir * 4.0
				var side := Vector2(-dir.y, dir.x)
				draw_colored_polygon(PackedVector2Array([tip, tip-dir*10.0+side*5.0, tip-dir*10.0-side*5.0]), Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.42))


func _draw_ball_prediction(arena: Rect2) -> void:
	var from := _field_point(ball_position, arena) - Vector2(0, ball_height * 26.0)
	var to := _field_point(ball_target, arena) - Vector2(0, ball_target_height * 26.0)
	var distance := from.distance_to(to)
	if distance < 8.0:
		return
	# The arc makes the ball path readable instead of looking like a teleport.
	var control := (from + to) * 0.5 - Vector2(0, 28.0 + maxf(ball_height, ball_target_height) * 32.0)
	var previous := from
	for i in range(1, 13):
		var t := float(i) / 12.0
		var a := from.lerp(control, t)
		var b := control.lerp(to, t)
		var p := a.lerp(b, t)
		if i % 2 == 0:
			draw_line(previous, p, Color(0.92,0.96,1.0,0.20), 1.5)
		previous = p


func _draw_ball_v24(arena: Rect2) -> void:
	for i in range(ball_trail.size() - 1, -1, -1):
		var alpha := (1.0 - float(i) / float(maxi(1, ball_trail.size()))) * 0.20
		var tp := _field_point(ball_trail[i], arena)
		draw_circle(tp, 4.0, Color(0.95,0.98,1.0,alpha))
	var p := _field_point(ball_position, arena)
	var lift := ball_height * 26.0
	draw_circle(p + Vector2(3, 5), 7.5 - ball_height * 2.0, Color(0,0,0,0.36))
	var visual := p - Vector2(0, lift)
	draw_circle(visual, 16.0, Color(0.85,0.94,1.0,0.05))
	draw_circle(visual, 8.5, Color("F4F7FB"))
	draw_circle(visual + Vector2(-2.2,-2.2), 2.5, Color("AAB7C8"))


func _draw_car_v24(center: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool) -> void:
	var dir := velocity.normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	var length := 17.0 if active else 14.0
	var width := 8.5 if active else 7.0
	var body := PackedVector2Array([
		center + dir * length,
		center + dir * 4.0 + side * width,
		center - dir * 11.0 + side * width * 0.74,
		center - dir * 11.0 - side * width * 0.74,
		center + dir * 4.0 - side * width,
	])
	if active:
		draw_circle(center, 18.0, Color(color.r,color.g,color.b,0.075))
	if support:
		draw_arc(center, 16.0, 0.0, TAU, 28, Color(color.r,color.g,color.b,0.24), 1.5)
	draw_colored_polygon(body, Color(color.r * 0.60, color.g * 0.60, color.b * 0.60, 1.0))
	draw_polyline(body, Color(color.r,color.g,color.b,0.90), 1.7, true)
	draw_line(center + dir * 2.0 + side * 4.0, center + dir * 8.0 + side * 2.7, Color(0.90,0.96,1.0,0.48), 2.0)
	draw_line(center + dir * 2.0 - side * 4.0, center + dir * 8.0 - side * 2.7, Color(0.90,0.96,1.0,0.48), 2.0)
	if velocity.length() > 0.12:
		var rear := center - dir * 12.0
		draw_line(rear, rear - dir * (10.0 if active else 7.0), Color(color.r,color.g,color.b,0.46), 3.0)
	if not role.is_empty():
		var text_color := Color(0.90,0.96,1.0,0.90) if active else Color(0.74,0.84,0.91,0.66)
		draw_string(FONT, center + Vector2(-18,-17), role, HORIZONTAL_ALIGNMENT_CENTER, 36, 8, text_color)


func _draw_header_v24() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var subtitle := "TEAM COMBO" if not combo_id.is_empty() else _phase_title_v24(phase)
	draw_string(FONT, Vector2(12, 23), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color(0.94,0.97,1.0,0.96))
	draw_string(FONT, Vector2(12, 42), subtitle, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.58,0.70,0.80,0.82))
	var pressure := clampf((float(momentum) + 100.0) / 200.0, 0.0, 1.0)
	draw_rect(Rect2(12, 48, size.x - 24, 3), Color(1,1,1,0.06), true)
	draw_rect(Rect2(12, 48, (size.x - 24) * pressure, 3), OUR_COLOR if momentum >= 0 else THEIR_COLOR, true)


func _draw_mastery_strip_v24() -> void:
	if mechanic_components.is_empty():
		return
	var items := [
		["SET", int(mechanic_components.get("setup", 0))],
		["CTRL", int(mechanic_components.get("control", 0))],
		["READ", int(mechanic_components.get("read", 0))],
		["FIN", int(mechanic_components.get("finish", 0))],
	]
	var x := 12.0
	var y := size.y - 12.0
	var available := size.x - 24.0
	var cell := available / 4.0
	for pair in items:
		var value := int(pair[1])
		var text := "%s %d" % [str(pair[0]), value]
		draw_string(FONT, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, cell - 3.0, 8, Color(0.68,0.78,0.86,0.70))
		x += cell


func _phase_title_v24(value: String) -> String:
	var replacements := {
		"buildup":"AUFBAU", "challenge":"CHALLENGE", "rotation_switch":"ROTATION",
		"wall_setup":"WALL SETUP", "air_carry":"AIR CARRY", "air_carry_2":"AIR CARRY",
		"air_pass":"PASS", "reset_1":"RESET 1", "reset_2":"RESET 2", "reset_3":"RESET 3", "reset_4":"RESET 4",
		"psycho_setup":"PSYCHO SETUP", "own_wall_carry":"OWN WALL", "backwall_musty":"BACKWALL MUSTY",
		"psycho_contact":"PSYCHO", "teammate_prejump":"PREJUMP", "redirect_finish":"REDIRECT",
		"goal_ours":"TOR", "goal_theirs":"GEGENTOR", "chance_ours":"CHANCE", "chance_theirs":"GEFAHR",
		"mechanic_fail":"RECOVERY"
	}
	return str(replacements.get(value, value.replace("_", " ").to_upper()))
