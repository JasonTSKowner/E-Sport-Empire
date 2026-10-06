class_name Arena3DViewV252
extends "res://scripts/arena_3d_view_v251.gd"

var ball_path_markers: Array[MeshInstance3D] = []
var rotation_markers: Array[MeshInstance3D] = []
var role_labels: Array[Label3D] = []


func _build_world() -> void:
	super._build_world()
	if world_root == null:
		return
	# Mobile needs slightly exaggerated gameplay pieces to stay readable.
	for car in our_cars:
		car.scale = Vector3.ONE * 1.18
	for car in their_cars:
		car.scale = Vector3.ONE * 1.18
	if ball_root != null:
		ball_root.scale = Vector3.ONE * 1.16
	_build_readability_markers()
	_build_role_labels()


func _build_readability_markers() -> void:
	for i in range(12):
		var mesh := SphereMesh.new()
		mesh.radius = 0.085 + float(i) * 0.003
		mesh.height = mesh.radius * 2.0
		var marker := MeshInstance3D.new()
		marker.mesh = mesh
		marker.material_override = _emissive_material(Color("D9F7FF"), 0.96)
		marker.visible = false
		world_root.add_child(marker)
		ball_path_markers.append(marker)

	for i in range(18):
		var ring := CylinderMesh.new()
		ring.top_radius = 0.14
		ring.bottom_radius = 0.14
		ring.height = 0.032
		var marker := MeshInstance3D.new()
		marker.mesh = ring
		marker.material_override = _emissive_material(Color(team_color.r, team_color.g, team_color.b, 1.0), 0.82)
		marker.visible = false
		world_root.add_child(marker)
		rotation_markers.append(marker)


func _build_role_labels() -> void:
	var labels := ["1ST", "2ND", "3RD"]
	for i in range(our_cars.size()):
		var label := Label3D.new()
		label.text = labels[i] if i < labels.size() else ""
		label.font_size = 44
		label.pixel_size = 0.012
		label.modulate = Color("D9F7FF")
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.94)
		label.outline_size = 10
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, 1.18, 0.0)
		label.no_depth_test = true
		our_cars[i].add_child(label)
		role_labels.append(label)


