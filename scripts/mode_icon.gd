class_name ModeIcon
extends Control

var mode := "Rocket League"
var accent := Color("74DFF7")


func configure(mode_name: String, color: Color) -> ModeIcon:
	mode = mode_name
	accent = color
	queue_redraw()
	return self


func _ready() -> void:
	custom_minimum_size = Vector2(38, 38)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var muted := Color(0.76, 0.81, 0.87, 0.34)
	draw_circle(c, 17.0, Color(0.045,0.058,0.072,0.96))
	draw_arc(c, 16.5, 0, TAU, 36, Color(accent.r, accent.g, accent.b, 0.24), 1.0)

	match mode:
		"Rocket League":
			# ball + pitch arcs
			draw_arc(c, 7.3, 0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.90), 1.5)
			var hex := PackedVector2Array()
			for i in range(6):
				var a := -PI / 2.0 + float(i) * TAU / 6.0
				hex.append(c + Vector2(cos(a), sin(a)) * 3.6)
			var closed := PackedVector2Array(hex)
			closed.append(hex[0])
			draw_polyline(closed, muted, 1.1, true)
			draw_arc(c, 12.0, -0.65, 0.65, 18, muted, 1.0)
		"Fortnite":
			# storm ring + build planes; abstract, not game-logo copying
			draw_arc(c, 10.5, -2.7, 2.25, 30, Color(accent.r, accent.g, accent.b, 0.88), 1.6)
			draw_line(c + Vector2(-7, 6), c + Vector2(7, -7), muted, 1.2)
			draw_line(c + Vector2(-2, 8), c + Vector2(9, -2), muted, 1.2)
			draw_line(c + Vector2(2, 7), c + Vector2(8, 1), muted, 1.2)
		_:
			# tactical radar for Warzone/other modes
			draw_arc(c, 10.0, 0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.76), 1.2)
			draw_arc(c, 5.0, 0, TAU, 24, muted, 1.0)
			draw_line(c, c + Vector2(7, -6), Color(accent.r, accent.g, accent.b, 0.92), 1.5)
			draw_circle(c + Vector2(6, 3), 1.6, Color(accent.r, accent.g, accent.b, 0.80))
