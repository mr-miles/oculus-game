extends SceneTree
## Smoke test: instantiate the main scene without XR and run some frames.
## Run: godot --headless --path game --script res://tests/test_scene.gd

func _init() -> void:
	var s: Node = load("res://main.tscn").instantiate()
	root.add_child(s)
	for i in 5:
		await process_frame
	var ok: bool = s.markers.size() == 4 and s.origin.position.is_equal_approx(s.logic.top_position(s.logic.player_tile))
	print("scene smoke: markers=%d origin=%s" % [s.markers.size(), s.origin.position])
	print("SCENE PASS" if ok else "SCENE FAIL")
	quit(0 if ok else 1)