func sync_match(
	our_positions: Array,
	their_positions: Array,
	our_velocities: Array,
	their_velocities: Array,
	ball_position: Vector2,
	ball_height: float,
	ball_target: Vector2,
	ball_target_height: float,
	our_targets: Array,
	active_actor: int,
	support_actor: int,
	phase_name: String = "",
	mechanic_family: String = ""
) -> void:
	super.sync_match(
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
	_update_ball_path_dots(ball_position, ball_height, ball_target, ball_target_height)
	_update_rotation_dots(our_positions, our_targets, active_actor, support_actor)
	_apply_mechanic_car_pose(active_actor, phase_name, mechanic_family, ball_height)
	_update_role_label_visibility(active_actor, support_actor)


func sync_training(
	car_position: Vector2,
	car_velocity: Vector2,
	ball_position: Vector2,
	ball_height: float,
	future_ball: Vector2,
	future_height: float,
	target_position: Vector2,
	focus_family: String
) -> void:
	super.sync_training(car_position, car_velocity, ball_position, ball_height, future_ball, future_height, target_position, focus_family)
	_update_ball_path_dots(ball_position, ball_height, future_ball, future_height)
	_hide_rotation_dots()
	_apply_training_car_pose(focus_family, ball_height)
	for i in range(role_labels.size()):
		role_labels[i].visible = false


func _update_ball_path_dots(from_pos: Vector2, from_height: float, to_pos: Vector2, to_height: float) -> void:
	var start := _field_to_world(from_pos, 0.32 + from_height * 4.0)
	var finish := _field_to_world(to_pos, 0.32 + to_height * 4.0)
	var distance := start.distance_to(finish)
	for i in range(ball_path_markers.size()):
		var marker := ball_path_markers[i]
		marker.visible = distance > 0.35
		if not marker.visible:
			continue
		var t := float(i + 1) / float(ball_path_markers.size() + 1)
		var point := start.lerp(finish, t)
		point.y += sin(t * PI) * (0.62 + maxf(from_height, to_height) * 1.45)
		marker.position = point
		var fade := 0.84 + t * 0.50
		marker.scale = Vector3.ONE * fade


func _update_rotation_dots(positions: Array, targets: Array, active_actor: int, support_actor: int) -> void:
	_hide_rotation_dots()
	var marker_index := 0
	for car_index in range(mini(3, mini(positions.size(), targets.size()))):
		var from := _field_to_world(positions[car_index], 0.055)
		var to := _field_to_world(targets[car_index], 0.055)
		var dot_count := 7 if car_index == active_actor else 5 if car_index == support_actor else 3
		for j in range(dot_count):
			if marker_index >= rotation_markers.size():
				return
			var t := float(j + 1) / float(dot_count + 1)
			var marker := rotation_markers[marker_index]
			marker.visible = true
			marker.position = from.lerp(to, t)
			var scale_value := 1.50 if car_index == active_actor else 1.08 if car_index == support_actor else 0.76
			marker.scale = Vector3(scale_value, 1.0, scale_value)
			marker_index += 1


func _hide_rotation_dots() -> void:
	for marker in rotation_markers:
		marker.visible = false


func _apply_mechanic_car_pose(active_actor: int, phase_name: String, mechanic_family: String, ball_height: float) -> void:
	if active_actor < 0 or active_actor >= our_cars.size():
		return
	var car := our_cars[active_actor]
	var aerial_families := ["air_dribble", "reset", "multi_reset", "stall", "double_tap", "redirect", "ceiling", "pogo", "psycho"]
	var aerial_phase := phase_name.contains("air") or phase_name.contains("reset") or phase_name.contains("ceiling") or phase_name.contains("psycho") or phase_name.contains("redirect") or phase_name.contains("backboard")
	if mechanic_family in aerial_families or aerial_phase:
		car.position.y = 0.55 + clampf(ball_height, 0.08, 1.0) * 3.25
		car.rotation_degrees.x = -8.0 - clampf(ball_height, 0.0, 1.0) * 12.0
	else:
		car.rotation_degrees.x = 0.0

	if phase_name.contains("sidewall") or phase_name.contains("wall"):
		car.position.y = maxf(car.position.y, 1.15)
		car.rotation_degrees.z = 62.0
	elif phase_name.contains("ceiling"):
		car.position.y = maxf(car.position.y, 3.45)
		car.rotation_degrees.z = 180.0
	else:
		car.rotation_degrees.z = 0.0


func _apply_training_car_pose(focus_family: String, ball_height: float) -> void:
	if our_cars.is_empty():
		return
	var car := our_cars[0]
	var aerial_families := ["air_dribble", "reset", "multi_reset", "stall", "double_tap", "redirect", "ceiling", "pogo", "psycho"]
	if focus_family in aerial_families:
		car.position.y = 0.55 + clampf(ball_height, 0.08, 1.0) * 3.0
		car.rotation_degrees.x = -10.0 - clampf(ball_height, 0.0, 1.0) * 10.0
	else:
		car.rotation_degrees.x = 0.0
		car.rotation_degrees.z = 0.0

	if focus_family == "psycho":
		car.rotation_degrees.z = 48.0
	elif focus_family == "ceiling":
		car.position.y = maxf(car.position.y, 3.35)
		car.rotation_degrees.z = 180.0


func _update_role_label_visibility(active_actor: int, support_actor: int) -> void:
	for i in range(role_labels.size()):
		var label := role_labels[i]
		label.visible = i < our_cars.size() and our_cars[i].visible
		label.modulate = Color("F4FDFF") if i == active_actor else Color("9DEBFA") if i == support_actor else Color("7B8B96")
