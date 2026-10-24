extends ViewTest
## AC-15: left stick right turns the origin 30 degrees; the tile is unchanged.

func _init() -> void:
	var g := await new_game()
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var tile: Vector2i = g.logic.player_tile
	var yaw := origin.rotation.y
	g.press("stick_right")
	var turned := rad_to_deg(absf(angle_difference(yaw, origin.rotation.y)))
	check("ac_15 yaw changes by 30 degrees", absf(turned - 30.0) <= 0.5)
	check("ac_15 player tile unchanged", g.logic.player_tile == tile)
	g.press("stick_left")
	check("ac_15 left stick turns back", absf(angle_difference(yaw, origin.rotation.y)) < 0.01)
	finish()
