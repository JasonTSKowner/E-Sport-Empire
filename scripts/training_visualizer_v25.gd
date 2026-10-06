class_name TrainingVisualizerV25
extends "res://scripts/training_visualizer_v23.gd"

const Arena3DRef = preload("res://scripts/arena_3d_stage.gd")
const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var arena_3d: Arena3DStage
var mechanic_label_2d: Label
var step_label_2d: Label
var status_label_2d: Label


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 470.0)
	_build_3d_surface()
	_sync_3d()


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 470.0)
	if arena_3d != null:
		arena_3d.configure_team_count(1)
		arena_3d.set_training_mode(true, color)
	_refresh_overlay()
	_sync_3d()


func _process(delta: float) -> void:
	super._process(delta)
	_refresh_overlay()
	_sync_3d()


func _draw() -> void:
	# v2.5 replaces the old flat training diagram with a 3D replay stage.
	pass


func _build_3d_surface() -> void:
	if arena_3d != null:
		return
	arena_3d = Arena3DRef.new()
	arena_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_3d.offset_left = 0
	arena_3d.offset_top = 0
	arena_3d.offset_right = 0
	arena_3d.offset_bottom = 0
	arena_3d.configure_team_count(1)
	arena_3d.set_training_mode(true, accent)
	add_child(arena_3d)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 10
	top.offset_top = 10
	top.offset_right = -10
	top.offset_bottom = 68
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.022, 0.032, 0.84)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.14)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	top.add_theme_stylebox_override("panel", style)
	add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	top.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -1)
	mechanic_label_2d = Label.new()
	mechanic_label_2d.text = "MECHANIK-LABOR"
	mechanic_label_2d.add_theme_font_override("font", FONT)
	mechanic_label_2d.add_theme_font_size_override("font_size", 15)
	mechanic_label_2d.add_theme_color_override("font_color", Color("F2F7FA"))
	copy.add_child(mechanic_label_2d)
	step_label_2d = Label.new()
	step_label_2d.text = "SETUP"
	step_label_2d.add_theme_font_override("font", FONT)
	step_label_2d.add_theme_font_size_override("font_size", 8)
	step_label_2d.add_theme_color_override("font_color", Color("8CA5B5"))
	copy.add_child(step_label_2d)
	row.add_child(copy)

	status_label_2d = Label.new()
	status_label_2d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label_2d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label_2d.add_theme_font_override("font", FONT)
	status_label_2d.add_theme_font_size_override("font_size", 8)
	status_label_2d.add_theme_color_override("font_color", accent)
	row.add_child(status_label_2d)
	_refresh_overlay()


func _refresh_overlay() -> void:
	if mechanic_label_2d == null:
		return
	var shown := signature_label.to_upper() if not signature_label.is_empty() else drill_label.to_upper()
	mechanic_label_2d.text = shown
	step_label_2d.text = _current_step_label(drill_phase).to_upper()
	status_label_2d.text = "FOKUS %d/%d\nMÜDE %d" % [focus_remaining, focus_limit, fatigue]


func _sync_3d() -> void:
	if arena_3d == null:
		return
	var future_t := minf(0.999, drill_phase + 0.16)
	var car_target := _car_target_for_drill(future_t)
	var future_ball := _ball_target_for_drill(future_t)
	var future_height := _ball_height_for_drill(future_t)
	arena_3d.set_training_state(
		car_position,
		car_velocity,
		car_target,
		ball_position,
		ball_height,
		future_ball,
		future_height,
		target_position,
		_current_step_label(drill_phase),
		accent
	)
