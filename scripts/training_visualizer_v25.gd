class_name TrainingVisualizerV25
extends "res://scripts/training_visualizer_v242.gd"

const FONT_V25 = preload("res://assets/fonts/SpaceGrotesk.ttf")

var player_name_v25 := "SPIELER"
var components_v25: Dictionary = {}

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 548.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 548.0)
	player_name_v25 = str(player.get("name", "SPIELER")).to_upper()
	components_v25 = {}
	if not focus_mechanic.is_empty():
		var mechanic_id := str(focus_mechanic.get("id", ""))
		var all_details: Dictionary = player.get("mechanic_mastery_detail", {})
		components_v25 = (all_details.get(mechanic_id, {}) as Dictionary).duplicate(true)
	queue_redraw()

func _draw() -> void:
	var arena := Rect2(Vector2(5, 72), Vector2(maxf(1.0, size.x - 10.0), maxf(1.0, size.y - 98.0)))
	_v25_backdrop(arena)
	_v25_pitch(arena)
	_v25_context_players(arena)
	_v25_ball_path(arena)
	_v25_player_car(arena)
	_v25_ball(arena)
	_v25_hud()

func _v25_project(p: Vector2, arena: Rect2) -> Vector2:
	var depth := clampf(p.x, 0.0, 1.0)
	var near_y := arena.end.y - 18.0
	var far_y := arena.position.y + 46.0
	var screen_y := lerpf(near_y, far_y, pow(depth, 0.92))
	var half_width := lerpf(arena.size.x * 0.49, arena.size.x * 0.205, depth)
	return Vector2(arena.get_center().x + (p.y - 0.5) * 2.0 * half_width, screen_y)

func _v25_scale(p: Vector2) -> float:
	return lerpf(1.30, 0.50, pow(clampf(p.x, 0.0, 1.0), 0.90))

func _v25_backdrop(arena: Rect2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("020407"), true)
	for i in range(14):
		var t := float(i) / 13.0
		var c := Color("111923").lerp(Color("03070B"), t)
		draw_rect(Rect2(0, float(i) * size.y / 14.0, size.x, size.y / 14.0 + 1), c, true)

	# Stadium bowl behind the field.
	var horizon_y := arena.position.y + 30.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon_y - 26), Vector2(size.x, horizon_y - 26),
		Vector2(size.x * 0.88, horizon_y + 34), Vector2(size.x * 0.12, horizon_y + 34)
	]), Color(0.045,0.060,0.078,0.96))
	for row in range(4):
		var y := horizon_y - 13.0 + float(row) * 11.0
		var count := 24 - row * 2
		for i in range(count):
			var x := 10.0 + float(i) * (size.x - 20.0) / float(maxi(1, count - 1))
			var pulse := 0.08 + 0.035 * sin(animation_time * 0.8 + float(i) * 1.3 + row)
			var c := accent if (i + row) % 9 == 0 else Color(0.76,0.82,0.90,1)
			draw_circle(Vector2(x,y), 1.1 if row < 2 else 0.8, Color(c.r,c.g,c.b,pulse))

	# Floodlights / atmosphere.
	for i in range(5):
		var x := 24.0 + float(i) * (size.x - 48.0) / 4.0
		draw_circle(Vector2(x, horizon_y - 20.0), 2.2, Color(0.94,0.97,1.0,0.32))
		var beam := PackedVector2Array([
			Vector2(x-4,horizon_y-18), Vector2(x+4,horizon_y-18),
			Vector2(x+48,arena.end.y), Vector2(x-48,arena.end.y)
		])
		draw_colored_polygon(beam, Color(accent.r,accent.g,accent.b,0.008))

func _v25_pitch(arena: Rect2) -> void:
	var nl := _v25_project(Vector2(0,0), arena)
	var nr := _v25_project(Vector2(0,1), arena)
	var fl := _v25_project(Vector2(1,0), arena)
	var fr := _v25_project(Vector2(1,1), arena)
	var pitch := PackedVector2Array([nl,nr,fr,fl])
	draw_colored_polygon(pitch, Color("06161D"))

	# Stronger grass depth bands.
	for i in range(10):
		var x0 := float(i)/10.0
		var x1 := float(i+1)/10.0
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([
				_v25_project(Vector2(x0,0),arena), _v25_project(Vector2(x0,1),arena),
				_v25_project(Vector2(x1,1),arena), _v25_project(Vector2(x1,0),arena)
			]), Color(0.035,0.12,0.15,0.48))

	# Side walls and boards.
	for left in [true,false]:
		var near := nl if left else nr
		var far := fl if left else fr
		var wall := PackedVector2Array([near,far,far+Vector2(0,-28),near+Vector2((-5 if left else 5),-12)])
		draw_colored_polygon(wall, Color(accent.r,accent.g,accent.b,0.055))
		draw_polyline(PackedVector2Array([near,far,far+Vector2(0,-28)]), Color(accent.r,accent.g,accent.b,0.20), 1.3)

	# Field markings in perspective.
	for x in [0.25,0.50,0.75]:
		draw_line(_v25_project(Vector2(x,0),arena), _v25_project(Vector2(x,1),arena), Color(0.68,0.82,0.90,0.12 if x != 0.5 else 0.23), 1.2)
	var center := _v25_project(Vector2(0.5,0.5),arena)
	draw_arc(center, 25.0, 0, TAU, 44, Color(0.68,0.82,0.90,0.18), 1.2)

	# Pads.
	for p in [Vector2(0.12,0.18),Vector2(0.12,0.82),Vector2(0.36,0.34),Vector2(0.36,0.66),Vector2(0.64,0.34),Vector2(0.64,0.66),Vector2(0.88,0.18),Vector2(0.88,0.82)]:
		var s := _v25_scale(p)
		var q := _v25_project(p,arena)
		draw_circle(q,5.5*s,Color(0.97,0.68,0.26,0.08))
		draw_circle(q,2.0*s,Color(0.98,0.72,0.28,0.88))

	_v25_goal(Vector2(0,0.5), arena, true)
	_v25_goal(Vector2(1,0.5), arena, false)
	draw_polyline(PackedVector2Array([nl,nr,fr,fl,nl]), Color(accent.r,accent.g,accent.b,0.25), 1.5)

