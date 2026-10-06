extends "res://scripts/cinematic_shell_v25.gd"


func _home_3d_hero_v25() -> Control:
	var root := super._home_3d_hero_v25()
	# Fill almost the full mobile content area with the arena instead of leaving dashboard dead space.
	root.custom_minimum_size.y = 700.0

	# The old top-right 1V1 badge was visually cramped on narrow phones; the playlist is already clear in Ranked.
	if root.get_child_count() > 1:
		var top := root.get_child(1)
		if top is MarginContainer and top.get_child_count() > 0:
			var row := top.get_child(0)
			if row is HBoxContainer and row.get_child_count() > 1:
				var badge := row.get_child(row.get_child_count() - 1) as Control
				if badge != null:
					badge.visible = false
	return root
