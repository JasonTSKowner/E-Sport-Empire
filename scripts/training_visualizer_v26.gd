class_name TrainingVisualizerV26
extends "res://scripts/training_perspective_surface_v25.gd"

const V26_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 512.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player,readiness,color)
	custom_minimum_size = Vector2(0.0,512.0)

func _v241_project_field(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x,0.0,1.0)
	var eased := pow(depth,0.84)
	var near_y := arena.end.y-10.0
	var far_y := arena.position.y+84.0
	var half_width := lerpf(arena.size.x*0.54,arena.size.x*0.17,eased)
	var sway := (float(ball_position.y)-0.5)*arena.size.x*-0.052
	return Vector2(arena.get_center().x+sway+(p.y-0.5)*2.0*half_width,lerpf(near_y,far_y,eased))

func _v241_depth_scale(p: Vector2) -> float:
	return lerpf(1.56,0.51,pow(clampf(p.x,0.0,1.0),0.80))

func _draw() -> void:
	var arena := Rect2(Vector2(6,72),Vector2(maxf(1.0,size.x-12),maxf(1.0,size.y-112)))
	_v241_draw_backdrop(arena)
	_v241_draw_pitch(arena)
	_draw_drill_checkpoints_v26(arena)
	_v241_draw_guides(arena)
	_draw_future_ghosts_v26(arena)
	_v241_draw_car(arena)
	_v241_draw_ball(arena)
	_draw_contact_read_v26(arena)
	_draw_header_v26()
	_draw_sequence_strip_v26()

func _v241_draw_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("010307"),true)
	for i in range(16):
		var t := float(i)/15.0
		var c := Color("111A24").lerp(Color("010307"),t)
		draw_rect(Rect2(0,float(i)*size.y/16.0,size.x,size.y/16.0+1),c,true)
	for bay in range(5):
		var x := 8.0+float(bay)*(size.x-16.0)/5.0
		var w := (size.x-22.0)/5.0-2.0
		draw_rect(Rect2(x,arena.position.y-7,w,48),Color(0.025,0.045,0.060,0.86),true)
		draw_line(Vector2(x+5,arena.position.y+7),Vector2(x+w-5,arena.position.y+7),Color(accent.r,accent.g,accent.b,0.09),2.0)
		for row in range(3):
			var yy := arena.position.y+17+float(row)*8
			draw_line(Vector2(x+7,yy),Vector2(x+w-7,yy),Color(0.70,0.82,0.90,0.04),1.0)
	for i in range(7):
		var x := 18.0+float(i)*(size.x-36.0)/6.0
		draw_circle(Vector2(x,arena.position.y+2),2.4,Color(0.92,0.98,1.0,0.26))
		var beam := PackedVector2Array([Vector2(x-2.5,arena.position.y+6),Vector2(x+2.5,arena.position.y+6),Vector2(x+48,arena.end.y),Vector2(x-48,arena.end.y)])
		draw_colored_polygon(beam,Color(accent.r,accent.g,accent.b,0.008))
	draw_circle(Vector2(size.x*0.78,arena.position.y+54),size.x*0.30,Color(accent.r,accent.g,accent.b,0.028))

func _v241_draw_pitch(arena: Rect2) -> void:
	super._v241_draw_pitch(arena)
	var near_l := _v241_project_field(Vector2(0,0),arena)
	var near_r := _v241_project_field(Vector2(0,1),arena)
	var far_l := _v241_project_field(Vector2(1,0),arena)
	var far_r := _v241_project_field(Vector2(1,1),arena)
	for side in [0,1]:
		var a := near_l if side==0 else near_r
		var b := far_l if side==0 else far_r
		var direction := -1.0 if side==0 else 1.0
		var wall := PackedVector2Array([a,b,b+Vector2(direction*3,-28),a+Vector2(direction*6,-34)])
		draw_colored_polygon(wall,Color(accent.r,accent.g,accent.b,0.035))
		draw_line(a+Vector2(direction*2,-9),b+Vector2(direction*2,-22),Color(accent.r,accent.g,accent.b,0.16),1.2)
		for i in range(1,5):
			var t := float(i)/5.0
			var p := a.lerp(b,t)
			draw_line(p+Vector2(direction*2,-4),p+Vector2(direction*2,-17),Color(0.74,0.88,0.94,0.045),1.0)