func _v25_goal(pos: Vector2, arena: Rect2, near_goal: bool) -> void:
	var c := _v25_project(pos, arena)
	var s := _v25_scale(pos)
	var w := 102.0*s
	var h := 35.0*s
	var front := Rect2(c.x-w*0.5, c.y-h*0.5 + (8.0 if near_goal else -6.0), w, h)
	var back := Rect2(front.position + Vector2(0, 11.0*s if near_goal else -8.0*s), front.size*Vector2(0.82,0.82))
	back.position.x = c.x - back.size.x*0.5
	draw_rect(back, Color(accent.r,accent.g,accent.b,0.025), true)
	draw_rect(front, Color(accent.r,accent.g,accent.b,0.045), true)
	draw_rect(front, Color(accent.r,accent.g,accent.b,0.35), false, 1.7)
	draw_rect(back, Color(accent.r,accent.g,accent.b,0.13), false, 1.0)
	for i in range(1,6):
		var xx := front.position.x + front.size.x*float(i)/6.0
		var bx := back.position.x + back.size.x*float(i)/6.0
		draw_line(Vector2(xx,front.position.y),Vector2(bx,back.position.y),Color(accent.r,accent.g,accent.b,0.09),1.0)

func _v25_context_players(arena: Rect2) -> void:
	# Opponent / teammate ghosts make drills readable, not random.
	if focus_family in ["defense","save"] or drill_id == "defensive_reads":
		_v25_ghost_car(Vector2(clampf(ball_position.x+0.12,0.0,0.92), clampf(ball_position.y+0.05,0.08,0.92)), arena, Color("FF6B7A"), "ANGREIFER")
	elif drill_id == "finishing_pack":
		_v25_ghost_car(Vector2(0.93,0.50), arena, Color("FF6B7A"), "KEEPER")
	elif drill_id == "rotation_review":
		_v25_ghost_car(Vector2(0.56,0.30), arena, Color("74DFF7"), "2ND")
		_v25_ghost_car(Vector2(0.72,0.70), arena, Color("74DFF7"), "3RD")

func _v25_ghost_car(p: Vector2, arena: Rect2, color: Color, label: String) -> void:
	var c := _v25_project(p,arena)
	var s := _v25_scale(p)*0.90
	draw_circle(c+Vector2(2,4*s),10*s,Color(0,0,0,0.22))
	var body := Rect2(c-Vector2(10,5)*s, Vector2(20,10)*s)
	draw_rect(body,Color(color.r,color.g,color.b,0.16),true)
	draw_rect(body,Color(color.r,color.g,color.b,0.54),false,1.3)
	draw_string(FONT_V25,c+Vector2(-24,-10*s),label,HORIZONTAL_ALIGNMENT_CENTER,48,7,Color(color.r,color.g,color.b,0.62))

func _v25_ball_path(arena: Rect2) -> void:
	var future_t := minf(0.999, drill_phase + 0.17)
	var from := _v25_project(ball_position,arena) - Vector2(0,ball_height*44.0*_v25_scale(ball_position))
	var fp := _ball_target_for_drill(future_t)
	var fh := _ball_height_for_drill(future_t)
	var to := _v25_project(fp,arena) - Vector2(0,fh*44.0*_v25_scale(fp))
	var ctrl := (from+to)*0.5-Vector2(0,34.0+maxf(ball_height,fh)*28.0)
	var prev := from
	for i in range(1,15):
		var t := float(i)/14.0
		var p := from.lerp(ctrl,t).lerp(ctrl.lerp(to,t),t)
		var alpha := 0.08 + t*0.20
		draw_line(prev,p,Color(0.93,0.97,1.0,alpha),1.6)
		prev = p
	var target := _v25_project(target_position,arena)
	draw_arc(target,16.0*_v25_scale(target_position),0,TAU,36,Color(accent.r,accent.g,accent.b,0.28),1.7)

