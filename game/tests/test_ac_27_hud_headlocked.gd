extends ViewTest
## AC-27: Hud is a descendant of XRCamera3D, not of a controller; its local transform never changes.

func _init() -> void:
	var g := await new_game()
	var hud: Node3D = g.find_child("Hud", true, false)
	var cam: Node = g.find_child("XRCamera3D", true, false)
	check("ac_27 Hud under XRCamera3D", cam.is_ancestor_of(hud))
	check("ac_27 Hud not under either controller",
			not g.find_child("LeftController", true, false).is_ancestor_of(hud)
			and not g.find_child("RightController", true, false).is_ancestor_of(hud))
	var before := hud.transform
	var t := free_visible_tile(g)
	g.logic.synthoids[t] = true
	g.aim_at(t)
	g.press("ax_button")
	g.advance(0.3)
	g.press("stick_right")
	check("ac_27 local transform constant while the camera moves", hud.transform == before)
	finish()
