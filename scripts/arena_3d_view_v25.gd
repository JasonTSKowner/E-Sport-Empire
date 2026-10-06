class_name Arena3DViewV25
extends SubViewportContainer

const FIELD_WIDTH := 9.2
const FIELD_LENGTH := 15.4
const FIELD_HALF_W := FIELD_WIDTH * 0.5
const FIELD_HALF_L := FIELD_LENGTH * 0.5

var viewport_3d: SubViewport
var world_root: Node3D
var camera: Camera3D
var ball_root: Node3D
var ball_shadow: MeshInstance3D
var our_cars: Array[Node3D] = []
var their_cars: Array[Node3D] = []
var trajectory_mesh: ImmediateMesh
var rotation_mesh: ImmediateMesh
var trajectory_instance: MeshInstance3D
var rotation_instance: MeshInstance3D
var target_marker: MeshInstance3D
var team_color := Color("37D6F6")
var enemy_color := Color("FF6B7A")
var training_mode := false
var built := false


func configure(our_color: Color, their_color: Color = Color("FF6B7A"), as_training: bool = false) -> Arena3DViewV25:
	team_color = our_color
	enemy_color = their_color
	training_mode = as_training
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	if not built:
		_build_world()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	if not built:
		_build_world()


func _build_world() -> void:
	if built:
		return
	built = true

	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(760, 520)
	viewport_3d.transparent_bg = false
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)

	world_root = Node3D.new()
	world_root.name = "ArenaWorld"
	viewport_3d.add_child(world_root)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("02050A")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("A6C7DA")
	environment.ambient_light_energy = 0.42
	environment_node.environment = environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color("D9EEFA")
	key_light.light_energy = 1.45
	key_light.rotation_degrees = Vector3(-52.0, -18.0, 0.0)
	key_light.shadow_enabled = true
	world_root.add_child(key_light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 7.5, 1.5)
	fill.light_color = Color("5CDDF5")
	fill.light_energy = 1.65
	fill.omni_range = 22.0
	world_root.add_child(fill)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 55.0
	camera.position = Vector3(0.0, 10.8, 16.8)
	world_root.add_child(camera)
	camera.look_at(Vector3(0.0, 0.5, -0.7), Vector3.UP)

	_build_field()
	_build_goals()
	_build_arena_shell()
	_build_boost_pads()

	for i in range(3):
		var our_car := _build_car(team_color)
		our_car.name = "OurCar%d" % i
		world_root.add_child(our_car)
		our_cars.append(our_car)

		var their_car := _build_car(enemy_color)
		their_car.name = "TheirCar%d" % i
		world_root.add_child(their_car)
		their_cars.append(their_car)

	ball_root = _build_ball()
	world_root.add_child(ball_root)

	trajectory_instance = MeshInstance3D.new()
	trajectory_mesh = ImmediateMesh.new()
	trajectory_instance.mesh = trajectory_mesh
	trajectory_instance.material_override = _unshaded_material(Color(0.92, 0.98, 1.0, 1.0))
	world_root.add_child(trajectory_instance)

	rotation_instance = MeshInstance3D.new()
	rotation_mesh = ImmediateMesh.new()
	rotation_instance.mesh = rotation_mesh
	rotation_instance.material_override = _unshaded_material(Color(team_color.r, team_color.g, team_color.b, 1.0))
	world_root.add_child(rotation_instance)

	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.72
	marker_mesh.bottom_radius = 0.72
	marker_mesh.height = 0.025
	target_marker = MeshInstance3D.new()
	target_marker.mesh = marker_mesh
	target_marker.material_override = _emissive_material(Color("5DE1A5"), 0.55)
	target_marker.position.y = 0.06
	target_marker.visible = training_mode
	world_root.add_child(target_marker)


