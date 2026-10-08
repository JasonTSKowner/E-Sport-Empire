class_name TrainingVisualizerV30
extends "res://scripts/training_perspective_surface_v242.gd"

const FONT_V30 = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 472.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 472.0)

func _draw() -> void:
	var arena := Rect2(Vector2(4, 68), Vector2(maxf(1.0, size.x - 8), maxf(1.0, size.y - 100)))
	_draw_lab_world(arena)
	_draw_training_route_v30(arena)
	_draw_ghost_frames(arena)
	_draw_car_v30(arena)
	_draw_ball_v30(arena)
	_draw_lab_hud()

func _draw_lab_world(arena: Rect2) -> void:
	for i in range(18):
		var t := float(i)/17.0
		var c := Color("111821").lerp(Color("020407"),t)
		draw_rect(Rect2(0,size.y*t,size.x,size.y/17.0+2),c,true)
	var horizon := arena.position.y+54.0
	var stands := PackedVector2Array([Vector2(0,arena.position.y-8),Vector2(size.x,arena.position.y-8),Vector2(size.x*0.90,horizon),Vector2(size.x*0.10,horizon)])
	draw_colored_polygon(stands,Color(0.035,0.048,0.064,0.98))
	for row in range(4):
		var y := arena.position.y+7.0+row*10.0
		var count := 26-row*2
		for i in range(count):
			var x := 10.0+float(i)*(size.x-20.0)/float(maxi(1,count-1))
			var a := 0.07+0.03*sin(animation_time*0.9+i*1.5+row)
			var c := accent if (i+row)%10==0 else Color(0.74,0.82,0.90,1.0)
			draw_circle(Vector2(x,y),1.0,Color(c.r,c.g,c.b,a))
	for i in range(7):
		var x := 18.0+float(i)*(size.x-36.0)/6.0
		draw_circle(Vector2(x,arena.position.y+1),2.0,Color(0.92,0.97,1.0,0.26))
		var beam := PackedVector2Array([Vector2(x-4,arena.position.y+4),Vector2(x+4,arena.position.y+4),Vector2(x+42,arena.end.y),Vector2(x-42,arena.end.y)])
		draw_colored_polygon(beam,Color(accent.r,accent.g,accent.b,0.010))
	_draw_pitch_v30(arena)

func _draw_pitch_v30(arena: Rect2) -> void:
	var near_l := _v241_project_field(Vector2(0,0),arena)
	var near_r := _v241_project_field(Vector2(0,1),arena)
	var far_l := _v241_project_field(Vector2(1,0),arena)
	var far_r := _v241_project_field(Vector2(1,1),arena)
	var pitch := PackedVector2Array([near_l,near_r,far_r,far_l])
	draw_colored_polygon(pitch,Color("06171D"))
	draw_polyline(PackedVector2Array([near_l,near_r,far_r,far_l,near_l]),Color(accent.r,accent.g,accent.b,0.28),2.0)
	for i in range(10):
		var a := float(i)/10.0
		var b := float(i+1)/10.0
		if i%2==0:
			var band := PackedVector2Array([_v241_project_field(Vector2(a,0),arena),_v241_project_field(Vector2(a,1),arena),_v241_project_field(Vector2(b,1),arena),_v241_project_field(Vector2(b,0),arena)])
			draw_colored_polygon(band,Color(0.04,0.13,0.16,0.42))
	var ca := _v241_project_field(Vector2(0.5,0),arena)
	var cb := _v241_project_field(Vector2(0.5,1),arena)
	draw_line(ca,cb,Color(0.60,0.80,0.88,0.22),1.4)
	var center := _v241_project_field(Vector2(0.5,0.5),arena)
	draw_arc(center,24,0,TAU,44,Color(0.60,0.80,0.88,0.17),1.2)
	for p in [Vector2(0.12,0.18),Vector2(0.12,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.88,0.18),Vector2(0.88,0.82)]:
		var s := _v241_depth_scale(p)
		var pt := _v241_project_field(p,arena)
		draw_circle(pt,5.1*s,Color(0.96,0.72,0.34,0.08))
		draw_circle(pt,2.0*s,Color(0.98,0.75,0.36,0.84))
	_draw_goal_v30(Vector2(0,0.5),arena,true)
	_draw_goal_v30(Vector2(1,0.5),arena,false)
	var brand_y := near_l.y+9
	draw_line(Vector2(near_l.x+14,brand_y),Vector2(near_r.x-14,brand_y),Color(accent.r,accent.g,accent.b,0.14),3.0)
	draw_string(FONT_V30,Vector2(near_l.x+24,brand_y+13),"PERFORMANCE LAB  •  SESSION LIVE",HORIZONTAL_ALIGNMENT_LEFT,near_r.x-near_l.x-48,7,Color(0.72,0.84,0.90,0.30))

func _draw_goal_v30(pos: Vector2, arena: Rect2, near_goal: bool) -> void:
	var center := _v241_project_field(pos,arena)
	var s := _v241_depth_scale(pos)
	var w := 96*s
	var h := 34*s
	var front := Rect2(center.x-w*0.5,center.y-h*0.5+(9 if near_goal else -8),w,h)
	var off := Vector2(0,10*s if near_goal else -8*s)
	var back := Rect2(front.position+off,front.size*Vector2(0.80,0.84))
	back.position.x=center.x-back.size.x*0.5
	draw_rect(back,Color(accent.r,accent.g,accent.b,0.035),true)
	draw_rect(front,Color(accent.r,accent.g,accent.b,0.045),true)
	draw_rect(front,Color(accent.r,accent.g,accent.b,0.38),false,1.8)
	draw_rect(back,Color(accent.r,accent.g,accent.b,0.14),false,1.0)

