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
	var dark := accent.darkened(0.58)
	var light := accent.lightened(0.24)

	for glow_index in range(4, 0, -1):
		draw_circle(center, scale * (35.0 + float(glow_index) * 2.8), Color(accent.r, accent.g, accent.b, 0.018 * float(glow_index)))

	var crest := _scaled_points(
		[
			Vector2(-30, -31), Vector2(0, -43), Vector2(30, -31), Vector2(38, -4),
			Vector2(26, 29), Vector2(0, 44), Vector2(-26, 29), Vector2(-38, -4),
		],
		center,
		scale
	)
	var crest_inner := _scaled_points(
		[
			Vector2(-24, -27), Vector2(0, -36), Vector2(24, -27), Vector2(31, -3),
			Vector2(21, 24), Vector2(0, 37), Vector2(-21, 24), Vector2(-31, -3),
		],
		center,
		scale
	)
	draw_colored_polygon(crest, Color(0.01, 0.02, 0.07, 0.92))
	_draw_closed_outline(crest, Color(accent.r, accent.g, accent.b, 0.82), maxf(1.2, scale * 2.0))
	draw_colored_polygon(crest_inner, Color(dark.r, dark.g, dark.b, 0.74))
	_draw_closed_outline(crest_inner, Color(light.r, light.g, light.b, 0.42), maxf(1.0, scale * 1.1))

	match family:
		"Bronze":
			_draw_bronze(center, scale, accent, light)
		"Silver":
			_draw_silver(center, scale, accent, light)
		"Gold":
			_draw_gold(center, scale, accent, light)
		"Platinum":
			_draw_platinum(center, scale, accent, light)
		"Diamond":
			_draw_diamond(center, scale, accent, light)
		"Champion":
			_draw_champion(center, scale, accent, light)
		"Grand Champion":
			_draw_grand_champion(center, scale, accent, light)
		"Supersonic Legend":
			_draw_ssl(center, scale, accent, light)
		_:
			_draw_unranked(center, scale, accent)

	if family not in ["Unranked", "Supersonic Legend"]:
		_draw_tier_pips(center, scale, accent)


