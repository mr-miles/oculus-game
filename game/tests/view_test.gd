class_name ViewTest
extends SceneTree
## Shared base for the scene tests (AC-12..15, 21..36): PASS/FAIL printing and
## helpers to build the lobby / a level and to set up level situations.
## Each test script is its own Godot process:
##   godot --headless --path game --script res://tests/test_ac_NN_name.gd

var failures := 0


func check(test_name: String, cond: bool) -> void:
	print(("PASS " if cond else "FAIL ") + test_name)
	if not cond:
		failures += 1


func finish() -> void:
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func new_game(level := 1) -> Node:  # call with await
	## A level scene with manual time (use advance()).
	var g: Node = load("res://main.tscn").instantiate()
	g.start_level = level
	g.auto_advance = false
	root.add_child(g)
	await process_frame
	return g


func new_lobby() -> Node:  # call with await
	var l: Node = load("res://lobby.tscn").instantiate()
	root.add_child(l)
	await process_frame
	return l


func settle() -> void:
	## Let queued frees and scene swaps finish.
	await process_frame
	await process_frame


func free_visible_tile(g: Node) -> Vector2i:
	var best := Vector2i(-1, -1)
	for z in g.logic.size:
		for x in g.logic.size:
			var t := Vector2i(x, z)
			if g.logic.can_see(t) and not g.logic.occupied(t):
				if best.x < 0 or g.logic.height(t) > g.logic.height(best):
					best = t
	return best


func stand_next_to(g: Node, target: Vector2i) -> void:
	## Put the player on a free neighbour of `target`, raised so that it looks
	## straight at it (a legal setup for sight-based actions).
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = target + d
		if g.logic.in_bounds(n) and not g.logic.occupied(n):
			g.logic.heights[n.y][n.x] = g.logic.height(target) + 1
			g.logic.player_tile = n
			g.rig.place_at(g.logic.top_position(n))
			return


func absorb_one_sentinel(g: Node) -> void:
	var t: Vector2i = g.logic.sentinels[0].tile
	stand_next_to(g, t)
	g.aim_at(t)
	g.press("trigger_left_click")


func tree_bounds(tree: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in tree.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func ray_from(g: Node, from: Vector3, toward: Vector3) -> Vector2i:
	## Point the right controller from `from` at `toward` and return the tile the ray selects.
	var dir := (toward - from).normalized()
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	g.rig.right.global_transform = Transform3D(Basis.looking_at(dir, up), from)
	g.rig.left.global_transform = g.rig.right.global_transform
	return g.aimed_tile()


func ray_down_at(g: Node, t: Vector2i) -> Vector2i:
	var c: Vector3 = g.logic.top_position(t)
	return ray_from(g, c + Vector3(0.1, 6.0, 0.1), c)


func find_tile(g: Node, wanted: Callable) -> Vector2i:
	for z in g.logic.size:
		for x in g.logic.size:
			if wanted.call(Vector2i(x, z)):
				return Vector2i(x, z)
	return Vector2i(-1, -1)


func terrain_triangles(g: Node) -> Array:
	## Every triangle of the terrain as {v: [3 positions], c: [3 colours]}.
	var out := []
	for m in g.find_child("Terrain", true, false).get_children():
		var arrays: Array = (m as MeshInstance3D).mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in range(0, verts.size(), 3):
			out.append({"v": [verts[i], verts[i + 1], verts[i + 2]], "c": [cols[i], cols[i + 1], cols[i + 2]]})
	return out
