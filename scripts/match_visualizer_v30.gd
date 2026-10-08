class_name MatchVisualizerV30
extends "res://scripts/match_visualizer_v242.gd"

const FONT_V30 = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 520.0)

func _project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var near_y := arena.end.y - 18.0
	var far_y := arena.position.y + 74.0
	var y := lerpf(near_y, far_y, depth)
	var half_width := lerpf(arena.size.x * 0.50, arena.size.x * 0.21, depth)
	var x := arena.get_center().x + (p.y - 0.5) * 2.0 * half_width
	return Vector2(x, y)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.34, 0.52, clampf(p.x, 0.0, 1.0))

func _draw() -> void:
	var arena := Rect2(Vector2(4, 70), Vector2(maxf(1.0, size.x - 8), maxf(1.0, size.y - 102)))
	_draw_world(arena)
	_draw_rotation_paths(arena)
	_draw_ball_route_v30(arena)

	var their_order: Array[int] = []
	for i in range(their_positions.size()): their_order.append(i)
	their_order.sort_custom(func(a: int, b: int) -> bool: return their_positions[a].x > their_positions[b].x)
	for index in their_order:
		_draw_car_v30(their_positions[index], their_velocities[index], THEIR_COLOR, "", false, false, arena)

	var our_order: Array[int] = []
	for i in range(our_positions.size()): our_order.append(i)
	our_order.sort_custom(func(a: int, b: int) -> bool: return our_positions[a].x > our_positions[b].x)
	for index in our_order:
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		_draw_car_v30(our_positions[index], our_velocities[index], OUR_COLOR, role, index == active_actor, index == support_actor, arena)

	_draw_ball_v30(arena)
	_draw_scorebug_v30()
	_draw_play_call_v30()

	if phase == "mechanic_fail":
		draw_rect(Rect2(12, 54, size.x - 24, 28), Color(0.34, 0.035, 0.05, 0.92), true)
		draw_string(FONT_V30, Vector2(20, 73), "PLAY BREAKDOWN  ·  RECOVERY ROTATION", HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 9, Color(1.0,0.84,0.86,0.96))

func _draw_world(arena: Rect2) -> void:
	for i in range(18):
		var t := float(i) / 17.0
		var c := Color("111821").lerp(Color("020407"), t)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 17.0 + 2.0), c, true)

	var horizon := arena.position.y + 58.0
	var stands := PackedVector2Array([
		Vector2(0, arena.position.y - 8), Vector2(size.x, arena.position.y - 8),
		Vector2(size.x * 0.88, horizon), Vector2(size.x * 0.12, horizon)
	])
	draw_colored_polygon(stands, Color(0.035,0.048,0.064,0.98))
	for row in range(5):
		var y := arena.position.y + 6.0 + row * 10.0
		var count := 30 - row * 3
		for i in range(count):
			var x := 8.0 + float(i) * (size.x - 16.0) / float(maxi(1, count - 1))
			var cc := OUR_COLOR if (i + row) % 11 == 0 else THEIR_COLOR if (i + row) % 13 == 0 else Color(0.72,0.80,0.88,1.0)
			var alpha := 0.07 + 0.035 * sin(time_alive * 0.9 + i * 1.4 + row)
			draw_circle(Vector2(x,y), 1.0, Color(cc.r,cc.g,cc.b,alpha))

	for i in range(8):
		var x := 16.0 + float(i) * (size.x - 32.0) / 7.0
		draw_circle(Vector2(x, arena.position.y + 1.0), 2.1, Color(0.92,0.97,1.0,0.28))
		var beam := PackedVector2Array([Vector2(x-4,arena.position.y+4),Vector2(x+4,arena.position.y+4),Vector2(x+44,arena.end.y),Vector2(x-44,arena.end.y)])
		draw_colored_polygon(beam, Color(0.82,0.93,1.0,0.010))

	_draw_pitch_v30(arena)

