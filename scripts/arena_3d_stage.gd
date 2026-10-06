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
var camera_home := Vector3(0.0, 8.7, 14.3)
var camera_focus := Vector3(0.0, 0.75, 0.0)
var accent := OUR_COLOR


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 448.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_ensure_built()
	_sync_viewport_size()


func _process(_delta: float) -> void:
	if built:
		_sync_viewport_size()


func _sync_viewport_size() -> void:
	if viewport_3d == null or size.x < 8.0 or size.y < 8.0:
		return
	var desired := Vector2i(maxi(512, int(size.x * 1.65)), maxi(512, int(size.y * 1.65)))
	if viewport_3d.size != desired:
		viewport_3d.size = desired


func _ensure_built() -> void:
	if built:
		return

	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(680, 760)
	viewport_3d.transparent_bg = false
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)

	world_root = Node3D.new()
	viewport_3d.add_child(world_root)

	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("03070C")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("93C5DF")
	env.ambient_light_energy = 0.88
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = env
	world_root.add_child(world_environment)

	camera_3d = Camera3D.new()
	camera_3d.fov = 42.0
	camera_3d.near = 0.1
	camera_3d.far = 80.0
	camera_3d.position = camera_home
	world_root.add_child(camera_3d)
	camera_3d.current = true
	camera_3d.look_at_from_position(camera_home, camera_focus, Vector3.UP)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-55.0, -32.0, 0.0)
	key_light.light_color = Color("D4EEFF")
	key_light.light_energy = 1.65
	key_light.shadow_enabled = true
	world_root.add_child(key_light)

	fill_light = OmniLight3D.new()
	fill_light.position = Vector3(0.0, 5.8, 1.5)
	fill_light.omni_range = 26.0
	fill_light.light_color = Color("68CFFC")
	fill_light.light_energy = 3.8
	world_root.add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(0.0, 3.2, -7.5)
	rim_light.omni_range = 24.0
	rim_light.light_color = Color("8A7CFF")
	rim_light.light_energy = 1.5
	world_root.add_child(rim_light)

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
	_add_box(Vector3(0.06, 0.025, 12.2), Vector3(0.0, 0.015, 0.0), _material(Color("8FB5C9"), Color("5BBCE7"), 0.38, 0.60))
	for x in [-7.0, -3.5, 3.5, 7.0]:
		_add_box(Vector3(0.025, 0.018, 12.0), Vector3(x, 0.012, 0.0), _material(Color("27404E"), Color("173240"), 0.12, 0.85))

	_add_box(Vector3(22.8, 0.90, 0.24), Vector3(0.0, 0.45, -6.45), _material(BOARD_COLOR, Color("1D4A5B"), 0.28, 0.70))
	_add_box(Vector3(22.8, 0.90, 0.24), Vector3(0.0, 0.45, 6.45), _material(BOARD_COLOR, Color("1D4A5B"), 0.28, 0.70))
	_add_box(Vector3(0.24, 0.90, 13.1), Vector3(-11.25, 0.45, 0.0), _material(BOARD_COLOR, Color("173B4B"), 0.22, 0.70))
	_add_box(Vector3(0.24, 0.90, 13.1), Vector3(11.25, 0.45, 0.0), _material(BOARD_COLOR, Color("4A2330"), 0.22, 0.70))

	# Layered stands keep the horizon alive instead of leaving a black void.
	_add_box(Vector3(24.0, 2.5, 1.45), Vector3(0.0, 1.15, -7.7), _material(Color("070B11"), Color("102936"), 0.18, 0.92))
	_add_box(Vector3(24.0, 2.5, 1.45), Vector3(0.0, 1.15, 7.7), _material(Color("070B11"), Color("102936"), 0.18, 0.92))
	_add_box(Vector3(24.8, 1.8, 0.85), Vector3(0.0, 3.1, -8.25), _material(Color("05080D"), Color("132B37"), 0.12, 0.94))
	_add_box(Vector3(24.8, 1.8, 0.85), Vector3(0.0, 3.1, 8.25), _material(Color("05080D"), Color("132B37"), 0.12, 0.94))

	# Broadcast ribbon boards.
	_add_box(Vector3(21.2, 0.10, 0.18), Vector3(0.0, 2.35, -6.98), _material(Color("D8F3FF"), Color("76E3FF"), 2.6, 0.16))
	_add_box(Vector3(21.2, 0.10, 0.18), Vector3(0.0, 2.35, 6.98), _material(Color("D8F3FF"), Color("76E3FF"), 2.6, 0.16))
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		_add_box(Vector3(2.5, 0.55, 0.09), Vector3(x, 1.35, -6.60), _material(Color("0B1820"), OUR_COLOR, 0.48, 0.65))
		_add_box(Vector3(2.5, 0.55, 0.09), Vector3(x, 1.35, 6.60), _material(Color("170D13"), THEIR_COLOR, 0.40, 0.65))

	# Roof/light gantry visible at the top of the broadcast camera.
	for x in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		_add_box(Vector3(2.1, 0.08, 0.10), Vector3(x, 5.0, -6.9), _material(Color("ECF9FF"), Color("D7F5FF"), 3.3, 0.10))
		_add_box(Vector3(2.1, 0.08, 0.10), Vector3(x, 5.0, 6.9), _material(Color("ECF9FF"), Color("D7F5FF"), 3.3, 0.10))

	_build_goal(-1)
	_build_goal(1)
	_build_boost_pads()


