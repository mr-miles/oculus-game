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
	g.press("by_button")


func tree_bounds(tree: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in tree.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
