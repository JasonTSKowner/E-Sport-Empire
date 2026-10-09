class_name TrainingVisualizerV25
extends "res://scripts/training_visualizer_v242.gd"

const FONT_V25 = preload("res://assets/fonts/SpaceGrotesk.ttf")

var player_name_v25 := "SPIELER"
var components_v25: Dictionary = {}

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 548.0)

func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 548.0)
	player_name_v25 = str(player.get("name", "SPIELER")).to_upper()
	components_v25 = {}
	if not focus_mechanic.is_empty():
		var mechanic_id := str(focus_mechanic.get("id", ""))
		var all_details: Dictionary = player.get("mechanic_mastery_detail", {})
		components_v25 = (all_details.get(mechanic_id, {}) as Dictionary).duplicate(true)
	queue_redraw()

func _draw() -> void:
	var arena := Rect2(Vector2(5, 72), Vector2(maxf(1.0, size.x - 10.0), maxf(1.0, size.y - 98.0)))
	_v241_draw_backdrop(arena)
	_v241_draw_pitch(arena)
	_v25_context_players(arena)
	_v241_draw_guides(arena)
	_v241_draw_car(arena)
	_v241_draw_ball(arena)
	_v25_hud()

func _v25_context_players(arena: Rect2) -> void:
	if focus_family in ["defense", "save"] or drill_id == "defensive_reads":
		_v25_ghost_car(Vector2(clampf(ball_position.x + 0.12, 0.0, 0.92), clampf(ball_position.y + 0.05, 0.08, 0.92)), arena, Color("FF6B7A"), "ANGREIFER")
	elif drill_id == "finishing_pack":
		_v25_ghost_car(Vector2(0.93, 0.50), arena, Color("FF6B7A"), "KEEPER")
	elif drill_id == "rotation_review":
		_v25_ghost_car(Vector2(0.56, 0.30), arena, Color("74DFF7"), "2ND")
		_v25_ghost_car(Vector2(0.72, 0.70), arena, Color("74DFF7"), "3RD")

func _v25_ghost_car(p: Vector2, arena: Rect2, color: Color, label: String) -> void:
	var center: Vector2 = _v241_project_field(p, arena)
	var scale: float = _v241_depth_scale(p) * 0.92
	draw_circle(center + Vector2(2, 4 * scale), 10 * scale, Color(0, 0, 0, 0.24))
	var body := Rect2(center - Vector2(10, 5) * scale, Vector2(20, 10) * scale)
	draw_rect(body, Color(color.r, color.g, color.b, 0.15), true)
	draw_rect(body, Color(color.r, color.g, color.b, 0.56), false, 1.3)
	draw_string(FONT_V25, center + Vector2(-24, -10 * scale), label, HORIZONTAL_ALIGNMENT_CENTER, 48, 7, Color(color.r, color.g, color.b, 0.68))

func _v25_hud() -> void:
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	draw_string(FONT_V25, Vector2(12, 21), player_name_v25, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 9, Color(0.62, 0.73, 0.82, 0.86))
	draw_string(FONT_V25, Vector2(12, 43), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 18, Color(0.96, 0.98, 1, 0.98))
	draw_string(FONT_V25, Vector2(12, 61), "%s  ·  %s" % [category, step_label], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(accent.r, accent.g, accent.b, 0.88))

	var right := "FOKUS %d/%d   MÜDE %d" % [focus_remaining, focus_limit, fatigue]
	var right_width: float = FONT_V25.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(FONT_V25, Vector2(size.x - 12 - right_width, 21), right, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.74, 0.82, 0.88, 0.74))

	if not components_v25.is_empty():
		var items := [
			["SET", int(components_v25.get("setup", 0))],
			["CTRL", int(components_v25.get("control", 0))],
			["READ", int(components_v25.get("read", 0))],
			["FIN", int(components_v25.get("finish", 0))],
		]
		var cell: float = (size.x - 24.0) / 4.0
		for i in range(4):
			var x := 12.0 + cell * i
			var value := int(items[i][1])
			draw_rect(Rect2(x, size.y - 15, cell - 5, 3), Color(1, 1, 1, 0.055), true)
			draw_rect(Rect2(x, size.y - 15, (cell - 5) * float(value) / 100.0, 3), Color(accent.r, accent.g, accent.b, 0.55), true)
			draw_string(FONT_V25, Vector2(x, size.y - 21), "%s %d" % [str(items[i][0]), value], HORIZONTAL_ALIGNMENT_LEFT, cell - 5, 7, Color(0.66, 0.75, 0.82, 0.72))
