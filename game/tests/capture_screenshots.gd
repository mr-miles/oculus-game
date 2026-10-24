extends ViewTest
## Renders the docs/screenshots images. Needs a display (tools/screenshots.sh runs it under Xvfb):
##   godot --path game --script res://tests/capture_screenshots.gd -- <output-dir>

var out_dir := "res://../docs/screenshots"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _lobby_shots()
	await _level_shots()
	quit(0)


func _shot(shot_name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, shot_name])
	print("saved ", shot_name)


func _face(g: Node, from: Vector2i, target: Vector2i) -> void:
	## Turn the XR origin so the player looks at `target`.
	var d: Vector3 = g.logic.top_position(target) - g.logic.top_position(from)
	g.rig.origin.rotation.y = atan2(-d.x, -d.z)


func _lobby_shots() -> void:
	var l := await new_lobby()
	await _shot("lobby-1-story")
	l.next()
	l.next()
	await _shot("lobby-3-how-to-play")
	l.queue_free()
	await settle()


func _level_shots() -> void:
	var g := await new_game()
	var logic: GameLogic = g.logic
	var start: Vector2i = logic.player_tile
	var tree: Vector2i = logic.trees.keys()[0]
	_face(g, start, tree)
	await _shot("hud-start")
	# A body next to the tree for scale, then the hill's Sentinel with the watched warning.
	var body := free_visible_tile(g)
	g.aim_at(body)
	g.press("trigger_click")
	_face(g, start, body)
	await _shot("move-1-before")
	g.press("ax_button")
	g.advance(0.3)
	await _shot("move-2-after")
	var s: Vector2i = logic.sentinels[0].tile
	_face(g, logic.player_tile, s)
	logic.watched = true
	logic.drain_countdown = 5.2
	g.refresh()
	await _shot("hud-watched-sentinel")
	# Trees: stand close to one.
	logic.watched = false
	stand_next_to(g, tree)
	_face(g, logic.player_tile, tree)
	g.refresh()
	await _shot("trees-bigger")