func _build_field() -> void:
	_make_box(
		"FieldBase",
		Vector3(FIELD_WIDTH + 0.5, 0.18, FIELD_LENGTH + 0.5),
		Vector3(0.0, -0.10, 0.0),
		Color("061016")
	)

	var stripe_length := FIELD_LENGTH / 10.0
	for i in range(10):
		var z := -FIELD_HALF_L + stripe_length * (float(i) + 0.5)
		var c := Color("071B22") if i % 2 == 0 else Color("06171E")
		_make_box("Stripe%d" % i, Vector3(FIELD_WIDTH, 0.022, stripe_length), Vector3(0.0, 0.012, z), c)

	var line_mat := Color("335B68")
	_make_box("CenterLine", Vector3(FIELD_WIDTH, 0.026, 0.055), Vector3(0.0, 0.035, 0.0), line_mat, true)
	_make_box("LeftLine", Vector3(0.055, 0.026, FIELD_LENGTH), Vector3(-FIELD_HALF_W, 0.035, 0.0), line_mat, true)
	_make_box("RightLine", Vector3(0.055, 0.026, FIELD_LENGTH), Vector3(FIELD_HALF_W, 0.035, 0.0), line_mat, true)
	_make_box("NearLine", Vector3(FIELD_WIDTH, 0.026, 0.055), Vector3(0.0, 0.035, FIELD_HALF_L), line_mat, true)
	_make_box("FarLine", Vector3(FIELD_WIDTH, 0.026, 0.055), Vector3(0.0, 0.035, -FIELD_HALF_L), line_mat, true)

	var center_disc_mesh := CylinderMesh.new()
	center_disc_mesh.top_radius = 1.25
	center_disc_mesh.bottom_radius = 1.25
	center_disc_mesh.height = 0.018
	var center_disc := MeshInstance3D.new()
	center_disc.mesh = center_disc_mesh
	center_disc.position = Vector3(0.0, 0.032, 0.0)
	center_disc.material_override = _material(Color("0A222A"), 0.0, 0.0)
	world_root.add_child(center_disc)


func _build_goals() -> void:
	_build_goal("OwnGoal", FIELD_HALF_L + 0.22, team_color, 1.0)
	_build_goal("TheirGoal", -FIELD_HALF_L - 0.22, enemy_color, -1.0)


func _build_goal(prefix: String, z: float, color: Color, depth_dir: float) -> void:
	var goal_width := 4.15
	var goal_height := 2.05
	var post := 0.11
	var depth := 1.05
	_make_box(prefix + "PostL", Vector3(post, goal_height, post), Vector3(-goal_width * 0.5, goal_height * 0.5, z), color, true)
	_make_box(prefix + "PostR", Vector3(post, goal_height, post), Vector3(goal_width * 0.5, goal_height * 0.5, z), color, true)
	_make_box(prefix + "Crossbar", Vector3(goal_width + post, post, post), Vector3(0.0, goal_height, z), color, true)
	_make_box(prefix + "DepthL", Vector3(post, post, depth), Vector3(-goal_width * 0.5, goal_height, z + depth_dir * depth * 0.5), color, true)
	_make_box(prefix + "DepthR", Vector3(post, post, depth), Vector3(goal_width * 0.5, goal_height, z + depth_dir * depth * 0.5), color, true)


