extends ViewTest
## AC-34: the ray selects the tile when it passes over a tree (or synthoid) on it.

func _ray_from(g: Node, from: Vector3, toward: Vector3) -> Vector2i:
	var dir := (toward - from).normalized()
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	g.rig.right.global_transform = Transform3D(Basis.looking_at(dir, up), from)
	return g.aimed_tile()


func _init() -> void:
	var g := await new_game()
	var tree: Vector2i = g.logic.trees.keys()[0]
	var top: Vector3 = g.logic.top_position(tree)
	check("ac_34 ray into the canopy selects the tree tile",
			_ray_from(g, top + Vector3(0.6, 6.0, 0.0), top + Vector3(0.6, 2.5, 0.0)) == tree)
	var south := Vector2i(tree.x, tree.y - 1)
	if g.logic.in_bounds(south) and g.logic.height(south) + 1 < top.y + 2.6 and not g.logic.occupied(south):
		check("ac_34 ray at the canopy's side selects the tree tile",
				_ray_from(g, top + Vector3(0.0, 2.6, -4.0), top + Vector3(0.0, 2.6, 0.0)) == tree)
	# A synthoid's body: a ray descending towards its head must not run on to the tile behind.
	var t := free_visible_tile(g)
	g.logic.synthoids[t] = true
	g.refresh()
	var s: Vector3 = g.logic.top_position(t)
	check("ac_34 ray at a synthoid's head selects its tile",
			_ray_from(g, s + Vector3(0, 6.0, 0), s + Vector3(0, 1.4, 0)) == t)
	finish()
