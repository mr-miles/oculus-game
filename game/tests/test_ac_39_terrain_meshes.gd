extends ViewTest
## AC-39: the 31x31 terrain is at most 16 mesh instances (merged blocks).

func _init() -> void:
	var g := await new_game()
	check("ac_39 grid is 31x31", g.logic.size == 31)
	var blocks := g.find_child("Terrain", true, false).find_children("*", "MeshInstance3D", true, false)
	check("ac_39 terrain uses 1..16 mesh instances", blocks.size() >= 1 and blocks.size() <= 16)
	var all_filled := true
	for b in blocks:
		all_filled = all_filled and (b as MeshInstance3D).mesh.get_surface_count() == 1
	check("ac_39 every block has geometry", all_filled)
	finish()
