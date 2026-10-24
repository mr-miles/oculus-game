extends ViewTest
## AC-29: the HUD energy number follows create and absorb.

func _shown(g: Node) -> int:
	return int((g.find_child("HudEnergy", true, false) as Label3D).text.get_slice(" ", 1))


func _init() -> void:
	var g := await new_game()
	check("ac_29 starts at logic energy", _shown(g) == g.logic.energy)
	var t := free_visible_tile(g)
	g.aim_at(t)
	g.press("trigger_click")
	check("ac_29 drops by 3 after create", _shown(g) == g.logic.energy and g.logic.energy == 7)
	g.press("by_button")
	check("ac_29 rises by 3 after absorbing the body", _shown(g) == g.logic.energy and g.logic.energy == 10)
	finish()
