extends ViewTest
## AC-52: HudMode shows the create mode; a retry goes back to synthoid.

func _mode(g: Node) -> String:
	return (g.find_child("HudMode", true, false) as Label3D).text


func _init() -> void:
	var g := await new_game()
	check("ac_52 level start: synthoid", _mode(g) == "Create: Synthoid (3)")
	g.press("grip_click")
	check("ac_52 after grip: boulder", _mode(g) == "Create: Boulder (2)")
	g.logic.state = "lost"
	g.advance(0.1)
	g.press("trigger_click")
	check("ac_52 after a retry: synthoid", _mode(g) == "Create: Synthoid (3)")
	finish()
