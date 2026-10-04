class_name OVRRing
extends Control

var value := 75
var maximum := 100
var accent := Color("7FE7FF")
var caption := "OVR"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(78, 78)
	queue_redraw()


func configure(new_value: int, new_accent: Color, new_caption: String = "OVR") -> OVRRing:
	value = clampi(new_value, 0, maximum)
	accent = new_accent
	caption = new_caption
	queue_redraw()
	return self


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var start := -PI * 0.72
	var span := PI * 1.44
	draw_arc(center, radius, start, start + span, 64, Color(0.40, 0.46, 0.54, 0.18), 5.0, true)
	var progress := float(value) / float(maximum)
	draw_arc(center, radius, start, start + span * progress, 64, accent, 5.0, true)

	var font := ThemeDB.fallback_font
	var value_text := str(value)
	var value_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_string(font, center + Vector2(-value_size.x * 0.5, 6), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("F5F7FA"))

	var cap := caption.to_upper()
	var cap_size := font.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(font, center + Vector2(-cap_size.x * 0.5, 22), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("98A3B3"))
