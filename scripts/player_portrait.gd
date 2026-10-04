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

	# Layered player-card body.
	for index in range(14):
		var t := float(index) / 13.0
		var c := Color("111923").lerp(Color("070A0F"), t)
		c = c.lerp(Color(accent.r * 0.24, accent.g * 0.24, accent.b * 0.24, 1.0), (1.0 - t) * 0.08)
		var h := r.size.y / 14.0 + 1.0
		draw_rect(Rect2(0, float(index) * r.size.y / 14.0, r.size.x, h), c, true)

	# Editorial diagonal block.
	var wedge := PackedVector2Array([
		Vector2(r.size.x * 0.54, 0),
		Vector2(r.size.x, 0),
		Vector2(r.size.x, r.size.y * 0.68),
		Vector2(r.size.x * 0.70, r.size.y * 0.55),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.085))
	draw_line(Vector2(3, 0), Vector2(3, r.size.y), Color(accent.r, accent.g, accent.b, 0.82), 3.0)

	# Large initials watermark creates identity without fake-realistic faces.
	var initials := player_name.left(2).to_upper()
	var watermark_size := int(clampf(r.size.x * 0.42, 18.0, 38.0))
	var mark_width := APP_FONT.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, watermark_size).x
	draw_string(APP_FONT, Vector2(r.size.x - mark_width - 6, r.size.y * 0.28), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, watermark_size, Color(1, 1, 1, 0.055))

	# Abstract esports athlete silhouette: deliberate, graphic, not pseudo-realistic.
	var center_x := r.size.x * 0.50
	var head_center := Vector2(center_x, r.size.y * 0.31)
	var head_radius := minf(r.size.x, r.size.y) * 0.105
	var skin := Color("9B887A").lerp(Color("67564D"), float(seed % 100) / 130.0)
	var jersey := Color("18212B").lerp(Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 1.0), 0.22)

	# Shoulders and jersey use sharp sport-card geometry.
	var shoulders := PackedVector2Array([
		Vector2(r.size.x * 0.12, r.size.y),
		Vector2(r.size.x * 0.18, r.size.y * 0.67),
		Vector2(center_x - head_radius * 1.1, r.size.y * 0.59),
		Vector2(center_x + head_radius * 1.1, r.size.y * 0.59),
		Vector2(r.size.x * 0.82, r.size.y * 0.67),
		Vector2(r.size.x * 0.90, r.size.y),
	])
	draw_colored_polygon(shoulders, jersey)

	# Jersey panels and sponsor-like identity bars.
	draw_line(Vector2(r.size.x * 0.23, r.size.y * 0.71), Vector2(r.size.x * 0.77, r.size.y * 0.71), Color(accent.r, accent.g, accent.b, 0.38), 1.5)
	draw_rect(Rect2(center_x - 12, r.size.y * 0.76, 24, 3), Color(accent.r, accent.g, accent.b, 0.22), true)
	draw_rect(Rect2(center_x - 8, r.size.y * 0.82, 16, 2), Color(1, 1, 1, 0.10), true)

	# Neck and clean silhouette head.
	draw_rect(Rect2(center_x - head_radius * 0.38, head_center.y + head_radius * 0.62, head_radius * 0.76, head_radius * 1.10), skin.darkened(0.08), true)
	draw_circle(head_center, head_radius, skin)

	# Hair is intentionally graphic.
	var hair := Color("15191F").lerp(Color("3A2D28"), float((seed / 7) % 100) / 180.0)
	var hair_poly := PackedVector2Array([
		Vector2(head_center.x - head_radius, head_center.y - head_radius * 0.10),
		Vector2(head_center.x - head_radius * 0.70, head_center.y - head_radius * 0.92),
		Vector2(head_center.x + head_radius * 0.10, head_center.y - head_radius * 1.08),
		Vector2(head_center.x + head_radius, head_center.y - head_radius * 0.52),
		Vector2(head_center.x + head_radius * 0.82, head_center.y + head_radius * 0.05),
		Vector2(head_center.x - head_radius * 0.84, head_center.y + head_radius * 0.18),
	])
	draw_colored_polygon(hair_poly, hair)

	# Headset gives esports context without tiny facial details.
	draw_arc(head_center, head_radius * 1.20, PI + 0.28, TAU - 0.28, 28, Color("596879"), 2.0)
	draw_rect(Rect2(head_center.x - head_radius * 1.23, head_center.y - 1, 3.5, head_radius * 0.95), Color("455464"), true)
	draw_rect(Rect2(head_center.x + head_radius * 1.02, head_center.y - 1, 3.5, head_radius * 0.95), Color("455464"), true)

	# Soft rim light.
	var rim := 0.32 + sin(time_value * 0.7) * 0.04
	draw_arc(head_center, head_radius * 1.03, -1.65, 0.35, 22, Color(accent.r, accent.g, accent.b, rim), 1.1)

	# Lower identity strip.
	draw_rect(Rect2(0, r.size.y - 18, r.size.x, 18), Color(0.015, 0.020, 0.028, 0.82), true)
	var display_name := player_name.to_upper()
	var font_size := 8 if display_name.length() <= 10 else 7
	draw_string(APP_FONT, Vector2(8, r.size.y - 6), display_name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, font_size, Color(0.90, 0.93, 0.97, 0.86))

	# Minimal frame, no rounded-card outline.
	draw_line(Vector2(0, 0), Vector2(r.size.x, 0), Color(1, 1, 1, 0.06), 1.0)
	draw_line(Vector2(r.size.x - 1, 0), Vector2(r.size.x - 1, r.size.y), Color(1, 1, 1, 0.035), 1.0)
