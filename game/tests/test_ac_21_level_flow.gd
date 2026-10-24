extends ViewTest
## AC-21: clearing level n<10 loads n+1; clearing 10 shows the ending, then the lobby.

func _init() -> void:
	var g := await new_game(1)
	while g.logic.sentinels_left() > 0:
		absorb_one_sentinel(g)
	check("ac_21 level won", g.logic.state == "won")
	g.advance(3.1)
	check("ac_21 level 2 loaded", g.logic.level == 2)
	check("ac_21 HUD says Level 2 of 10", (g.find_child("HudLevel", true, false) as Label3D).text == "Level 2 of 10")
	g.queue_free()
	await settle()
	# A lost level offers the trigger to retry the same level with its original energy.
	var lost := await new_game(3)
	var start_energy: int = lost.logic.start_energy
	lost.logic.energy = 0
	lost.logic.state = "lost"
	lost.advance(0.1)
	check("ac_21 lost message shown", (lost.find_child("HudMessage", true, false) as Label3D).text.contains("try again"))
	lost.press("trigger_click")
	check("ac_21 trigger retries the same level", lost.logic.level == 3 and lost.logic.state == "playing"
			and lost.logic.energy == start_energy)
	lost.queue_free()
	await settle()
	var last := await new_game(10)
	while last.logic.sentinels_left() > 0:
		absorb_one_sentinel(last)
	check("ac_21 ending card shown", (last.find_child("EndingCard", true, false) as Node3D).visible)
	last.advance(3.1)
	await settle()
	check("ac_21 lobby follows the ending", root.get_node_or_null("Lobby") != null and root.get_node_or_null("Main") == null)
	finish()