func _draw_drill_checkpoints_v26(arena: Rect2) -> void:
	var checkpoints: Array[float] = [0.18,0.38,0.62,0.84]
	for i in range(checkpoints.size()):
		var t: float = checkpoints[i]
		var p := _ball_target_for_drill(t)
		var h := _ball_height_for_drill(t)
		var point := _v241_project_field(p,arena)-Vector2(0,h*56.0*_v241_depth_scale(p))
		var reached: bool = drill_phase>=t
		var alpha: float = 0.26 if reached else 0.10
		draw_circle(point,5.0,Color(accent.r,accent.g,accent.b,alpha*0.28))
		draw_arc(point,7.5,0,TAU,24,Color(accent.r,accent.g,accent.b,alpha),1.0)
		draw_string(V26_FONT,point+Vector2(-8,3),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,16,7,Color(0.88,0.96,1.0,alpha+0.18))

func _v241_draw_guides(arena: Rect2) -> void:
	var future_t := minf(0.999,drill_phase+0.18)
	var car := _v241_project_field(car_position,arena)
	var future_car := _v241_project_field(_car_target_for_drill(future_t),arena)
	draw_dashed_line(car,future_car,Color(accent.r,accent.g,accent.b,0.38),2.2,10.0)
	var d := (future_car-car).normalized()
	if d.length()>0.1:
		var side := Vector2(-d.y,d.x)
		var tip := future_car-d*3.0
		draw_colored_polygon(PackedVector2Array([tip,tip-d*10+side*5,tip-d*10-side*5]),Color(accent.r,accent.g,accent.b,0.34))
	var ball := _v241_project_field(ball_position,arena)-Vector2(0,ball_height*56.0*_v241_depth_scale(ball_position))
	var future_pos := _ball_target_for_drill(future_t)
	var future_h := _ball_height_for_drill(future_t)
	var future_ball := _v241_project_field(future_pos,arena)-Vector2(0,future_h*56.0*_v241_depth_scale(future_pos))
	var control := (ball+future_ball)*0.5-Vector2(0,40.0+maxf(ball_height,future_h)*44.0)
	var previous := ball
	for i in range(1,27):
		var t := float(i)/26.0
		var a := ball.lerp(control,t)
		var b := control.lerp(future_ball,t)
		var p := a.lerp(b,t)
		var fade := lerpf(0.48,0.10,t)
		draw_line(previous,p,Color(0.94,0.98,1.0,fade),1.9 if t<0.55 else 1.3)
		if i%5==0: draw_circle(p,2.0,Color(0.94,0.98,1.0,fade*0.8))
		previous=p
	var target := _v241_project_field(target_position,arena)
	var s := _v241_depth_scale(target_position)
	draw_arc(target,17.0*s,0,TAU,32,Color(accent.r,accent.g,accent.b,0.32),1.7)
	draw_arc(target,7.0*s,0,TAU,28,Color(accent.r,accent.g,accent.b,0.15),1.2)

func _draw_future_ghosts_v26(arena: Rect2) -> void:
	var ghost_steps: Array[float] = [0.16,0.31]
	for step: float in ghost_steps:
		var t := minf(0.999,drill_phase+step)
		var p := _car_target_for_drill(t)
		var center := _v241_project_field(p,arena)
		var s := _v241_depth_scale(p)
		draw_arc(center,11.0*s,0,TAU,24,Color(accent.r,accent.g,accent.b,0.095),1.0)
		draw_line(center+Vector2(-6*s,0),center+Vector2(6*s,0),Color(accent.r,accent.g,accent.b,0.08),1.0)
		draw_line(center+Vector2(0,-4*s),center+Vector2(0,4*s),Color(accent.r,accent.g,accent.b,0.08),1.0)

func _v241_draw_car(arena: Rect2) -> void:
	super._v241_draw_car(arena)
	var center := _v241_project_field(car_position,arena)
	var s := _v241_depth_scale(car_position)
	draw_arc(center,26.0*s,0,TAU,34,Color(accent.r,accent.g,accent.b,0.16+0.03*sin(animation_time*4.2)),1.2)

