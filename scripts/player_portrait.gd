class_name PlayerPortrait
extends Control

var player_name := "PLAYER"
var accent := Color("7FE7FF")
var seed := 0


func configure(name_value: String, color: Color) -> PlayerPortrait:
	player_name = name_value
	accent = color
	seed = abs(player_name.hash())
	queue_redraw()
	return self


func _ready() -> void:
	custom_minimum_size = Vector2(68, 76)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("0A0F15"), true)
	draw_rect(r, Color(0.72,0.78,0.86,0.07), false, 1.0)

	# editorial stripe
	draw_rect(Rect2(0, 0, 3, r.size.y), Color(accent.r,accent.g,accent.b,0.88), true)
	var stripe_x := r.size.x * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(stripe_x,0), Vector2(r.size.x,0), Vector2(r.size.x,r.size.y*0.42), Vector2(stripe_x-14,0)
	]), Color(accent.r,accent.g,accent.b,0.07))

	var skin := Color("B8A18D").lerp(Color("735A4B"), float(seed % 100) / 130.0)
	var hair := Color("15191E").lerp(Color("4A352A"), float((seed / 7) % 100) / 160.0)
	var jersey := Color("151D27").lerp(Color(accent.r*0.42, accent.g*0.42, accent.b*0.42, 1.0), 0.35)

	var cx := r.size.x * 0.51
	var head_y := r.size.y * 0.31
	var head_r := r.size.x * 0.16

	# shoulders / jersey silhouette
	var shoulder_y := r.size.y * 0.62
	var body := PackedVector2Array([
		Vector2(r.size.x*0.14, r.size.y),
		Vector2(r.size.x*0.20, shoulder_y),
		Vector2(cx-11, shoulder_y-7),
		Vector2(cx+11, shoulder_y-7),
		Vector2(r.size.x*0.82, shoulder_y),
		Vector2(r.size.x*0.90, r.size.y)
	])
	draw_colored_polygon(body, jersey)
	draw_line(Vector2(r.size.x*0.20, shoulder_y), Vector2(r.size.x*0.82, shoulder_y), Color(accent.r,accent.g,accent.b,0.24), 1.0)

	# neck
	draw_rect(Rect2(cx-6, head_y+head_r*0.65, 12, 13), skin.darkened(0.06), true)

	# head
	draw_circle(Vector2(cx, head_y), head_r, skin)

	# hair variation
	var hair_drop := 0.22 + float(seed % 6) * 0.035
	var hair_poly := PackedVector2Array([
		Vector2(cx-head_r, head_y-1),
		Vector2(cx-head_r*0.72, head_y-head_r*0.90),
		Vector2(cx+head_r*0.18, head_y-head_r*1.07),
		Vector2(cx+head_r, head_y-head_r*0.42),
		Vector2(cx+head_r*0.84, head_y-head_r*0.05),
		Vector2(cx-head_r*0.82, head_y+head_r*hair_drop)
	])
	draw_colored_polygon(hair_poly, hair)

	# headset
	draw_arc(Vector2(cx, head_y), head_r*1.18, PI+0.30, TAU-0.30, 26, Color("3C4858"), 2.0)
	draw_rect(Rect2(cx-head_r*1.20, head_y-1, 3, 9), Color("536274"), true)
	draw_rect(Rect2(cx+head_r*1.03, head_y-1, 3, 9), Color("536274"), true)

	# face indications
	draw_line(Vector2(cx-head_r*0.42, head_y+1), Vector2(cx-head_r*0.16, head_y+1), Color(0.12,0.11,0.10,0.50), 1.0)
	draw_line(Vector2(cx+head_r*0.16, head_y+1), Vector2(cx+head_r*0.42, head_y+1), Color(0.12,0.11,0.10,0.50), 1.0)
	draw_line(Vector2(cx-head_r*0.18, head_y+head_r*0.45), Vector2(cx+head_r*0.20, head_y+head_r*0.45), Color(0.18,0.13,0.12,0.35), 1.0)

	# tiny jersey identity
	var font := ThemeDB.fallback_font
	var initials := player_name.left(2).to_upper()
	draw_string(font, Vector2(7, r.size.y-7), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.86,0.90,0.95,0.70))
