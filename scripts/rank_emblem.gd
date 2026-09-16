class_name RankEmblem
extends Control

const RankedDataRef = preload("res://scripts/ranked_data.gd")

var family := "Unranked"
var tier := 0
var division := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(72.0, 72.0)
	queue_redraw()


func configure(rank_data: Dictionary) -> RankEmblem:
	family = str(rank_data.get("family", "Unranked"))
	tier = int(rank_data.get("tier", 0))
	division = int(rank_data.get("division", 0))
	queue_redraw()
	return self


func set_rank(new_family: String, new_tier: int = 0, new_division: int = 0) -> void:
	family = new_family
	tier = new_tier
	division = new_division
	queue_redraw()


func _draw() -> void:
	var bounds := get_rect().size
	var center := bounds * 0.5
	var scale := minf(bounds.x, bounds.y) / 100.0
	var accent: Color = RankedDataRef.color_for_family(family)
	var dark := accent.darkened(0.64)
	var light := accent.lightened(0.25)

	for glow_index in range(5, 0, -1):
		draw_circle(
			center,
			scale * (29.0 + float(glow_index) * 3.2),
			Color(accent.r, accent.g, accent.b, 0.012 * float(glow_index))
		)

	match family:
		"Bronze":
			_draw_bronze(center, scale, accent, dark, light)
		"Silver":
			_draw_silver(center, scale, accent, dark, light)
		"Gold":
			_draw_gold(center, scale, accent, dark, light)
		"Platinum":
			_draw_platinum(center, scale, accent, dark, light)
		"Diamond":
			_draw_diamond(center, scale, accent, dark, light)
		"Champion":
			_draw_champion(center, scale, accent, dark, light)
		"Grand Champion":
			_draw_grand_champion(center, scale, accent, dark, light)
		"Supersonic Legend":
			_draw_ssl(center, scale, accent, dark, light)
		_:
			_draw_unranked(center, scale, accent)


