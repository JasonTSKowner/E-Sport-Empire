extends "res://scripts/cinematic_shell_v261.gd"

func _home_hero_v243() -> Control:
	var stage := super._home_hero_v243()
	stage.custom_minimum_size.y = 774.0
	return stage