func _build_arena_shell() -> void:
	var board_color := Color("0B2630")
	_make_box("LeftBoard", Vector3(0.18, 0.85, FIELD_LENGTH + 1.4), Vector3(-FIELD_HALF_W - 0.26, 0.42, 0.0), board_color)
	_make_box("RightBoard", Vector3(0.18, 0.85, FIELD_LENGTH + 1.4), Vector3(FIELD_HALF_W + 0.26, 0.42, 0.0), board_color)
	_make_box("LeftGlow", Vector3(0.045, 0.12, FIELD_LENGTH + 1.3), Vector3(-FIELD_HALF_W - 0.37, 0.86, 0.0), team_color, true)
	_make_box("RightGlow", Vector3(0.045, 0.12, FIELD_LENGTH + 1.3), Vector3(FIELD_HALF_W + 0.37, 0.86, 0.0), enemy_color, true)

	_make_box("LeftStand", Vector3(2.0, 3.0, FIELD_LENGTH + 2.0), Vector3(-FIELD_HALF_W - 2.1, 1.2, 0.0), Color("050A10"))
	_make_box("RightStand", Vector3(2.0, 3.0, FIELD_LENGTH + 2.0), Vector3(FIELD_HALF_W + 2.1, 1.2, 0.0), Color("050A10"))

	for i in range(7):
		var z := -FIELD_HALF_L + (FIELD_LENGTH / 6.0) * float(i)
		_make_box("LightL%d" % i, Vector3(0.18, 0.10, 0.55), Vector3(-FIELD_HALF_W - 1.25, 3.05, z), Color("8EDFF4"), true)
		_make_box("LightR%d" % i, Vector3(0.18, 0.10, 0.55), Vector3(FIELD_HALF_W + 1.25, 3.05, z), Color("8EDFF4"), true)


func _build_boost_pads() -> void:
	var positions := [
		Vector2(0.14, 0.18), Vector2(0.14, 0.82),
		Vector2(0.36, 0.34), Vector2(0.36, 0.66),
		Vector2(0.64, 0.34), Vector2(0.64, 0.66),
		Vector2(0.86, 0.18), Vector2(0.86, 0.82)
	]
	for i in range(positions.size()):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.20
		mesh.bottom_radius = 0.20
		mesh.height = 0.025
		var pad := MeshInstance3D.new()
		pad.mesh = mesh
		pad.position = _field_to_world(positions[i], 0.045)
		pad.material_override = _emissive_material(Color("D8A643"), 0.50)
		world_root.add_child(pad)


func _build_car(color: Color) -> Node3D:
	var root := Node3D.new()

	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.94, 0.28, 1.30)
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.28, 0.0)
	body.material_override = _material(Color(color.r * 0.58, color.g * 0.58, color.b * 0.58, 1.0), 0.38, 0.18)
	root.add_child(body)

	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(0.86, 0.20, 0.52)
	var hood := MeshInstance3D.new()
	hood.mesh = hood_mesh
	hood.position = Vector3(0.0, 0.37, -0.43)
	hood.material_override = _material(Color(color.r * 0.72, color.g * 0.72, color.b * 0.72, 1.0), 0.28, 0.22)
	root.add_child(hood)

	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(0.68, 0.30, 0.58)
	var cabin := MeshInstance3D.new()
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 0.50, 0.14)
	cabin.material_override = _material(Color("183443"), 0.10, 0.05)
	root.add_child(cabin)

	var wheel_mat := _material(Color("05070A"), 0.0, 0.05)
	for wheel_pos in [Vector3(-0.51, 0.19, -0.39), Vector3(0.51, 0.19, -0.39), Vector3(-0.51, 0.19, 0.39), Vector3(0.51, 0.19, 0.39)]:
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = 0.16
		wheel_mesh.bottom_radius = 0.16
		wheel_mesh.height = 0.13
		var wheel := MeshInstance3D.new()
		wheel.mesh = wheel_mesh
		wheel.position = wheel_pos
		wheel.rotation_degrees.z = 90.0
		wheel.material_override = wheel_mat
		root.add_child(wheel)

	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.78
	ring_mesh.bottom_radius = 0.78
	ring_mesh.height = 0.018
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.position = Vector3(0.0, 0.025, 0.0)
	ring.material_override = _emissive_material(Color(color.r * 0.55, color.g * 0.55, color.b * 0.55, 1.0), 0.42)
	ring.visible = false
	root.add_child(ring)
	root.set_meta("active_ring", ring)

	for side in [-0.22, 0.22]:
		var boost_mesh := BoxMesh.new()
		boost_mesh.size = Vector3(0.10, 0.10, 0.82)
		var boost := MeshInstance3D.new()
		boost.mesh = boost_mesh
		boost.position = Vector3(side, 0.25, 0.93)
		boost.material_override = _emissive_material(color, 0.72)
		boost.visible = false
		root.add_child(boost)
		root.set_meta("boost_%s" % ("l" if side < 0.0 else "r"), boost)

	return root


