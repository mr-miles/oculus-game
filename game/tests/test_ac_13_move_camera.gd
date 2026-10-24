extends ViewTest
## AC-13: after a move the camera is 1.6 m above the new tile and the HUD shows.

func _init() -> void:
	var g := await new_game()
	var t := free_visible_tile(g)
	g.logic.synthoids[t] = true
	g.aim_at(t)
	g.press("ax_button")
	g.advance(0.3)
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	check("ac_13 camera y = height + 1.6", absf(cam.global_position.y - (g.logic.height(t) + 1.6)) < 0.01)
	var hud: Node3D = g.find_child("Hud", true, false)
	check("ac_13 HUD visible", hud.is_visible_in_tree())
	check("ac_13 HUD energy text present", (g.find_child("HudEnergy", true, false) as Label3D).text != "")
	finish()
