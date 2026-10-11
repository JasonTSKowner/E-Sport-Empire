extends "res://scripts/cinematic_shell_v26.gd"

func _home_stage_v26() -> Control:
	var stage := super._home_stage_v26()
	stage.custom_minimum_size.y = 560
	return stage

func _ranked_stage_v26() -> Control:
	var stage := super._ranked_stage_v26()
	stage.custom_minimum_size.y = 515
	return stage

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var panel := super._player_profile_panel(player, accent)
	panel.custom_minimum_size.y = 260
	return panel

func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var panel := super._prospect_card(player, accent)
	panel.custom_minimum_size.y = 210
	return panel
