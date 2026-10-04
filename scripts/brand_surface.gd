class_name BrandSurface
extends PanelContainer

var accent := Color("74DFF7")
var variant := "card"
var time_value := 0.0


func configure(new_accent: Color, new_variant: String = "card") -> BrandSurface:
	accent = new_accent
	variant = new_variant
	_apply_margins()
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_margins()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	time_value += delta
	queue_redraw()


func _apply_margins() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	var margin := 15.0 if variant == "hero" else 11.0 if variant == "card" else 8.0
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return

	var base_top := Color("131A22") if variant == "hero" else Color("0F141B")
	var base_bottom := Color("0A0E14") if variant == "hero" else Color("0B0F14")
	var bands := 10 if variant == "hero" else 6
	for index in range(bands):
		var t := float(index) / float(maxi(1, bands - 1))
		var c := base_top.lerp(base_bottom, t)
		var h := rect.size.y / float(bands) + 1.0
		draw_rect(Rect2(0, float(index) * rect.size.y / float(bands), rect.size.x, h), c, true)

	# One architectural accent plane instead of a glowing outline around every card.
	var right_plane := PackedVector2Array([
		Vector2(rect.size.x * 0.78, 0),
		Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y),
		Vector2(rect.size.x * 0.88, rect.size.y),
	])
	draw_colored_polygon(right_plane, Color(accent.r, accent.g, accent.b, 0.022 if variant == "card" else 0.040))

	if variant == "hero":
		var pulse := 0.5 + 0.5 * sin(time_value * 0.42)
		var glow_center := Vector2(rect.size.x * 0.90, rect.size.y * 0.08)
		draw_circle(glow_center, minf(115.0, rect.size.x * 0.30), Color(accent.r, accent.g, accent.b, 0.030 + pulse * 0.008))
		var slash := PackedVector2Array([
			Vector2(rect.size.x * 0.65, 0),
			Vector2(rect.size.x * 0.68, 0),
			Vector2(rect.size.x * 0.52, rect.size.y),
			Vector2(rect.size.x * 0.49, rect.size.y),
		])
		draw_colored_polygon(slash, Color(accent.r, accent.g, accent.b, 0.060))
		draw_rect(Rect2(0, 0, 3, rect.size.y), Color(accent.r, accent.g, accent.b, 0.70), true)
	else:
		# Cards read as content rows, not mini windows.
		draw_rect(Rect2(0, rect.size.y - 1, rect.size.x, 1), Color(1, 1, 1, 0.055), true)

	# Fine polished highlight on top edge only.
	draw_line(Vector2(0, 0), Vector2(rect.size.x, 0), Color(1, 1, 1, 0.045), 1.0)
