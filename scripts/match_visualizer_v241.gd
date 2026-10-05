class_name MatchVisualizerV241
extends "res://scripts/match_visualizer_v24.gd"

const V241_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 448.0)

func _project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var near_y := arena.end.y - 20.0
	var far_y := arena.position.y + 28.0
	var screen_y := lerpf(near_y, far_y, depth)
	var half_width := lerpf(arena.size.x * 0.47, arena.size.x * 0.24, depth)
	var screen_x := arena.get_center().x + (p.y - 0.5) * 2.0 * half_width
	return Vector2(screen_x, screen_y)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.18, 0.62, clampf(p.x, 0.0, 1.0))

func _draw() -> void:
	var arena := Rect2(Vector2(7, 62), Vector2(maxf(1.0, size.x - 14), maxf(1.0, size.y - 90)))
	_draw_broadcast_backdrop(arena)
	_draw_perspective_pitch(arena)
	_draw_rotation_paths(arena)
	_draw_projected_ball_path(arena)

	for index in range(their_positions.size()):
		_draw_projected_car(their_positions[index], their_velocities[index], THEIR_COLOR, "", false, false, arena)

	for index in range(our_positions.size()):
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		_draw_projected_car(
			our_positions[index], our_velocities[index], OUR_COLOR, role,
			index == active_actor, index == support_actor, arena
		)

	_draw_projected_ball(arena)
	_draw_broadcast_header()
	_draw_mastery_strip()

	if phase == "mechanic_fail":
		draw_rect(Rect2(10, 52, size.x - 20, 26), Color(0.34, 0.045, 0.055, 0.88), true)
		draw_string(V241_FONT, Vector2(18, 70), "PLAY VERLOREN  ·  RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 9, Color(1.0,0.82,0.84,0.96))

	if goal_flash > 0.01:
		var c := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(arena, Color(c.r,c.g,c.b,goal_flash * 0.08), true)
		var goal_point := _project_field(Vector2(1.0,0.5) if goal_side > 0 else Vector2(0.0,0.5), arena)
		for ring in range(3):
			draw_arc(goal_point, 26.0 + float(ring) * 20.0, 0.0, TAU, 44, Color(c.r,c.g,c.b,goal_flash*(0.44-float(ring)*0.10)), 2.6)

func _draw_broadcast_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("030509"), true)
	for i in range(12):
		var t := float(i) / 11.0
		var c := Color("10151C").lerp(Color("030509"), t)
		draw_rect(Rect2(0, float(i) * size.y / 12.0, size.x, size.y / 12.0 + 1), c, true)
	# Stadium bowl and light rigs.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, arena.position.y - 8), Vector2(size.x, arena.position.y - 8),
		Vector2(size.x * 0.86, arena.position.y + 42), Vector2(size.x * 0.14, arena.position.y + 42)
	]), Color(0.035,0.048,0.062,0.95))
	for i in range(11):
		var x := 16.0 + float(i) * (size.x - 32.0) / 10.0
		draw_circle(Vector2(x, arena.position.y + 2), 2.0, Color(0.86,0.94,1.0,0.20 + 0.06*sin(time_alive*1.3+float(i))))
	draw_circle(Vector2(size.x*0.18, 72), size.x*0.30, Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.025))
	draw_circle(Vector2(size.x*0.85, 78), size.x*0.28, Color(THEIR_COLOR.r,THEIR_COLOR.g,THEIR_COLOR.b,0.018))

func _draw_perspective_pitch(arena: Rect2) -> void:
	var near_l := _project_field(Vector2(0,0), arena)
	var near_r := _project_field(Vector2(0,1), arena)
	var far_l := _project_field(Vector2(1,0), arena)
	var far_r := _project_field(Vector2(1,1), arena)
	var pitch := PackedVector2Array([near_l, near_r, far_r, far_l])
	draw_colored_polygon(pitch, Color("07171D"))
	draw_polyline(PackedVector2Array([near_l,near_r,far_r,far_l,near_l]), Color(0.42,0.64,0.74,0.32), 2.0)

	# Depth stripes.
	for i in range(8):
		var x0 := float(i) / 8.0
		var x1 := float(i + 1) / 8.0
		if i % 2 == 0:
			var band := PackedVector2Array([
				_project_field(Vector2(x0,0), arena), _project_field(Vector2(x0,1), arena),
				_project_field(Vector2(x1,1), arena), _project_field(Vector2(x1,0), arena)
			])
			draw_colored_polygon(band, Color(0.04,0.12,0.15,0.48))

	# Center line and circle compressed by perspective.
	var c1 := _project_field(Vector2(0.5,0), arena)
	var c2 := _project_field(Vector2(0.5,1), arena)
	draw_line(c1,c2,Color(0.56,0.76,0.84,0.23),1.4)
	var center := _project_field(Vector2(0.5,0.5), arena)
	draw_arc(center, 24.0, 0.0, TAU, 40, Color(0.56,0.76,0.84,0.18), 1.2)

	# Boost pads.
	for p in [Vector2(0.12,0.18),Vector2(0.12,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.88,0.18),Vector2(0.88,0.82)]:
		var s := _depth_scale(p)
		var point := _project_field(p,arena)
		draw_circle(point, 5.0*s, Color(0.95,0.72,0.34,0.08))
		draw_circle(point, 2.0*s, Color(0.95,0.74,0.36,0.82))

	_draw_perspective_goal(Vector2(0.0,0.5), OUR_COLOR, arena, true)
	_draw_perspective_goal(Vector2(1.0,0.5), THEIR_COLOR, arena, false)

