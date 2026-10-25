extends Node3D
## VR view of one level. Right controller points a ray at tiles: trigger =
## create synthoid, A = move into it. The left controller has its own (orange) ray:
## left trigger = absorb. Left stick snap-turns, Y pauses, X shows a hint. All rules live in GameLogic; this node only shows
## the state and forwards input. Tests drive it with press / aim_at / advance.

const TREE_HEIGHT := 3.0
const TRUNK_HEIGHT := 1.2
const TRUNK_RADIUS := 0.25
const CANOPY_RADIUS := 0.9
const SYNTHOID_HEIGHT := 1.6
const BOULDER_RADIUS := 0.8
const COLOR_BOULDER := Color(0.55, 0.55, 0.58)
const SENTINEL_HEIGHT := 3.0
const FADE_SECONDS := 0.2
const CLEARED_SECONDS := 3.0
const DEFLATE_SECONDS := 0.8  # an absorbed Sentinel sags and shrinks away over this long
const RAY_REACH := 90.0
const RAY_STEP := 0.2
const MSG_LOST := "You ran out of energy. Pull the trigger to try again."
const COLOR_SYNTHOID := Color(0.2, 0.4, 1.0)
const COLOR_TREE := Color(0.1, 0.8, 0.2)
const COLOR_SENTINEL := Color(0.8, 0.15, 0.15)
const COLOR_NOSE := Color(1, 0.9, 0.2)

const PAUSE_DISTANCE := 1.5  # metres in front of the player when the pause menu opens

var start_level := 1          ## set by the lobby before the node enters the tree
var auto_advance := true      ## tests turn this off and call advance() themselves
var logic: GameLogic
var rig: Rig
var hud: Hud
var sfx: Sfx
var menu: Menu3D
var sentinels_total := 0
var paused := false
var create_kind := "synthoid"  ## what the trigger creates: "synthoid" or "boulder"

var _world: Node3D
var _cursor: MeshInstance3D
var _cursor_left: MeshInstance3D  # where the left (absorb) ray lands
var _fade: MeshInstance3D
var _ending: Label3D
var _markers := {}    # Vector2i -> Node3D (trees, synthoids)
var _sentinels := {}  # Vector2i -> Node3D
var _deflating: Array = []  # [Node3D, seconds left] for Sentinels being absorbed
var _won_card: Label3D  # big "Hill cleared!" in the middle of the view
var _boulders := {}   # Vector2i -> Node3D (a stack), with meta "count"
var _ghost: MeshInstance3D
var _message := ""
var _aim_tile := Vector2i(-1, -1)
var _aim_forced := false
var _fade_left := -1.0
var _move_to := Vector2i(-1, -1)
var _cleared_left := -1.0
var _announced := ""


func _ready() -> void:
	Scenery.add_sky(self)
	rig = Rig.new()
	add_child(rig)
	rig.button.connect(_dispatch)
	rig.left_button.connect(_dispatch)
	rig.snap.connect(func(d: int) -> void: _dispatch("stick_right" if d > 0 else "stick_left"))
	sfx = Sfx.new()
	add_child(sfx)
	hud = Hud.new()
	rig.camera.add_child(hud)
	_build_overlays()
	_cursor = Scenery.mesh_node("Cursor", _disc(0.8, 0.04), Color.WHITE, Vector3.ZERO)
	_cursor.material_override = Rig.unshaded(Color.WHITE)
	_cursor.visible = false
	add_child(_cursor)
	_cursor_left = Scenery.mesh_node("CursorLeft", _disc(0.5, 0.04), Color.WHITE, Vector3.ZERO)
	_cursor_left.material_override = Rig.unshaded(Rig.LEFT_RAY_COLOR)
	_cursor_left.visible = false
	add_child(_cursor_left)
	_ghost = Scenery.mesh_node("Ghost", null, Color.WHITE, Vector3.ZERO)
	add_child(_ghost)
	load_level(start_level)


