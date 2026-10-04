class_name CinematicSurface
extends PanelContainer

var accent := Color("74DFF7")
var variant := "default"
var intensity := 1.0
var animation_time := 0.0


func configure(color: Color, style: String = "default", strength: float = 1.0) -> CinematicSurface:
	accent = color
	variant = style
	intensity = strength
	_apply_panel_style()
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_panel_style()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return

	# Layered dark body. Horizontal bands fake a restrained gradient without shaders.
	var bands := 18
	for index in range(bands):
		var t := float(index) / float(maxi(1, bands - 1))
		var band_color := Color("111923").lerp(Color("090D13"), t)
		band_color = band_color.lerp(Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 1.0), (1.0 - t) * 0.055 * intensity)
		var h := rect.size.y / float(bands) + 1.0
		draw_rect(Rect2(0, float(index) * rect.size.y / float(bands), rect.size.x, h), band_color, true)

	# Deep edge shadow and polished top highlight.
	draw_rect(Rect2(0, rect.size.y - 16, rect.size.x, 16), Color(0, 0, 0, 0.12), true)
	draw_line(Vector2(1, 1), Vector2(rect.size.x - 1, 1), Color(1, 1, 1, 0.055), 1.0)
	draw_line(Vector2(1, rect.size.y - 1), Vector2(rect.size.x - 1, rect.size.y - 1), Color(0, 0, 0, 0.34), 1.0)

	# Signature diagonal geometry gives every hero a sports-broadcast identity.
	var sweep := 7.0 + sin(animation_time * 0.32) * 2.0
	var wedge := PackedVector2Array([
		Vector2(rect.size.x * 0.58 + sweep, 0),
		Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y),
		Vector2(rect.size.x * 0.74 + sweep, rect.size.y),
	])
	draw_colored_polygon(wedge, Color(accent.r, accent.g, accent.b, 0.035 * intensity))

	var slash := PackedVector2Array([
		Vector2(rect.size.x * 0.76 + sweep, 0),
		Vector2(rect.size.x * 0.79 + sweep, 0),
		Vector2(rect.size.x * 0.64 + sweep, rect.size.y),
		Vector2(rect.size.x * 0.61 + sweep, rect.size.y),
	])
	draw_colored_polygon(slash, Color(accent.r, accent.g, accent.b, 0.085 * intensity))

	# Variant-specific art direction.
	match variant:
		"rank":
			_draw_rank_art(rect)
		"player":
			_draw_player_art(rect)
		"queue":
			_draw_queue_art(rect)
		"training":
			_draw_training_art(rect)
		"club":
			_draw_club_art(rect)
		_:
			_draw_default_art(rect)

	# Accent rail: stronger than a border, but only in one place.
	draw_rect(Rect2(0, 0, 3, rect.size.y), Color(accent.r, accent.g, accent.b, 0.78), true)


func _draw_rank_art(rect: Rect2) -> void:
	var center := Vector2(rect.size.x * 0.83, rect.size.y * 0.48)
	var pulse := 0.5 + 0.5 * sin(animation_time * 0.7)
	for index in range(4):
		var radius := 45.0 + float(index) * 19.0
		draw_arc(center, radius, -2.5, 2.4, 56, Color(accent.r, accent.g, accent.b, 0.065 - float(index) * 0.010 + pulse * 0.006), 1.2)
	for index in range(6):
		var x := rect.size.x * 0.58 + float(index) * 17.0
		draw_line(Vector2(x, 8), Vector2(x - 42, rect.size.y - 8), Color(1, 1, 1, 0.018), 1.0)


func _draw_player_art(rect: Rect2) -> void:
	var horizon := rect.size.y * 0.68
	draw_line(Vector2(rect.size.x * 0.42, horizon), Vector2(rect.size.x, horizon), Color(accent.r, accent.g, accent.b, 0.12), 1.0)
	for index in range(5):
		var y := horizon + float(index) * 9.0
		draw_line(Vector2(rect.size.x * 0.40, y), Vector2(rect.size.x, y), Color(1, 1, 1, 0.018), 1.0)


func _draw_queue_art(rect: Rect2) -> void:
	var progress := fmod(animation_time * 28.0, rect.size.x + 120.0) - 120.0
	var beam := PackedVector2Array([
		Vector2(progress, 0),
		Vector2(progress + 80, 0),
		Vector2(progress + 20, rect.size.y),
		Vector2(progress - 60, rect.size.y),
	])
	draw_colored_polygon(beam, Color(accent.r, accent.g, accent.b, 0.035))
	for index in range(7):
		var x := rect.size.x * 0.54 + float(index) * 13.0
		draw_line(Vector2(x, rect.size.y * 0.28), Vector2(x + 24, rect.size.y * 0.72), Color(accent.r, accent.g, accent.b, 0.045), 1.0)


func _draw_training_art(rect: Rect2) -> void:
	var base_y := rect.size.y * 0.78
	for index in range(5):
		var y := base_y - float(index) * 14.0
		draw_line(Vector2(rect.size.x * 0.48, y), Vector2(rect.size.x - 12, y), Color(accent.r, accent.g, accent.b, 0.035 + float(index) * 0.006), 1.0)
	for index in range(4):
		var x := rect.size.x * 0.58 + float(index) * 27.0
		draw_line(Vector2(x, rect.size.y * 0.22), Vector2(x - 35, base_y), Color(1, 1, 1, 0.022), 1.0)


func _draw_club_art(rect: Rect2) -> void:
	for index in range(5):
		var w := 18.0 + float(index) * 12.0
		var h := 24.0 + float(index % 3) * 18.0
		var x := rect.size.x - 18.0 - w - float(index) * 19.0
		draw_rect(Rect2(x, rect.size.y - h - 10, w, h), Color(accent.r, accent.g, accent.b, 0.025 + float(index) * 0.006), true)


func _draw_default_art(rect: Rect2) -> void:
	var center := Vector2(rect.size.x * 0.88, rect.size.y * 0.16)
	draw_circle(center, minf(88.0, rect.size.x * 0.24), Color(accent.r, accent.g, accent.b, 0.025))
