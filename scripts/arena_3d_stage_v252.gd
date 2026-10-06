class_name Arena3DStageV252
extends "res://scripts/arena_3d_stage.gd"


func _make_car(color: Color) -> Node3D:
	var root := super._make_car(color)

	# Front splitter / lower aero gives the car a wider, intentional silhouette.
	var splitter := MeshInstance3D.new()
	var splitter_mesh := BoxMesh.new()
	splitter_mesh.size = Vector3(0.18, 0.055, 0.98)
	splitter.mesh = splitter_mesh
	splitter.position = Vector3(0.88, 0.20, 0.0)
	splitter.material_override = _material(Color("05080B"), color, 0.16, 0.70)
	root.add_child(splitter)

	# Side skirts break the boxy body into a more believable sports-car profile.
	for z in [-0.46, 0.46]:
		var skirt := MeshInstance3D.new()
		var skirt_mesh := BoxMesh.new()
		skirt_mesh.size = Vector3(1.34, 0.075, 0.07)
		skirt.mesh = skirt_mesh
		skirt.position = Vector3(-0.02, 0.24, z)
		skirt.material_override = _material(color.darkened(0.56), color, 0.20, 0.62)
		root.add_child(skirt)

	# Wheel rims: visible metallic discs inside the round tyres.
	for wheel_pos in [Vector3(0.48,0.22,-0.535), Vector3(0.48,0.22,0.535), Vector3(-0.52,0.22,-0.535), Vector3(-0.52,0.22,0.535)]:
		var rim := MeshInstance3D.new()
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = 0.112
		rim_mesh.bottom_radius = 0.112
		rim_mesh.height = 0.025
		rim_mesh.radial_segments = 16
		rim.mesh = rim_mesh
		rim.position = wheel_pos
		rim.rotation.x = PI * 0.5
		rim.material_override = _material(Color("8FA2B0"), Color("BDEBFF"), 0.26, 0.22)
		root.add_child(rim)

	# Rear diffuser and twin exhaust/boost ports.
	var diffuser := MeshInstance3D.new()
	var diffuser_mesh := BoxMesh.new()
	diffuser_mesh.size = Vector3(0.12, 0.13, 0.72)
	diffuser.mesh = diffuser_mesh
	diffuser.position = Vector3(-0.87, 0.27, 0.0)
	diffuser.material_override = _material(Color("04070A"), Color("18252D"), 0.08, 0.86)
	root.add_child(diffuser)
	for z in [-0.22, 0.22]:
		var port := MeshInstance3D.new()
		var port_mesh := CylinderMesh.new()
		port_mesh.top_radius = 0.065
		port_mesh.bottom_radius = 0.065
		port_mesh.height = 0.09
		port_mesh.radial_segments = 12
		port.mesh = port_mesh
		port.position = Vector3(-0.95, 0.38, z)
		port.rotation.z = PI * 0.5
		port.material_override = _material(Color("111A20"), color, 0.42, 0.34)
		root.add_child(port)

	# Thin roof highlight makes orientation readable during aerial rolls/resets.
	var roof_line := MeshInstance3D.new()
	var roof_line_mesh := BoxMesh.new()
	roof_line_mesh.size = Vector3(0.44, 0.025, 0.055)
	roof_line.mesh = roof_line_mesh
	roof_line.position = Vector3(-0.16, 0.93, 0.0)
	roof_line.material_override = _material(Color("E6F7FF"), color, 1.7, 0.12)
	root.add_child(roof_line)

	return root