func _disc(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	return c


func _build_overlays() -> void:
	_fade = Scenery.mesh_node("Vignette", QuadMesh.new(), Color.BLACK, Vector3(0, 0, -0.3))
	(_fade.mesh as QuadMesh).size = Vector2(2, 2)
	_fade.material_override = Rig.unshaded(Color(0, 0, 0, 0))
	(_fade.material_override as StandardMaterial3D).no_depth_test = true
	(_fade.material_override as StandardMaterial3D).render_priority = 100
	_fade.visible = false
	rig.camera.add_child(_fade)
	_ending = Label3D.new()
	_ending.name = "EndingCard"
	_ending.text = "The valley is bright again!\nThe Sentinels are friendly beacons now.\nThank you for playing."
	_ending.font_size = 56
	_ending.pixel_size = 0.0015
	_ending.no_depth_test = true
	_ending.render_priority = 12
	_ending.position = Vector3(0, 0.25, -1.2)
	_ending.visible = false
	rig.camera.add_child(_ending)
	_won_card = Label3D.new()
	_won_card.name = "WonCard"
	_won_card.font_size = 160
	_won_card.pixel_size = 0.002
	_won_card.outline_size = 36
	_won_card.modulate = Color(1, 0.95, 0.4)
	_won_card.no_depth_test = true
	_won_card.render_priority = 13
	_won_card.position = Vector3(0, 0.1, -2.0)
	_won_card.visible = false
	rig.camera.add_child(_won_card)
	menu = Menu3D.new(Vector2(1.0, 0.75))
	menu.name = "PauseMenu"
	menu.add_label("Title", Vector2(0, 0.28), 56).text = "Paused"
	menu.add_button("ResumeButton", "resume", "Resume", Vector2(0, 0.12), Vector2(0.7, 0.14))
	menu.add_button("RestartButton", "restart", "Restart level", Vector2(0, -0.06), Vector2(0.7, 0.14))
	menu.add_button("LobbyButton", "lobby", "Back to lobby", Vector2(0, -0.24), Vector2(0.7, 0.14))
	menu.chosen.connect(_on_pause_choice)
	menu.visible = false
	add_child(menu)  # fixed in the world; _place_pause_menu puts it in front of you on open


# --- levels -----------------------------------------------------------------

func load_level(n: int) -> void:
	_enter(Levels.build(n))


func _enter(level_logic: GameLogic) -> void:
	logic = level_logic
	create_kind = "synthoid"
	sentinels_total = logic.sentinels_left()
	_message = "Aim, then pull the trigger to make a body."
	_announced = ""
	_cleared_left = -1.0
	_fade_left = -1.0
	_ending.visible = false
	_won_card.visible = false
	_deflating.clear()  # the old world (and these nodes with it) is freed by _build_world
	_set_paused(false)
	_build_world()
	rig.place_at(logic.top_position(logic.player_tile))
	refresh()


func retry_level() -> void:
	_enter(Levels.retry(logic))


func go_lobby() -> void:
	var lobby: Node = load("res://lobby.tscn").instantiate()
	get_parent().add_child(lobby)
	queue_free()


func _build_world() -> void:
	if _world:
		_world.queue_free()
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)
	_markers.clear()
	_sentinels.clear()
	_boulders.clear()
	var terrain := Terrain.new()
	_world.add_child(terrain)
	terrain.build(logic)


func _sync_objects() -> void:
	for k in _markers.keys():
		if logic.object_at(k) != _markers[k].get_meta("kind"):
			_markers[k].queue_free()
			_markers.erase(k)
	for k in _sentinels.keys():
		if logic.sentinel_at(k) < 0:
			_start_deflate(_sentinels[k])
			_sentinels.erase(k)
	for t in logic.synthoids.keys():
		if not _markers.has(t):
			_markers[t] = _place(_make_synthoid(t), t, "synthoid")
	for t in logic.trees.keys():
		if not _markers.has(t):
			_markers[t] = _place(_make_tree(t), t, "tree")
	_sync_boulders()
	for s in logic.sentinels:
		if not _sentinels.has(s.tile):
			var node := _make_sentinel(s.tile)
			_world.add_child(node)
			_sentinels[s.tile] = node
		_sentinels[s.tile].rotation.y = deg_to_rad(s.facing)


func _sync_boulders() -> void:
	for k in _boulders.keys():
		if logic.boulders.get(k, 0) != _boulders[k].get_meta("count"):
			_boulders[k].queue_free()
			_boulders.erase(k)
	for t in logic.boulders:
		if not _boulders.has(t):
			_boulders[t] = _make_boulders(t, logic.boulders[t])


