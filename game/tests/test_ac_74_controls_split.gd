extends ViewTest
## AC-74: the right hand creates and moves, the left hand absorbs with its own ray.

func _init() -> void:
	var g := await new_game()
	var logic: GameLogic = g.logic
	var tree := Vector2i(-1, -1)
	for t in logic.trees:
		if logic.can_see(t):
			tree = t
			break
	check("ac_74 the start view shows a tree", tree.x >= 0)
	var tile := find_tile(g, func(t: Vector2i) -> bool:
		return logic.is_flat(t) and logic.can_see(t) and not logic.occupied(t) and t != logic.player_tile)
	check("ac_74 the left controller has its own ray", g.rig.get("_left_ray") != null)
	# Right B does nothing any more.
	g.aim_at(tree)
	var energy: int = logic.energy
	g.press("by_button")
	check("ac_74 right B no longer absorbs", logic.trees.has(tree) and logic.energy == energy)
	# The right trigger creates, never absorbs.
	g.press("trigger_click")
	check("ac_74 right trigger does not absorb", logic.trees.has(tree))
	# The left trigger absorbs the tile the LEFT ray aims at, whatever the right ray does.
	g._aim_forced = false
	var c: Vector3 = logic.top_position(tree)
	var from := c + Vector3(0.1, 6.0, 0.1)
	var dir := (c - from).normalized()
	g.rig.left.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	var away: Vector3 = logic.top_position(tile)
	var from_r := away + Vector3(0.1, 6.0, 0.1)
	g.rig.right.global_transform = Transform3D(Basis.looking_at((away - from_r).normalized(), Vector3.UP), from_r)
	check("ac_74 left ray aims at the tree", g.aimed_tile("left") == tree)
	check("ac_74 right ray aims elsewhere", g.aimed_tile("right") == tile)
	var before: int = logic.energy
	g.press("trigger_left_click")
	check("ac_74 left trigger absorbed the tree the left ray aims at", not logic.trees.has(tree) and logic.energy == before + GameLogic.TREE_ENERGY)
	var left_ray: Node3D = g.rig.left.get_child(g.rig.left.get_child_count() - 1)
	check("ac_74 the left ray is a child of the left controller", left_ray is MeshInstance3D)
	# The right trigger made a synthoid on the right ray's tile earlier or not; just check no absorb of it.
	finish()