func _build_ball() -> Node3D:
	var root := Node3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.31
	sphere_mesh.height = 0.62
	var sphere := MeshInstance3D.new()
	sphere.mesh = sphere_mesh
	sphere.material_override = _material(Color("E9F0F7"), 0.16, 0.12)
	root.add_child(sphere)

	var light := OmniLight3D.new()
	light.light_color = Color("DDEFFF")
	light.light_energy = 0.38
	light.omni_range = 3.5
	root.add_child(light)

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.34
	shadow_mesh.bottom_radius = 0.34
	shadow_mesh.height = 0.014
	ball_shadow = MeshInstance3D.new()
	ball_shadow.mesh = shadow_mesh
	ball_shadow.material_override = _material(Color("020304"), 0.0, 0.0)
	world_root.add_child(ball_shadow)
	return root


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
	support_actor: int
) -> void:
	if not built:
		_build_world()

	for i in range(our_cars.size()):
		var visible_car := i < our_positions.size()
		our_cars[i].visible = visible_car
		if visible_car:
			var velocity: Vector2 = our_velocities[i] if i < our_velocities.size() else Vector2.ZERO
			_update_car(our_cars[i], our_positions[i], velocity, i == active_actor, i == support_actor)

	for i in range(their_cars.size()):
		var visible_car := i < their_positions.size()
		their_cars[i].visible = visible_car
		if visible_car:
			var velocity: Vector2 = their_velocities[i] if i < their_velocities.size() else Vector2.ZERO
			_update_car(their_cars[i], their_positions[i], velocity, false, false)

	_update_ball(ball_position, ball_height)
	_update_trajectory(ball_position, ball_height, ball_target, ball_target_height)
	_update_rotations(our_positions, our_targets, active_actor, support_actor)
	target_marker.visible = false
	_update_camera(ball_position, ball_height)


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
	if not built:
		_build_world()
	training_mode = true

	for i in range(our_cars.size()):
		our_cars[i].visible = i == 0
	for i in range(their_cars.size()):
		their_cars[i].visible = false

	_update_car(our_cars[0], car_position, car_velocity, true, false)
	_update_ball(ball_position, ball_height)
	_update_trajectory(ball_position, ball_height, future_ball, future_height)

	rotation_mesh.clear_surfaces()
	var future_car := car_position + (car_velocity.normalized() * 0.12 if car_velocity.length() > 0.02 else Vector2(0.10, 0.0))
	_draw_line_strip(rotation_mesh, [_field_to_world(car_position, 0.12), _field_to_world(future_car, 0.12)], _unshaded_material(team_color))

	target_marker.visible = true
	target_marker.position = _field_to_world(target_position, 0.055)

	if focus_family in ["defense", "save"]:
		their_cars[0].visible = true
		var ghost_pos := Vector2(clampf(ball_position.x + 0.12, 0.05, 0.95), clampf(ball_position.y + 0.08, 0.12, 0.88))
		_update_car(their_cars[0], ghost_pos, Vector2(-0.22, -0.08), false, false)

	_update_camera(ball_position, ball_height)


func _update_car(car: Node3D, field_pos: Vector2, velocity: Vector2, active: bool, support: bool) -> void:
	car.position = _field_to_world(field_pos, 0.0)
	if velocity.length() > 0.01:
		var dir := Vector3(velocity.y, 0.0, -velocity.x)
		if dir.length() > 0.01:
			car.look_at(car.global_position + dir, Vector3.UP)
	var ring: MeshInstance3D = car.get_meta("active_ring", null)
	if ring != null:
		ring.visible = active or support
		ring.scale = Vector3.ONE * (1.0 if active else 0.82)
	var boost_l: MeshInstance3D = car.get_meta("boost_l", null)
	var boost_r: MeshInstance3D = car.get_meta("boost_r", null)
	var boosting := velocity.length() > 0.055
	if boost_l != null:
		boost_l.visible = boosting
	if boost_r != null:
		boost_r.visible = boosting