func _make_boulders(t: Vector2i, count: int) -> Node3D:
	## A stack of flat grey slabs, each GameLogic.BOULDER_HEIGHT high, with no gaps.
	var n := Node3D.new()
	n.name = "Boulders_%d_%d" % [t.x, t.y]
	n.set_meta("count", count)
	n.position = Vector3((t.x + 0.5) * GameLogic.TILE, float(logic.height(t)), (t.y + 0.5) * GameLogic.TILE)
	for i in count:
		n.add_child(Scenery.mesh_node("Boulder_%d" % i, _slab(), COLOR_BOULDER,
				Vector3(0, GameLogic.BOULDER_HEIGHT * (i + 0.5), 0)))
	_world.add_child(n)
	return n


func _slab() -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = BOULDER_RADIUS * 0.92
	c.bottom_radius = BOULDER_RADIUS
	c.height = GameLogic.BOULDER_HEIGHT
	return c


func _place(node: Node3D, t: Vector2i, kind: String) -> Node3D:
	node.position = logic.top_position(t)
	node.set_meta("kind", kind)
	_world.add_child(node)
	return node


func _make_synthoid(t: Vector2i) -> Node3D:
	var n := Node3D.new()
	n.name = "Synthoid_%d_%d" % [t.x, t.y]
	n.add_child(Scenery.mesh_node("Body", _capsule(), COLOR_SYNTHOID, Vector3(0, SYNTHOID_HEIGHT / 2.0, 0)))
	return n


func _make_tree(t: Vector2i) -> Node3D:
	var n := Node3D.new()
	n.name = "Tree_%d_%d" % [t.x, t.y]
	var trunk_h := TRUNK_HEIGHT
	var trunk := CylinderMesh.new()
	trunk.top_radius = TRUNK_RADIUS
	trunk.bottom_radius = TRUNK_RADIUS
	trunk.height = trunk_h
	n.add_child(Scenery.mesh_node("Trunk", trunk, Color(0.45, 0.3, 0.15), Vector3(0, trunk_h / 2.0, 0)))
	var canopy := SphereMesh.new()
	canopy.radius = CANOPY_RADIUS
	canopy.height = CANOPY_RADIUS * 2.0  # 1.8 m: 60% of the 3 m tree
	n.add_child(Scenery.mesh_node("Canopy", canopy, COLOR_TREE,
			Vector3(0, TRUNK_HEIGHT + CANOPY_RADIUS + 0.01, 0)))
	return n


func _start_deflate(n: Node3D) -> void:
	n.name = "Deflating_" + n.name
	_deflating.append([n, DEFLATE_SECONDS])


func _step_deflate(seconds: float) -> void:
	## Absorbed Sentinels lose their air: they squash down, bulge a little, then vanish.
	for e in _deflating.duplicate():
		e[1] -= seconds
		var n: Node3D = e[0]
		if e[1] <= 0.0:
			n.queue_free()
			_deflating.erase(e)
			continue
		var k: float = e[1] / DEFLATE_SECONDS  # 1 -> 0
		n.scale = Vector3(1.0 + 0.5 * (1.0 - k), maxf(k * k, 0.02), 1.0 + 0.5 * (1.0 - k))


func _make_sentinel(t: Vector2i) -> Node3D:
	var n := Node3D.new()
	n.name = "Sentinel_%d_%d" % [t.x, t.y]
	n.position = logic.top_position(t)
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 2.2
	n.add_child(Scenery.mesh_node("Body", cap, COLOR_SENTINEL, Vector3(0, 1.1, 0)))
	var nose := BoxMesh.new()
	nose.size = Vector3(0.2, 0.2, 0.6)
	n.add_child(Scenery.mesh_node("Nose", nose, COLOR_NOSE, Vector3(0, 1.8, 0.5)))
	return n


# --- input ------------------------------------------------------------------

func press(button: String) -> void:
	_dispatch(button)


func aim_at(tile: Vector2i) -> void:
	_aim_tile = tile
	_aim_forced = true


func advance(seconds: float) -> void:
	_step_fade(seconds)
	_step_deflate(seconds)
	if not paused:
		if logic.state == "playing":
			logic.advance(seconds)
		_step_flow(seconds)
	_announce_state()
	refresh()


