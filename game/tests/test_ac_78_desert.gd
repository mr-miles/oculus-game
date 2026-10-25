extends ViewTest
## AC-78: a desert of dunes surrounds the hill.

func _init() -> void:
	var g := await new_game()
	var desert: MeshInstance3D = g.find_child("Desert", true, false)
	check("ac_78 the level has a Desert", desert != null and desert.mesh != null)
	var extent: float = g.logic.size * GameLogic.TILE
	var box := desert.get_aabb()
	check("ac_78 the desert reaches 200 m beyond the hill in every direction (%s)" % box, box.position.x <= -200.0 and box.end.x >= extent + 200.0 and box.position.z <= -200.0 and box.end.z >= extent + 200.0)
	check("ac_78 dunes rise above the flat ground (%.1f m)" % box.end.y, box.end.y > 1.5 and box.end.y < 12.0)
	check("ac_78 the sand never goes below y = -0.1 (%.2f)" % box.position.y, box.position.y >= -0.1)
	check("ac_78 flat at the hill's edge", Desert.height_at(-2.0, 10.0, 2.0) < 0.01 and Desert.height_at(0.0, 0.0, 0.0) == 0.0)
	var tris := (desert.mesh as ArrayMesh).surface_get_array_len(0) / 3
	check("ac_78 desert stays within the Quest triangle budget (%d)" % tris, tris < 30000)
	var env: WorldEnvironment = g.find_child("Sky", true, false)
	check("ac_78 distance haze is on", env.environment.fog_enabled)
	finish()
