class_name PlayerPresentationV26
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var player_name := "KESHI"
var accent := Color("74DFF7")
var overall := 60
var potential := 90
var mode := "profile"
var pulse := 0.0

func configure(name: String, color: Color, ovr: int = 60, pot: int = 90, presentation_mode: String = "profile") -> PlayerPresentationV26:
	player_name = name
	accent = color
	overall = ovr
	potential = pot
	mode = presentation_mode
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()
	return self

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var seed: int = absi(player_name.hash())
	var cx: float = w * 0.52
	var ground_y: float = h * 0.91
	var glow: float = 0.045 + sin(pulse * 0.9) * 0.008
	draw_circle(Vector2(cx, h * 0.42), minf(w,h) * 0.48, Color(accent.r,accent.g,accent.b,glow))

	var podium := PackedVector2Array([
		Vector2(w*0.18,ground_y), Vector2(w*0.84,ground_y),
		Vector2(w*0.74,h*0.99), Vector2(w*0.28,h*0.99)
	])
	draw_colored_polygon(podium, Color(0.025,0.045,0.058,0.92))
	draw_polyline(PackedVector2Array([podium[0],podium[1],podium[2],podium[3],podium[0]]), Color(accent.r,accent.g,accent.b,0.16), 1.2)

	var hip_y: float = h * 0.69
	var leg_left := PackedVector2Array([
		Vector2(cx-21,hip_y), Vector2(cx-5,hip_y), Vector2(cx-9,ground_y), Vector2(cx-27,ground_y)
	])
	var leg_right := PackedVector2Array([
		Vector2(cx+5,hip_y), Vector2(cx+22,hip_y), Vector2(cx+28,ground_y), Vector2(cx+9,ground_y)
	])
	draw_colored_polygon(leg_left, Color("101820"))
	draw_colored_polygon(leg_right, Color("101820"))

	var shoulder_y: float = h * 0.38
	var torso := PackedVector2Array([
		Vector2(cx-36, shoulder_y+8), Vector2(cx-22, shoulder_y-4),
		Vector2(cx+22, shoulder_y-4), Vector2(cx+38, shoulder_y+8),
		Vector2(cx+28, hip_y), Vector2(cx-28, hip_y)
	])
	draw_colored_polygon(torso, Color(0.035,0.13,0.16,0.98))
	draw_polyline(PackedVector2Array([torso[0],torso[1],torso[2],torso[3],torso[4],torso[5],torso[0]]), Color(accent.r,accent.g,accent.b,0.72), 1.7)

	var left_arm := PackedVector2Array([
		Vector2(cx-36,shoulder_y+9), Vector2(cx-48,shoulder_y+25),
		Vector2(cx-44,h*0.61), Vector2(cx-30,h*0.59), Vector2(cx-26,shoulder_y+22)
	])
	var right_arm := PackedVector2Array([
		Vector2(cx+36,shoulder_y+9), Vector2(cx+49,shoulder_y+24),
		Vector2(cx+44,h*0.61), Vector2(cx+30,h*0.59), Vector2(cx+26,shoulder_y+22)
	])
	draw_colored_polygon(left_arm, Color(0.035,0.11,0.14,1.0))
	draw_colored_polygon(right_arm, Color(0.035,0.11,0.14,1.0))

	draw_rect(Rect2(cx-7, h*0.30, 14, 16), Color("8C7567"), true)
	draw_circle(Vector2(cx,h*0.245), 23.0, Color("9A8171"))
	var hair_shift: float = float(seed % 6)
	var hair := PackedVector2Array([
		Vector2(cx-22,h*0.235), Vector2(cx-17,h*0.185-hair_shift*0.2),
		Vector2(cx-4,h*0.166), Vector2(cx+12,h*0.176),
		Vector2(cx+22,h*0.214), Vector2(cx+19,h*0.242),
		Vector2(cx-20,h*0.242)
	])
	draw_colored_polygon(hair, Color("12171D"))

	draw_arc(Vector2(cx,h*0.235), 26.0, PI*1.02, PI*1.98, 24, Color(0.12,0.16,0.20,1.0), 4.0)
	draw_rect(Rect2(cx-28,h*0.235,6,19), Color(0.06,0.10,0.12,1.0), true)
	draw_rect(Rect2(cx+22,h*0.235,6,19), Color(0.06,0.10,0.12,1.0), true)
	draw_line(Vector2(cx+26,h*0.252), Vector2(cx+35,h*0.274), Color(accent.r,accent.g,accent.b,0.58), 2.0)

	draw_line(Vector2(cx-18,h*0.43), Vector2(cx+18,h*0.43), Color(accent.r,accent.g,accent.b,0.48), 2.4)
	draw_string(FONT, Vector2(cx-25,h*0.52), "TSK", HORIZONTAL_ALIGNMENT_CENTER, 50, 14, Color(0.90,0.96,1.0,0.86))
	var number: int = 10 + int(seed % 89)
	draw_string(FONT, Vector2(cx-21,h*0.60), "%02d" % number, HORIZONTAL_ALIGNMENT_CENTER, 42, 12, Color(accent.r,accent.g,accent.b,0.72))

	if mode != "hero":
		draw_rect(Rect2(8,h-37,w-16,29), Color(0.015,0.025,0.034,0.82), true)
		draw_string(FONT, Vector2(15,h-20), player_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w*0.55, 9, Color(0.90,0.94,0.98,0.92))
		var info: String = "%d OVR  /  POT %d" % [overall,potential]
		draw_string(FONT, Vector2(w*0.48,h-20), info, HORIZONTAL_ALIGNMENT_RIGHT, w*0.44, 8, Color(accent.r,accent.g,accent.b,0.72))