func _draw_training_route_v30(arena: Rect2) -> void:
	var car := _v241_project_field(car_position,arena)
	var future_t := minf(0.999,drill_phase+0.16)
	var future_car := _v241_project_field(_car_target_for_drill(future_t),arena)
	draw_dashed_line(car,future_car,Color(accent.r,accent.g,accent.b,0.30),2.0,8.0)
	var ball := _v241_project_field(ball_position,arena)-Vector2(0,ball_height*42*_v241_depth_scale(ball_position))
	var future_pos := _ball_target_for_drill(future_t)
	var future_h := _ball_height_for_drill(future_t)
	var future_ball := _v241_project_field(future_pos,arena)-Vector2(0,future_h*42*_v241_depth_scale(future_pos))
	var control := (ball+future_ball)*0.5-Vector2(0,38+maxf(ball_height,future_h)*24)
	var previous := ball
	for i in range(1,15):
		var t := float(i)/14.0
		var a := ball.lerp(control,t)
		var b := control.lerp(future_ball,t)
		var p := a.lerp(b,t)
		if i%2==0: draw_line(previous,p,Color(0.96,0.99,1.0,0.24),1.6)
		previous=p
	var target := _v241_project_field(target_position,arena)
	var target_s := _v241_depth_scale(target_position)
	draw_circle(target,20*target_s,Color(accent.r,accent.g,accent.b,0.035))
	draw_arc(target,20*target_s,0,TAU,38,Color(accent.r,accent.g,accent.b,0.34),1.8)
	draw_arc(target,10*target_s,0,TAU,32,Color(accent.r,accent.g,accent.b,0.20),1.2)

func _draw_ghost_frames(arena: Rect2) -> void:
	for offset in [0.07,0.13,0.20]:
		var t := minf(0.999,drill_phase+float(offset))
		var p := _v241_project_field(_car_target_for_drill(t),arena)
		var s := _v241_depth_scale(_car_target_for_drill(t))
		draw_circle(p,8*s,Color(accent.r,accent.g,accent.b,0.025))
		draw_arc(p,8*s,0,TAU,20,Color(accent.r,accent.g,accent.b,0.08),1.0)

func _draw_car_v30(arena: Rect2) -> void:
	var center := _v241_project_field(car_position,arena)
	var next_pos := car_position+(car_velocity.normalized()*0.04 if car_velocity.length()>0.02 else Vector2(0.04,0))
	var next := _v241_project_field(next_pos,arena)
	var dir := (next-center).normalized()
	if dir.length()<0.1: dir=Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _v241_depth_scale(car_position)*1.18
	var rear := center-dir*12*s
	var nose := center+dir*17*s
	draw_circle(center+Vector2(2,5*s),12*s,Color(0,0,0,0.34))
	for off_value in [Vector2(-6.0,-7.6),Vector2(6.0,-7.6),Vector2(-6.0,7.6),Vector2(6.0,7.6)]:
		var off: Vector2 = off_value
		var wp: Vector2 = center+dir*off.x*s+side*off.y*s
		draw_circle(wp,3*s,Color(0.01,0.015,0.022,0.98))
		draw_circle(wp,1.3*s,Color(0.38,0.46,0.54,0.90))
	var body := PackedVector2Array([nose,center+dir*6*s+side*8.2*s,center-dir*8*s+side*6.5*s,rear+side*4.7*s,rear-side*4.7*s,center-dir*8*s-side*6.5*s,center+dir*6*s-side*8.2*s])
	draw_circle(center,22*s,Color(accent.r,accent.g,accent.b,0.085))
	draw_colored_polygon(body,Color(accent.r*0.34,accent.g*0.34,accent.b*0.34,1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(accent.r,accent.g,accent.b,0.98),1.9)
	var glass := PackedVector2Array([center+dir*8*s+side*3.8*s,center+dir*9*s-side*3.8*s,center-dir*s-side*4.2*s,center-dir*s+side*4.2*s])
	draw_colored_polygon(glass,Color(0.62,0.84,0.94,0.34))
	if car_velocity.length()>0.04:
		draw_line(rear,rear-dir*13*s,Color(accent.r,accent.g,accent.b,0.58),3.6*s)

func _draw_ball_v30(arena: Rect2) -> void:
	var ground := _v241_project_field(ball_position,arena)
	var s := _v241_depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*42*s)
	draw_circle(ground+Vector2(3,6),8*s*(1.0-ball_height*0.18),Color(0,0,0,0.40))
	draw_circle(visual,18*s,Color(0.88,0.96,1.0,0.06))
	draw_circle(visual,9.5*s,Color("F7FAFE"))
	draw_arc(visual,5.8*s,-0.3,1.5,12,Color(0.28,0.35,0.42,0.78),1.1*s)
	draw_arc(visual,4.8*s,2.1,4.2,12,Color(0.28,0.35,0.42,0.68),1.0*s)

func _draw_lab_hud() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category","TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_rect(Rect2(12,10,size.x-24,40),Color(0.025,0.035,0.050,0.94),true)
	draw_rect(Rect2(12,10,size.x-24,40),Color(1,1,1,0.07),false,1.0)
	draw_string(FONT_V30,Vector2(22,29),mechanic,HORIZONTAL_ALIGNMENT_LEFT,size.x-44,12,Color(0.95,0.98,1.0,0.96))
	draw_string(FONT_V30,Vector2(22,43),"%s  •  %s"%[category,step_label],HORIZONTAL_ALIGNMENT_LEFT,size.x-44,8,Color(0.62,0.76,0.84,0.82))
	var footer := "FOKUS %d/%d   •   MÜDIGKEIT %d"%[focus_remaining,focus_limit,fatigue]
	draw_string(FONT_V30,Vector2(14,size.y-11),footer,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,8,Color(0.64,0.76,0.84,0.70))
