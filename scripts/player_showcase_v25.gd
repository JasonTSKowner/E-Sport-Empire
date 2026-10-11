class_name PlayerShowcaseV25
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var player_name := "PLAYER"
var accent := Color("74DFF7")
var overall := 50
var potential := 80
var role := "PLAYER"
var region := "EU"

func configure(player: Dictionary, color: Color, ovr: int) -> PlayerShowcaseV25:
	player_name = str(player.get("name", "PLAYER")).to_upper()
	accent = color
	overall = ovr
	potential = int(player.get("potential", 80))
	role = str(player.get("role", "PLAYER")).to_upper()
	region = str(player.get("region", "EU")).to_upper()
	custom_minimum_size = Vector2(138, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("071018"), true)
	for i in range(8):
		var y := float(i) * rect.size.y / 8.0
		draw_rect(Rect2(0, y, rect.size.x, rect.size.y / 8.0 + 1.0), Color("0C1821").lerp(Color("071018"), float(i) / 7.0), true)
	var cut := PackedVector2Array([
		Vector2(rect.size.x * 0.57, 0), Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y * 0.52), Vector2(rect.size.x * 0.34, rect.size.y * 0.74)
	])
	draw_colored_polygon(cut, Color(accent.r, accent.g, accent.b, 0.10))
	draw_line(Vector2(0, 1), Vector2(rect.size.x, 1), Color(accent.r, accent.g, accent.b, 0.65), 2.0)

	var center := Vector2(rect.size.x * 0.47, rect.size.y * 0.52)
	var head := center + Vector2(0, -35)
	draw_circle(head, 15.5, Color("1B2732"))
	draw_circle(head + Vector2(-4, -4), 4.2, Color("2E4050"))
	var shoulders := PackedVector2Array([
		center + Vector2(-35, -8), center + Vector2(-18, -27),
		center + Vector2(18, -27), center + Vector2(35, -8),
		center + Vector2(29, 42), center + Vector2(-29, 42)
	])
	draw_colored_polygon(shoulders, Color("102631"))
	draw_polyline(shoulders, Color(accent.r, accent.g, accent.b, 0.55), 1.4, true)
	var chest := PackedVector2Array([
		center + Vector2(-21, -23), center + Vector2(21, -23),
		center + Vector2(18, 35), center + Vector2(-18, 35)
	])
	draw_colored_polygon(chest, Color(accent.r * 0.16, accent.g * 0.20, accent.b * 0.22, 1.0))
	draw_string(FONT, center + Vector2(-21, 18), "%02d" % overall, HORIZONTAL_ALIGNMENT_CENTER, 42, 18, Color(0.92, 0.97, 1.0, 0.95))

	draw_rect(Rect2(8, rect.size.y - 39, rect.size.x - 16, 31), Color(0.015, 0.025, 0.034, 0.82), true)
	draw_string(FONT, Vector2(12, rect.size.y - 22), player_name, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 9, Color(0.92, 0.96, 1.0, 0.94))
	draw_string(FONT, Vector2(12, rect.size.y - 10), "%s  ·  %s" % [role, region], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 7, Color(0.57, 0.66, 0.73, 0.82))

	var pot_text := "POT %d" % potential
	draw_string(FONT, Vector2(rect.size.x - 52, 15), pot_text, HORIZONTAL_ALIGNMENT_RIGHT, 44, 7, Color(accent.r, accent.g, accent.b, 0.90))
