extends ViewTest
## AC-45: a boulder on your own tile lifts you 0.5 m; a synthoid there is refused.

func _init() -> void:
	var g := await new_game()
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var own: Vector2i = g.logic.player_tile
	var energy: int = g.logic.energy
	g.aim_at(own)
	g.press("trigger_click")
	check("ac_45 synthoid on own tile fails with a reason", g.logic.energy == energy
			and (g.find_child("HudMessage", true, false) as Label3D).text != "")
	g.press("grip_click")
	var before := origin.global_position
	g.press("trigger_click")
	g.advance(0.3)
	check("ac_45 energy -2", g.logic.energy == energy - 2)
	check("ac_45 tile unchanged, one boulder under the player", g.logic.player_tile == own and g.logic.boulders.get(own, 0) == 1)
	check("ac_45 origin is one boulder higher, x and z unchanged", absf(origin.global_position.y - before.y - GameLogic.BOULDER_HEIGHT) <= 0.01
			and absf(origin.global_position.x - before.x) <= 0.01 and absf(origin.global_position.z - before.z) <= 0.01)
	check("ac_45 camera y = altitude + one boulder + 1.6", absf(cam.global_position.y - (g.logic.height(own) + GameLogic.BOULDER_HEIGHT + 1.6)) <= 0.01)
	finish()
