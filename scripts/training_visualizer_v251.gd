class_name TrainingVisualizerV251
extends "res://scripts/training_visualizer_v25.gd"

const V251_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 500.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 500.0)

func _v241_depth_scale(p: Vector2) -> float:
	return lerpf(1.58, 0.53, pow(clampf(p.x, 0.0, 1.0), 0.80))

func _v241_draw_car(arena: Rect2) -> void:
	var center: Vector2 = _v241_project_field(car_position, arena)
	var next_pos: Vector2 = car_position + (car_velocity.normalized() * 0.05 if car_velocity.length() > 0.02 else Vector2(0.05, 0.0))
	var next: Vector2 = _v241_project_field(next_pos, arena)
	var dir: Vector2 = (next - center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var s: float = _v241_depth_scale(car_position)

	var shadow := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		shadow.append(center + Vector2(cos(a) * 18.0 * s + 3.0 * s, sin(a) * 6.2 * s + 5.0 * s))
	draw_colored_polygon(shadow, Color(0,0,0,0.34))
	draw_circle(center, 28.0 * s, Color(accent.r,accent.g,accent.b,0.05))
	draw_arc(center, 23.0 * s, 0, TAU, 36, Color(accent.r,accent.g,accent.b,0.22), 1.3 * s)

	for off in [Vector2(-7,-7),Vector2(-7,7),Vector2(8,-7),Vector2(8,7)]:
		var wp := center + dir * off.x * s + side * off.y * s
		draw_circle(wp, 3.5 * s, Color("07090D"))
		draw_circle(wp, 1.9 * s, Color("303945"))

	var chassis := PackedVector2Array([
		center + dir * 18.0 * s,
		center + dir * 8.0 * s + side * 9.0 * s,
		center - dir * 12.0 * s + side * 8.0 * s,
		center - dir * 15.0 * s,
		center - dir * 12.0 * s - side * 8.0 * s,
		center + dir * 8.0 * s - side * 9.0 * s,
	])
	draw_colored_polygon(chassis, Color(accent.r*0.34,accent.g*0.34,accent.b*0.34,1.0))
	draw_polyline(PackedVector2Array([chassis[0],chassis[1],chassis[2],chassis[3],chassis[4],chassis[5],chassis[0]]), Color(accent.r,accent.g,accent.b,0.96), 1.7 * s)

	var cabin_center := center + dir * 2.0 * s - Vector2(0,4.0*s)
	var cabin := PackedVector2Array([
		cabin_center + dir * 8.0 * s,
		cabin_center + side * 5.8 * s,
		cabin_center - dir * 7.0 * s + side * 4.5 * s,
		cabin_center - dir * 7.0 * s - side * 4.5 * s,
		cabin_center - side * 5.8 * s,
	])
	draw_colored_polygon(cabin, Color(accent.r*0.58,accent.g*0.58,accent.b*0.58,1.0))
	draw_polyline(PackedVector2Array([cabin[0],cabin[1],cabin[2],cabin[3],cabin[4],cabin[0]]), Color(0.90,0.96,1.0,0.24), 1.0 * s)
	draw_line(cabin_center + dir*5.0*s + side*4.0*s, cabin_center + dir*5.0*s - side*4.0*s, Color(0.76,0.90,1.0,0.42), 2.2 * s)

	if car_velocity.length() > 0.045:
		var rear := center - dir * 15.0 * s
		draw_line(rear, rear-dir*16.0*s, Color(accent.r,accent.g,accent.b,0.20), 7.0*s)
		draw_line(rear, rear-dir*18.0*s, Color(accent.r,accent.g,accent.b,0.52), 3.0*s)
		draw_line(rear, rear-dir*12.0*s, Color(0.96,0.99,1.0,0.54), 1.2*s)

	var tag := "YOU"
	var tag_w := 40.0 * s
	var tag_pos := center + Vector2(-tag_w*0.5,-28.0*s)
	draw_rect(Rect2(tag_pos, Vector2(tag_w,13.0*s)), Color(0.01,0.02,0.03,0.80), true)
	draw_rect(Rect2(tag_pos, Vector2(tag_w,13.0*s)), Color(accent.r,accent.g,accent.b,0.28), false, 1.0)
	draw_string(V251_FONT, tag_pos+Vector2(0,9.5*s), tag, HORIZONTAL_ALIGNMENT_CENTER, tag_w, maxi(6,int(8.0*s)), Color(0.94,0.98,1.0,0.94))

func _v241_draw_ball(arena: Rect2) -> void:
	var ground: Vector2 = _v241_project_field(ball_position, arena)
	var s: float = _v241_depth_scale(ball_position)
	var lift: float = ball_height * 58.0 * s
	var visual := ground - Vector2(0,lift)
	if ball_height > 0.10:
		draw_line(ground, visual, Color(0.78,0.90,0.98,0.10), maxf(1.0,1.1*s))
		draw_circle(ground, 10.0*s, Color(0,0,0,0.11))
		draw_circle(ground, 5.0*s, Color(0,0,0,0.28))
	else:
		draw_circle(ground+Vector2(2.5,4.0)*s,7.0*s,Color(0,0,0,0.30))
	var radius := 9.2*s
	draw_circle(visual,radius*1.9,Color(0.82,0.94,1.0,0.04))
	draw_circle(visual,radius,Color("F1F4F7"))
	draw_circle(visual+Vector2(-1.0,-1.5)*s,2.6*s,Color("8794A4"))
	for a in [0.0, TAU/3.0, 2.0*TAU/3.0]:
		var p := visual + Vector2(cos(a),sin(a))*radius*0.58
		draw_circle(p,1.5*s,Color(0.55,0.60,0.67,0.72))
	draw_circle(visual+Vector2(-radius*0.34,-radius*0.38),1.8*s,Color(1,1,1,0.76))
