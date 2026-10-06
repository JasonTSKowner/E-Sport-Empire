class_name Arena3DStage
extends SubViewportContainer

const OUR_COLOR := Color("76E3FF")
const THEIR_COLOR := Color("FF667C")
const FIELD_COLOR := Color("07141C")
const BOARD_COLOR := Color("111A24")
const GOLD := Color("E5B862")

var viewport_3d: SubViewport
var world_root: Node3D
var camera_3d: Camera3D
var key_light: DirectionalLight3D
var fill_light: OmniLight3D
var ball_node: MeshInstance3D
var prediction_mesh: MeshInstance3D
var rotation_mesh: MeshInstance3D
var target_marker: MeshInstance3D
var our_cars: Array = []
var their_cars: Array = []
var team_count := 1
var training_mode := false
var built := false
var current_phase := "kickoff"
var camera_home := Vector3(0.0, 13.8, 17.8)
var camera_focus := Vector3.ZERO
var accent := OUR_COLOR


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 448.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_ensure_built()


func _ensure_built() -> void:
	if built:
		return

	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(640, 640)
	viewport_3d.transparent_bg = false
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)

	world_root = Node3D.new()
	viewport_3d.add_child(world_root)

	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("020407")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("89AFC9")
	env.ambient_light_energy = 0.72
	world_environment.environment = env
	world_root.add_child(world_environment)

	camera_3d = Camera3D.new()
	camera_3d.fov = 48.0
	camera_3d.near = 0.1
	camera_3d.far = 80.0
	camera_3d.position = camera_home
	world_root.add_child(camera_3d)
	camera_3d.current = true
	camera_3d.look_at_from_position(camera_home, Vector3.ZERO, Vector3.UP)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	key_light.light_color = Color("C8E8FF")
	key_light.light_energy = 1.4
	key_light.shadow_enabled = true
	world_root.add_child(key_light)

	fill_light = OmniLight3D.new()
	fill_light.position = Vector3(0.0, 6.5, 1.0)
	fill_light.omni_range = 25.0
	fill_light.light_color = Color("68CFFC")
	fill_light.light_energy = 3.2
	world_root.add_child(fill_light)

	_build_arena_geometry()
	_build_ball()
	prediction_mesh = MeshInstance3D.new()
	rotation_mesh = MeshInstance3D.new()
	world_root.add_child(prediction_mesh)
	world_root.add_child(rotation_mesh)
	_build_target_marker()

	built = true
	configure_team_count(team_count)


func _build_arena_geometry() -> void:
	_add_box(Vector3(22.4, 0.22, 13.2), Vector3(0.0, -0.11, 0.0), _material(FIELD_COLOR, Color("07141C"), 0.08, 0.80))

	# Center line and soft lane markers.
	_add_box(Vector3(0.06, 0.025, 12.2), Vector3(0.0, 0.015, 0.0), _material(Color("8FB5C9"), Color("5BBCE7"), 0.35, 0.60))
	for x in [-7.0, -3.5, 3.5, 7.0]:
		_add_box(Vector3(0.025, 0.018, 12.0), Vector3(x, 0.012, 0.0), _material(Color("27404E"), Color("173240"), 0.12, 0.85))

	# Arena boards.
	_add_box(Vector3(22.8, 0.85, 0.24), Vector3(0.0, 0.42, -6.45), _material(BOARD_COLOR, Color("1D4A5B"), 0.22, 0.72))
	_add_box(Vector3(22.8, 0.85, 0.24), Vector3(0.0, 0.42, 6.45), _material(BOARD_COLOR, Color("1D4A5B"), 0.22, 0.72))
	_add_box(Vector3(0.24, 0.85, 13.1), Vector3(-11.25, 0.42, 0.0), _material(BOARD_COLOR, Color("173B4B"), 0.18, 0.72))
	_add_box(Vector3(0.24, 0.85, 13.1), Vector3(11.25, 0.42, 0.0), _material(BOARD_COLOR, Color("4A2330"), 0.18, 0.72))

	# Stadium stands and light strips.
	_add_box(Vector3(24.0, 2.2, 1.35), Vector3(0.0, 1.0, -7.6), _material(Color("070B11"), Color("10212B"), 0.12, 0.92))
	_add_box(Vector3(24.0, 2.2, 1.35), Vector3(0.0, 1.0, 7.6), _material(Color("070B11"), Color("10212B"), 0.12, 0.92))
	_add_box(Vector3(21.0, 0.08, 0.16), Vector3(0.0, 2.15, -6.92), _material(Color("D8F3FF"), Color("9DE8FF"), 1.8, 0.18))
	_add_box(Vector3(21.0, 0.08, 0.16), Vector3(0.0, 2.15, 6.92), _material(Color("D8F3FF"), Color("9DE8FF"), 1.8, 0.18))

	_build_goal(-1)
	_build_goal(1)
	_build_boost_pads()


