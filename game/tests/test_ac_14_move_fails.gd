extends ViewTest
## AC-14: A with no valid target leaves the origin alone and says why.

func _init() -> void:
	var g := await new_game()
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var before := origin.global_position
	g.aim_at(free_visible_tile(g))
	g.press("ax_button")
	g.advance(0.3)
	check("ac_14 origin unchanged", origin.global_position.is_equal_approx(before))
	check("ac_14 HudMessage has a reason", (g.find_child("HudMessage", true, false) as Label3D).text != "")
	g.aim_at(Vector2i(-1, -1))
	g.press("ax_button")
	check("ac_14 no tile aimed also gives a reason", (g.find_child("HudMessage", true, false) as Label3D).text != "")
	finish()