func _dispatch(button: String) -> void:
	if paused:
		match button:
			"trigger_click":
				menu.activate(menu.pick(rig.ray_origin(), rig.ray_direction()))
			"by_left_button":
				_set_paused(false)
		refresh()
		return
	if button == "by_left_button":
		_set_paused(true)
		sfx.play("menu")
		refresh()
		return
	if logic.state == "won":
		return
	match button:
		"trigger_click":
			if logic.state == "lost":
				retry_level()
			else:
				_create()
		"grip_click":
			create_kind = "boulder" if create_kind == "synthoid" else "synthoid"
			sfx.play("menu")
			refresh()
		"ax_button":
			var reason := _check_tile(logic.move)
			if reason == "":
				_start_move()
			_finish("move", reason)
		"trigger_left_click":
			_finish("absorb", _check_tile(logic.absorb, "left"))
		"ax_left_button":
			_message = _hint()
			refresh()
		"stick_right":
			rig.snap_turn(1)
		"stick_left":
			rig.snap_turn(-1)


func _create() -> void:
	var reason := _check_tile(func(t: Vector2i) -> String: return logic.create(t, create_kind))
	if reason == "" and aimed_tile() == logic.player_tile:
		rig.place_at(logic.top_position(logic.player_tile))  # a boulder under you lifts you
	_finish("create", reason)


func choose_pause(id: String) -> void:
	menu.activate(id)


func _on_pause_choice(id: String) -> void:
	match id:
		"resume":
			_set_paused(false)
		"restart":
			retry_level()
		"lobby":
			go_lobby()
	refresh()


func _set_paused(on: bool) -> void:
	paused = on
	if on:
		_place_pause_menu()
	menu.visible = on


func _place_pause_menu() -> void:
	## Put the pause menu in front of where the player looks now, at eye height,
	## facing them, and leave it fixed in the world (a menu that follows the head
	## cannot be aimed at). Uses the camera's yaw, so it is right at any rig yaw.
	var cam := rig.camera.global_transform
	var forward := Vector3(-cam.basis.z.x, 0, -cam.basis.z.z)
	forward = forward.normalized() if forward.length() > 0.001 else Vector3(0, 0, -1)
	var at := cam.origin + forward * PAUSE_DISTANCE
	menu.look_at_from_position(at, at + forward, Vector3.UP)  # front (+z) faces the player


func _check_tile(action: Callable, hand := "right") -> String:
	## Run a tile action on the tile aimed by `hand`; "" on success, else the HUD reason.
	var t := aimed_tile(hand)
	if not logic.in_bounds(t):
		return GameLogic.MSG_OFF_GRID
	return action.call(t)


func _finish(sound: String, reason: String) -> void:
	if reason == "":
		_message = ""
		sfx.play(sound)
		rig.haptic(0.2)
	else:
		_message = reason
		sfx.play("fail")
		rig.haptic(0.05)
	_announce_state()
	refresh()


func _hint() -> String:
	if logic.state == "lost":
		return "Pull the trigger to try again."
	if logic.watched:
		return "Hide behind a hill, or absorb the Sentinel."
	if logic.energy < GameLogic.SYNTHOID_COST:
		return "Aim your left controller at a tree and pull its trigger to gain energy."
	return "Make a body on a high tile you can see (trigger), then press A."


# --- moving, flow -----------------------------------------------------------

func _start_move() -> void:
	_move_to = logic.player_tile
	_fade_left = FADE_SECONDS


func _step_fade(seconds: float) -> void:
	if _fade_left < 0.0:
		return
	var before := _fade_left
	_fade_left -= seconds
	var half := FADE_SECONDS / 2.0
	if before > half and _fade_left <= half:
		rig.place_at(logic.top_position(_move_to))
	var alpha := 0.0
	if _fade_left > 0.0:
		alpha = 1.0 - absf(_fade_left - half) / half
	_fade.visible = alpha > 0.0
	(_fade.material_override as StandardMaterial3D).albedo_color.a = alpha
	if _fade_left <= 0.0:
		_fade_left = -1.0
		rig.place_at(logic.top_position(_move_to))