func _draw_pitch_v30(arena: Rect2) -> void:
	var near_l := _project_field(Vector2(0,0), arena)
	var near_r := _project_field(Vector2(0,1), arena)
	var far_l := _project_field(Vector2(1,0), arena)
	var far_r := _project_field(Vector2(1,1), arena)
	var pitch := PackedVector2Array([near_l,near_r,far_r,far_l])
	draw_colored_polygon(pitch, Color("06171D"))
	draw_polyline(PackedVector2Array([near_l,near_r,far_r,far_l,near_l]), Color(0.55,0.75,0.84,0.30), 2.0)

	for i in range(10):
		var a := float(i) / 10.0
		var b := float(i + 1) / 10.0
		if i % 2 == 0:
			var band := PackedVector2Array([_project_field(Vector2(a,0),arena),_project_field(Vector2(a,1),arena),_project_field(Vector2(b,1),arena),_project_field(Vector2(b,0),arena)])
			draw_colored_polygon(band, Color(0.04,0.13,0.16,0.42))

	var center_a := _project_field(Vector2(0.5,0), arena)
	var center_b := _project_field(Vector2(0.5,1), arena)
	draw_line(center_a, center_b, Color(0.60,0.80,0.88,0.24), 1.5)
	var center := _project_field(Vector2(0.5,0.5), arena)
	draw_arc(center, 25.0, 0, TAU, 48, Color(0.60,0.80,0.88,0.18), 1.3)

	for p in [Vector2(0.12,0.18),Vector2(0.12,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.88,0.18),Vector2(0.88,0.82)]:
		var s := _depth_scale(p)
		var point := _project_field(p, arena)
		draw_circle(point, 5.2*s, Color(0.96,0.72,0.34,0.08))
		draw_circle(point, 2.1*s, Color(0.98,0.75,0.36,0.86))

	_draw_goal_v30(Vector2(0,0.5), OUR_COLOR, arena, true)
	_draw_goal_v30(Vector2(1,0.5), THEIR_COLOR, arena, false)

	var board_y := near_l.y + 9.0
	draw_line(Vector2(near_l.x+14,board_y),Vector2(near_r.x-14,board_y),Color(0.72,0.88,0.94,0.12),3.0)
	draw_string(FONT_V30,Vector2(near_l.x+24,board_y+13),"E-SPORT EMPIRE  •  LIVE ARENA",HORIZONTAL_ALIGNMENT_LEFT,near_r.x-near_l.x-48,7,Color(0.72,0.82,0.88,0.30))

func _draw_goal_v30(pos: Vector2, color: Color, arena: Rect2, near_goal: bool) -> void:
	var center := _project_field(pos, arena)
	var s := _depth_scale(pos)
	var w := 98.0*s
	var h := 35.0*s
	var front := Rect2(center.x-w*0.5, center.y-h*0.5+(9.0 if near_goal else -8.0), w, h)
	var offset := Vector2(0, 11.0*s if near_goal else -9.0*s)
	var back := Rect2(front.position+offset, front.size*Vector2(0.80,0.84))
	back.position.x = center.x-back.size.x*0.5
	draw_rect(back,Color(color.r,color.g,color.b,0.035),true)
	draw_rect(front,Color(color.r,color.g,color.b,0.045),true)
	draw_rect(front,Color(color.r,color.g,color.b,0.42),false,1.8)
	draw_rect(back,Color(color.r,color.g,color.b,0.16),false,1.0)
	for i in range(1,6):
		var xx := front.position.x+front.size.x*float(i)/6.0
		var bx := back.position.x+back.size.x*float(i)/6.0
		draw_line(Vector2(xx,front.position.y),Vector2(bx,back.position.y),Color(color.r,color.g,color.b,0.10),1.0)

