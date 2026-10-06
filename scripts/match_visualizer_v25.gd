class_name MatchVisualizerV25
extends "res://scripts/match_visualizer_v242.gd"

const Arena3DV25 = preload("res://scripts/arena_3d_view_v251.gd")
const V25_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var arena_3d: Arena3DViewV251


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 492.0)
	_create_3d_arena()


func _create_3d_arena() -> void:
	if arena_3d != null and is_instance_valid(arena_3d):
		return
	arena_3d = Arena3DV25.new()
	arena_3d.name = "Arena3D"
	arena_3d.team_color = OUR_COLOR
	arena_3d.enemy_color = THEIR_COLOR
	arena_3d.training_mode = false
	arena_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_3d.offset_left = 7.0
	arena_3d.offset_right = -7.0
	arena_3d.offset_top = 58.0
	arena_3d.offset_bottom = -34.0
	arena_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_3d)
	arena_3d.configure(OUR_COLOR, THEIR_COLOR, false)


func _process(delta: float) -> void:
	super._process(delta)
	if arena_3d == null or not is_instance_valid(arena_3d):
		return
	arena_3d.sync_match(
		our_positions,
		their_positions,
		our_velocities,
		their_velocities,
		ball_position,
		ball_height,
		ball_target,
		ball_target_height,
		our_targets,
		active_actor,
		support_actor
	)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("02050A"), true)
	var accent := OUR_COLOR if momentum >= 0 else THEIR_COLOR
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else _phase_title_v24(phase)
	var subtitle := "TEAM COMBO" if not combo_id.is_empty() else _phase_title_v24(phase)

	draw_string(V25_FONT, Vector2(12, 23), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color(0.95, 0.98, 1.0, 0.98))
	draw_string(V25_FONT, Vector2(12, 42), subtitle, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 8, Color(0.58, 0.72, 0.82, 0.88))

	var pressure := clampf((float(momentum) + 100.0) / 200.0, 0.0, 1.0)
	draw_rect(Rect2(12, 49, size.x - 24, 3), Color(1, 1, 1, 0.07), true)
	draw_rect(Rect2(12, 49, (size.x - 24) * pressure, 3), accent, true)

	var role_text := "1ST  ACTIVE   ·   2ND  SUPPORT   ·   3RD  SAFETY"
	draw_string(V25_FONT, Vector2(12, size.y - 17), role_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 7, Color(0.58, 0.70, 0.79, 0.70))

	if not mechanic_components.is_empty():
		var mastery := "SET %d   CTRL %d   READ %d   FIN %d" % [
			int(mechanic_components.get("setup", 0)),
			int(mechanic_components.get("control", 0)),
			int(mechanic_components.get("read", 0)),
			int(mechanic_components.get("finish", 0))
		]
		draw_string(V25_FONT, Vector2(12, size.y - 5), mastery, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 7, Color(0.70, 0.80, 0.87, 0.70))

	if phase == "mechanic_fail":
		draw_rect(Rect2(10, 55, size.x - 20, 25), Color(0.34, 0.045, 0.055, 0.90), true)
		draw_string(V25_FONT, Vector2(18, 73), "PLAY VERLOREN  ·  RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 9, Color(1.0, 0.84, 0.86, 0.98))

	if goal_flash > 0.01:
		var c := OUR_COLOR if goal_side > 0 else THEIR_COLOR
		draw_rect(Rect2(7, 58, size.x - 14, size.y - 92), Color(c.r, c.g, c.b, goal_flash * 0.09), true)
