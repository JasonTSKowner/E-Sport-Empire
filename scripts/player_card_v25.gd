class_name PlayerCardV25
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var data: Dictionary = {}
var accent := Color("74DFF7")
var overall := 50
var potential := 75
var card_mode := "roster"
var pulse := 0.0

func configure(player: Dictionary, color: Color, ovr: int, pot: int, mode: String = "roster") -> PlayerCardV25:
	data = player.duplicate(true)
	accent = color
	overall = ovr
	potential = pot
	card_mode = mode
	custom_minimum_size = Vector2(0, 260 if mode == "roster" else 246)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x < 8 or r.size.y < 8:
		return
	_draw_background(r)
	_draw_identity(r)
	_draw_athlete(r)
	_draw_rating(r)
	_draw_stats(r)
	_draw_footer(r)

func _draw_background(r: Rect2) -> void:
	for i in range(16):
		var t := float(i) / 15.0
		var c := Color("101720").lerp(Color("03060A"), t)
		draw_rect(Rect2(0, r.size.y * t, r.size.x, r.size.y / 15.0 + 2), c, true)
	var wedge := PackedVector2Array([
		Vector2(r.size.x * 0.42, 0), Vector2(r.size.x, 0),
		Vector2(r.size.x, r.size.y * 0.73), Vector2(r.size.x * 0.65, r.size.y * 0.55),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.075))
	draw_circle(Vector2(r.size.x * 0.28, r.size.y * 0.46), r.size.x * 0.25, Color(accent.r, accent.g, accent.b, 0.026))
	draw_arc(Vector2(r.size.x * 0.28, r.size.y * 0.46), r.size.x * 0.22, 0, TAU, 64, Color(accent.r, accent.g, accent.b, 0.07), 1.2)
	draw_line(Vector2(0, 1), Vector2(r.size.x, 1), Color(accent.r, accent.g, accent.b, 0.22), 1.0)
	draw_line(Vector2(4, 0), Vector2(4, r.size.y), Color(accent.r, accent.g, accent.b, 0.75), 3.0)

func _draw_identity(r: Rect2) -> void:
	var name := str(data.get("name", "SPIELER")).to_upper()
	var role := str(data.get("role", "PLAYER")).to_upper()
	var region := str(data.get("region", "EU")).to_upper()
	var age := int(data.get("age", 16))
	var kicker := "SCOUT REPORT" if card_mode == "scout" else "ACTIVE ROSTER"
	draw_string(FONT, Vector2(18, 25), kicker, HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.55, 7, Color(accent.r, accent.g, accent.b, 0.86))
	draw_string(FONT, Vector2(18, 52), name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.62, 24, Color(0.95, 0.97, 1.0, 0.98))
	draw_string(FONT, Vector2(18, 70), "%s  /  %s  /  %d J." % [role, region, age], HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.60, 8, Color(0.60, 0.68, 0.76, 0.86))

