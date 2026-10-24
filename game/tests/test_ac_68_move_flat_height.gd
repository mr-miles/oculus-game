extends ViewTest
## AC-68: after a transfer next to sloped tiles the origin is at the flat altitude, never interpolated.

func _init() -> void:
	var g := await new_game()
	var logic: GameLogic = g.logic
	var t := find_tile(g, func(c: Vector2i) -> bool:
		if not (logic.is_flat(c) and logic.can_see(c) and not logic.occupied(c)):
			return false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if logic.in_bounds(c + d) and not logic.is_flat(c + d):
				return true
		return false)
	check("ac_68 found a flat visible tile beside a slope", t.x >= 0)
	logic.synthoids[t] = true
	g.aim_at(t)
	g.press("ax_button")
	g.advance(0.3)
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var altitude: float = float(logic.height(t)) + 0.5 * logic.boulders.get(t, 0)
	check("ac_68 origin y is the flat altitude", absf(origin.global_position.y - altitude) <= 0.01)
	check("ac_68 camera y is that + 1.6", absf(cam.global_position.y - (altitude + 1.6)) <= 0.01)
	finish()
