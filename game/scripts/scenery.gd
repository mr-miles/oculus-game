class_name Scenery
extends RefCounted
## Shared look: sky, light and flat-coloured materials for the lobby and levels.

static func add_sky(parent: Node) -> void:
	## A shader sky (blue gradient, drifting clouds, a sun disc) lit by a sun that casts shadows.
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://scripts/sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_32  # ambient is a flat colour, the radiance map is unused
	sky.process_mode = Sky.PROCESS_MODE_REALTIME  # the clouds move
	var env := WorldEnvironment.new()
	env.name = "Sky"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_SKY
	env.environment.sky = sky
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.66, 0.75)
	env.environment.ambient_light_energy = 0.9
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL  # one cascade: cheap on a Quest 2
	sun.directional_shadow_max_distance = 80.0
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 2.0
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