func _announce_state() -> void:
	if logic.state == _announced or logic.state == "playing":
		return
	_announced = logic.state
	if logic.state == "won":
		sfx.play("win")
		if logic.level >= Levels.COUNT:
			_message = "You freed the valley!"
			_ending.visible = true
		else:
			_message = "Hill cleared!"
		_won_card.text = _message
		_won_card.visible = true
		_ending.position = Vector3(0, -0.35, -1.2)
		_cleared_left = CLEARED_SECONDS
	else:
		sfx.play("lose")
		_message = MSG_LOST


func _step_flow(seconds: float) -> void:
	if _cleared_left < 0.0:
		return
	_cleared_left -= seconds
	if _cleared_left > 0.0:
		return
	_cleared_left = -1.0
	if logic.level >= Levels.COUNT:
		go_lobby()
	else:
		_enter(Levels.next(logic))


# --- aiming and drawing -----------------------------------------------------

func aimed_tile(hand := "right") -> Vector2i:
	if _aim_forced:
		return _aim_tile
	return _ray_tile(hand)


func _ray_tile(hand := "right") -> Vector2i:
	## First tile whose ground surface (slopes included) or standing object the
	## right-hand ray reaches. Objects count as part of their tile, so aiming at
	## a tree's canopy or a synthoid's head selects that tile.
	var from := rig.ray_origin(hand)
	var dir := rig.ray_direction(hand)
	var steps := int(RAY_REACH / RAY_STEP)
	for i in range(1, steps):
		var p := from + dir * (i * RAY_STEP)
		var t := Vector2i(int(floor(p.x / GameLogic.TILE)), int(floor(p.z / GameLogic.TILE)))
		if logic.in_bounds(t) and p.y <= logic.surface_height(p.x, p.z) + _object_height(t):
			return t
	return Vector2i(-1, -1)


func _object_height(t: Vector2i) -> float:
	match logic.object_at(t):
		"tree":
			return TREE_HEIGHT
		"synthoid":
			return SYNTHOID_HEIGHT
		"sentinel":
			return SENTINEL_HEIGHT
	return 0.0


func refresh() -> void:
	_sync_objects()
	hud.show_state(logic, sentinels_total, create_kind, _message)


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)
	if paused:
		_cursor.visible = false
		_cursor_left.visible = false
		_ghost.visible = false
		menu.highlight(menu.pick(rig.ray_origin(), rig.ray_direction()))
		return
	var lt := aimed_tile("left")
	_cursor_left.visible = logic.in_bounds(lt)
	if _cursor_left.visible:
		_cursor_left.position = logic.top_position(lt) + Vector3(0, 0.05, 0)
		rig.set_ray_length(maxf(rig.ray_origin("left").distance_to(_cursor_left.position), 0.2), "left")
	else:
		rig.set_ray_length(3.0, "left")
	var t := aimed_tile()
	if logic.in_bounds(t):
		_cursor.visible = true
		_cursor.position = logic.top_position(t) + Vector3(0, 0.03, 0)
		var c := _disc_colour(t)
		(_cursor.material_override as StandardMaterial3D).albedo_color = c
		rig.set_ray_length(maxf(rig.ray_origin().distance_to(_cursor.position), 0.2))
		_ghost.visible = false
		if logic.is_flat(t):
			_show_ghost(t)
	else:
		_ghost.visible = false
		_cursor.visible = false
		rig.set_ray_length(3.0)


func _show_ghost(t: Vector2i) -> void:
	## A translucent preview of what the trigger would create on the aimed tile.
	var boulder := create_kind == "boulder"
	_ghost.mesh = _slab() if boulder else _capsule()
	_ghost.material_override = Rig.unshaded(Color(COLOR_BOULDER, 0.5) if boulder else Color(COLOR_SYNTHOID, 0.5))
	var lift := 0.0 if boulder else SYNTHOID_HEIGHT / 2.0
	_ghost.position = logic.top_position(t) + Vector3(0, lift + (GameLogic.BOULDER_HEIGHT / 2.0 if boulder else 0.0), 0)
	_ghost.visible = true


func _capsule() -> CapsuleMesh:
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = SYNTHOID_HEIGHT
	return cap


func _disc_colour(t: Vector2i) -> Color:
	## Yellow: flat and visible. Red: flat but hidden. Grey: sloped, nothing can happen there.
	if not logic.is_flat(t):
		return Color(0.6, 0.6, 0.6)
	return Color(1, 1, 0.2) if logic.can_see(t) else Color(1, 0.2, 0.2)
