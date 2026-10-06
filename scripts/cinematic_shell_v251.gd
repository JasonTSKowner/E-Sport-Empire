extends "res://scripts/cinematic_shell_v25.gd"


func _home_3d_hero_v25() -> Control:
	var root := super._home_3d_hero_v25()
	# Use the free vertical space as gameplay artwork instead of leaving a dead dashboard area.
	root.custom_minimum_size.y = 650.0

	# The playlist badge in the top-right needs a fixed mobile width so 1V1 never wraps vertically.
	if root.get_child_count() > 1:
		var top := root.get_child(1)
		if top is MarginContainer and top.get_child_count() > 0:
			var row := top.get_child(0)
			if row is HBoxContainer and row.get_child_count() > 1:
				var badge := row.get_child(row.get_child_count() - 1) as Control
				if badge != null:
					badge.custom_minimum_size.x = 58.0
	return root