func _build_goal(side: int) -> void:
	var x := 10.95 * float(side)
	var color := OUR_COLOR if side < 0 else THEIR_COLOR
	var mat := _material(color.darkened(0.55), color, 1.3, 0.32)
	_add_box(Vector3(0.18, 2.9, 0.18), Vector3(x, 1.45, -2.15), mat)
	_add_box(Vector3(0.18, 2.9, 0.18), Vector3(x, 1.45, 2.15), mat)
	_add_box(Vector3(0.18, 0.18, 4.48), Vector3(x, 2.86, 0.0), mat)
	_add_box(Vector3(1.2, 0.12, 4.48), Vector3(x + 0.58 * float(side), 0.08, 0.0), _material(Color("0B1118"), color, 0.28, 0.80))


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
		mesh_instance.material_override = _material(GOLD.darkened(0.28), GOLD, 1.35, 0.30)
		mesh_instance.position = _to_world(pad, 0.0) + Vector3(0.0, -0.21, 0.0)
		world_root.add_child(mesh_instance)


func _build_ball() -> void:
	ball_node = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.38
	sphere.height = 0.76
	sphere.radial_segments = 28
	sphere.rings = 16
	ball_node.mesh = sphere
	ball_node.material_override = _material(Color("EAF4FB"), Color("C8F2FF"), 0.48, 0.26)
	world_root.add_child(ball_node)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.15
	core_mesh.height = 0.30
	core.mesh = core_mesh
	core.material_override = _material(Color("4D5965"), Color("294A5B"), 0.18, 0.58)
	ball_node.add_child(core)


func _build_target_marker() -> void:
	target_marker = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.70
	mesh.bottom_radius = 0.70
	mesh.height = 0.025
	mesh.radial_segments = 28
	target_marker.mesh = mesh
	target_marker.material_override = _material(Color(0.20, 0.75, 0.95, 0.16), Color("63DFFF"), 1.1, 0.64)
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
	key_light.light_energy = 1.65 + goal_flash * 1.8
	fill_light.light_energy = 3.8 + goal_flash * 3.2


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
	node.position = _to_world(pos, height)
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
		ring.material_override = _material(Color(ring_color.r, ring_color.g, ring_color.b, 0.18), ring_color, 1.25, 0.68)

	var glow := node.get_node_or_null("Glow") as OmniLight3D
	if glow != null:
		glow.visible = active
		glow.light_energy = 2.1 if active else 0.0
	var boost := node.get_node_or_null("Boost") as MeshInstance3D
	if boost != null:
		boost.visible = velocity.length() > 0.035 or active
		boost.scale.x = 1.15 if active else 0.70


