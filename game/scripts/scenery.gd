class_name Scenery
extends RefCounted
## Shared look: sky, light and flat-coloured materials for the lobby and levels.

static func add_sky(parent: Node) -> void:
	var env := WorldEnvironment.new()
	env.name = "Sky"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.75, 0.95)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 35, 0)
	parent.add_child(sun)


static func material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


static func mesh_node(node_name: String, mesh: Mesh, color: Color, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = mesh
	m.material_override = material(color)
	m.position = at
	return m
