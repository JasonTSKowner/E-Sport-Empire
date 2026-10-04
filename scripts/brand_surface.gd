class_name BrandSurface
extends PanelContainer

var accent := Color("7FE7FF")
var variant := "card"
var draw_time := 0.0


func configure(new_accent: Color, new_variant: String = "card") -> BrandSurface:
	accent = new_accent
	variant = new_variant
	_apply_margins()
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_margins()
	set_process(variant == "hero")


func _process(delta: float) -> void:
	draw_time += delta
	if variant == "hero":
		queue_redraw()


func _apply_margins() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	var margin := 18.0 if variant == "hero" else 14.0 if variant == "card" else 10.0
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return

	var base := Color("10151D") if variant == "hero" else Color("0D1218") if variant == "card" else Color("0A0F15")
	draw_style_box(_background_style(base, 12 if variant == "hero" else 7), rect)

	# structural separators, not glow
	var line_alpha := 0.55 if variant == "hero" else 0.22
	draw_rect(Rect2(0, 0, rect.size.x, 2 if variant == "hero" else 1), Color(accent.r, accent.g, accent.b, line_alpha), true)

	if variant == "hero":
		# asymmetrical upper-right brand plane
		var cut := minf(rect.size.x * 0.34, 150.0)
		var plane := PackedVector2Array([
			Vector2(rect.size.x - cut, 0),
			Vector2(rect.size.x, 0),
			Vector2(rect.size.x, minf(92.0, rect.size.y * 0.55)),
			Vector2(rect.size.x - cut * 0.52, 0),
		])
		draw_colored_polygon(plane, Color(accent.r, accent.g, accent.b, 0.055))

		# quiet technical grid in the plane
		for i in range(4):
			var x := rect.size.x - cut + float(i) * cut / 3.0
			draw_line(Vector2(x, 8), Vector2(x + 34, minf(rect.size.y - 8, 86)), Color(0.75,0.82,0.90,0.035), 1.0)

		var pulse := 0.7 + sin(draw_time * 0.9) * 0.08
		draw_circle(Vector2(rect.size.x - 20, 20), 2.0, Color(accent.r, accent.g, accent.b, 0.45 * pulse))
		draw_circle(Vector2(rect.size.x - 29, 20), 1.1, Color(0.75,0.82,0.90,0.18))
	elif variant == "metric":
		draw_rect(Rect2(0, 0, 3, rect.size.y), Color(accent.r, accent.g, accent.b, 0.78), true)


func _background_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.72, 0.78, 0.86, 0.075)
	style.shadow_color = Color(0, 0, 0, 0.16)
	style.shadow_size = 3 if variant == "hero" else 0
	style.shadow_offset = Vector2(0, 2)
	return style
