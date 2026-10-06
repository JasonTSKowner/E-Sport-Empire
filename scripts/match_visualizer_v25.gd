class_name MatchVisualizerV25
extends "res://scripts/match_visualizer_v23.gd"

const Arena3DRef = preload("res://scripts/arena_3d_stage.gd")
const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var arena_3d: Arena3DStage
var title_label: Label
var phase_label: Label
var role_label: Label


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 470.0)
	_build_3d_surface()
	_sync_3d()


func configure(session: Dictionary) -> void:
	super.configure(session)
	if arena_3d != null:
		arena_3d.configure_team_count(our_positions.size())
		_sync_3d()


func play_turn(event: Dictionary, action: String, quality: int, new_momentum: int) -> void:
	super.play_turn(event, action, quality, new_momentum)
	_refresh_overlay()
	_sync_3d()


func _process(delta: float) -> void:
	super._process(delta)
	_sync_3d()


func _draw() -> void:
	# v2.5 deliberately removes the old tactical-board renderer.
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
	arena_3d.configure_team_count(maxi(1, our_positions.size()))
	add_child(arena_3d)

	var top_back := PanelContainer.new()
	top_back.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_back.offset_left = 10
	top_back.offset_top = 10
	top_back.offset_right = -10
	top_back.offset_bottom = 68
	top_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.022, 0.032, 0.84)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.55, 0.82, 0.95, 0.10)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	top_back.add_theme_stylebox_override("panel", style)
	add_child(top_back)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	top_back.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -1)
	title_label = Label.new()
	title_label.text = "LIVE MATCH"
	title_label.add_theme_font_override("font", FONT)
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("F2F7FA"))
	copy.add_child(title_label)
	phase_label = Label.new()
	phase_label.text = "KICKOFF"
	phase_label.add_theme_font_override("font", FONT)
	phase_label.add_theme_font_size_override("font_size", 8)
	phase_label.add_theme_color_override("font_color", Color("8CA5B5"))
	copy.add_child(phase_label)
	row.add_child(copy)

	role_label = Label.new()
	role_label.text = "1ST  •  2ND  •  3RD"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	role_label.add_theme_font_override("font", FONT)
	role_label.add_theme_font_size_override("font_size", 8)
	role_label.add_theme_color_override("font_color", Color("76E3FF"))
	row.add_child(role_label)
	_refresh_overlay()


func _refresh_overlay() -> void:
	if title_label == null:
		return
	var title := mechanic_label.to_upper() if not mechanic_label.is_empty() else "LIVE MATCH"
	if not combo_id.is_empty():
		title += "  →  TEAM COMBO"
	title_label.text = title
	phase_label.text = "%s  ·  MOMENTUM %+d" % [_phase_text(phase), momentum]
	var roles: Array[String] = []
	for index in range(our_positions.size()):
		var role := "1ST" if index == 0 else "2ND" if index == 1 else "3RD"
		if index == active_actor:
			role += " BALL"
		elif index == support_actor:
			role += " READ"
		roles.append(role)
	role_label.text = "  •  ".join(roles)


func _sync_3d() -> void:
	if arena_3d == null:
		return
	arena_3d.set_match_state(
		our_positions,
		their_positions,
		our_velocities,
		their_velocities,
		our_targets,
		ball_position,
		ball_height,
		ball_target,
		ball_target_height,
		active_actor,
		support_actor,
		phase,
		goal_flash
	)


func _phase_text(value: String) -> String:
	var labels := {
		"kickoff": "KICKOFF",
		"buildup": "AUFBAU",
		"challenge": "CHALLENGE",
		"rotation_switch": "ROTATION",
		"wall_setup": "WALL SETUP",
		"control_setup": "CONTROL",
		"air_carry": "AIR DRIBBLE",
		"air_carry_2": "AIR CONTROL",
		"air_pass": "AIR PASS",
		"musty_load": "MUSTY SETUP",
		"musty_release": "MUSTY RELEASE",
		"reset_contact": "RESET CONTACT",
		"reset_control": "RESET CONTROL",
		"reset_1": "RESET 1",
		"reset_2": "RESET 2",
		"reset_3": "RESET 3",
		"reset_4": "RESET 4",
		"psycho_setup": "PSYCHO SETUP",
		"own_wall_carry": "OWN WALL CARRY",
		"backwall_musty": "BACKWALL MUSTY",
		"psycho_contact": "PSYCHO TOUCH",
		"teammate_prejump": "TM8 PREJUMP",
		"redirect_finish": "REDIRECT",
		"prejump": "PREJUMP",
		"ceiling_setup": "CEILING SETUP",
		"ceiling_drop": "CEILING DROP",
		"pogo_drop": "POGO DROP",
		"pogo_bounce": "POGO BOUNCE",
		"mechanic_fail": "RECOVERY",
		"goal_ours": "TOR",
		"goal_theirs": "GEGENTOR",
		"chance_ours": "CHANCE",
		"chance_theirs": "DEFENSE"
	}
	return str(labels.get(value, value.replace("_", " ").to_upper()))
