extends ViewTest
## AC-76: the sky is a shader sky with moving clouds, and the sun casts shadows.

func _check_scene(label: String, scene: Node) -> void:
	var env: WorldEnvironment = scene.find_child("Sky", true, false)
	check("ac_76 %s: has a sky" % label, env != null and env.environment.background_mode == Environment.BG_SKY)
	var sky: Sky = env.environment.sky
	var mat := sky.sky_material as ShaderMaterial
	check("ac_76 %s: sky is a shader with a time-driven cloud layer" % label,
			mat != null and mat.shader.code.contains("TIME") and mat.shader.code.contains("fbm"))
	check("ac_76 %s: the sky re-renders every frame so clouds move" % label, sky.process_mode == Sky.PROCESS_MODE_REALTIME)
	var sun: DirectionalLight3D = scene.find_child("Sun", true, false)
	check("ac_76 %s: the Sun exists and casts shadows" % label, sun != null and sun.shadow_enabled)
	check("ac_76 %s: one shadow cascade (Quest 2 budget)" % label, sun.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL)
	check("ac_76 %s: the sun is above the horizon, shining down" % label, sun.global_transform.basis.z.y > 0.3)


func _init() -> void:
	var g := await new_game()
	_check_scene("level", g)
	var terrain := g.find_child("Terrain", true, false)
	var meshes := g.find_children("*", "MeshInstance3D", true, false)
	var casters := 0
	for m in meshes:
		if (m as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters += 1
	check("ac_76 objects in the level can cast shadows (%d)" % casters, casters > 5)
	var l := await new_lobby()
	_check_scene("lobby", l)
	finish()
