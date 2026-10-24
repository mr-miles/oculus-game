extends ViewTest
## AC-26: pause menu (left Y) -> Back to lobby returns to the lobby.

func _init() -> void:
	var g := await new_game()
	g.press("by_left_button")
	var menu: Node3D = g.find_child("PauseMenu", true, false)
	check("ac_26 pause menu shown", menu.is_visible_in_tree())
	for id in ["ResumeButton", "RestartButton", "LobbyButton"]:
		check("ac_26 %s present" % id, menu.find_child(id, true, false) != null)
	g.press("by_left_button")
	check("ac_26 Y again resumes", not menu.is_visible_in_tree())
	g.press("by_left_button")
	g.choose_pause("lobby")
	await settle()
	check("ac_26 lobby is shown", root.get_node_or_null("Lobby") != null and root.get_node_or_null("Main") == null)
	finish()
