extends ViewTest
## AC-66: terrain vertices sit on the corner grid, split on the a-d diagonal, with a border skirt to y = 0.

func _near(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) < 0.001


func _has_triangle(tris: Array, p: Vector3, q: Vector3, r: Vector3) -> bool:
	for t in tris:
		var ok := 0
		for v in t.v:
			if _near(v, p) or _near(v, q) or _near(v, r):
				ok += 1
		if ok == 3:
			return true
	return false


func _init() -> void:
	var g := await new_game()
	var logic: GameLogic = g.logic
	var tris := terrain_triangles(g)
	var surface := []
	var walls := []
	for t in tris:
		var n: Vector3 = (t.v[1] - t.v[0]).cross(t.v[2] - t.v[0])
		(walls if absf(n.y) < 0.0001 else surface).append(t)
	var bad_corner := 0
	var bad_split := 0
	for z in logic.size:
		for x in logic.size:
			var a := Vector3(x * 2.0, logic.corner(x, z), z * 2.0)
			var b := Vector3((x + 1) * 2.0, logic.corner(x + 1, z), z * 2.0)
			var c := Vector3(x * 2.0, logic.corner(x, z + 1), (z + 1) * 2.0)
			var d := Vector3((x + 1) * 2.0, logic.corner(x + 1, z + 1), (z + 1) * 2.0)
			if not (_has_triangle(surface, a, b, d) and _has_triangle(surface, a, d, c)):
				bad_split += 1
	for t in surface:
		for v in t.v:
			if absf(v.y - logic.corner(roundi(v.x / 2.0), roundi(v.z / 2.0))) > 0.001:
				bad_corner += 1
	check("ac_66 every vertex is on a corner altitude", bad_corner == 0)
	check("ac_66 every tile is split along the a-d diagonal", bad_split == 0)
	# Skirt: every border edge of the field has a wall down to y = 0.
	var gaps := 0
	for i in logic.size:
		for edge in [[Vector3(i * 2.0, 0, 0), Vector3((i + 1) * 2.0, 0, 0)],
				[Vector3(i * 2.0, 0, logic.size * 2.0), Vector3((i + 1) * 2.0, 0, logic.size * 2.0)],
				[Vector3(0, 0, i * 2.0), Vector3(0, 0, (i + 1) * 2.0)],
				[Vector3(logic.size * 2.0, 0, i * 2.0), Vector3(logic.size * 2.0, 0, (i + 1) * 2.0)]]:
			var found := false
			for w in walls:
				var low := 0
				for v in w.v:
					if absf(v.y) < 0.001 and (_near(Vector3(v.x, 0, v.z), edge[0]) or _near(Vector3(v.x, 0, v.z), edge[1])):
						low += 1
				if low >= 1:
					found = true
					break
			if not found:
				gaps += 1
	check("ac_66 the border has a skirt down to y = 0", gaps == 0 and walls.size() >= 4 * logic.size * 2)
	finish()
