extends ViewTest
## AC-53: moving into a synthoid standing on 2 boulders puts the eye 1.0 m higher.

func _init() -> void:
	var g := await new_game()
	var t := free_visible_tile(g)
	g.logic.boulders[t] = 2
	g.logic.synthoids[t] = true
	g.aim_at(t)
	g.press("ax_button")
	g.advance(0.3)
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	check("ac_53 camera y = altitude + two boulders + 1.6", absf(cam.global_position.y - (g.logic.height(t) + 2.0 * GameLogic.BOULDER_HEIGHT + 1.6)) <= 0.01)
	check("ac_53 the boulders stay on the tile", g.logic.boulders.get(t, 0) == 2 and g.logic.player_tile == t)
	finish()
