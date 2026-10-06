extends "res://scripts/cinematic_shell_v25.gd"

const ArenaV252 = preload("res://scripts/arena_3d_stage_v252.gd")


func _home_3d_hero_v25() -> Control:
	var root := super._home_3d_hero_v25()
	root.custom_minimum_size.y = 700.0
	_replace_showcase_arena(
		root,
		[Vector2(0.42,0.61)], [Vector2(0.64,0.39)],
		Vector2(0.54,0.49), 0.18, Vector2(0.70,0.43), 0.42,
		"buildup"
	)

	if root.get_child_count() > 1:
		var top := root.get_child(1)
		if top is MarginContainer and top.get_child_count() > 0:
			var row := top.get_child(0)
			if row is HBoxContainer and row.get_child_count() > 1:
				var badge := row.get_child(row.get_child_count() - 1) as Control
				if badge != null:
					badge.visible = false
	return root


func _rank_profile_card(playlist: String) -> Control:
	var root := super._rank_profile_card(playlist)
	_replace_showcase_arena(
		root,
		[Vector2(0.43,0.60)], [Vector2(0.63,0.40)],
		Vector2(0.55,0.48), 0.22, Vector2(0.74,0.44), 0.46,
		"challenge"
	)
	# Let more of the actual arena stay visible above the competitive overlay.
	if root.get_child_count() > 1:
		var panel := root.get_child(1) as Control
		if panel != null:
			panel.offset_top = -126.0
	return root


func _replace_showcase_arena(
	root: Control,
	ours: Array,
	theirs: Array,
	ball_pos: Vector2,
	ball_height: float,
	ball_target: Vector2,
	target_height: float,
	phase_name: String
) -> void:
	if root.get_child_count() == 0:
		return
	var old := root.get_child(0)
	if old == null:
		return
	var upgraded := ArenaV252.new()
	upgraded.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgraded.offset_left = 0
	upgraded.offset_top = 0
	upgraded.offset_right = 0
	upgraded.offset_bottom = 0
	upgraded.configure_team_count(1)
	upgraded.set_match_state(
		ours, theirs,
		[Vector2(0.05,-0.02)], [Vector2(-0.04,0.02)],
		[Vector2(0.53,0.50)],
		ball_pos, ball_height, ball_target, target_height,
		0, -1, phase_name, 0.0
	)
	root.remove_child(old)
	old.queue_free()
	root.add_child(upgraded)
	root.move_child(upgraded, 0)