func _update_ball(field_pos: Vector2, height_value: float) -> void:
	var world := _field_to_world(field_pos, 0.32 + clampf(height_value, 0.0, 1.2) * 4.0)
	ball_root.position = world
	ball_root.rotation_degrees += Vector3(0.8, 1.4, 0.6)
	ball_shadow.position = _field_to_world(field_pos, 0.035)
	var shadow_scale := 1.0 + clampf(height_value, 0.0, 1.0) * 0.95
	ball_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)


func _update_trajectory(from_pos: Vector2, from_height: float, to_pos: Vector2, to_height: float) -> void:
	trajectory_mesh.clear_surfaces()
	var points: Array[Vector3] = []
	var start := _field_to_world(from_pos, 0.32 + from_height * 4.0)
	var finish := _field_to_world(to_pos, 0.32 + to_height * 4.0)
	for i in range(15):
		var t := float(i) / 14.0
		var point := start.lerp(finish, t)
		point.y += sin(t * PI) * (0.65 + maxf(from_height, to_height) * 1.25)
		points.append(point)
	_draw_line_strip(trajectory_mesh, points, _unshaded_material(Color("DDF5FF")))


func _update_rotations(positions: Array, targets: Array, active_actor: int, support_actor: int) -> void:
	rotation_mesh.clear_surfaces()
	var material := _unshaded_material(team_color)
	for i in range(mini(positions.size(), targets.size())):
		if i > 2:
			break
		var from := _field_to_world(positions[i], 0.10)
		var to := _field_to_world(targets[i], 0.10)
		var lift := 0.10 if i == active_actor else 0.055 if i == support_actor else 0.035
		from.y += lift
		to.y += lift
		_draw_line_strip(rotation_mesh, [from, to], material, false)


func _update_camera(ball_pos: Vector2, ball_height: float) -> void:
	if camera == null:
		return
	var ball_world := _field_to_world(ball_pos, 0.32 + ball_height * 4.0)
	var target := Vector3(ball_world.x * 0.16, 0.75 + minf(1.0, ball_height) * 0.35, ball_world.z * 0.10)
	var desired := Vector3(ball_world.x * 0.05, 10.8 + minf(1.0, ball_height) * 0.45, 16.8)
	camera.position = camera.position.lerp(desired, 0.08)
	camera.look_at(target, Vector3.UP)


func _field_to_world(p: Vector2, height_value: float) -> Vector3:
	var x := (clampf(p.y, 0.0, 1.0) - 0.5) * FIELD_WIDTH
	var z := lerpf(FIELD_HALF_L, -FIELD_HALF_L, clampf(p.x, 0.0, 1.0))
	return Vector3(x, height_value, z)


func _draw_line_strip(mesh: ImmediateMesh, points: Array, material: Material, clear_first: bool = false) -> void:
	if clear_first:
		mesh.clear_surfaces()
	if points.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for point in points:
		mesh.surface_add_vertex(point)
	mesh.surface_end()


func _make_box(name: String, box_size: Vector3, pos: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _emissive_material(color, 0.28) if emissive else _material(color, 0.14, 0.08)
	world_root.add_child(instance)
	return instance


func _material(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.72) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material


func _emissive_material(color: Color, energy: float = 0.40) -> StandardMaterial3D:
	var material := _material(color, 0.08, 0.48)
	material.emission_enabled = true
	material.emission = Color(color.r * energy, color.g * energy, color.b * energy, 1.0)
	return material


func _unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	return material
