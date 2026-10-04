class_name PremiumNavIcon
extends Control

var kind := "home"
var accent := Color("98A3B3")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(20, 20)
	queue_redraw()


func configure(new_kind: String, color: Color) -> PremiumNavIcon:
	kind = new_kind
	accent = color
	queue_redraw()
	return self


func set_accent(color: Color) -> void:
	accent = color
	queue_redraw()


func _draw() -> void:
	var c := get_rect().size * 0.5
	var w := 1.6
	match kind:
		"home":
			var roof := PackedVector2Array([
				Vector2(c.x - 7, c.y - 1),
				Vector2(c.x, c.y - 7),
				Vector2(c.x + 7, c.y - 1),
			])
			draw_polyline(roof, accent, w, true)
			draw_rect(Rect2(c.x - 5.5, c.y - 1, 11, 8), accent, false, w)
			draw_line(Vector2(c.x - 2, c.y + 7), Vector2(c.x - 2, c.y + 2), accent, w)
			draw_line(Vector2(c.x - 2, c.y + 2), Vector2(c.x + 2, c.y + 2), accent, w)
			draw_line(Vector2(c.x + 2, c.y + 2), Vector2(c.x + 2, c.y + 7), accent, w)
		"team":
			draw_circle(Vector2(c.x - 3, c.y - 3), 3.1, Color.TRANSPARENT)
			draw_arc(Vector2(c.x - 3, c.y - 3), 3.1, 0, TAU, 24, accent, w)
			draw_arc(Vector2(c.x + 4.5, c.y - 1.5), 2.4, 0, TAU, 24, accent, w)
			draw_arc(Vector2(c.x - 3, c.y + 7), 6.0, PI + 0.3, TAU - 0.3, 20, accent, w)
			draw_arc(Vector2(c.x + 4.5, c.y + 6.5), 4.4, PI + 0.45, TAU - 0.25, 18, accent, w)
		"play":
			var shield := PackedVector2Array([
				Vector2(c.x, c.y - 8),
				Vector2(c.x + 6.5, c.y - 4),
				Vector2(c.x + 5.5, c.y + 4),
				Vector2(c.x, c.y + 8),
				Vector2(c.x - 5.5, c.y + 4),
				Vector2(c.x - 6.5, c.y - 4),
				Vector2(c.x, c.y - 8),
			])
			draw_polyline(shield, accent, w, true)
			draw_line(Vector2(c.x - 3, c.y + 1), Vector2(c.x - 0.5, c.y - 1.5), accent, w)
			draw_line(Vector2(c.x - 0.5, c.y - 1.5), Vector2(c.x + 1.5, c.y + 0.5), accent, w)
			draw_line(Vector2(c.x + 1.5, c.y + 0.5), Vector2(c.x + 4.5, c.y - 3), accent, w)
		"market":
			draw_arc(Vector2(c.x - 2, c.y - 2), 5.5, 0, TAU, 28, accent, w)
			draw_line(Vector2(c.x + 2, c.y + 2), Vector2(c.x + 7, c.y + 7), accent, w)
			draw_line(Vector2(c.x - 2, c.y - 5), Vector2(c.x - 2, c.y + 1), accent, w)
			draw_line(Vector2(c.x - 5, c.y - 2), Vector2(c.x + 1, c.y - 2), accent, w)
		"empire":
			draw_line(Vector2(c.x - 7, c.y + 7), Vector2(c.x + 7, c.y + 7), accent, w)
			draw_rect(Rect2(c.x - 6, c.y - 3, 12, 10), accent, false, w)
			draw_line(Vector2(c.x - 6, c.y - 3), Vector2(c.x, c.y - 7), accent, w)
			draw_line(Vector2(c.x, c.y - 7), Vector2(c.x + 6, c.y - 3), accent, w)
			draw_rect(Rect2(c.x - 3.5, c.y + 1, 2.5, 6), accent, false, w)
			draw_rect(Rect2(c.x + 1.5, c.y - 1, 2.5, 8), accent, false, w)