func _draw_athlete(r: Rect2) -> void:
	var center := Vector2(r.size.x * 0.31, r.size.y * 0.54)
	var head_r := 18.0
	var skin_seed := abs(str(data.get("name", "PLAYER")).hash()) % 100
	var skin := Color("AA9281").lerp(Color("6A554C"), float(skin_seed) / 135.0)
	var jersey := Color("161E27").lerp(Color(accent.r * 0.40, accent.g * 0.40, accent.b * 0.40, 1.0), 0.30)
	var shoulders := PackedVector2Array([
		Vector2(center.x - 56, r.size.y * 0.79), Vector2(center.x - 42, r.size.y * 0.65),
		Vector2(center.x - 18, r.size.y * 0.61), Vector2(center.x + 18, r.size.y * 0.61),
		Vector2(center.x + 45, r.size.y * 0.66), Vector2(center.x + 58, r.size.y * 0.79),
	])
	draw_colored_polygon(shoulders, jersey)
	draw_line(Vector2(center.x - 44, r.size.y * 0.67), Vector2(center.x + 44, r.size.y * 0.67), Color(accent.r, accent.g, accent.b, 0.38), 2.0)
	draw_rect(Rect2(center.x - 13, r.size.y * 0.70, 26, 4), Color(accent.r, accent.g, accent.b, 0.22), true)
	draw_rect(Rect2(center.x - 7, center.y + 13, 14, 23), skin.darkened(0.10), true)
	draw_circle(center, head_r, skin)
	var hair := PackedVector2Array([
		Vector2(center.x - 18, center.y - 2), Vector2(center.x - 13, center.y - 18),
		Vector2(center.x + 3, center.y - 22), Vector2(center.x + 17, center.y - 13),
		Vector2(center.x + 16, center.y + 1), Vector2(center.x - 16, center.y + 3),
	])
	draw_colored_polygon(hair, Color("171B21"))
	draw_arc(center, head_r * 1.22, PI + 0.28, TAU - 0.28, 28, Color("5B6D7F"), 2.2)
	draw_rect(Rect2(center.x - head_r * 1.24, center.y - 1, 4, 16), Color("42515F"), true)
	draw_rect(Rect2(center.x + head_r * 1.04, center.y - 1, 4, 16), Color("42515F"), true)
	var rim := 0.26 + sin(pulse * 0.8) * 0.04
	draw_arc(center, head_r * 1.05, -1.6, 0.4, 24, Color(accent.r, accent.g, accent.b, rim), 1.3)

func _draw_rating(r: Rect2) -> void:
	var right := r.size.x - 18.0
	var rating_text := str(overall)
	var rating_width := FONT.get_string_size(rating_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
	draw_string(FONT, Vector2(right - rating_width, 51), rating_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(0.96, 0.98, 1.0, 0.98))
	var cap := "OVR"
	var cap_w := FONT.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(FONT, Vector2(right - cap_w, 67), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(accent.r, accent.g, accent.b, 0.86))
	var pot := "POT %d" % potential
	var pot_w := FONT.get_string_size(pot, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(FONT, Vector2(right - pot_w, 84), pot, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.36, 0.88, 0.65, 0.92))

func _draw_stats(r: Rect2) -> void:
	var labels := ["MECH", "SHOT", "DEF", "SENSE"]
	var values := [
		int(data.get("mechanics", 50)), int(data.get("shooting", 50)),
		int(data.get("defense", 50)), int(data.get("game_sense", 50)),
	]
	var start_x := r.size.x * 0.52
	var width := r.size.x * 0.44
	var y := r.size.y * 0.48
	for i in range(4):
		var row_y := y + float(i) * 28.0
		var value := values[i]
		draw_string(FONT, Vector2(start_x, row_y), labels[i], HORIZONTAL_ALIGNMENT_LEFT, 44, 7, Color(0.58, 0.67, 0.75, 0.84))
		var value_text := str(value)
		draw_string(FONT, Vector2(start_x + width - 26, row_y), value_text, HORIZONTAL_ALIGNMENT_RIGHT, 26, 9, Color(0.92, 0.95, 0.98, 0.94))
		var bar_y := row_y + 6.0
		draw_rect(Rect2(start_x, bar_y, width, 3), Color(1, 1, 1, 0.055), true)
		draw_rect(Rect2(start_x, bar_y, width * clampf(float(value) / 100.0, 0.0, 1.0), 3), Color(accent.r, accent.g, accent.b, 0.60), true)

func _draw_footer(r: Rect2) -> void:
	var footer_y := r.size.y - 25.0
	draw_rect(Rect2(0, footer_y - 9, r.size.x, 34), Color(0.008, 0.012, 0.018, 0.78), true)
	var rotation := int(data.get("rotation", 50))
	var consistency := int(data.get("consistency", 50))
	var boost := int(data.get("boost_control", 50))
	var text := "ROT %d   ·   CONS %d   ·   BOOST %d" % [rotation, consistency, boost]
	draw_string(FONT, Vector2(18, footer_y + 5), text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36, 8, Color(0.62, 0.71, 0.79, 0.78))
