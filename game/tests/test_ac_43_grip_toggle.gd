extends ViewTest
## AC-43: grip toggles synthoid <-> boulder and nothing else.

func _init() -> void:
	var g := await new_game()
	check("ac_43 starts as synthoid", g.create_kind == "synthoid")
	var energy: int = g.logic.energy
	var tile: Vector2i = g.logic.player_tile
	var seen := {}
	for i in 7:
		g.press("grip_click")
		seen[g.create_kind] = true
		check("ac_43 press %d: expected %s" % [i + 1, "boulder" if i % 2 == 0 else "synthoid"],
				g.create_kind == ("boulder" if i % 2 == 0 else "synthoid"))
	check("ac_43 only the two kinds ever appear", seen.size() == 2 and seen.has("synthoid") and seen.has("boulder"))
	check("ac_43 toggling changes nothing else", g.logic.energy == energy and g.logic.player_tile == tile)
	finish()