func _build_goal(side: int) -> void:
	var x := 10.95 * float(side)
	var color := OUR_COLOR if side < 0 else THEIR_COLOR
	var mat := _material(color.darkened(0.55), color, 1.0, 0.35)
	_add_box(Vector3(0.18, 2.9, 0.18), Vector3(x, 1.45, -2.15), mat)
	_add_box(Vector3(0.18, 2.9, 0.18), Vector3(x, 1.45, 2.15), mat)
	_add_box(Vector3(0.18, 0.18, 4.48), Vector3(x, 2.86, 0.0), mat)
	_add_box(Vector3(1.2, 0.12, 4.48), Vector3(x + 0.58 * float(side), 0.08, 0.0), _material(Color("0B1118"), color, 0.20, 0.80))


func _build_boost_pads() -> void:
	var pads := [
		Vector2(0.16, 0.18), Vector2(0.16, 0.82), Vector2(0.35, 0.34), Vector2(0.35, 0.66),
		Vector2(0.50, 0.20), Vector2(0.50, 0.80), Vector2(0.65, 0.34), Vector2(0.65, 0.66),
		Vector2(0.84, 0.18), Vector2(0.84, 0.82)
	]
	for pad in pads:
		var mesh_instance := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.24
		mesh.bottom_radius = 0.24
		mesh.height = 0.035
		mesh.radial_segments = 20
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _material(GOLD.darkened(0.28), GOLD, 1.1, 0.34)
		mesh_instance.position = _to_world(pad, 0.0) + Vector3(0.0, -0.21, 0.0)
		world_root.add_child(mesh_instance)


func _build_ball() -> void:
	ball_node = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.72
	sphere.radial_segments = 24
	sphere.rings = 12
	ball_node.mesh = sphere
	ball_node.material_override = _material(Color("EAF4FB"), Color("BDEEFF"), 0.40, 0.30)
	world_root.add_child(ball_node)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.14
	core_mesh.height = 0.28
	core.mesh = core_mesh
	core.material_override = _material(Color("6A7680"), Color("456C80"), 0.22, 0.55)
	ball_node.add_child(core)


func _build_target_marker() -> void:
	target_marker = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.70
	mesh.bottom_radius = 0.70
	mesh.height = 0.025
	mesh.radial_segments = 28
	target_marker.mesh = mesh
	target_marker.material_override = _material(Color(0.20, 0.75, 0.95, 0.16), Color("63DFFF"), 0.9, 0.68)
	target_marker.visible = false
	world_root.add_child(target_marker)


func configure_team_count(count: int) -> void:
	team_count = maxi(1, count)
	_ensure_built()
	for node in our_cars:
		if is_instance_valid(node):
			node.free()
	for node in their_cars:
		if is_instance_valid(node):
			node.free()
	our_cars.clear()
	their_cars.clear()

	for _i in range(team_count):
		var ours := _make_car(OUR_COLOR)
		world_root.add_child(ours)
		our_cars.append(ours)
		var theirs := _make_car(THEIR_COLOR)
		world_root.add_child(theirs)
		their_cars.append(theirs)


func set_training_mode(enabled: bool, color: Color = OUR_COLOR) -> void:
	training_mode = enabled
	accent = color
	_ensure_built()
	for car in their_cars:
		if is_instance_valid(car):
			car.visible = not enabled
	target_marker.visible = enabled
	fill_light.light_color = color


