class_name PlayerPortrait
extends Control

const APP_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var player_name := "PLAYER"
var accent := Color("74DFF7")
var seed := 0
var time_value := 0.0

func configure(name_value: String, color: Color) -> PlayerPortrait:
	player_name = name_value
	accent = color
	seed = abs(player_name.hash())
	queue_redraw()
	return self

func _ready() -> void:
	custom_minimum_size = Vector2(76, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x < 2.0 or r.size.y < 2.0:
		return

	# Intentional esports identity card: graphic and premium, no fake tiny face.
	for i in range(16):
		var t := float(i) / 15.0
		var c := Color("111923").lerp(Color("05080D"), t)
		draw_rect(Rect2(0, r.size.y * t, r.size.x, r.size.y / 15.0 + 1.0), c, true)

	var glow := 0.055 + sin(time_value * 0.65) * 0.008
	draw_circle(Vector2(r.size.x * 0.72, r.size.y * 0.26), r.size.x * 0.62, Color(accent.r, accent.g, accent.b, glow))

	# Editorial diagonal layers.
	var wedge := PackedVector2Array([
		Vector2(r.size.x * 0.52, 0),
		Vector2(r.size.x, 0),
		Vector2(r.size.x, r.size.y * 0.66),
		Vector2(r.size.x * 0.70, r.size.y * 0.54),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.10))
	var cut := PackedVector2Array([
		Vector2(0, r.size.y * 0.72),
		Vector2(r.size.x * 0.62, r.size.y * 0.52),
		Vector2(r.size.x, r.size.y * 0.62),
		Vector2(r.size.x, r.size.y),
		Vector2(0, r.size.y),
	])
	draw_colored_polygon(cut, Color(0.015,0.025,0.035,0.90))

	# Strong brand spine.
	draw_rect(Rect2(0, 0, 4, r.size.y), Color(accent.r, accent.g, accent.b, 0.92), true)
	draw_rect(Rect2(7, 10, 1, maxf(1.0, r.size.y - 30)), Color(1,1,1,0.06), true)

	var initials := player_name.substr(0, mini(2, player_name.length())).to_upper()
	if initials.is_empty():
		initials = "PL"

	# Large monogram crest.
	var crest_center := Vector2(r.size.x * 0.52, r.size.y * 0.42)
	var crest_radius := minf(r.size.x, r.size.y) * 0.27
	var points := PackedVector2Array()
	for i in range(6):
		var a := -PI * 0.5 + TAU * float(i) / 6.0
		points.append(crest_center + Vector2(cos(a), sin(a)) * crest_radius)
	draw_colored_polygon(points, Color(0.04,0.065,0.085,0.94))
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, Color(accent.r, accent.g, accent.b, 0.72), 1.7)

	var monogram_size := int(clampf(minf(r.size.x, r.size.y) * 0.29, 18.0, 38.0))
	var text_w := APP_FONT.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, monogram_size).x
	draw_string(APP_FONT, Vector2(crest_center.x - text_w * 0.5, crest_center.y + monogram_size * 0.34), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, monogram_size, Color(0.94,0.97,1.0,0.96))

	# Jersey / team marks below the crest make it feel like an esport player card.
	var jersey_y := r.size.y * 0.67
	draw_line(Vector2(r.size.x * 0.20, jersey_y), Vector2(r.size.x * 0.82, jersey_y), Color(accent.r,accent.g,accent.b,0.46), 2.0)
	draw_rect(Rect2(r.size.x * 0.33, jersey_y + 7, r.size.x * 0.34, 3), Color(1,1,1,0.10), true)
	draw_rect(Rect2(r.size.x * 0.40, jersey_y + 15, r.size.x * 0.20, 2), Color(accent.r,accent.g,accent.b,0.24), true)

	# Small serial detail gives every card a deliberate identity.
	var serial := "%03d" % (seed % 1000)
	draw_string(APP_FONT, Vector2(11, 17), "PLAYER / " + serial, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 18, 6, Color(0.66,0.76,0.84,0.55))

	# Nameplate.
	draw_rect(Rect2(0, r.size.y - 22, r.size.x, 22), Color(0.01,0.015,0.022,0.94), true)
	var display_name := player_name.to_upper()
	var font_size := 9 if display_name.length() <= 9 else 7
	draw_string(APP_FONT, Vector2(10, r.size.y - 7), display_name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, font_size, Color(0.94,0.96,0.99,0.92))

	# Fine frame only.
	draw_line(Vector2(0,0), Vector2(r.size.x,0), Color(1,1,1,0.08), 1.0)
	draw_line(Vector2(r.size.x-1,0), Vector2(r.size.x-1,r.size.y), Color(1,1,1,0.05), 1.0)
