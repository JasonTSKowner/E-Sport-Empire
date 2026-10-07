extends "res://scripts/training_perspective_surface_v241.gd"

const V242_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 418.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 418.0)

func _v241_draw_backdrop(arena: Rect2) -> void:
	super._v241_draw_backdrop(arena)
	# Practice arena audience / equipment lights.
	for row in range(3):
		var y := arena.position.y + 11.0 + float(row) * 9.0
		var count := 19 - row
		for i in range(count):
			var x := 12.0 + float(i) * (size.x - 24.0) / float(maxi(1, count - 1))
			var a := 0.08 + 0.03 * sin(animation_time * 0.9 + float(i) * 1.4 + row)
			var c := accent if (i + row) % 8 == 0 else Color(0.72,0.80,0.88,1.0)
			draw_circle(Vector2(x,y),1.0,Color(c.r,c.g,c.b,a))

	# Training floodlight beams.
	for i in range(3):
		var sx := size.x * (0.22 + float(i) * 0.28)
		var beam := PackedVector2Array([
			Vector2(sx-5,arena.position.y),Vector2(sx+5,arena.position.y),
			Vector2(sx+43,arena.end.y),Vector2(sx-43,arena.end.y)
		])
		draw_colored_polygon(beam,Color(accent.r,accent.g,accent.b,0.009))

func _v241_draw_pitch(arena: Rect2) -> void:
	super._v241_draw_pitch(arena)
	var near_l := _v241_project_field(Vector2(0,0),arena)
	var near_r := _v241_project_field(Vector2(0,1),arena)
	var far_l := _v241_project_field(Vector2(1,0),arena)
	var far_r := _v241_project_field(Vector2(1,1),arena)

	# Side glass and practice boards.
	var left_wall := PackedVector2Array([near_l,far_l,far_l+Vector2(0,-17),near_l+Vector2(-2,-8)])
	var right_wall := PackedVector2Array([near_r,far_r,far_r+Vector2(0,-17),near_r+Vector2(2,-8)])
	draw_colored_polygon(left_wall,Color(accent.r,accent.g,accent.b,0.055))
	draw_colored_polygon(right_wall,Color(accent.r,accent.g,accent.b,0.055))
	draw_polyline(PackedVector2Array([near_l,far_l,far_l+Vector2(0,-17)]),Color(accent.r,accent.g,accent.b,0.15),1.0)
	draw_polyline(PackedVector2Array([near_r,far_r,far_r+Vector2(0,-17)]),Color(accent.r,accent.g,accent.b,0.15),1.0)
	for i in range(5):
		var a := float(i)/5.0
		var b := float(i+1)/5.0
		draw_line(near_l.lerp(far_l,a)+Vector2(0,-4),near_l.lerp(far_l,b)+Vector2(0,-8),Color(accent.r,accent.g,accent.b,0.12),3.0)
		draw_line(near_r.lerp(far_r,a)+Vector2(0,-4),near_r.lerp(far_r,b)+Vector2(0,-8),Color(accent.r,accent.g,accent.b,0.12),3.0)

	# Practice branding strip.
	var brand_y := near_l.y + 8.0
	draw_line(Vector2(near_l.x+18,brand_y),Vector2(near_r.x-18,brand_y),Color(accent.r,accent.g,accent.b,0.12),2.0)
	draw_string(V242_FONT,Vector2(near_l.x+24,brand_y+12),"PERFORMANCE LAB  //  LIVE DRILL",HORIZONTAL_ALIGNMENT_LEFT,near_r.x-near_l.x-48,7,Color(0.68,0.80,0.88,0.22))