func _draw_car_v30(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center := _project_field(p, arena)
	var next := _project_field(p + (velocity.normalized()*0.04 if velocity.length()>0.02 else Vector2(0.04,0)), arena)
	var dir := (next-center).normalized()
	if dir.length() < 0.1: dir = Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _depth_scale(p) * (1.12 if active else 1.0)
	var rear := center-dir*12.0*s
	var nose := center+dir*17.0*s

	draw_circle(center+Vector2(2,5*s),12*s,Color(0,0,0,0.34))
	for off_value in [Vector2(-6.0,-7.6),Vector2(6.0,-7.6),Vector2(-6.0,7.6),Vector2(6.0,7.6)]:
		var off: Vector2 = off_value
		var wp: Vector2 = center+dir*off.x*s+side*off.y*s
		draw_circle(wp,3.0*s,Color(0.01,0.015,0.022,0.98))
		draw_circle(wp,1.3*s,Color(0.38,0.46,0.54,0.90))

	var body := PackedVector2Array([nose,center+dir*6*s+side*8.2*s,center-dir*8*s+side*6.5*s,rear+side*4.7*s,rear-side*4.7*s,center-dir*8*s-side*6.5*s,center+dir*6*s-side*8.2*s])
	if active:
		draw_circle(center,22*s,Color(color.r,color.g,color.b,0.085))
		draw_arc(center,20*s,0,TAU,36,Color(color.r,color.g,color.b,0.30),1.5)
	elif support:
		draw_arc(center,18*s,0,TAU,30,Color(color.r,color.g,color.b,0.22),1.2)
	draw_colored_polygon(body,Color(color.r*0.34,color.g*0.34,color.b*0.34,1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(color.r,color.g,color.b,0.98),1.9)
	var glass := PackedVector2Array([center+dir*8*s+side*3.8*s,center+dir*9*s-side*3.8*s,center-dir*1*s-side*4.2*s,center-dir*1*s+side*4.2*s])
	draw_colored_polygon(glass,Color(0.62,0.84,0.94,0.34))
	draw_line(center+dir*14*s,center+dir*6*s,Color(0.95,0.98,1.0,0.38),1.5*s)
	if velocity.length()>0.08:
		draw_line(rear,rear-dir*(12*s),Color(color.r,color.g,color.b,0.58),3.6*s)
		draw_line(rear-dir*(12*s),rear-dir*(18*s),Color(0.94,0.98,1.0,0.22),1.6*s)
	if not role.is_empty():
		draw_string(FONT_V30,center+Vector2(-20,-22*s),role,HORIZONTAL_ALIGNMENT_CENTER,40,8,Color(0.94,0.98,1.0,0.94 if active else 0.64))

func _draw_ball_route_v30(arena: Rect2) -> void:
	var from := _project_field(ball_position,arena)-Vector2(0,ball_height*46.0*_depth_scale(ball_position))
	var to := _project_field(ball_target,arena)-Vector2(0,ball_target_height*46.0*_depth_scale(ball_target))
	if from.distance_to(to)<8: return
	var control := (from+to)*0.5-Vector2(0,42+maxf(ball_height,ball_target_height)*28)
	var previous := from
	for i in range(1,17):
		var t := float(i)/16.0
		var a := from.lerp(control,t)
		var b := control.lerp(to,t)
		var p := a.lerp(b,t)
		if i%2==0: draw_line(previous,p,Color(0.96,0.99,1.0,0.24),1.7)
		previous=p

func _draw_ball_v30(arena: Rect2) -> void:
	var ground := _project_field(ball_position,arena)
	var s := _depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*46.0*s)
	draw_circle(ground+Vector2(3,6),8.0*s*(1.0-ball_height*0.18),Color(0,0,0,0.40))
	draw_circle(visual,18*s,Color(0.88,0.96,1.0,0.06))
	draw_circle(visual,9.5*s,Color("F7FAFE"))
	draw_arc(visual,5.8*s,-0.3,1.5,12,Color(0.28,0.35,0.42,0.78),1.1*s)
	draw_arc(visual,4.8*s,2.1,4.2,12,Color(0.28,0.35,0.42,0.68),1.0*s)
	draw_circle(visual+Vector2(-2.3,-2.7)*s,1.9*s,Color(1,1,1,0.80))

func _draw_scorebug_v30() -> void:
	var box := Rect2(12, 10, size.x - 24, 36)
	draw_rect(box,Color(0.025,0.035,0.050,0.94),true)
	draw_rect(box,Color(1,1,1,0.07),false,1.0)
	draw_string(FONT_V30,Vector2(22,33),"TSK",HORIZONTAL_ALIGNMENT_LEFT,68,11,OUR_COLOR)
	draw_string(FONT_V30,Vector2(size.x-88,33),"RIVAL",HORIZONTAL_ALIGNMENT_RIGHT,66,11,THEIR_COLOR)
	var clock := "LIVE"
	draw_string(FONT_V30,Vector2(size.x*0.5-42,33),clock,HORIZONTAL_ALIGNMENT_CENTER,84,10,Color(0.90,0.95,1.0,0.92))

func _draw_play_call_v30() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var sub := "TEAM COMBO" if not combo_id.is_empty() else _phase_title_v24(phase)
	draw_string(FONT_V30,Vector2(14,63),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,13,Color(0.95,0.98,1.0,0.96))
	draw_string(FONT_V30,Vector2(14,size.y-11),sub,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,8,Color(0.64,0.76,0.84,0.70))
