class_name BrandSurface
extends PanelContainer

var accent := Color("74DFF7")
var variant := "card"


func configure(new_accent: Color, new_variant: String = "card") -> BrandSurface:
	accent = new_accent
	variant = new_variant
	_apply_margins()
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_margins()
	queue_redraw()


func _apply_margins() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	var margin := 16.0 if variant == "hero" else 12.0 if variant == "card" else 9.0
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return

	var base := Color("141A22") if variant == "hero" else Color("10151C") if variant == "card" else Color("0D1218")
	var radius := 12 if variant == "hero" else 8
	draw_style_box(_background_style(base, radius), rect)

	if variant == "hero":
		# One restrained identity plane instead of neon/grid decoration.
		var glow_center := Vector2(rect.size.x + 18.0, 10.0)
		draw_circle(glow_center, minf(118.0, rect.size.x * 0.32), Color(accent.r, accent.g, accent.b, 0.055))
		draw_rect(Rect2(0, 18, 3, maxf(20.0, rect.size.y - 36)), Color(accent.r, accent.g, accent.b, 0.72), true)
	elif variant == "metric":
		draw_rect(Rect2(0, 7, 2, maxf(10.0, rect.size.y - 14)), Color(accent.r, accent.g, accent.b, 0.68), true)


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
	style.border_color = Color(0.75, 0.80, 0.86, 0.075 if variant == "card" else 0.11)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 5 if variant == "hero" else 1
	style.shadow_offset = Vector2(0, 2)
	return style