func _v241_draw_goal(pos: Vector2, arena: Rect2, near_goal: bool) -> void:
	var center := _v241_project_field(pos,arena)
	var s := _v241_depth_scale(pos)
	var w := 92.0*s
	var h := 31.0*s
	var y := center.y + (8.0 if near_goal else -7.0)
	var front := Rect2(center.x-w*0.5,y-h*0.5,w,h)
	var offset := Vector2(0,8.0*s if near_goal else -6.0*s)
	var back := Rect2(front.position+offset,front.size*Vector2(0.84,0.86))
	back.position.x = center.x-back.size.x*0.5
	draw_rect(back,Color(accent.r,accent.g,accent.b,0.03),true)
	draw_rect(front,Color(accent.r,accent.g,accent.b,0.04),true)
	draw_rect(front,Color(accent.r,accent.g,accent.b,0.31),false,1.6)
	draw_rect(back,Color(accent.r,accent.g,accent.b,0.11),false,1.0)
	for i in range(1,6):
		var xx := front.position.x+front.size.x*float(i)/6.0
		var bx := back.position.x+back.size.x*float(i)/6.0
		draw_line(Vector2(xx,front.position.y),Vector2(bx,back.position.y),Color(accent.r,accent.g,accent.b,0.08),1.0)

func _v241_draw_car(arena: Rect2) -> void:
	var center := _v241_project_field(car_position,arena)
	var next_pos := car_position + (car_velocity.normalized()*0.04 if car_velocity.length()>0.02 else Vector2(0.04,0))
	var next := _v241_project_field(next_pos,arena)
	var dir := (next-center).normalized()
	if dir.length()<0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _v241_depth_scale(car_position)*1.10
	var rear := center-dir*11.0*s

	# Shadow and four wheels.
	draw_circle(center+Vector2(2,4*s),11.5*s,Color(0,0,0,0.28))
	for wheel_offset in [Vector2(-5.5,-7.3),Vector2(6.0,-7.3),Vector2(-5.5,7.3),Vector2(6.0,7.3)]:
		var wp: Vector2 = center + dir*float(wheel_offset.x)*s + side*float(wheel_offset.y)*s
		draw_circle(wp,2.8*s,Color(0.015,0.02,0.026,0.98))
		draw_circle(wp,1.2*s,Color(0.34,0.42,0.49,0.75))

	var nose := center+dir*15.5*s
	var body := PackedVector2Array([
		nose,
		center+dir*5*s+side*7.7*s,
		center-dir*8*s+side*6.2*s,
		rear+side*4.5*s,
		rear-side*4.5*s,
		center-dir*8*s-side*6.2*s,
		center+dir*5*s-side*7.7*s,
	])
	draw_circle(center,20.0*s,Color(accent.r,accent.g,accent.b,0.07))
	draw_colored_polygon(body,Color(accent.r*0.39,accent.g*0.39,accent.b*0.39,1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(accent.r,accent.g,accent.b,0.98),1.8)
	var roof := PackedVector2Array([
		center+dir*7*s+side*3.5*s,
		center+dir*8*s-side*3.5*s,
		center-dir*1*s-side*4*s,
		center-dir*1*s+side*4*s,
	])
	draw_colored_polygon(roof,Color(0.62,0.82,0.92,0.34))
	draw_line(center+dir*12.5*s,center+dir*5*s,Color(0.92,0.97,1.0,0.34),1.4*s)
	draw_circle(center+dir*13*s+side*3.8*s,1.1*s,Color(0.88,0.97,1.0,0.80))
	draw_circle(center+dir*13*s-side*3.8*s,1.1*s,Color(0.88,0.97,1.0,0.80))
	draw_line(rear+side*3*s,rear-side*3*s,Color(1.0,0.30,0.34,0.55),1.4*s)
	if car_velocity.length()>0.04:
		draw_line(rear,rear-dir*(11.0*s),Color(accent.r,accent.g,accent.b,0.50),3.4*s)

func _v241_draw_ball(arena: Rect2) -> void:
	var ground := _v241_project_field(ball_position,arena)
	var s := _v241_depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*36.0*s)
	draw_circle(ground+Vector2(3,5),7.4*s*(1.0-ball_height*0.18),Color(0,0,0,0.38))
	draw_circle(visual,15.8*s,Color(0.86,0.95,1.0,0.055))
	draw_circle(visual,8.4*s,Color("F4F7FB"))
	draw_arc(visual,5.0*s,-0.2,1.5,12,Color(0.30,0.37,0.44,0.72),1.0*s)
	draw_arc(visual,4.2*s,2.2,4.1,12,Color(0.30,0.37,0.44,0.60),1.0*s)
	draw_circle(visual+Vector2(-2.1,-2.4)*s,1.7*s,Color(1,1,1,0.72))