func set_match_state(
	our_positions: Array,
	their_positions: Array,
	our_velocities: Array,
	their_velocities: Array,
	our_targets: Array,
	ball_position: Vector2,
	ball_height: float,
	ball_target: Vector2,
	ball_target_height: float,
	active_actor: int,
	support_actor: int,
	phase: String,
	goal_flash: float
) -> void:
	_ensure_built()
	if our_cars.size() != our_positions.size():
		configure_team_count(our_positions.size())
	set_training_mode(false)
	current_phase = phase

	for i in range(our_cars.size()):
		var height := _car_height_for_phase(i, active_actor, support_actor, phase, ball_height)
		_place_car(our_cars[i], our_positions[i], our_velocities[i], height, i == active_actor, i == support_actor, phase)
	for i in range(their_cars.size()):
		_place_car(their_cars[i], their_positions[i], their_velocities[i], 0.0, false, false, phase)

	ball_node.position = _to_world(ball_position, ball_height)
	ball_node.rotation.y += 0.035
	_update_prediction(ball_position, ball_height, ball_target, ball_target_height, Color("DDF6FF"))
	_update_rotations(our_positions, our_targets, active_actor, support_actor)
	_update_camera(ball_position, ball_height, phase, goal_flash)
	key_light.light_energy = 1.4 + goal_flash * 1.7
	fill_light.light_energy = 3.2 + goal_flash * 3.0


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
	_ensure_built()
	if our_cars.size() != 1:
		configure_team_count(1)
	set_training_mode(true, color)
	current_phase = phase_label.to_lower()
	_place_car(our_cars[0], car_position, car_velocity, _training_car_height(ball_height, phase_label), true, false, phase_label.to_lower())
	ball_node.position = _to_world(ball_position, ball_height)
	ball_node.rotation.y += 0.03
	target_marker.position = _to_world(target_position, 0.0) + Vector3(0.0, -0.20, 0.0)
	_update_prediction(ball_position, ball_height, future_ball, future_ball_height, color)
	_update_rotations([car_position], [car_target], 0, -1)
	_update_camera(ball_position, ball_height, phase_label.to_lower(), 0.0)


func _place_car(node: Node3D, pos: Vector2, velocity: Vector2, height: float, active: bool, support: bool, phase: String) -> void:
	var world_pos := _to_world(pos, height)
	node.position = world_pos
	var yaw := 0.0
	if velocity.length() > 0.015:
		yaw = atan2(-velocity.y, velocity.x)
	var pitch := 0.0
	var roll := 0.0
	if active:
		if phase in ["musty_load", "musty_release", "backwall_musty"]:
			pitch = 0.72
		elif phase in ["reset_contact", "reset_control", "reset_1", "reset_2", "reset_3", "reset_4", "second_reset", "third_reset"]:
			pitch = -0.30
			roll = 0.35
		elif phase in ["psycho_contact", "psycho_setup", "own_wall_carry"]:
			roll = -0.52
			pitch = 0.18
		elif phase in ["pogo_drop", "pogo_bounce"]:
			pitch = 0.52
		elif phase in ["ceiling_setup", "ceiling_drop"]:
			roll = PI * 0.88
	if support and phase in ["prejump", "teammate_prejump", "redirect_finish", "redirect_read"]:
		pitch = -0.25
		roll = 0.18
	node.rotation = Vector3(pitch, yaw, roll)

	var ring := node.get_node_or_null("Ring") as MeshInstance3D
	if ring != null:
		ring.visible = active or support
		ring.scale = Vector3.ONE * (1.18 if active else 0.88)
		var ring_color := OUR_COLOR if active else Color("9FA9FF")
		ring.material_override = _material(Color(ring_color.r, ring_color.g, ring_color.b, 0.22), ring_color, 1.2, 0.72)

	var glow := node.get_node_or_null("Glow") as OmniLight3D
	if glow != null:
		glow.visible = active
		glow.light_energy = 1.8 if active else 0.0


func _make_car(color: Color) -> Node3D:
	var root := Node3D.new()

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.45, 0.34, 0.78)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.37, 0.0)
	body.material_override = _material(color.darkened(0.48), color, 0.38, 0.42)
	root.add_child(body)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(0.66, 0.30, 0.63)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(-0.12, 0.67, 0.0)
	cabin.material_override = _material(Color("14212C"), Color("2D6378"), 0.22, 0.18)
	root.add_child(cabin)

	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.36, 0.12, 0.58)
	nose.mesh = nose_mesh
	nose.position = Vector3(0.80, 0.34, 0.0)
	nose.material_override = _material(color.darkened(0.22), color, 0.48, 0.36)
	root.add_child(nose)

	for wheel_pos in [Vector3(0.48,0.18,-0.43), Vector3(0.48,0.18,0.43), Vector3(-0.48,0.18,-0.43), Vector3(-0.48,0.18,0.43)]:
		var wheel := MeshInstance3D.new()
		var wheel_mesh := BoxMesh.new()
		wheel_mesh.size = Vector3(0.30, 0.30, 0.16)
		wheel.mesh = wheel_mesh
		wheel.position = wheel_pos
		wheel.material_override = _material(Color("050608"), Color("0A0E12"), 0.05, 0.92)
		root.add_child(wheel)

	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.0, 0.035, 0.82)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0.05, 0.56, 0.0)
	stripe.material_override = _material(color, color, 1.25, 0.22)
	root.add_child(stripe)

	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.78
	ring_mesh.bottom_radius = 0.78
	ring_mesh.height = 0.025
	ring_mesh.radial_segments = 28
	ring.mesh = ring_mesh
	ring.position = Vector3(0.0, -0.02, 0.0)
	ring.visible = false
	root.add_child(ring)

	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.position = Vector3(0.0, 1.0, 0.0)
	glow.omni_range = 4.0
	glow.light_color = color
	glow.light_energy = 0.0
	glow.visible = false
	root.add_child(glow)
	return root


