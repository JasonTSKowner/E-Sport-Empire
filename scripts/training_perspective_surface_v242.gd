extends "res://scripts/training_perspective_surface_v241.gd"


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 418.0)


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	custom_minimum_size = Vector2(0.0, 418.0)