func _draw_bronze(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	for index in range(3):
		var height := 14.0 + float(index) * 7.0
		var rect := Rect2(
			center + Vector2((-18.0 + float(index) * 13.0) * scale, (17.0 - height) * scale),
			Vector2(8.0 * scale, height * scale)
		)
		draw_rect(rect, accent if index != 1 else light, true)
		draw_rect(rect, Color(1, 1, 1, 0.22), false, maxf(1.0, scale))


func _draw_silver(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	for offset in [-10.0, 4.0]:
		var chevron := _scaled_points(
			[Vector2(-22, offset - 6), Vector2(0, offset + 8), Vector2(22, offset - 6), Vector2(17, offset - 13), Vector2(0, offset - 2), Vector2(-17, offset - 13)],
			center,
			scale
		)
		draw_colored_polygon(chevron, light if offset < 0 else accent)


func _draw_gold(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	var crown := _scaled_points(
		[Vector2(-24, 16), Vector2(-20, -16), Vector2(-6, -4), Vector2(0, -24), Vector2(7, -4), Vector2(21, -16), Vector2(24, 16)],
		center,
		scale
	)
	draw_colored_polygon(crown, accent)
	_draw_closed_outline(crown, light, maxf(1.0, scale * 1.4))
	draw_line(center + Vector2(-20, 8) * scale, center + Vector2(20, 8) * scale, light, maxf(1.0, scale * 2.0), true)


func _draw_platinum(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	var outer := _scaled_points([Vector2(0, -29), Vector2(24, 0), Vector2(0, 29), Vector2(-24, 0)], center, scale)
	var inner := _scaled_points([Vector2(0, -17), Vector2(13, 0), Vector2(0, 17), Vector2(-13, 0)], center, scale)
	draw_colored_polygon(outer, Color(accent.r, accent.g, accent.b, 0.88))
	_draw_closed_outline(outer, light, maxf(1.0, scale * 1.5))
	draw_colored_polygon(inner, Color(0.03, 0.09, 0.16, 0.92))
	_draw_closed_outline(inner, light, maxf(1.0, scale))


func _draw_diamond(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	var diamond := _scaled_points([Vector2(0, -30), Vector2(27, -5), Vector2(16, 25), Vector2(-16, 25), Vector2(-27, -5)], center, scale)
	draw_colored_polygon(diamond, Color(accent.r, accent.g, accent.b, 0.84))
	_draw_closed_outline(diamond, light, maxf(1.0, scale * 1.7))
	draw_line(center + Vector2(0, -29) * scale, center + Vector2(0, 24) * scale, Color(1, 1, 1, 0.42), maxf(1.0, scale), true)
	draw_line(center + Vector2(-26, -5) * scale, center + Vector2(26, -5) * scale, Color(1, 1, 1, 0.26), maxf(1.0, scale), true)


func _draw_champion(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	var left := _scaled_points([Vector2(-4, -21), Vector2(-29, -14), Vector2(-18, 1), Vector2(-31, 12), Vector2(-8, 20), Vector2(0, 5)], center, scale)
	var right := _mirror_points(left, center)
	draw_colored_polygon(left, accent)
	draw_colored_polygon(right, accent)
	_draw_closed_outline(left, light, maxf(1.0, scale * 1.2))
	_draw_closed_outline(right, light, maxf(1.0, scale * 1.2))
	draw_circle(center, 8.0 * scale, light)


func _draw_grand_champion(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	var points: Array[Vector2] = []
	for index in range(16):
		var radius := 29.0 if index % 2 == 0 else 14.0
		var angle := -PI * 0.5 + float(index) * TAU / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var star := _scaled_points(points, center, scale)
	draw_colored_polygon(star, accent)
	_draw_closed_outline(star, light, maxf(1.0, scale * 1.25))
	draw_circle(center, 7.0 * scale, Color(0.08, 0.02, 0.10, 0.88))


func _draw_ssl(center: Vector2, scale: float, accent: Color, light: Color) -> void:
	draw_arc(center, 27.0 * scale, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.94), maxf(2.0, scale * 3.0), true)
	draw_arc(center, 17.0 * scale, 0.0, TAU, 40, Color(0.55, 0.42, 1.0, 0.84), maxf(1.5, scale * 2.0), true)
	var core := _scaled_points([Vector2(0, -15), Vector2(13, 8), Vector2(0, 17), Vector2(-13, 8)], center, scale)
	draw_colored_polygon(core, light)
	for angle in [-2.45, -0.69, 1.57]:
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * 30.0 * scale, center + direction * 38.0 * scale, Color(0.64, 0.46, 1.0, 0.86), maxf(1.2, scale * 2.0), true)


func _draw_unranked(center: Vector2, scale: float, accent: Color) -> void:
	draw_arc(center, 23.0 * scale, 0.0, TAU, 36, accent, maxf(1.5, scale * 2.5), true)
	draw_line(center + Vector2(-8, -8) * scale, center + Vector2(0, -16) * scale, accent, maxf(1.5, scale * 2.0), true)
	draw_line(center + Vector2(0, -16) * scale, center + Vector2(9, -8) * scale, accent, maxf(1.5, scale * 2.0), true)
	draw_line(center + Vector2(9, -8) * scale, center + Vector2(0, 4) * scale, accent, maxf(1.5, scale * 2.0), true)
	draw_circle(center + Vector2(0, 15) * scale, 2.5 * scale, accent)


func _draw_tier_pips(center: Vector2, scale: float, accent: Color) -> void:
	var count := clampi(tier, 1, 3)
	var start_x := -float(count - 1) * 5.0
	for index in range(count):
		draw_circle(center + Vector2(start_x + float(index) * 10.0, 31.0) * scale, 2.5 * scale, accent.lightened(0.18))


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
