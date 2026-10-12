class_name MatchVisualizerV26
extends "res://scripts/match_visualizer_v25.gd"

const V26_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 548.0)

func _project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x,0.0,1.0)
	var eased := pow(depth,0.84)
	var near_y := arena.end.y - 10.0
	var far_y := arena.position.y + 86.0
	var half_width := lerpf(arena.size.x*0.54,arena.size.x*0.17,eased)
	var focus_lane := float(ball_position.y)
	if active_actor >= 0 and active_actor < our_positions.size():
		focus_lane = lerpf(focus_lane,float(our_positions[active_actor].y),0.28)
	var camera_sway := (focus_lane-0.5)*arena.size.x*-0.055
	var kick := sin(time_alive*42.0)*camera_kick*1.8
	return Vector2(
		arena.get_center().x + camera_sway + kick + (p.y-0.5)*2.0*half_width,
		lerpf(near_y,far_y,eased)
	)

func _depth_scale(p: Vector2) -> float:
	return lerpf(1.58,0.50,pow(clampf(p.x,0.0,1.0),0.80))

func _draw() -> void:
	var arena := Rect2(Vector2(6,70),Vector2(maxf(1.0,size.x-12),maxf(1.0,size.y-108)))
	_draw_broadcast_backdrop(arena)
	_draw_perspective_pitch(arena)
	_draw_phase_zones(arena)
	_draw_rotation_paths(arena)
	_draw_projected_ball_path(arena)

	# Far objects first, near objects last for a stronger depth illusion.
	var actors: Array[Dictionary] = []
	for index in range(their_positions.size()):
		actors.append({"p":their_positions[index],"v":their_velocities[index],"c":THEIR_COLOR,"role":"","active":false,"support":false})
	for index in range(our_positions.size()):
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		actors.append({"p":our_positions[index],"v":our_velocities[index],"c":OUR_COLOR,"role":role,"active":index==active_actor,"support":index==support_actor})
	actors.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["p"].x) > float(b["p"].x))
	for actor in actors:
		_draw_projected_car(actor["p"],actor["v"],actor["c"],actor["role"],actor["active"],actor["support"],arena)

	_draw_projected_ball(arena)
	_draw_contact_focus(arena)
	_draw_broadcast_header_v26()
	_draw_role_strip_v26()
	_draw_mastery_strip()

	if phase == "mechanic_fail":
		draw_rect(Rect2(8,55,size.x-16,31),Color(0.29,0.025,0.04,0.94),true)
		draw_line(Vector2(10,85),Vector2(size.x-10,85),Color(THEIR_COLOR.r,THEIR_COLOR.g,THEIR_COLOR.b,0.34),2.0)
		draw_string(V26_FONT,Vector2(18,76),"PLAY LOST  ·  RECOVER & ROTATE",HORIZONTAL_ALIGNMENT_LEFT,size.x-36,9,Color(1.0,0.84,0.86,0.96))

	if goal_flash > 0.01:
		var c := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(arena,Color(c.r,c.g,c.b,goal_flash*0.08),true)
		var goal_point := _project_field(Vector2(1.0,0.5) if goal_side>0 else Vector2(0.0,0.5),arena)
		for ring in range(4):
			draw_arc(goal_point,28.0+float(ring)*22.0+(1.0-goal_flash)*30.0,0,TAU,48,Color(c.r,c.g,c.b,goal_flash*(0.46-float(ring)*0.085)),2.8)
		draw_string(V26_FONT,Vector2(0,size.y*0.48),"GOAL",HORIZONTAL_ALIGNMENT_CENTER,size.x,28,Color(c.r,c.g,c.b,goal_flash*0.88))

