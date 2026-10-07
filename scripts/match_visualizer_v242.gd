class_name MatchVisualizerV242
extends "res://scripts/match_visualizer_v241.gd"

const V242_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 456.0)

func _draw_broadcast_backdrop(arena: Rect2) -> void:
	super._draw_broadcast_backdrop(arena)
	# Dense crowd tiers so the play space feels like an arena instead of a diagram.
	var tier_top := arena.position.y + 10.0
	for row in range(3):
		var y := tier_top + float(row) * 10.0
		var count := 22 - row * 2
		for i in range(count):
			var x := 10.0 + float(i) * (size.x - 20.0) / float(maxi(1, count - 1))
			var flicker := 0.05 + 0.035 * sin(time_alive * (0.75 + row * 0.1) + float(i) * 1.73)
			var crowd_color := OUR_COLOR if (i + row) % 7 == 0 else THEIR_COLOR if (i + row) % 11 == 0 else Color(0.70,0.78,0.86,1.0)
			draw_circle(Vector2(x, y), 1.1 if row == 0 else 0.9, Color(crowd_color.r,crowd_color.g,crowd_color.b,0.08 + flicker))

	# Broadcast light beams.
	for i in range(4):
		var start_x := size.x * (0.16 + float(i) * 0.22)
		var beam := PackedVector2Array([
			Vector2(start_x - 5.0, arena.position.y - 2.0),
			Vector2(start_x + 5.0, arena.position.y - 2.0),
			Vector2(start_x + 46.0, arena.end.y),
			Vector2(start_x - 46.0, arena.end.y),
		])
		draw_colored_polygon(beam, Color(0.70,0.86,0.96,0.010))

func _draw_perspective_pitch(arena: Rect2) -> void:
	super._draw_perspective_pitch(arena)
	var near_l := _project_field(Vector2(0,0), arena)
	var near_r := _project_field(Vector2(0,1), arena)
	var far_l := _project_field(Vector2(1,0), arena)
	var far_r := _project_field(Vector2(1,1), arena)

	# Glass sidewalls / ad boards.
	var left_wall := PackedVector2Array([
		near_l, far_l,
		far_l + Vector2(0,-18), near_l + Vector2(-2,-8)
	])
	var right_wall := PackedVector2Array([
		near_r, far_r,
		far_r + Vector2(0,-18), near_r + Vector2(2,-8)
	])
	draw_colored_polygon(left_wall, Color(0.16,0.34,0.42,0.10))
	draw_colored_polygon(right_wall, Color(0.16,0.34,0.42,0.10))
	draw_polyline(PackedVector2Array([near_l,far_l,far_l+Vector2(0,-18)]), Color(0.56,0.78,0.88,0.16), 1.0)
	draw_polyline(PackedVector2Array([near_r,far_r,far_r+Vector2(0,-18)]), Color(0.56,0.78,0.88,0.16), 1.0)

	# Arena boards with subtle animated accent segments.
	for side in [0,1]:
		for i in range(5):
			var a := float(i) / 5.0
			var b := float(i + 1) / 5.0
			var p0 := near_l.lerp(far_l, a) if side == 0 else near_r.lerp(far_r, a)
			var p1 := near_l.lerp(far_l, b) if side == 0 else near_r.lerp(far_r, b)
			var c := OUR_COLOR if (i + side) % 2 == 0 else Color(0.66,0.74,0.82,1.0)
			draw_line(p0 + Vector2(0,-4), p1 + Vector2(0,-8), Color(c.r,c.g,c.b,0.11), 3.0)

	# Near-side broadcast branding strip.
	var brand_y := near_l.y + 8.0
	draw_line(Vector2(near_l.x + 18.0, brand_y), Vector2(near_r.x - 18.0, brand_y), Color(0.70,0.86,0.94,0.10), 2.0)
	draw_string(V242_FONT, Vector2(near_l.x + 26.0, brand_y + 12.0), "E-SPORT EMPIRE  //  LIVE", HORIZONTAL_ALIGNMENT_LEFT, near_r.x-near_l.x-52.0, 7, Color(0.68,0.78,0.84,0.22))

func _draw_perspective_goal(field_pos: Vector2, color: Color, arena: Rect2, near_goal: bool) -> void:
	# Draw a deeper goal tunnel instead of a flat rectangle.
	var center := _project_field(field_pos, arena)
	var scale := _depth_scale(field_pos)
	var w := 94.0 * scale
	var h := 32.0 * scale
	var y := center.y + (8.0 if near_goal else -7.0)
	var front := Rect2(center.x - w * 0.5, y - h * 0.5, w, h)
	var depth_offset := Vector2(0, 9.0 * scale if near_goal else -7.0 * scale)
	var back := Rect2(front.position + depth_offset, front.size * Vector2(0.84,0.86))
	back.position.x = center.x - back.size.x * 0.5
	draw_rect(back, Color(color.r,color.g,color.b,0.035), true)
	draw_rect(front, Color(color.r,color.g,color.b,0.045), true)
	draw_rect(front, Color(color.r,color.g,color.b,0.38), false, 1.7)
	draw_rect(back, Color(color.r,color.g,color.b,0.14), false, 1.0)
	for i in range(1,6):
		var xx := front.position.x + front.size.x * float(i) / 6.0
		var bx := back.position.x + back.size.x * float(i) / 6.0
		draw_line(Vector2(xx,front.position.y),Vector2(bx,back.position.y),Color(color.r,color.g,color.b,0.10),1.0)
	for i in range(1,4):
		var yy := front.position.y + front.size.y * float(i) / 4.0
		var by := back.position.y + back.size.y * float(i) / 4.0
		draw_line(Vector2(front.position.x,yy),Vector2(back.position.x,by),Color(color.r,color.g,color.b,0.08),1.0)

