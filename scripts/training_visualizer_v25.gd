class_name TrainingVisualizerV25
extends "res://scripts/training_visualizer_v242.gd"

const Arena3DV25 = preload("res://scripts/arena_3d_view_v25.gd")
const V25_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var arena_3d: Arena3DViewV25


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 460.0)
	_create_3d_arena()


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 460.0)


func _create_3d_arena() -> void:
	if arena_3d != null and is_instance_valid(arena_3d):
		return
	arena_3d = Arena3DV25.new().configure(accent, Color("FF6B7A"), true)
	arena_3d.name = "TrainingArena3D"
	arena_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_3d.offset_left = 7.0
	arena_3d.offset_right = -7.0
	arena_3d.offset_top = 58.0
	arena_3d.offset_bottom = -27.0
	arena_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_3d)


func _process(delta: float) -> void:
	super._process(delta)
	if arena_3d == null or not is_instance_valid(arena_3d):
		return
	var future_t := minf(0.999, drill_phase + 0.16)
	var future_ball := _ball_target_for_drill(future_t)
	var future_height := _ball_height_for_drill(future_t)
	arena_3d.sync_training(
		car_position,
		car_velocity,
		ball_position,
		ball_height,
		future_ball,
		future_height,
		target_position,
		focus_family
	)


func _draw() -> void:
	# Gameplay is intentionally delegated to the 3D viewport. Keep only the
	# information that explains the drill and the current execution phase.
	draw_rect(Rect2(Vector2.ZERO, size), Color("02050A"), true)
	var mechanic := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	var category := str(focus_mechanic.get("category", "TRAINING")).to_upper() if not focus_mechanic.is_empty() else "TRAINING"
	var current_step := _current_step_label(drill_phase)

	draw_string(V25_FONT, Vector2(12, 24), mechanic, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color(0.95, 0.98, 1.0, 0.98))
	draw_string(V25_FONT, Vector2(12, 43), "%s  ·  %s" % [category, current_step], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.60, 0.74, 0.84, 0.88))

	var ratio := float(focus_remaining) / float(maxi(1, focus_limit))
	draw_rect(Rect2(12, 49, size.x - 24, 3), Color(1, 1, 1, 0.07), true)
	draw_rect(Rect2(12, 49, (size.x - 24) * ratio, 3), accent, true)

	var footer := "FOKUS %d/%d   ·   MÜDIGKEIT %d   ·   LIVE 3D" % [focus_remaining, focus_limit, fatigue]
	draw_string(V25_FONT, Vector2(12, size.y - 8), footer, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.64, 0.75, 0.83, 0.72))
