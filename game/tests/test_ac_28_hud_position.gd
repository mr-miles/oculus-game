extends ViewTest
## AC-28: Hud local position is (0, -0.3 +-0.05, -1.2 +-0.1).

func _init() -> void:
	var g := await new_game()
	var hud: Node3D = g.find_child("Hud", true, false)
	check("ac_28 x is 0", absf(hud.position.x) < 0.001)
	check("ac_28 y is -0.3 +-0.05", absf(hud.position.y + 0.3) <= 0.05)
	check("ac_28 z is -1.2 +-0.1", absf(hud.position.z + 1.2) <= 0.1)
	finish()
