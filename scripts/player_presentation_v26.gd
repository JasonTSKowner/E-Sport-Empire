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
	var hero_scale: float = 1.08 if mode == "hero" else 1.0
	var glow: float = 0.055 + sin(pulse * 0.85) * 0.009

	# Media-day backlight and subtle scan architecture.
	draw_circle(Vector2(cx, h * 0.39), minf(w,h) * 0.50, Color(accent.r,accent.g,accent.b,glow))
	draw_circle(Vector2(cx, h * 0.39), minf(w,h) * 0.36, Color(accent.r,accent.g,accent.b,0.018))
	for i in range(5):
		var x: float = w * (0.12 + float(i) * 0.20)
		draw_line(Vector2(x,h*0.13),Vector2(x-18,h*0.88),Color(accent.r,accent.g,accent.b,0.026),1.0)
	for i in range(3):
		var y: float = h * (0.30 + float(i) * 0.20)
		draw_line(Vector2(w*0.08,y),Vector2(w*0.94,y),Color(0.82,0.91,0.97,0.025),1.0)

	# Shoulder / jersey silhouette – cropped like an esports media-day portrait.
	var shoulder_y: float = h * 0.48
	var torso_bottom: float = h * (0.96 if mode == "hero" else 0.86)
	var shoulder_half: float = w * 0.36 * hero_scale
	var waist_half: float = w * 0.23 * hero_scale
	var torso := PackedVector2Array([
		Vector2(cx-shoulder_half,shoulder_y+16),
		Vector2(cx-shoulder_half*0.78,shoulder_y-8),
		Vector2(cx-shoulder_half*0.42,shoulder_y-18),
		Vector2(cx+shoulder_half*0.42,shoulder_y-18),
		Vector2(cx+shoulder_half*0.78,shoulder_y-8),
		Vector2(cx+shoulder_half,shoulder_y+16),
		Vector2(cx+waist_half,torso_bottom),
		Vector2(cx-waist_half,torso_bottom),
	])
	draw_colored_polygon(torso, Color("07171E"))
	draw_polyline(PackedVector2Array([torso[0],torso[1],torso[2],torso[3],torso[4],torso[5],torso[6],torso[7],torso[0]]),Color(accent.r,accent.g,accent.b,0.72),1.8)

	# Jersey side panels and shoulder lighting.
	var left_panel := PackedVector2Array([
		Vector2(cx-shoulder_half,shoulder_y+16),
		Vector2(cx-shoulder_half*0.58,shoulder_y-10),
		Vector2(cx-waist_half*0.86,torso_bottom),
		Vector2(cx-waist_half,torso_bottom),
	])
	var right_panel := PackedVector2Array([
		Vector2(cx+shoulder_half,shoulder_y+16),
		Vector2(cx+shoulder_half*0.58,shoulder_y-10),
		Vector2(cx+waist_half*0.86,torso_bottom),
		Vector2(cx+waist_half,torso_bottom),
	])
	draw_colored_polygon(left_panel,Color(accent.r*0.12,accent.g*0.22,accent.b*0.25,0.90))
	draw_colored_polygon(right_panel,Color(accent.r*0.10,accent.g*0.19,accent.b*0.22,0.90))
	draw_line(Vector2(cx-shoulder_half*0.73,shoulder_y+1),Vector2(cx-shoulder_half*0.30,shoulder_y+15),Color(accent.r,accent.g,accent.b,0.58),2.2)
	draw_line(Vector2(cx+shoulder_half*0.73,shoulder_y+1),Vector2(cx+shoulder_half*0.30,shoulder_y+15),Color(accent.r,accent.g,accent.b,0.42),2.0)

	# Neck and stylized face with one-sided light instead of a flat avatar face.
	var neck_y: float = h * 0.39
	draw_rect(Rect2(cx-9,neck_y,18,h*0.10),Color("705E55"),true)
	var head_center := Vector2(cx,h*0.285)
	var head_radius: float = minf(w,h) * 0.145 * hero_scale
	draw_circle(head_center,head_radius,Color("8B7467"))
	var face_shadow := PackedVector2Array([
		Vector2(cx,head_center.y-head_radius),
		Vector2(cx+head_radius,head_center.y-head_radius*0.38),
		Vector2(cx+head_radius*0.82,head_center.y+head_radius*0.62),
		Vector2(cx+head_radius*0.18,head_center.y+head_radius),
		Vector2(cx,head_center.y+head_radius*0.90),
	])
	draw_colored_polygon(face_shadow,Color("5B4C46"))
	draw_arc(head_center,head_radius,PI*0.62,PI*1.48,18,Color(0.92,0.78,0.70,0.20),1.2)

	# Hair silhouette varies slightly per name.
	var hair_peak: float = float(seed % 5) * 1.2
	var hair := PackedVector2Array([
		Vector2(cx-head_radius*0.96,head_center.y-head_radius*0.30),
		Vector2(cx-head_radius*0.72,head_center.y-head_radius*0.93-hair_peak),
		Vector2(cx-head_radius*0.18,head_center.y-head_radius*1.10),
		Vector2(cx+head_radius*0.32,head_center.y-head_radius*1.02),
		Vector2(cx+head_radius*0.83,head_center.y-head_radius*0.63),
		Vector2(cx+head_radius*0.94,head_center.y-head_radius*0.18),
		Vector2(cx+head_radius*0.38,head_center.y-head_radius*0.42),
		Vector2(cx-head_radius*0.20,head_center.y-head_radius*0.38),
	])
	draw_colored_polygon(hair,Color("0A0F14"))

	# Premium headset + mic.
	draw_arc(head_center,head_radius*1.17,PI*1.03,PI*1.97,28,Color("18232C"),5.2)
	draw_rect(Rect2(cx-head_radius*1.20,head_center.y-head_radius*0.05,7,head_radius*0.72),Color("111B23"),true)
	draw_rect(Rect2(cx+head_radius*1.20-7,head_center.y-head_radius*0.05,7,head_radius*0.72),Color("111B23"),true)
	draw_line(Vector2(cx+head_radius*1.13,head_center.y+head_radius*0.32),Vector2(cx+head_radius*1.44,head_center.y+head_radius*0.55),Color(accent.r,accent.g,accent.b,0.72),2.2)
	draw_circle(Vector2(cx+head_radius*1.47,head_center.y+head_radius*0.57),2.5,Color(accent.r,accent.g,accent.b,0.82))

	# Folded-arm silhouette gives the profile a less mannequin-like stance.
	var arm_y: float = h * 0.67
	var left_arm := PackedVector2Array([
		Vector2(cx-shoulder_half*0.84,shoulder_y+20),
		Vector2(cx-shoulder_half*0.98,arm_y),
		Vector2(cx-10,arm_y+28),
		Vector2(cx+3,arm_y+15),
		Vector2(cx-shoulder_half*0.58,arm_y-5),
	])
	var right_arm := PackedVector2Array([
		Vector2(cx+shoulder_half*0.84,shoulder_y+20),
		Vector2(cx+shoulder_half*0.98,arm_y),
		Vector2(cx+10,arm_y+28),
		Vector2(cx-3,arm_y+15),
		Vector2(cx+shoulder_half*0.58,arm_y-5),
	])
	draw_colored_polygon(left_arm,Color("0B2028"))
	draw_colored_polygon(right_arm,Color("091C24"))
	draw_line(Vector2(cx-shoulder_half*0.88,arm_y),Vector2(cx-4,arm_y+23),Color(accent.r,accent.g,accent.b,0.18),1.3)
	draw_line(Vector2(cx+shoulder_half*0.88,arm_y),Vector2(cx+4,arm_y+23),Color(accent.r,accent.g,accent.b,0.14),1.3)

	# Jersey crest / sponsor lockup.
	var crest_y: float = h * 0.55
	draw_rect(Rect2(cx-w*0.13,crest_y,w*0.26,2.4),Color(accent.r,accent.g,accent.b,0.62),true)
	draw_string(FONT,Vector2(cx-w*0.18,h*0.63),"TSK",HORIZONTAL_ALIGNMENT_CENTER,w*0.36,16,Color(0.92,0.97,1.0,0.92))
	var number: int = 10 + int(seed % 89)
	draw_string(FONT,Vector2(cx-w*0.13,h*0.72),"%02d"%number,HORIZONTAL_ALIGNMENT_CENTER,w*0.26,10,Color(accent.r,accent.g,accent.b,0.62))

	# Lower media-card footer on profile/scout cards.
	if mode != "hero":
		var footer_y: float = h - 38.0
		draw_rect(Rect2(7,footer_y,w-14,31),Color(0.008,0.016,0.024,0.90),true)
		draw_line(Vector2(10,footer_y),Vector2(w-10,footer_y),Color(accent.r,accent.g,accent.b,0.16),1.0)
		draw_string(FONT,Vector2(14,footer_y+20),player_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,w*0.53,9,Color(0.92,0.96,1.0,0.94))
		var info: String = "%d OVR  /  POT %d" % [overall,potential]
		draw_string(FONT,Vector2(w*0.46,footer_y+20),info,HORIZONTAL_ALIGNMENT_RIGHT,w*0.45,8,Color(accent.r,accent.g,accent.b,0.76))