func _draw_perspective_goal(field_pos: Vector2, color: Color, arena: Rect2, near_goal: bool) -> void:
	var center := _project_field(field_pos,arena)
	var scale := _depth_scale(field_pos)
	var w := 92.0*scale
	var h := 32.0*scale
	var y := center.y + (8.0 if near_goal else -7.0)
	var box := Rect2(center.x-w*0.5,y-h*0.5,w,h)
	draw_rect(box,Color(color.r,color.g,color.b,0.055),true)
	draw_rect(box,Color(color.r,color.g,color.b,0.32),false,1.6)
	for i in range(1,5):
		var xx := box.position.x + box.size.x * float(i)/5.0
		draw_line(Vector2(xx,box.position.y),Vector2(xx,box.end.y),Color(color.r,color.g,color.b,0.09),1.0)

func _draw_rotation_paths(arena: Rect2) -> void:
	for index in range(our_positions.size()):
		if index >= our_targets.size(): continue
		var from := _project_field(our_positions[index],arena)
		var to := _project_field(our_targets[index],arena)
		var alpha := 0.42 if index == active_actor else 0.18 if index == support_actor else 0.08
		draw_dashed_line(from,to,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,alpha),2.1 if index==active_actor else 1.2,8.0)

func _draw_projected_ball_path(arena: Rect2) -> void:
	var from := _project_field(ball_position,arena) - Vector2(0,ball_height*38.0*_depth_scale(ball_position))
	var to := _project_field(ball_target,arena) - Vector2(0,ball_target_height*38.0*_depth_scale(ball_target))
	if from.distance_to(to) < 8.0: return
	var control := (from+to)*0.5 - Vector2(0,34.0 + maxf(ball_height,ball_target_height)*24.0)
	var previous := from
	for i in range(1,15):
		var t := float(i)/14.0
		var a := from.lerp(control,t)
		var b := control.lerp(to,t)
		var p := a.lerp(b,t)
		if i%2==0: draw_line(previous,p,Color(0.94,0.98,1.0,0.22),1.5)
		previous = p

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center := _project_field(p,arena)
	var next := _project_field(p + velocity.normalized()*0.04 if velocity.length()>0.02 else p+Vector2(0.04,0),arena)
	var dir := (next-center).normalized()
	if dir.length()<0.1: dir=Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _depth_scale(p) * (1.08 if active else 1.0)
	var nose := center+dir*14.0*s
	var rear := center-dir*10.0*s
	var body := PackedVector2Array([nose,center+dir*3*s+side*7*s,rear+side*5*s,rear-side*5*s,center+dir*3*s-side*7*s])
	if active: draw_circle(center,19.0*s,Color(color.r,color.g,color.b,0.075))
	if support: draw_arc(center,17.0*s,0,TAU,28,Color(color.r,color.g,color.b,0.22),1.4)
	draw_colored_polygon(body,Color(color.r*0.48,color.g*0.48,color.b*0.48,1.0))
	draw_polyline(body,Color(color.r,color.g,color.b,0.95),1.7,true)
	# windshield / roof highlight
	draw_colored_polygon(PackedVector2Array([center+dir*6*s+side*3*s,center+dir*8*s-side*3*s,center+dir*1*s-side*3.5*s,center+dir*1*s+side*3.5*s]),Color(0.72,0.88,0.96,0.30))
	if velocity.length()>0.08:
		draw_line(rear,rear-dir*(9.0*s),Color(color.r,color.g,color.b,0.46),3.0*s)
	if not role.is_empty():
		draw_string(V241_FONT,center+Vector2(-18,-18*s),role,HORIZONTAL_ALIGNMENT_CENTER,36,8,Color(0.88,0.95,1.0,0.86 if active else 0.58))

func _draw_projected_ball(arena: Rect2) -> void:
	var ground := _project_field(ball_position,arena)
	var s := _depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*38.0*s)
	draw_circle(ground+Vector2(2,4),7.0*s*(1.0-ball_height*0.20),Color(0,0,0,0.38))
	draw_circle(visual,14.5*s,Color(0.88,0.95,1.0,0.05))
	draw_circle(visual,8.0*s,Color("F4F7FB"))
	draw_circle(visual+Vector2(-2,-2)*s,2.2*s,Color("AAB7C8"))

func _draw_broadcast_header() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var sub := "TEAM COMBO" if not combo_id.is_empty() else _phase_title_v24(phase)
	draw_string(V241_FONT,Vector2(12,23),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,15,Color(0.94,0.97,1.0,0.96))
	draw_string(V241_FONT,Vector2(12,42),sub,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,8,Color(0.58,0.70,0.80,0.82))
	var pressure := clampf((float(momentum)+100.0)/200.0,0.0,1.0)
	draw_rect(Rect2(12,49,size.x-24,3),Color(1,1,1,0.06),true)
	draw_rect(Rect2(12,49,(size.x-24)*pressure,3),OUR_COLOR if momentum>=0 else THEIR_COLOR,true)

func _draw_mastery_strip() -> void:
	if mechanic_components.is_empty(): return
	var items := [["SET",int(mechanic_components.get("setup",0))],["CTRL",int(mechanic_components.get("control",0))],["READ",int(mechanic_components.get("read",0))],["FIN",int(mechanic_components.get("finish",0))]]
	var cell := (size.x-24.0)/4.0
	for i in range(4):
		draw_string(V241_FONT,Vector2(12+cell*i,size.y-10),"%s %d"%[items[i][0],items[i][1]],HORIZONTAL_ALIGNMENT_CENTER,cell-3,8,Color(0.68,0.78,0.86,0.68))