func _draw_projected_car(p: Vector2, velocity: Vector2, color: Color, role: String, active: bool, support: bool, arena: Rect2) -> void:
	var center := _project_field(p, arena)
	var next := _project_field(p + velocity.normalized()*0.04 if velocity.length()>0.02 else p+Vector2(0.04,0), arena)
	var dir := (next-center).normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	var side := Vector2(-dir.y,dir.x)
	var s := _depth_scale(p) * (1.10 if active else 1.0)

	# Ground shadow before body.
	var shadow_center := center + Vector2(2.0,4.0*s)
	draw_circle(shadow_center, 11.0*s, Color(0,0,0,0.28))

	# Wheels give the vehicle a readable car silhouette.
	for wheel_offset in [Vector2(-5.5,-7.2),Vector2(6.0,-7.2),Vector2(-5.5,7.2),Vector2(6.0,7.2)]:
		var wp: Vector2 = center + dir * float(wheel_offset.x) * s + side * float(wheel_offset.y) * s
		draw_circle(wp, 2.7*s, Color(0.015,0.020,0.026,0.98))
		draw_circle(wp, 1.2*s, Color(0.34,0.42,0.49,0.74))

	var nose := center+dir*15.5*s
	var rear := center-dir*11.0*s
	var body := PackedVector2Array([
		nose,
		center+dir*5.0*s+side*7.6*s,
		center-dir*8.0*s+side*6.2*s,
		rear+side*4.5*s,
		rear-side*4.5*s,
		center-dir*8.0*s-side*6.2*s,
		center+dir*5.0*s-side*7.6*s,
	])
	if active:
		draw_circle(center,20.0*s,Color(color.r,color.g,color.b,0.075))
	if support:
		draw_arc(center,17.0*s,0,TAU,28,Color(color.r,color.g,color.b,0.24),1.5)
	draw_colored_polygon(body,Color(color.r*0.40,color.g*0.40,color.b*0.40,1.0))
	draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[6],body[0]]),Color(color.r,color.g,color.b,0.98),1.8)

	# Roof / glass and hood stripe.
	var roof := PackedVector2Array([
		center+dir*7.0*s+side*3.4*s,
		center+dir*8.0*s-side*3.4*s,
		center-dir*1.0*s-side*4.0*s,
		center-dir*1.0*s+side*4.0*s,
	])
	draw_colored_polygon(roof,Color(0.62,0.82,0.92,0.34))
	draw_line(center+dir*12.5*s,center+dir*5.0*s,Color(0.92,0.97,1.0,0.34),1.4*s)

	# Headlights and taillight.
	draw_circle(center+dir*13.0*s+side*3.8*s,1.1*s,Color(0.88,0.97,1.0,0.80))
	draw_circle(center+dir*13.0*s-side*3.8*s,1.1*s,Color(0.88,0.97,1.0,0.80))
	draw_line(rear+side*3.0*s,rear-side*3.0*s,Color(1.0,0.30,0.34,0.55),1.4*s)

	if velocity.length()>0.08:
		var boost_len := 11.0*s if active else 8.0*s
		draw_line(rear,rear-dir*boost_len,Color(color.r,color.g,color.b,0.50),3.4*s)
		draw_line(rear-dir*boost_len,rear-dir*(boost_len+5.0*s),Color(0.92,0.96,1.0,0.18),1.4*s)

	if not role.is_empty():
		draw_string(V242_FONT,center+Vector2(-18,-19*s),role,HORIZONTAL_ALIGNMENT_CENTER,36,8,Color(0.90,0.96,1.0,0.90 if active else 0.58))

func _draw_projected_ball(arena: Rect2) -> void:
	var ground := _project_field(ball_position,arena)
	var s := _depth_scale(ball_position)
	var visual := ground-Vector2(0,ball_height*38.0*s)
	draw_circle(ground+Vector2(3,5),7.4*s*(1.0-ball_height*0.20),Color(0,0,0,0.38))
	draw_circle(visual,15.8*s,Color(0.86,0.95,1.0,0.055))
	draw_circle(visual,8.4*s,Color("F4F7FB"))
	# Dark panel seams make the ball read as a real object at mobile size.
	draw_arc(visual,5.0*s,-0.2,1.5,12,Color(0.30,0.37,0.44,0.72),1.0*s)
	draw_arc(visual,4.2*s,2.2,4.1,12,Color(0.30,0.37,0.44,0.60),1.0*s)
	draw_circle(visual+Vector2(-2.1,-2.4)*s,1.7*s,Color(1,1,1,0.72))
