extends ViewTest
## AC-42: every HUD text element sits above the gaze line, inside the view.

func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	for n in ["HudEnergy", "HudLevel", "HudSentinels", "HudMode", "HudWatched", "HudMessage"]:
		var node: Node3D = g.find_child(n, true, false)
		check("ac_42 %s exists" % n, node != null)
		var p := cam.global_transform.affine_inverse() * node.global_position
		check("ac_42 %s local y in 0.5..1.5 (%.2f)" % [n, p.y], p.y >= 0.5 and p.y <= 1.5)
		check("ac_42 %s |x| <= 1.8" % n, absf(p.x) <= 1.8)
		check("ac_42 %s at z = -2.5" % n, absf(p.z + 2.5) <= 0.1)
		var up := rad_to_deg(atan2(p.y, -p.z))
		var side := rad_to_deg(atan2(absf(p.x), -p.z))
		check("ac_42 %s above gaze and inside the view (%.0f up, %.0f side)" % [n, up, side], up > 5.0 and up < 35.0 and side < 38.0)
	finish()
