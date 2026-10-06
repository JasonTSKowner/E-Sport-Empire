class_name Arena3DViewV251
extends "res://scripts/arena_3d_view_v25.gd"


func _build_car(color: Color) -> Node3D:
	var root: Node3D = super._build_car(color)
	# Lower, wider esports-car silhouette layered over the functional base car.
	_add_local_box(root, "FrontSplitter", Vector3(1.02, 0.055, 0.20), Vector3(0.0, 0.15, -0.72), Color("071017"), 0.02, 0.38)
	_add_local_box(root, "RearBumper", Vector3(0.98, 0.10, 0.18), Vector3(0.0, 0.18, 0.70), Color(color.r * 0.34, color.g * 0.34, color.b * 0.34, 1.0), 0.20, 0.28)
	_add_local_box(root, "SideSkirtL", Vector3(0.08, 0.08, 1.08), Vector3(-0.50, 0.17, 0.02), Color("071017"), 0.04, 0.35)
	_add_local_box(root, "SideSkirtR", Vector3(0.08, 0.08, 1.08), Vector3(0.50, 0.17, 0.02), Color("071017"), 0.04, 0.35)

	var hood: MeshInstance3D = _add_local_box(root, "SlopedHood", Vector3(0.83, 0.10, 0.46), Vector3(0.0, 0.43, -0.48), Color(color.r * 0.78, color.g * 0.78, color.b * 0.78, 1.0), 0.32, 0.20)
	hood.rotation_degrees.x = -7.0
	var roof: MeshInstance3D = _add_local_box(root, "LowRoof", Vector3(0.62, 0.10, 0.50), Vector3(0.0, 0.62, 0.10), Color("1A3948"), 0.06, 0.12)
	roof.rotation_degrees.x = 2.5

	# Rear wing makes the tiny mobile silhouette instantly car-like.
	_add_local_box(root, "SpoilerWing", Vector3(0.92, 0.055, 0.16), Vector3(0.0, 0.57, 0.69), Color("0A1118"), 0.14, 0.25)
	_add_local_box(root, "SpoilerStandL", Vector3(0.055, 0.22, 0.055), Vector3(-0.30, 0.47, 0.65), Color("0A1118"), 0.12, 0.28)
	_add_local_box(root, "SpoilerStandR", Vector3(0.055, 0.22, 0.055), Vector3(0.30, 0.47, 0.65), Color("0A1118"), 0.12, 0.28)

	# Strong light signatures still read when the car is far away.
	_add_local_box(root, "HeadlightBar", Vector3(0.62, 0.055, 0.035), Vector3(0.0, 0.34, -0.675), Color("D9F6FF"), 0.0, 0.20, true)
	_add_local_box(root, "TailLightBar", Vector3(0.66, 0.055, 0.035), Vector3(0.0, 0.32, 0.675), Color("FF3E55"), 0.0, 0.20, true)
	return root


func _build_arena_shell() -> void:
	super._build_arena_shell()

	# Transparent side glass is the missing visual cue for wall plays.
	_add_world_glass("GlassLeft", Vector3(0.055, 2.65, FIELD_LENGTH + 1.15), Vector3(-FIELD_HALF_W - 0.42, 1.73, 0.0), team_color)
	_add_world_glass("GlassRight", Vector3(0.055, 2.65, FIELD_LENGTH + 1.15), Vector3(FIELD_HALF_W + 0.42, 1.73, 0.0), enemy_color)

	# Backboards make double taps / psychos spatially understandable.
	_add_world_glass("OwnBackboard", Vector3(FIELD_WIDTH + 0.7, 3.25, 0.055), Vector3(0.0, 1.92, FIELD_HALF_L + 0.43), team_color)
	_add_world_glass("TheirBackboard", Vector3(FIELD_WIDTH + 0.7, 3.25, 0.055), Vector3(0.0, 1.92, -FIELD_HALF_L - 0.43), enemy_color)

	# Physical corner posts and upper lighting frame the field like a real venue.
	var corner_x_values: Array[float] = [-FIELD_HALF_W - 0.48, FIELD_HALF_W + 0.48]
	var corner_z_values: Array[float] = [-FIELD_HALF_L - 0.48, FIELD_HALF_L + 0.48]
	for x: float in corner_x_values:
		for z: float in corner_z_values:
			_add_world_box("ArenaPost", Vector3(0.16, 3.75, 0.16), Vector3(x, 1.86, z), Color("17313B"), 0.20, 0.30)

	var rig_z_values: Array[float] = [-FIELD_HALF_L * 0.72, -FIELD_HALF_L * 0.24, FIELD_HALF_L * 0.24, FIELD_HALF_L * 0.72]
	for z: float in rig_z_values:
		_add_world_box("RigL", Vector3(1.60, 0.08, 0.08), Vector3(-FIELD_HALF_W - 1.05, 3.75, z), Color("83E5FA"), 0.02, 0.18, true)
		_add_world_box("RigR", Vector3(1.60, 0.08, 0.08), Vector3(FIELD_HALF_W + 1.05, 3.75, z), Color("83E5FA"), 0.02, 0.18, true)

	# Simple crowd-light rows add density without expensive geometry.
	var side_values: Array[float] = [-1.0, 1.0]
	for side: float in side_values:
		for row: int in range(3):
			for i: int in range(9):
				var z: float = -FIELD_HALF_L + 0.9 + float(i) * (FIELD_LENGTH - 1.8) / 8.0
				var x: float = side * (FIELD_HALF_W + 1.45 + float(row) * 0.28)
				var c: Color = team_color if (i + row) % 7 == 0 else enemy_color if (i + row) % 8 == 0 else Color("71818D")
				_add_world_box("CrowdLight", Vector3(0.06, 0.06, 0.14), Vector3(x, 1.15 + float(row) * 0.44, z), c, 0.0, 0.25, true)


func _build_goal(prefix: String, z: float, color: Color, depth_dir: float) -> void:
	super._build_goal(prefix, z, color, depth_dir)
	# A darker tunnel behind the frame creates real goal depth.
	_add_world_box(prefix + "TunnelFloor", Vector3(4.20, 0.06, 1.10), Vector3(0.0, 0.03, z + depth_dir * 0.55), Color("03070B"), 0.0, 0.36)
	_add_world_box(prefix + "TunnelBack", Vector3(4.20, 2.05, 0.06), Vector3(0.0, 1.02, z + depth_dir * 1.08), Color(color.r * 0.08, color.g * 0.08, color.b * 0.08, 1.0), 0.0, 0.36)


func _add_local_box(parent: Node3D, node_name: String, box_size: Vector3, pos: Vector3, color: Color, metallic: float, roughness: float, emissive: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _emissive_material(color, 0.62) if emissive else _material(color, metallic, roughness)
	parent.add_child(instance)
	return instance


func _add_world_box(node_name: String, box_size: Vector3, pos: Vector3, color: Color, metallic: float, roughness: float, emissive: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _emissive_material(color, 0.46) if emissive else _material(color, metallic, roughness)
	world_root.add_child(instance)
	return instance


func _add_world_glass(node_name: String, box_size: Vector3, pos: Vector3, tint: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.10)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.08
	mat.roughness = 0.20
	mat.emission_enabled = true
	mat.emission = Color(tint.r * 0.08, tint.g * 0.08, tint.b * 0.08, 1.0)
	instance.material_override = mat
	world_root.add_child(instance)
	return instance
