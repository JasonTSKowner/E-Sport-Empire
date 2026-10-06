class_name ArenaTrainingCameraV251
extends "res://scripts/arena_3d_stage_v252.gd"


func set_training_state(
	car_position: Vector2,
	car_velocity: Vector2,
	car_target: Vector2,
	ball_position: Vector2,
	ball_height: float,
	future_ball: Vector2,
	future_ball_height: float,
	target_position: Vector2,
	phase_label: String,
	color: Color
) -> void:
	super.set_training_state(
		car_position, car_velocity, car_target,
		ball_position, ball_height, future_ball, future_ball_height,
		target_position, phase_label, color
	)
	var midpoint := car_position.lerp(ball_position, 0.42)
	var focus := _to_world(midpoint, minf(ball_height * 0.32, 0.28))
	focus.y = 0.70 + minf(ball_height * 0.52, 0.68)
	var separation := car_position.distance_to(ball_position)
	var desired := Vector3(focus.x * 0.10, 8.2 + separation * 1.7, 14.0 + separation * 2.7)
	camera_3d.fov = 50.0
	camera_3d.position = camera_3d.position.lerp(desired, 0.28)
	camera_focus = camera_focus.lerp(focus, 0.32)
	camera_3d.look_at_from_position(camera_3d.position, camera_focus, Vector3.UP)
