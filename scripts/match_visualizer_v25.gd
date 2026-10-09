class_name MatchVisualizerV25
extends "res://scripts/match_visualizer_v242.gd"

const FONT_V25 = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 556.0)

func _project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x,0.0,1.0)
	var near_y := arena.end.y - 14.0
	var far_y := arena.position.y + 52.0
	var y := lerpf(near_y,far_y,pow(depth,0.91))
	var half_width := lerpf(arena.size.x*0.49,arena.size.x*0.19,depth)
	return Vector2(arena.get_center().x+(p.y-0.5)*2.0*half_width,y)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.34,0.48,pow(clampf(p.x,0.0,1.0),0.9))

func _draw_rotation_paths(arena: Rect2) -> void:
	for index in range(our_positions.size()):
		if index >= our_targets.size():
			continue
		var from := _project_field(our_positions[index],arena)
		var to := _project_field(our_targets[index],arena)
		var active := index == active_actor
		var support := index == support_actor
		var alpha := 0.54 if active else 0.22 if support else 0.09
		var width := 2.5 if active else 1.4 if support else 1.0
		if active:
			draw_line(from,to,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,alpha),width)
			var dir := (to-from).normalized()
			if dir.length()>0.1:
				var side := Vector2(-dir.y,dir.x)
				draw_colored_polygon(PackedVector2Array([to,to-dir*12+side*5,to-dir*12-side*5]),Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.48))
		else:
			draw_dashed_line(from,to,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,alpha),width,10.0)

func _draw_projected_ball_path(arena: Rect2) -> void:
	var from := _project_field(ball_position,arena)-Vector2(0,ball_height*45.0*_depth_scale(ball_position))
	var to := _project_field(ball_target,arena)-Vector2(0,ball_target_height*45.0*_depth_scale(ball_target))
	if from.distance_to(to)<8.0:
		return
	var control := (from+to)*0.5-Vector2(0,38.0+maxf(ball_height,ball_target_height)*30.0)
	var prev := from
	for i in range(1,17):
		var t := float(i)/16.0
		var p := from.lerp(control,t).lerp(control.lerp(to,t),t)
		draw_line(prev,p,Color(0.95,0.98,1.0,0.06+t*0.22),1.7)
		prev = p

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center := _project_field(p,arena)
	var next := _project_field(p+(velocity.normalized()*0.05 if velocity.length()>0.02 else Vector2(0.04,0)),arena)
	var dir := (next-center).normalized()
	if dir.length()<0.1: dir = Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _depth_scale(p)*(1.13 if active else 1.0)
	var rear := center-dir*12*s

	draw_circle(center+Vector2(3,5*s),13*s,Color(0,0,0,0.34))
	for off in [Vector2(-6,-8),Vector2(6,-8),Vector2(-6,8),Vector2(6,8)]:
		var w := center+dir*off.x*s+side*off.y*s
		draw_circle(w,3.0*s,Color(0.01,0.015,0.02,1))
		draw_circle(w,1.2*s,Color(0.42,0.50,0.58,0.78))

	var body := PackedVector2Array([
		center+dir*17*s,
		center+dir*6*s+side*8*s,
		center-dir*7*s+side*6.8*s,
		rear+side*4.7*s,
		rear-side*4.7*s,
		center-dir*7*s-side*6.8*s,
		center+dir*6*s-side*8*s
	])
	if active:
		draw_circle(center,24*s,Color(color.r,color.g,color.b,0.075))
	if support:
		draw_arc(center,19*s,0,TAU,32,Color(color.r,color.g,color.b,0.26),1.6)
	draw_colored_polygon(body,Color(color.r*0.34,color.g*0.34,color.b*0.34,1))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(color.r,color.g,color.b,0.98),2.0)
	var roof := PackedVector2Array([
		center+dir*8*s+side*3.8*s,center+dir*9*s-side*3.8*s,
		center-dir*1*s-side*4.3*s,center-dir*1*s+side*4.3*s
	])
	draw_colored_polygon(roof,Color(0.64,0.84,0.94,0.34))
	draw_circle(center+dir*14*s+side*4*s,1.2*s,Color(0.90,0.98,1,0.86))
	draw_circle(center+dir*14*s-side*4*s,1.2*s,Color(0.90,0.98,1,0.86))
	draw_line(rear+side*3*s,rear-side*3*s,Color(1,0.28,0.32,0.66),1.6*s)
	if velocity.length()>0.07:
		draw_line(rear,rear-dir*14*s,Color(color.r,color.g,color.b,0.62),4*s)
		draw_line(rear-dir*14*s,rear-dir*21*s,Color(0.94,0.98,1,0.20),1.5*s)
	if not role.is_empty():
		var label_color := Color(0.94,0.98,1,0.95 if active else 0.65)
		draw_string(FONT_V25,center+Vector2(-21,-21*s),role,HORIZONTAL_ALIGNMENT_CENTER,42,8,label_color)

func _draw_projected_ball(arena: Rect2) -> void:
	var ground := _project_field(ball_position,arena)
	var s := _depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*45*s)
	draw_circle(ground+Vector2(3,5),8.3*s*(1.0-ball_height*0.16),Color(0,0,0,0.43))
	draw_circle(visual,19*s,Color(0.88,0.96,1,0.06))
	draw_circle(visual,9.6*s,Color("F5F8FC"))
	draw_arc(visual,5.8*s,-0.2,1.5,14,Color(0.27,0.34,0.41,0.74),1.0*s)
	draw_arc(visual,4.9*s,2.1,4.2,14,Color(0.27,0.34,0.41,0.60),1.0*s)
	draw_circle(visual+Vector2(-2.4,-2.7)*s,1.9*s,Color(1,1,1,0.82))

func _draw_broadcast_header() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var subtitle := "TEAM COMBO" if not combo_id.is_empty() else _phase_title_v24(phase)
	draw_string(FONT_V25,Vector2(12,24),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,17,Color(0.96,0.98,1,0.98))
	draw_string(FONT_V25,Vector2(12,44),subtitle,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,8,Color(0.60,0.72,0.82,0.86))
	var live := "LIVE  ·  AUTO-SIM"
	var live_w := FONT_V25.get_string_size(live,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
	draw_string(FONT_V25,Vector2(size.x-12-live_w,19),live,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color(0.40,0.86,0.68,0.78))
	var pressure := clampf((float(momentum)+100.0)/200.0,0.0,1.0)
	draw_rect(Rect2(12,52,size.x-24,3),Color(1,1,1,0.055),true)
	draw_rect(Rect2(12,52,(size.x-24)*pressure,3),OUR_COLOR if momentum>=0 else THEIR_COLOR,true)