func _v25_player_car(arena: Rect2) -> void:
	var c := _v25_project(car_position,arena)
	var next_p := car_position + (car_velocity.normalized()*0.05 if car_velocity.length()>0.02 else Vector2(0.04,0))
	var dir := (_v25_project(next_p,arena)-c).normalized()
	if dir.length()<0.1: dir = Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _v25_scale(car_position)*1.14
	var rear := c-dir*12.0*s
	draw_circle(c+Vector2(3,5*s),13*s,Color(0,0,0,0.34))
	for off in [Vector2(-6,-8),Vector2(6,-8),Vector2(-6,8),Vector2(6,8)]:
		var w := c+dir*off.x*s+side*off.y*s
		draw_circle(w,3.1*s,Color(0.01,0.015,0.02,1))
		draw_circle(w,1.25*s,Color(0.45,0.54,0.62,0.78))
	var body := PackedVector2Array([
		c+dir*17*s,
		c+dir*6*s+side*8.2*s,
		c-dir*7*s+side*7.0*s,
		rear+side*4.6*s,
		rear-side*4.6*s,
		c-dir*7*s-side*7.0*s,
		c+dir*6*s-side*8.2*s
	])
	draw_circle(c,23*s,Color(accent.r,accent.g,accent.b,0.065))
	draw_colored_polygon(body,Color(accent.r*0.34,accent.g*0.34,accent.b*0.34,1))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(accent.r,accent.g,accent.b,0.98),2.0)
	var roof := PackedVector2Array([
		c+dir*8*s+side*3.8*s,c+dir*9*s-side*3.8*s,
		c-dir*1*s-side*4.3*s,c-dir*1*s+side*4.3*s
	])
	draw_colored_polygon(roof,Color(0.64,0.84,0.94,0.34))
	draw_line(rear+side*3*s,rear-side*3*s,Color(1,0.28,0.32,0.66),1.6*s)
	if car_velocity.length()>0.04:
		draw_line(rear,rear-dir*14*s,Color(accent.r,accent.g,accent.b,0.60),4.0*s)
		draw_line(rear-dir*14*s,rear-dir*21*s,Color(0.92,0.97,1,0.22),1.6*s)

func _v25_ball(arena: Rect2) -> void:
	var ground := _v25_project(ball_position,arena)
	var s := _v25_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*44.0*s)
	draw_circle(ground+Vector2(3,5),8.0*s*(1.0-ball_height*0.16),Color(0,0,0,0.42))
	draw_circle(visual,18*s,Color(0.86,0.95,1,0.055))
	draw_circle(visual,9.2*s,Color("F4F7FB"))
	draw_arc(visual,5.7*s,-0.2,1.55,14,Color(0.28,0.35,0.42,0.72),1.0*s)
	draw_arc(visual,4.8*s,2.1,4.2,14,Color(0.28,0.35,0.42,0.58),1.0*s)
	draw_circle(visual+Vector2(-2.4,-2.6)*s,1.8*s,Color(1,1,1,0.80))

func _v25_hud() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category","TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(FONT_V25,Vector2(12,23),player_name_v25,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,9,Color(0.62,0.73,0.82,0.86))
	draw_string(FONT_V25,Vector2(12,44),mechanic,HORIZONTAL_ALIGNMENT_LEFT,size.x-24,18,Color(0.96,0.98,1,0.98))
	draw_string(FONT_V25,Vector2(12,61),"%s  ·  %s" % [category,step_label],HORIZONTAL_ALIGNMENT_LEFT,size.x-24,8,Color(accent.r,accent.g,accent.b,0.88))

	# Compact focus/fatigue HUD.
	var right := "FOKUS %d/%d   MÜDE %d" % [focus_remaining,focus_limit,fatigue]
	var w := FONT_V25.get_string_size(right,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
	draw_string(FONT_V25,Vector2(size.x-12-w,23),right,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(0.74,0.82,0.88,0.74))

	# Mechanic component bar lives inside gameplay now.
	if not components_v25.is_empty():
		var labels := [["SET",int(components_v25.get("setup",0))],["CTRL",int(components_v25.get("control",0))],["READ",int(components_v25.get("read",0))],["FIN",int(components_v25.get("finish",0))]]
		var x := 12.0
		var cell := (size.x-24.0)/4.0
		for item in labels:
			var value := int(item[1])
			draw_rect(Rect2(x,size.y-17,cell-5,3),Color(1,1,1,0.055),true)
			draw_rect(Rect2(x,size.y-17,(cell-5)*float(value)/100.0,3),Color(accent.r,accent.g,accent.b,0.55),true)
			draw_string(FONT_V25,Vector2(x,size.y-23),"%s %d" % [str(item[0]),value],HORIZONTAL_ALIGNMENT_LEFT,cell-5,7,Color(0.66,0.75,0.82,0.72))
			x += cell