func _draw_bronze(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	draw_circle(center, 33.0 * scale, Color(0.02, 0.025, 0.055, 0.94))
	draw_arc(center, 31.0 * scale, 0.0, TAU, 64, dark, 7.0 * scale, true)
	draw_arc(center, 30.0 * scale, -2.8, 0.15, 42, light, 2.5 * scale, true)
	draw_arc(center + Vector2(0, 1) * scale, 22.5 * scale, -0.05, 2.85, 36, accent, 4.5 * scale, true)
	var blade_x := [-12.0, 0.0, 12.0]
	for index in range(level):
		var offset: float = blade_x[index + (3 - level) / 2]
		var blade := _scaled_points(
			[
				Vector2(offset - 5, 16), Vector2(offset - 2, -19),
				Vector2(offset + 7, -25), Vector2(offset + 4, 11),
			],
			center,
			scale
		)
		_draw_poly(blade, accent if index % 2 == 0 else light, light, maxf(1.0, scale))


func _draw_silver(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	var outer := _regular_polygon(center, 37.0 * scale, 6, PI / 6.0)
	var inner := _regular_polygon(center, 29.0 * scale, 6, PI / 6.0)
	_draw_poly(outer, Color(0.025, 0.035, 0.075, 0.96), light, 3.2 * scale)
	_draw_poly(inner, dark, Color(1, 1, 1, 0.22), 1.4 * scale)
	var starts := [-13.0, -3.0, 7.0]
	for index in range(level):
		var x: float = starts[index + (3 - level) / 2]
		var stripe := _scaled_points(
			[Vector2(x - 9, 18), Vector2(x + 3, -18), Vector2(x + 11, -18), Vector2(x - 1, 18)],
			center,
			scale
		)
		_draw_poly(stripe, light if index == 0 else accent, Color(1, 1, 1, 0.18), maxf(0.8, scale))


func _draw_gold(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	var outer := _scaled_points(
		[Vector2(0, -37), Vector2(34, 23), Vector2(23, 34), Vector2(-23, 34), Vector2(-34, 23)],
		center,
		scale
	)
	_draw_poly(outer, Color(0.025, 0.03, 0.055, 0.96), accent, 3.0 * scale)
	var base := _scaled_points(
		[Vector2(0, -27), Vector2(25, 20), Vector2(15, 27), Vector2(-15, 27), Vector2(-25, 20)],
		center,
		scale
	)
	_draw_poly(base, dark, light, 1.6 * scale)
	for index in range(level):
		var y := 15.0 - float(index) * 13.0
		var half_width := 17.0 - float(index) * 3.0
		var chevron := _scaled_points(
			[
				Vector2(-half_width, y + 6), Vector2(0, y - 5), Vector2(half_width, y + 6),
				Vector2(half_width - 4, y + 12), Vector2(0, y + 3), Vector2(-half_width + 4, y + 12),
			],
			center,
			scale
		)
		draw_colored_polygon(chevron, light if index == level - 1 else accent)


func _draw_platinum(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	var outer_star := _star_points(center, 35.0 * scale, 15.0 * scale, 5, -PI / 2.0)
	_draw_poly(outer_star, Color(0.02, 0.055, 0.09, 0.96), light, 2.8 * scale)
	var core_star := _star_points(center, 25.0 * scale, 11.0 * scale, 5, -PI / 2.0)
	_draw_poly(core_star, dark, accent, 2.0 * scale)
	for index in range(level):
		var spread := 18.0 + float(index) * 8.0
		var y := 4.0 + float(index) * 6.0
		draw_line(
			center + Vector2(-spread, y) * scale,
			center + Vector2(-7, y - 5) * scale,
			accent if index < 2 else light,
			3.0 * scale,
			true
		)
		draw_line(
			center + Vector2(spread, y) * scale,
			center + Vector2(7, y - 5) * scale,
			accent if index < 2 else light,
			3.0 * scale,
			true
		)


func _draw_diamond(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	for layer in range(level - 1, -1, -1):
		var width := 27.0 + float(layer) * 5.0
		var height := 30.0 + float(layer) * 4.0
		var y_offset := float(layer) * 4.0
		var gem := _scaled_points(
			[
				Vector2(0, -height + y_offset), Vector2(width, -8 + y_offset),
				Vector2(width - 8, 19 + y_offset), Vector2(0, height + y_offset),
				Vector2(-width + 8, 19 + y_offset), Vector2(-width, -8 + y_offset),
			],
			center,
			scale
		)
		_draw_poly(
			gem,
			Color(dark.r, dark.g, dark.b, 0.96) if layer > 0 else Color(accent.r, accent.g, accent.b, 0.78),
			light if layer == 0 else accent,
			(1.5 + float(layer) * 0.7) * scale
		)
	var top := center + Vector2(0, -30) * scale
	var left := center + Vector2(-27, -8) * scale
	var right := center + Vector2(27, -8) * scale
	var bottom := center + Vector2(0, 30) * scale
	draw_line(top, center, Color(1, 1, 1, 0.48), 1.4 * scale, true)
	draw_line(left, center, Color(1, 1, 1, 0.34), 1.2 * scale, true)
	draw_line(right, center, Color(1, 1, 1, 0.34), 1.2 * scale, true)
	draw_line(bottom, center, Color(0.05, 0.18, 0.4, 0.62), 1.2 * scale, true)


func _draw_champion(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	for layer in range(level, 0, -1):
		var spread := 18.0 + float(layer) * 6.0
		var left := _scaled_points(
			[
				Vector2(-4, -17), Vector2(-spread, -24 + layer * 2), Vector2(-spread + 6, -5),
				Vector2(-spread - 2, 11 + layer * 2), Vector2(-8, 21), Vector2(0, 5),
			],
			center,
			scale
		)
		var right := _mirror_points(left, center)
		var fill := Color(accent.r, accent.g, accent.b, 0.42 + float(layer) * 0.16)
		_draw_poly(left, fill, light if layer == 1 else accent, maxf(1.0, scale * 1.2))
		_draw_poly(right, fill, light if layer == 1 else accent, maxf(1.0, scale * 1.2))
	var core := _scaled_points(
		[Vector2(0, -23), Vector2(13, 0), Vector2(0, 24), Vector2(-13, 0)], center, scale
	)
	_draw_poly(core, dark, light, 2.2 * scale)
	draw_circle(center, 4.0 * scale, accent)


func _draw_grand_champion(center: Vector2, scale: float, accent: Color, dark: Color, light: Color) -> void:
	var level := clampi(tier, 1, 3)
	for layer in range(level, 0, -1):
		var spread := 17.0 + float(layer) * 7.0
		var rise := float(layer - 1) * 4.0
		var wing := _scaled_points(
			[
				Vector2(-7, -12), Vector2(-spread + 8, -25 - rise), Vector2(-spread, -11 - rise),
				Vector2(-spread + 5, 0), Vector2(-spread - 2, 12 + rise), Vector2(-8, 18),
			],
			center,
			scale
		)
		var mirror := _mirror_points(wing, center)
		var fill := Color(accent.r, accent.g, accent.b, 0.40 + float(layer) * 0.17)
		_draw_poly(wing, fill, light if layer == 1 else accent, maxf(1.0, scale * 1.1))
		_draw_poly(mirror, fill, light if layer == 1 else accent, maxf(1.0, scale * 1.1))
	var crown := _scaled_points(
		[
			Vector2(0, -31), Vector2(8, -17), Vector2(17, -20), Vector2(12, -5),
			Vector2(0, 16), Vector2(-12, -5), Vector2(-17, -20), Vector2(-8, -17),
		],
		center,
		scale
	)
	_draw_poly(crown, dark, light, 2.4 * scale)
	var core := _scaled_points(
		[Vector2(0, -14), Vector2(10, 0), Vector2(0, 14), Vector2(-10, 0)], center, scale
	)
	_draw_poly(core, accent, Color(1, 1, 1, 0.6), 1.2 * scale)


func _draw_ssl(center: Vector2, scale: float, accent: Color, _dark: Color, light: Color) -> void:
	var purple := Color("a974ff")
	var mint := Color("bfffe8")
	var wing := _scaled_points(
		[
			Vector2(-5, -17), Vector2(-18, -33), Vector2(-20, -17), Vector2(-38, -23),
			Vector2(-31, -5), Vector2(-42, 7), Vector2(-22, 10), Vector2(-18, 28),
			Vector2(-5, 18), Vector2(0, 5),
		],
		center,
		scale
	)
	var mirror := _mirror_points(wing, center)
	_draw_poly(wing, Color(accent.r, accent.g, accent.b, 0.86), mint, 1.8 * scale)
	_draw_poly(mirror, Color(accent.r, accent.g, accent.b, 0.86), mint, 1.8 * scale)
	var halo := _scaled_points(
		[
			Vector2(0, -36), Vector2(10, -22), Vector2(25, -19), Vector2(18, -6),
			Vector2(0, -12), Vector2(-18, -6), Vector2(-25, -19), Vector2(-10, -22),
		],
		center,
		scale
	)
	_draw_poly(halo, Color(purple.r, purple.g, purple.b, 0.82), light, 1.6 * scale)
	var core := _scaled_points(
		[
			Vector2(0, -18), Vector2(14, -4), Vector2(9, 15), Vector2(0, 23),
			Vector2(-9, 15), Vector2(-14, -4),
		],
		center,
		scale
	)
	_draw_poly(core, Color(0.13, 0.08, 0.25, 0.98), purple, 3.0 * scale)
	var gem := _scaled_points(
		[Vector2(0, -10), Vector2(8, 1), Vector2(0, 13), Vector2(-8, 1)], center, scale
	)
	_draw_poly(gem, mint, Color(1, 1, 1, 0.9), 1.2 * scale)


func _draw_unranked(center: Vector2, scale: float, accent: Color) -> void:
	var shield := _scaled_points(
		[
			Vector2(-28, -27), Vector2(0, -38), Vector2(28, -27), Vector2(32, 4),
			Vector2(18, 30), Vector2(0, 40), Vector2(-18, 30), Vector2(-32, 4),
		],
		center,
		scale
	)
	_draw_poly(shield, Color(0.025, 0.04, 0.09, 0.96), accent, 2.4 * scale)
	draw_arc(center + Vector2(0, -7) * scale, 12.0 * scale, -2.8, 0.2, 24, accent, 3.0 * scale, true)
	draw_line(center + Vector2(10, -5) * scale, center + Vector2(0, 7) * scale, accent, 3.0 * scale, true)
	draw_circle(center + Vector2(0, 18) * scale, 2.5 * scale, accent)


func _draw_poly(points: PackedVector2Array, fill: Color, outline: Color, width: float) -> void:
	draw_colored_polygon(points, fill)
	_draw_closed_outline(points, outline, width)


func _regular_polygon(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(sides):
		var angle := rotation + float(index) * TAU / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _star_points(
	center: Vector2, outer_radius: float, inner_radius: float, point_count: int, rotation: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := rotation + float(index) * PI / float(point_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _scaled_points(points: Array, center: Vector2, scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		var vector: Vector2 = point
		result.append(center + vector * scale)
	return result


func _mirror_points(points: PackedVector2Array, center: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(Vector2(center.x * 2.0 - point.x, point.y))
	return result


func _draw_closed_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.is_empty():
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)
