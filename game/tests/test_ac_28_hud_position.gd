extends ViewTest
## AC-28: Hud local position is (0, +0.9 +-0.05, -2.5 +-0.1), above the gaze centre.

func _init() -> void:
	var g := await new_game()
	var hud: Node3D = g.find_child("Hud", true, false)
	check("ac_28 x is 0", absf(hud.position.x) < 0.001)
	check("ac_28 y is +0.9 +-0.05 (above the gaze centre)", absf(hud.position.y - 0.9) <= 0.05)
	check("ac_28 z is -2.5 +-0.1", absf(hud.position.z + 2.5) <= 0.1)
	check("ac_28 HUD is at least 1.5x larger on screen than the old 1.2 m layout", hud.scale.x / absf(hud.position.z) >= 1.5 / 1.2 - 0.02)
	finish()
