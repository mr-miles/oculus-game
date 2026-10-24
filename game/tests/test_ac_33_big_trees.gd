extends ViewTest
## AC-33: trees are >= 3.0 m tall, 0.5..1.9 m wide, taller than a synthoid.

func _init() -> void:
	var g := await new_game()
	var trees := g.find_children("Tree_*", "Node3D", true, false)
	check("ac_33 level has trees", trees.size() > 0)
	for t in trees:
		var b := tree_bounds(t)
		check("ac_33 %s height >= 3.0" % t.name, b.size.y >= 3.0)
		check("ac_33 %s width in (0.5, 1.9]" % t.name, b.size.x > 0.5 and b.size.x <= 1.9 and b.size.z <= 1.9)
	var tile := free_visible_tile(g)
	g.logic.synthoids[tile] = true
	g.refresh()
	var syn: Node3D = g.find_child("Synthoid_*", true, false)
	check("ac_33 taller than a synthoid", tree_bounds(trees[0]).size.y > tree_bounds(syn).size.y)
	finish()
