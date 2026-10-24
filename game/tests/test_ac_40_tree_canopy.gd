extends ViewTest
## AC-40: a tree is a Trunk plus a Canopy that is >= half its height and clear of the ground.

func _init() -> void:
	var g := await new_game()
	var trees := g.find_children("Tree_*", "Node3D", true, false)
	check("ac_40 level has trees", trees.size() > 0)
	for t in trees:
		var trunk: MeshInstance3D = t.find_child("Trunk", false, false)
		var canopy: MeshInstance3D = t.find_child("Canopy", false, false)
		check("ac_40 %s has Trunk and Canopy" % t.name, trunk != null and canopy != null)
		var whole := tree_bounds(t)
		var leaves: AABB = canopy.global_transform * canopy.get_aabb()
		check("ac_40 %s canopy is >= 50%% of the height" % t.name, leaves.size.y / whole.size.y >= 0.5)
		check("ac_40 %s canopy bottom >= 0.9 m above the tile" % t.name, leaves.position.y - t.global_position.y >= 0.9)
	finish()
