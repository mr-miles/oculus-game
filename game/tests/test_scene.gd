extends ViewTest
## Smoke test of the real launch path: lobby -> Start -> a few live frames.
## Run: godot --headless --path game --script res://tests/test_scene.gd

func _init() -> void:
	var l := await new_lobby()
	l.press_start()
	for i in 10:
		await process_frame
	var g := root.get_node_or_null("Main")
	var ok: bool = g != null and g.logic.state == "playing"
	if ok:
		var objects: int = g.logic.trees.size() + g.logic.synthoids.size() + g.logic.sentinels.size()
		ok = g.find_children("Tree_*", "Node3D", true, false).size() == g.logic.trees.size() \
				and g.find_children("Sentinel_*", "Node3D", true, false).size() == g.logic.sentinels.size() \
				and g.rig.origin.global_position.is_equal_approx(g.logic.top_position(g.logic.player_tile)) \
				and objects > 0
	print("SCENE PASS" if ok else "SCENE FAIL")
	quit(0 if ok else 1)
