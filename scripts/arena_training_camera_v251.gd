class_name ArenaTrainingCameraV251
extends "res://scripts/arena_3d_stage.gd"


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
	# Training needs both the approach and the ball visible at once; follow their midpoint instead of only the ball.
	var midpoint := car_position.lerp(ball_position, 0.52)
	var focus := _to_world(midpoint, minf(ball_height * 0.35, 0.30))
	focus.y = 0.72 + minf(ball_height * 0.55, 0.72)
	var separation := car_position.distance_to(ball_position)
	var desired := Vector3(focus.x * 0.12, 8.0 + separation * 1.8, 13.5 + separation * 2.4)
	camera_3d.fov = 46.0
	camera_3d.position = camera_3d.position.lerp(desired, 0.24)
	camera_focus = camera_focus.lerp(focus, 0.28)
	camera_3d.look_at_from_position(camera_3d.position, camera_focus, Vector3.UP)
