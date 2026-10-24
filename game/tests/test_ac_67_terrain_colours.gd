extends ViewTest
## AC-67: flat tiles use the two checker colours, non-flat tiles one darker colour, all different.

func _init() -> void:
	var g := await new_game()
	var logic: GameLogic = g.logic
	var flat_colours := {}
	var slope_colours := {}
	for t in terrain_triangles(g):
		var cx: float = (t.v[0].x + t.v[1].x + t.v[2].x) / 6.0  # centroid in tile units (tile = 2 m)
		var cz: float = (t.v[0].z + t.v[1].z + t.v[2].z) / 6.0
		var tile := Vector2i(int(floor(cx)), int(floor(cz)))
		tile = Vector2i(clampi(tile.x, 0, logic.size - 1), clampi(tile.y, 0, logic.size - 1))
		var same: bool = t.c[0] == t.c[1] and t.c[1] == t.c[2]
		check("ac_67 one colour per triangle", same)
		if logic.is_flat(tile):
			flat_colours[t.c[0]] = true
		else:
			slope_colours[t.c[0]] = true
	check("ac_67 flat tiles use exactly two colours", flat_colours.size() == 2)
	check("ac_67 non-flat tiles use one colour", slope_colours.size() == 1)
	var all := {}
	for c in flat_colours:
		all[c] = true
	for c in slope_colours:
		all[c] = true
	check("ac_67 the three colours differ", all.size() == 3)
	var slope_c: Color = slope_colours.keys()[0]
	var darker := true
	for c in flat_colours:
		darker = darker and slope_c.get_luminance() < c.get_luminance()
	check("ac_67 the slope colour is darker", darker)
	finish()