func _draw_broadcast_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("010307"),true)
	for i in range(16):
		var t := float(i)/15.0
		var c := Color("121B26").lerp(Color("010307"),t)
		draw_rect(Rect2(0,float(i)*size.y/16.0,size.x,size.y/16.0+1),c,true)

	# Multi-tier stadium architecture.
	var horizon := arena.position.y+58.0
	for tier in range(3):
		var top := arena.position.y-12.0+float(tier)*24.0
		var bowl := PackedVector2Array([
			Vector2(-20,top),Vector2(size.x+20,top),
			Vector2(size.x*(0.90-float(tier)*0.035),top+34),
			Vector2(size.x*(0.10+float(tier)*0.035),top+34)
		])
		draw_colored_polygon(bowl,Color(0.028+float(tier)*0.008,0.045+float(tier)*0.009,0.062+float(tier)*0.010,0.90))
		var count := 30-tier*4
		for i in range(count):
			var x := 8.0+float(i)*(size.x-16.0)/float(maxi(1,count-1))
			var y := top+13.0+sin(float(i)*0.7)*2.0
			var flicker := 0.04+0.028*sin(time_alive*0.72+float(i)*1.17+float(tier))
			var cc := OUR_COLOR if (i+tier)%11==0 else THEIR_COLOR if (i+tier)%17==0 else Color(0.75,0.84,0.92)
			draw_circle(Vector2(x,y),0.95,Color(cc.r,cc.g,cc.b,flicker))

	for i in range(9):
		var x := 12.0+float(i)*(size.x-24.0)/8.0
		draw_circle(Vector2(x,arena.position.y+3),2.6,Color(0.92,0.98,1.0,0.28))
		draw_circle(Vector2(x,arena.position.y+3),8.0,Color(0.80,0.92,1.0,0.028))
		var beam := PackedVector2Array([
			Vector2(x-2.5,arena.position.y+7),Vector2(x+2.5,arena.position.y+7),
			Vector2(x+52,arena.end.y),Vector2(x-52,arena.end.y)
		])
		draw_colored_polygon(beam,Color(0.76,0.90,0.98,0.007))
	draw_circle(Vector2(size.x*0.15,horizon),size.x*0.30,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.027))
	draw_circle(Vector2(size.x*0.86,horizon),size.x*0.26,Color(THEIR_COLOR.r,THEIR_COLOR.g,THEIR_COLOR.b,0.020))

func _draw_perspective_pitch(arena: Rect2) -> void:
	super._draw_perspective_pitch(arena)
	var near_l := _project_field(Vector2(0,0),arena)
	var near_r := _project_field(Vector2(0,1),arena)
	var far_l := _project_field(Vector2(1,0),arena)
	var far_r := _project_field(Vector2(1,1),arena)
	# Transparent curved-wall suggestion and LED advertising.
	for side in [0,1]:
		var a := near_l if side==0 else near_r
		var b := far_l if side==0 else far_r
		var offset := -1.0 if side==0 else 1.0
		var wall := PackedVector2Array([a,b,b+Vector2(offset*3,-23),a+Vector2(offset*5,-29)])
		draw_colored_polygon(wall,Color(0.18,0.48,0.60,0.035))
		draw_line(a+Vector2(offset*2,-8),b+Vector2(offset*2,-19),Color(0.65,0.86,0.94,0.14),1.2)
		for i in range(6):
			var p0 := a.lerp(b,float(i)/6.0)
			var p1 := a.lerp(b,float(i+1)/6.0)
			var cc := OUR_COLOR if i%2==0 else Color(0.78,0.84,0.90)
			draw_line(p0+Vector2(offset*2,-5),p1+Vector2(offset*2,-10),Color(cc.r,cc.g,cc.b,0.13),3.0)

func _draw_phase_zones(arena: Rect2) -> void:
	# Context is shown in-world, not as giant debug labels.
	var target := _project_field(ball_target,arena)
	var s := _depth_scale(ball_target)
	var c := OUR_COLOR if ball_target.x >= 0.5 else THEIR_COLOR
	if phase in ["challenge","chance_ours","chance_theirs","finish_touch","redirect_finish","psycho_contact","reset_contact","second_reset","third_reset"]:
		draw_arc(target,19.0*s,0,TAU,34,Color(c.r,c.g,c.b,0.24),1.5)
		draw_arc(target,8.0*s,0,TAU,28,Color(c.r,c.g,c.b,0.14),1.1)

func _draw_rotation_paths(arena: Rect2) -> void:
	for index in range(our_positions.size()):
		if index >= our_targets.size(): continue
		var from := _project_field(our_positions[index],arena)
		var to := _project_field(our_targets[index],arena)
		var active := index==active_actor
		var support := index==support_actor
		var alpha := 0.46 if active else 0.25 if support else 0.055
		if not active and not support and format == "1v1": alpha = 0.0
		if alpha <= 0.0: continue
		draw_dashed_line(from,to,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,alpha),2.3 if active else 1.4,10.0)
		if active or support:
			var d := (to-from).normalized()
			if d.length()>0.1:
				var side := Vector2(-d.y,d.x)
				var tip := to-d*3.0
				draw_colored_polygon(PackedVector2Array([tip,tip-d*10+side*5,tip-d*10-side*5]),Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,alpha*0.82))

