extends ViewTest
## AC-25: Start is visible on every page; press_start loads level 1 with 10 energy.

func _init() -> void:
	var l := await new_lobby()
	var start: Node3D = l.find_child("StartButton", true, false)
	for i in 4:
		check("ac_25 StartButton visible on page %d" % (i + 1), start.is_visible_in_tree())
		l.next()
	l.press_start()
	await settle()
	var g := root.get_node_or_null("Main")
	check("ac_25 level scene loaded", g != null)
	check("ac_25 level 1, energy 10", g.logic.level == 1 and g.logic.energy == 10)
	check("ac_25 HUD says Level 1 of 10", (g.find_child("HudLevel", true, false) as Label3D).text == "Level 1 of 10")
	check("ac_25 lobby is gone", root.get_node_or_null("Lobby") == null)
	finish()