func _v241_draw_ball(arena: Rect2) -> void:
	super._v241_draw_ball(arena)
	var ground := _v241_project_field(ball_position,arena)
	var s := _v241_depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*56.0*s)
	if car_velocity.length()>0.04:
		var car := _v241_project_field(car_position,arena)
		if car.distance_to(visual)<72.0:
			draw_line(car,visual,Color(accent.r,accent.g,accent.b,0.10),1.0)

func _draw_contact_read_v26(arena: Rect2) -> void:
	var car := _v241_project_field(car_position,arena)
	var ground := _v241_project_field(ball_position,arena)
	var ball := ground-Vector2(0,ball_height*56.0*_v241_depth_scale(ball_position))
	if car.distance_to(ball)<54.0:
		draw_circle((car+ball)*0.5,18.0,Color(accent.r,accent.g,accent.b,0.022))

func _draw_header_v26() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category","TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_rect(Rect2(0,0,size.x,60),Color(0.01,0.018,0.026,0.96),true)
	draw_line(Vector2(0,60),Vector2(size.x,60),Color(accent.r,accent.g,accent.b,0.12),1.0)
	draw_string(V26_FONT,Vector2(14,24),mechanic,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,16,Color(0.95,0.98,1.0,0.98))
	draw_string(V26_FONT,Vector2(14,43),"%s  /  %s"%[category,step_label],HORIZONTAL_ALIGNMENT_LEFT,size.x-28,8,Color(0.62,0.74,0.83,0.84))
	var ratio := float(focus_remaining)/float(maxi(1,focus_limit))
	draw_rect(Rect2(14,50,size.x-28,3),Color(1,1,1,0.055),true)
	draw_rect(Rect2(14,50,(size.x-28)*ratio,3),accent,true)

func _draw_sequence_strip_v26() -> void:
	var steps := _sequence_labels_v26()
	var y := size.y-37.0
	draw_rect(Rect2(9,y-12,size.x-18,26),Color(0.01,0.018,0.025,0.82),true)
	var cell := (size.x-18.0)/float(maxi(1,steps.size()))
	var current := clampi(int(floor(drill_phase*float(steps.size()))),0,steps.size()-1)
	for i in range(steps.size()):
		var active := i==current
		var done := i<current
		var c := accent if active else Color(0.68,0.80,0.88) if done else Color(0.42,0.50,0.58)
		draw_string(V26_FONT,Vector2(9+cell*i,y+3),str(steps[i]),HORIZONTAL_ALIGNMENT_CENTER,cell,7,Color(c.r,c.g,c.b,0.90 if active else 0.52))
	var footer := "FOKUS %d/%d  ·  MÜDIGKEIT %d"%[focus_remaining,focus_limit,fatigue]
	draw_string(V26_FONT,Vector2(12,size.y-7),footer,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,7,Color(0.58,0.68,0.76,0.60))

func _sequence_labels_v26() -> Array[String]:
	match focus_family:
		"psycho": return ["WALL","BACKWALL","MUSTY","PSYCHO"]
		"multi_reset": return ["SETUP","RESET 1","RESET 2","FINISH"]
		"reset", "stall": return ["SETUP","CONTACT","CONTROL","FINISH"]
		"air_dribble": return ["SETUP","FIRST","CARRY","FINISH"]
		"double_tap": return ["SHOT","READ","FOLLOW","TOUCH"]
		"redirect": return ["READ","PREJUMP","ANGLE","REDIRECT"]
		"ceiling": return ["WALL","CEILING","DROP","FINISH"]
		"pinch", "team_pinch": return ["ANGLE","APPROACH","CONTACT","RELEASE"]
		"pogo": return ["AIR","DROP","BOUNCE","RECOVER"]
		"defense", "save": return ["READ","SHADOW","SAVE","CLEAR"]
		"flick", "musty": return ["CONTROL","LOAD","RELEASE","RECOVER"]
		_: return ["SETUP","READ","EXECUTE","RECOVER"]
