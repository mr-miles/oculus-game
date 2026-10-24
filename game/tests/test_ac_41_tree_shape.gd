extends ViewTest
## AC-41: canopy 1.4..1.9 m wide, slim brown trunk, green canopy.

func _colour(m: MeshInstance3D) -> Color:
	return (m.material_override as StandardMaterial3D).albedo_color


func _init() -> void:
	var g := await new_game()
	for t in g.find_children("Tree_*", "Node3D", true, false):
		var trunk: MeshInstance3D = t.find_child("Trunk", false, false)
		var canopy: MeshInstance3D = t.find_child("Canopy", false, false)
		var cw := (canopy.global_transform * canopy.get_aabb()).size.x
		var tw := (trunk.global_transform * trunk.get_aabb()).size.x
		check("ac_41 %s canopy width in 1.4..1.9" % t.name, cw >= 1.4 and cw <= 1.9)
		check("ac_41 %s trunk <= 0.5 m and < a third of the canopy" % t.name, tw <= 0.5 and tw < cw / 3.0)
		var leaf := _colour(canopy)
		var wood := _colour(trunk)
		check("ac_41 %s canopy is green" % t.name, leaf.g > leaf.r and leaf.g > leaf.b)
		check("ac_41 %s trunk is brown" % t.name, wood.r >= wood.g and wood.g > wood.b)
	finish()