func _draw_projected_ball_path(arena: Rect2) -> void:
	var from := _project_field(ball_position,arena)-Vector2(0,ball_height*56.0*_depth_scale(ball_position))
	var to := _project_field(ball_target,arena)-Vector2(0,ball_target_height*56.0*_depth_scale(ball_target))
	if from.distance_to(to)<7.0: return
	var apex := 40.0+maxf(ball_height,ball_target_height)*48.0
	var control := (from+to)*0.5-Vector2(0,apex)
	var previous := from
	for i in range(1,31):
		var t := float(i)/30.0
		var a := from.lerp(control,t)
		var b := control.lerp(to,t)
		var p := a.lerp(b,t)
		var fade := lerpf(0.52,0.10,t)
		draw_line(previous,p,Color(0.94,0.98,1.0,fade),2.0 if t<0.5 else 1.3)
		if i%5==0: draw_circle(p,2.2,Color(0.94,0.98,1.0,fade*0.85))
		previous=p
	var landing := _project_field(ball_target,arena)
	var ts := _depth_scale(ball_target)
	draw_arc(landing,15.0*ts,0,TAU,32,Color(0.92,0.98,1.0,0.25),1.4)
	draw_circle(landing,2.2*ts,Color(0.92,0.98,1.0,0.34))

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	super._draw_projected_car(p,velocity,color,role,active,support,arena)
	var center := _project_field(p,arena)
	var s := _depth_scale(p)
	if active:
		draw_arc(center,28.0*s,0,TAU,36,Color(color.r,color.g,color.b,0.18+0.04*sin(time_alive*4.0)),1.3)
		draw_string(V26_FONT,center+Vector2(-31,-31*s),"ON BALL",HORIZONTAL_ALIGNMENT_CENTER,62,7,Color(0.90,0.98,1.0,0.82))
	elif support:
		draw_string(V26_FONT,center+Vector2(-30,-27*s),"READ",HORIZONTAL_ALIGNMENT_CENTER,60,7,Color(0.82,0.92,0.98,0.68))

func _draw_projected_ball(arena: Rect2) -> void:
	super._draw_projected_ball(arena)
	var ground := _project_field(ball_position,arena)
	var s := _depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*56.0*s)
	if ball_velocity.length()>0.10:
		var d := (_project_field(ball_position+ball_velocity.normalized()*0.04,arena)-ground).normalized()
		for i in range(1,4):
			draw_line(visual-d*(10.0+float(i)*7.0)*s,visual-d*(15.0+float(i)*8.0)*s,Color(0.90,0.97,1.0,0.15/float(i)),2.2)

func _draw_contact_focus(arena: Rect2) -> void:
	if active_actor < 0 or active_actor >= our_positions.size(): return
	var car := _project_field(our_positions[active_actor],arena)
	var ball_ground := _project_field(ball_position,arena)
	var bs := _depth_scale(ball_position)
	var ball := ball_ground-Vector2(0,ball_height*56.0*bs)
	if car.distance_to(ball)<72.0:
		var mid := (car+ball)*0.5
		draw_circle(mid,22.0,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.025))
		draw_line(car,ball,Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.11),1.0)

func _draw_broadcast_header_v26() -> void:
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var sub := "TEAM COMBO  /  %s" % format.to_upper() if not combo_id.is_empty() else "%s  /  PLAY %02d" % [_phase_title_v24(phase),sequence]
	draw_rect(Rect2(0,0,size.x,58),Color(0.01,0.018,0.026,0.95),true)
	draw_line(Vector2(0,58),Vector2(size.x,58),Color(OUR_COLOR.r,OUR_COLOR.g,OUR_COLOR.b,0.12),1.0)
	draw_string(V26_FONT,Vector2(14,23),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,16,Color(0.95,0.98,1.0,0.98))
	draw_string(V26_FONT,Vector2(14,42),sub,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,8,Color(0.62,0.73,0.82,0.82))
	var pressure := clampf((float(momentum)+100.0)/200.0,0.0,1.0)
	draw_rect(Rect2(14,49,size.x-28,3),Color(1,1,1,0.055),true)
	draw_rect(Rect2(14,49,(size.x-28)*pressure,3),OUR_COLOR if momentum>=0 else THEIR_COLOR,true)

func _draw_role_strip_v26() -> void:
	if our_positions.size()<2: return
	var y := size.y-34.0
	draw_rect(Rect2(10,y-13,size.x-20,23),Color(0.01,0.018,0.025,0.78),true)
	var labels := ["1ST  PRESS","2ND  READ","3RD  SAFETY"]
	var count := mini(our_positions.size(),3)
	var cell := (size.x-20.0)/float(count)
	for i in range(count):
		var active := i==active_actor
		var support := i==support_actor
		var c := OUR_COLOR if active else Color(0.72,0.82,0.89) if support else Color(0.48,0.56,0.64)
		draw_string(V26_FONT,Vector2(10+cell*i,y+2),labels[i],HORIZONTAL_ALIGNMENT_CENTER,cell,7,Color(c.r,c.g,c.b,0.88 if active else 0.58))
