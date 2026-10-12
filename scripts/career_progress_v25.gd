class_name CareerProgressV25
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var accent := Color("74DFF7")
var career_level: int = 1
var setup_rating: int = 0
var ping: int = 46
var mechanic_label: String = "BASICS"
var mastery: int = 0
var next_label: String = "FIRST UNLOCK"
var next_progress: int = 0
var pulse: float = 0.0

func configure(color: Color, level: int, setup_value: int, ping_value: int, mech: String, mastery_value: int, upcoming: String, upcoming_progress: int) -> CareerProgressV25:
	accent = color
	career_level = clampi(level, 1, 10)
	setup_rating = clampi(setup_value, 0, 100)
	ping = maxi(0, ping_value)
	mechanic_label = mech.to_upper()
	mastery = clampi(mastery_value, 0, 100)
	next_label = upcoming.to_upper()
	next_progress = clampi(upcoming_progress, 0, 100)
	custom_minimum_size = Vector2(0, 196)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	for i in range(12):
		var t: float = float(i) / 11.0
		var c: Color = Color("101720").lerp(Color("05080C"), t)
		draw_rect(Rect2(0, r.size.y * t, r.size.x, r.size.y / 11.0 + 2.0), c, true)
	draw_line(Vector2(0, 1), Vector2(r.size.x, 1), Color(accent.r,accent.g,accent.b,0.22), 1.0)
	draw_circle(Vector2(r.size.x * 0.82, 28), r.size.x * 0.28, Color(accent.r,accent.g,accent.b,0.018 + sin(pulse) * 0.003))

	draw_string(FONT, Vector2(14, 22), "ROAD TO PRO", HORIZONTAL_ALIGNMENT_LEFT, 110, 8, Color(accent.r,accent.g,accent.b,0.88))
	draw_string(FONT, Vector2(r.size.x - 104, 22), "CAREER LV %d" % career_level, HORIZONTAL_ALIGNMENT_RIGHT, 90, 8, Color(0.78,0.84,0.90,0.82))

	var labels: Array[String] = ["BEDROOM", "RANKED", "CONTENDER", "PRO", "EMPIRE"]
	var active_index: int = clampi(int(floor(float(career_level - 1) / 2.0)), 0, labels.size() - 1)
	var line_y: float = 60.0
	var start_x: float = 28.0
	var end_x: float = r.size.x - 28.0
	draw_line(Vector2(start_x,line_y), Vector2(end_x,line_y), Color(1,1,1,0.08), 3.0)
	var progress_x: float = lerpf(start_x, end_x, float(career_level - 1) / 9.0)
	draw_line(Vector2(start_x,line_y), Vector2(progress_x,line_y), Color(accent.r,accent.g,accent.b,0.66), 3.0)
	for i in range(labels.size()):
		var x: float = lerpf(start_x,end_x,float(i)/float(labels.size()-1))
		var done: bool = i <= active_index
		var radius: float = 6.0 if i != active_index else 8.0
		if i == active_index:
			draw_circle(Vector2(x,line_y), 14.0, Color(accent.r,accent.g,accent.b,0.06 + sin(pulse*1.6)*0.01))
		draw_circle(Vector2(x,line_y), radius, Color(accent.r,accent.g,accent.b,0.90) if done else Color("29323D"))
		draw_string(FONT, Vector2(x-31,line_y+24), labels[i], HORIZONTAL_ALIGNMENT_CENTER, 62, 6, Color(0.72,0.80,0.87,0.88) if done else Color(0.40,0.46,0.53,0.70))

	var divider_y: float = 98.0
	draw_line(Vector2(14,divider_y), Vector2(r.size.x-14,divider_y), Color(1,1,1,0.055), 1.0)
	_draw_metric(Vector2(14,112), "SETUP", "%d%%" % setup_rating, Color("9DA8B7"), 80)
	_draw_metric(Vector2(100,112), "PING", "%d MS" % ping, Color("5DE1A5") if ping <= 35 else Color("D6B16B"), 78)
	_draw_metric(Vector2(184,112), "SIGNATURE", "%d%%" % mastery, accent, 94)

	var mech_x: float = 286.0 if r.size.x >= 370 else r.size.x * 0.68
	draw_string(FONT, Vector2(mech_x,124), mechanic_label, HORIZONTAL_ALIGNMENT_LEFT, r.size.x-mech_x-14, 9, Color(0.92,0.95,0.98,0.94))
	draw_string(FONT, Vector2(mech_x,139), "BESTE MECHANIC", HORIZONTAL_ALIGNMENT_LEFT, r.size.x-mech_x-14, 6, Color(0.48,0.56,0.64,0.80))

	var bottom_y: float = r.size.y - 27.0
	draw_string(FONT, Vector2(14,bottom_y), "NÄCHSTER UNLOCK", HORIZONTAL_ALIGNMENT_LEFT, 90, 6, Color(0.48,0.56,0.64,0.80))
	draw_string(FONT, Vector2(108,bottom_y), next_label, HORIZONTAL_ALIGNMENT_LEFT, r.size.x-170, 8, Color(0.82,0.88,0.93,0.90))
	var pct: String = "%d%%" % next_progress
	draw_string(FONT, Vector2(r.size.x-50,bottom_y), pct, HORIZONTAL_ALIGNMENT_RIGHT, 36, 8, Color(accent.r,accent.g,accent.b,0.90))
	draw_rect(Rect2(14,r.size.y-13,r.size.x-28,3), Color(1,1,1,0.055), true)
	draw_rect(Rect2(14,r.size.y-13,(r.size.x-28)*float(next_progress)/100.0,3), Color(accent.r,accent.g,accent.b,0.58), true)

func _draw_metric(pos: Vector2, label: String, value: String, color: Color, width: float) -> void:
	draw_string(FONT, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, 13, Color(0.94,0.97,1.0,0.96))
	draw_string(FONT, pos+Vector2(0,15), label, HORIZONTAL_ALIGNMENT_LEFT, width, 6, Color(color.r,color.g,color.b,0.86))
