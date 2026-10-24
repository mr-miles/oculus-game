extends ViewTest
## AC-42: every HUD text element sits above the gaze line, inside the view.

func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	for n in ["HudEnergy", "HudLevel", "HudSentinels", "HudMode", "HudWatched", "HudMessage"]:
		var node: Node3D = g.find_child(n, true, false)
		check("ac_42 %s exists" % n, node != null)
		var p := cam.global_transform.affine_inverse() * node.global_position
		check("ac_42 %s local y in 0.25..0.65 (%.2f)" % [n, p.y], p.y >= 0.25 and p.y <= 0.65)
		check("ac_42 %s |x| <= 0.8" % n, absf(p.x) <= 0.8)
		check("ac_42 %s at z = -1.2" % n, absf(p.z + 1.2) <= 0.1)
	finish()
