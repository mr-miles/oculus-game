extends ViewTest
## AC-12: A on an aimed visible synthoid moves XROrigin3D to the tile top.

func _init() -> void:
	var g := await new_game()
	var t := free_visible_tile(g)
	g.logic.synthoids[t] = true
	g.aim_at(t)
	g.press("ax_button")
	g.advance(0.3)
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	check("ac_12 origin at top_position(T) within 1 cm", origin.global_position.distance_to(g.logic.top_position(t)) < 0.01)
	check("ac_12 logic player tile is T", g.logic.player_tile == t)
	finish()
