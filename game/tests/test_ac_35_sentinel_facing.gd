extends ViewTest
## AC-35: each Sentinel's nose points where its logic facing says, after advance.

func _init() -> void:
	var g := await new_game()
	g.aim_at(free_visible_tile(g))
	g.press("trigger_click")  # Sentinels stay idle until the first action
	for step in 3:
		g.advance(12.0)
		for s in g.logic.sentinels:
			var node: Node3D = g.find_child("Sentinel_%d_%d" % [s.tile.x, s.tile.y], true, false)
			var nose: Node3D = node.find_child("Nose", true, false)
			var d := nose.global_position - node.global_position
			var shown := fposmod(rad_to_deg(atan2(d.x, d.z)), 360.0)
			var diff := absf(angle_difference(deg_to_rad(shown), deg_to_rad(s.facing)))
			check("ac_35 step %d nose matches facing %.1f" % [step, s.facing], diff < 0.01)
	finish()