func _update_prediction(start: Vector2, start_height: float, target: Vector2, target_height: float, color: Color) -> void:
	var mesh := ImmediateMesh.new()
	var mat := _material(Color(color.r, color.g, color.b, 0.72), color, 1.3, 0.35)
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
	for i in range(19):
		var t := float(i) / 18.0
		var p2 := start.lerp(target, t)
		var h := lerpf(start_height, target_height, t) + sin(t * PI) * 0.28
		mesh.surface_add_vertex(_to_world(p2, h))
	mesh.surface_end()
	prediction_mesh.mesh = mesh


func _update_rotations(positions: Array, targets: Array, active_actor: int, support_actor: int) -> void:
	var mesh := ImmediateMesh.new()
	for i in range(mini(positions.size(), targets.size())):
		var color := OUR_COLOR
		if i == support_actor:
			color = Color("9FA9FF")
		elif i != active_actor:
			color = Color("4F7F91")
		var mat := _material(Color(color.r, color.g, color.b, 0.55), color, 0.75 if i == active_actor else 0.32, 0.62)
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
		var from := _to_world(positions[i], 0.0) + Vector3(0.0, 0.03, 0.0)
		var to := _to_world(targets[i], 0.0) + Vector3(0.0, 0.03, 0.0)
		mesh.surface_add_vertex(from)
		mesh.surface_add_vertex(from.lerp(to, 0.45))
		mesh.surface_add_vertex(to)
		mesh.surface_end()
	rotation_mesh.mesh = mesh


func _update_camera(ball_pos: Vector2, ball_height: float, phase: String, goal_flash: float) -> void:
	var focus := _to_world(ball_pos, minf(ball_height * 0.55, 0.45))
	focus.y *= 0.38
	var mechanical := phase in [
		"wall_setup", "air_carry", "air_carry_2", "musty_load", "musty_release",
		"reset_contact", "reset_control", "reset_1", "reset_2", "reset_3", "reset_4",
		"psycho_setup", "own_wall_carry", "backwall_musty", "psycho_contact",
		"prejump", "teammate_prejump", "redirect_finish", "ceiling_setup", "ceiling_drop",
		"pogo_drop", "pogo_bounce"
	]
	var desired := camera_home
	if mechanical:
		desired = Vector3(focus.x * 0.22, 10.8, 14.3 + abs(focus.z) * 0.12)
	elif goal_flash > 0.05:
		desired = Vector3(focus.x * 0.10, 12.2, 15.5)
	else:
		desired.x = focus.x * 0.10
	camera_3d.position = camera_3d.position.lerp(desired, 0.12)
	camera_focus = camera_focus.lerp(focus, 0.16)
	camera_3d.look_at_from_position(camera_3d.position, camera_focus, Vector3.UP)


func _car_height_for_phase(index: int, active_actor: int, support_actor: int, phase: String, ball_height: float) -> float:
	if index == active_actor and phase in [
		"air_carry", "air_carry_2", "reset_contact", "reset_control", "reset_1", "reset_2", "reset_3", "reset_4",
		"second_reset", "third_reset", "musty_load", "musty_release", "backwall_musty", "psycho_contact",
		"ceiling_setup", "ceiling_drop", "pogo_drop", "pogo_bounce"
	]:
		return maxf(0.18, ball_height * 0.86)
	if index == support_actor and phase in ["prejump", "teammate_prejump", "redirect_finish", "redirect_read"]:
		return maxf(0.12, ball_height * 0.72)
	return 0.0


func _training_car_height(ball_height: float, phase_label: String) -> float:
	var label := phase_label.to_upper()
	if "AIR" in label or "RESET" in label or "CEILING" in label or "PSYCHO" in label or "MUSTY" in label or "REDIRECT" in label:
		return maxf(0.12, ball_height * 0.82)
	return 0.0


func _to_world(position: Vector2, height: float) -> Vector3:
	return Vector3((position.x - 0.5) * 20.0, 0.28 + height * 4.6, (position.y - 0.5) * 11.0)


func _add_box(size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	world_root.add_child(instance)
	return instance


func _material(color: Color, emission_color: Color, emission_energy: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.08
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_energy
	return material