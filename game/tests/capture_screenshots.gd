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
	g.press("by_left_button")  # Y: the pause menu appears in front of you, fixed in the world
	await _shot("pause-menu")
	g.press("by_left_button")
	# A body next to the tree for scale, then the hill's Sentinel with the watched warning.
	var body := free_visible_tile(g)
	g.aim_at(body)
	g.press("trigger_click")
	_face(g, start, body)
	await _shot("move-1-before")
	g.press("ax_button")
	g.advance(0.3)
	_face(g, logic.player_tile, tree)
	await _shot("move-2-after")
	var s: Vector2i = logic.sentinels[0].tile
	_face(g, logic.player_tile, s)
	logic.watched = true
	logic.watch_ticks = 194  # 5.2 s until the first drain
	g.refresh()
	g._step_watch_vignette(1.0)  # the red screen edges, fully in
	await _shot("hud-watched-sentinel")
	logic.watched = false
	g._step_watch_vignette(1.0)
	# Trees: stand a few tiles back so the whole tree is in view, a synthoid beside it for scale.
	logic.watched = false
	var spot := _spot_viewing(logic, tree)
	logic.player_tile = spot
	g.rig.place_at(logic.top_position(spot))
	logic.synthoids[_free_neighbour(logic, tree)] = true
	_face(g, spot, tree)
	g.refresh()
	await _shot("trees-bigger")
	# A boulder stack made with the real controls: three boulders, then a synthoid on top.
	logic.energy = 20
	var pile := _free_neighbour(logic, tree)
	logic.synthoids.erase(pile)
	g.refresh()
	g.aim_at(pile)
	g.press("grip_click")  # boulder mode: the HUD reads "Create: Boulder (2)"
	for i in 3:
		g.press("trigger_click")
	g.press("grip_click")
	g.press("trigger_click")  # the synthoid goes on top of the boulders
	g.press("grip_click")
	g.aim_at(Vector2i(-1, -1))
	g._aim_forced = false
	await _shot("boulder-stack")
	# Climb: two boulders under your own feet lift the view (boulder mode is still on).
	logic.energy = 20
	g.aim_at(logic.player_tile)
	g.press("trigger_click")
	g.press("trigger_click")
	g.aim_at(Vector2i(-1, -1))
	g._aim_forced = false
	g.refresh()
	await _shot("boulder-view-from-stack")
	# A slope close-up: stand on a flat tile beside a sloped one and look at it.
	var slope := find_tile(g, func(t: Vector2i) -> bool: return not logic.is_flat(t) and _flat_neighbour(logic, t).x >= 0)
	var edge := _flat_neighbour(logic, slope)
	logic.player_tile = edge
	g.rig.origin.rotation_degrees = Vector3.ZERO
	g.rig.place_at(logic.top_position(edge))
	_face(g, edge, slope)
	g.aim_at(slope)
	g.refresh()
	await _shot("slope-closeup")
	g.press("trigger_click")  # "Needs flat ground"
	await _shot("slope-needs-flat-ground")
	# Terrain from high above, looking straight down.
	g.rig.origin.global_position = Vector3(logic.size, 2.2 * logic.size, logic.size)
	g.rig.origin.rotation_degrees = Vector3(-90, 0, 0)
	await _shot("terrain-top-view")
	# Out over the edge of the hill: the desert and its haze.
	g.rig.origin.global_position = Vector3(logic.size * 2.0 + 20.0, 14.0, logic.size)
	g.rig.origin.rotation_degrees = Vector3(-8, -90, 0)
	await _shot("desert-view")


func _free_neighbour(logic: GameLogic, t: Vector2i) -> Vector2i:
	## A flat, empty, visible tile next to t (the player is already in place).
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = t + d
		if logic.in_bounds(n) and logic.is_flat(n) and logic.can_see(n) and not logic.occupied(n):
			return n
	return t


func _spot_viewing(logic: GameLogic, tree: Vector2i) -> Vector2i:
	## A free tile 3..5 tiles from the tree with a clear line of sight to it.
	var keep := logic.player_tile
	for dist in [4, 3, 5]:
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
			var c: Vector2i = tree + d * dist
			if logic.in_bounds(c) and not logic.occupied(c):
				logic.player_tile = c
				if logic.can_see(tree):
					logic.player_tile = keep
					return c
	logic.player_tile = keep
	return keep


func _flat_neighbour(logic: GameLogic, t: Vector2i) -> Vector2i:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = t + d
		if logic.in_bounds(n) and logic.is_flat(n) and not logic.occupied(n):
			return n
	return Vector2i(-1, -1)