func _make_car(color: Color) -> Node3D:
	var root := Node3D.new()

	var lower := MeshInstance3D.new()
	var lower_mesh := BoxMesh.new()
	lower_mesh.size = Vector3(1.62, 0.24, 0.82)
	lower.mesh = lower_mesh
	lower.position = Vector3(0.0, 0.30, 0.0)
	lower.material_override = _material(color.darkened(0.58), color, 0.30, 0.44)
	root.add_child(lower)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.36, 0.28, 0.76)
	body.mesh = body_mesh
	body.position = Vector3(0.08, 0.48, 0.0)
	body.material_override = _material(color.darkened(0.34), color, 0.56, 0.34)
	root.add_child(body)

	var hood := MeshInstance3D.new()
	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(0.52, 0.15, 0.68)
	hood.mesh = hood_mesh
	hood.position = Vector3(0.66, 0.55, 0.0)
	hood.rotation.z = -0.09
	hood.material_override = _material(color.darkened(0.18), color, 0.62, 0.30)
	root.add_child(hood)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(0.65, 0.33, 0.61)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(-0.18, 0.75, 0.0)
	cabin.rotation.z = 0.05
	cabin.material_override = _material(Color("12212B"), Color("32758C"), 0.30, 0.16)
	root.add_child(cabin)

	# Round wheels instead of block placeholders.
	for wheel_pos in [Vector3(0.48,0.22,-0.45), Vector3(0.48,0.22,0.45), Vector3(-0.52,0.22,-0.45), Vector3(-0.52,0.22,0.45)]:
		var wheel := MeshInstance3D.new()
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = 0.18
		wheel_mesh.bottom_radius = 0.18
		wheel_mesh.height = 0.16
		wheel_mesh.radial_segments = 16
		wheel.mesh = wheel_mesh
		wheel.position = wheel_pos
		wheel.rotation.x = PI * 0.5
		wheel.material_override = _material(Color("020305"), Color("0B1118"), 0.04, 0.94)
		root.add_child(wheel)

	var spoiler := MeshInstance3D.new()
	var spoiler_mesh := BoxMesh.new()
	spoiler_mesh.size = Vector3(0.12, 0.08, 0.92)
	spoiler.mesh = spoiler_mesh
	spoiler.position = Vector3(-0.73, 0.72, 0.0)
	spoiler.material_override = _material(color.darkened(0.22), color, 0.42, 0.38)
	root.add_child(spoiler)
	for z in [-0.31, 0.31]:
		var stand := MeshInstance3D.new()
		var stand_mesh := BoxMesh.new()
		stand_mesh.size = Vector3(0.08, 0.28, 0.08)
		stand.mesh = stand_mesh
		stand.position = Vector3(-0.68, 0.58, z)
		stand.material_override = spoiler.material_override
		root.add_child(stand)

	# Headlights and rear light bar help communicate direction instantly.
	for z in [-0.23, 0.23]:
		var headlight := MeshInstance3D.new()
		var light_mesh := BoxMesh.new()
		light_mesh.size = Vector3(0.045, 0.10, 0.18)
		headlight.mesh = light_mesh
		headlight.position = Vector3(0.82, 0.50, z)
		headlight.material_override = _material(Color("EAFBFF"), Color("C5F5FF"), 3.0, 0.10)
		root.add_child(headlight)
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.045, 0.08, 0.52)
	tail.mesh = tail_mesh
	tail.position = Vector3(-0.82, 0.47, 0.0)
	tail.material_override = _material(Color("FF465F"), Color("FF2849"), 2.4, 0.16)
	root.add_child(tail)

	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.10, 0.025, 0.79)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0.02, 0.64, 0.0)
	stripe.material_override = _material(color, color, 1.45, 0.20)
	root.add_child(stripe)

	var boost := MeshInstance3D.new()
	boost.name = "Boost"
	var boost_mesh := CylinderMesh.new()
	boost_mesh.top_radius = 0.07
	boost_mesh.bottom_radius = 0.24
	boost_mesh.height = 0.82
	boost_mesh.radial_segments = 12
	boost.mesh = boost_mesh
	boost.position = Vector3(-1.13, 0.40, 0.0)
	boost.rotation.z = PI * 0.5
	boost.material_override = _material(Color(color.r,color.g,color.b,0.58), color, 3.0, 0.12)
	boost.visible = false
	root.add_child(boost)

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
	glow.omni_range = 4.2
	glow.light_color = color
	glow.light_energy = 0.0
	glow.visible = false
	root.add_child(glow)
	return root


func _update_prediction(start: Vector2, start_height: float, target: Vector2, target_height: float, color: Color) -> void:
	var mesh := ImmediateMesh.new()
	var mat := _material(Color(color.r, color.g, color.b, 0.76), color, 1.5, 0.30)
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
	for i in range(21):
		var t := float(i) / 20.0
		var p2 := start.lerp(target, t)
		var h := lerpf(start_height, target_height, t) + sin(t * PI) * 0.30
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
		var mat := _material(Color(color.r, color.g, color.b, 0.58), color, 0.88 if i == active_actor else 0.38, 0.58)
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
		var from := _to_world(positions[i], 0.0) + Vector3(0.0, 0.04, 0.0)
		var to := _to_world(targets[i], 0.0) + Vector3(0.0, 0.04, 0.0)
		mesh.surface_add_vertex(from)
		mesh.surface_add_vertex(from.lerp(to, 0.45))
		mesh.surface_add_vertex(to)
		mesh.surface_end()
	rotation_mesh.mesh = mesh


func _update_camera(ball_pos: Vector2, ball_height: float, phase: String, goal_flash: float) -> void:
	var focus := _to_world(ball_pos, minf(ball_height * 0.55, 0.45))
	focus.y = 0.70 + minf(ball_height * 0.70, 1.0)
	var mechanical := phase in [
		"wall_setup", "air_carry", "air_carry_2", "musty_load", "musty_release",
		"reset_contact", "reset_control", "reset_1", "reset_2", "reset_3", "reset_4",
		"psycho_setup", "own_wall_carry", "backwall_musty", "psycho_contact",
		"prejump", "teammate_prejump", "redirect_finish", "ceiling_setup", "ceiling_drop",
		"pogo_drop", "pogo_bounce"
	]
	var desired := camera_home
	if mechanical:
		desired = Vector3(focus.x * 0.28, 7.7, 12.4 + abs(focus.z) * 0.10)
	elif goal_flash > 0.05:
		desired = Vector3(focus.x * 0.12, 8.1, 13.0)
	else:
		desired.x = focus.x * 0.12
	camera_3d.position = camera_3d.position.lerp(desired, 0.14)
	camera_focus = camera_focus.lerp(focus, 0.18)
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
	material.metallic = 0.10
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_energy
	return material