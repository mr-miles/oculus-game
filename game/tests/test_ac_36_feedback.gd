extends ViewTest
## AC-36: failed actions explain themselves; successful ones play their sound.

func _msg(g: Node) -> String:
	return (g.find_child("HudMessage", true, false) as Label3D).text


func _init() -> void:
	var g := await new_game()
	var own: Vector2i = g.logic.player_tile
	g.aim_at(own)
	g.press("trigger_click")
	check("ac_36 failed create explains", _msg(g) != "")
	g.aim_at(free_visible_tile(g))
	g.press("ax_button")
	check("ac_36 failed move explains", _msg(g) != "")
	g.press("by_button")
	check("ac_36 failed absorb explains", _msg(g) != "")
	check("ac_36 three failure sounds", g.sfx.counts.get("fail", 0) == 3)
	var t := free_visible_tile(g)
	g.aim_at(t)
	g.press("trigger_click")
	check("ac_36 create plays its sound", g.sfx.counts.get("create", 0) == 1 and _msg(g) == "")
	g.press("by_button")
	check("ac_36 absorb plays its sound", g.sfx.counts.get("absorb", 0) == 1)
	g.press("trigger_click")
	g.press("ax_button")
	check("ac_36 move plays its sound", g.sfx.counts.get("move", 0) == 1)
	finish()
