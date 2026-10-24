extends Node3D
## VR view for the Sentinel-style prototype. Right controller points a ray at
## tiles: trigger = create synthoid, A = transfer (teleport) into it,
## B = absorb tree/synthoid. Left-hand label shows energy.

var logic := Levels.build(1)
var origin: XROrigin3D
var camera: XRCamera3D
var right: XRController3D
var left: XRController3D
var ray_mesh: MeshInstance3D
var cursor: MeshInstance3D
var hud: Label3D
var sentinel: Node3D
var markers := {}  # Vector2i -> Node3D (synthoids, trees)
var xr_active := false


func _ready() -> void:
	_setup_xr()
	_build_world()
	_place_player()
	_refresh()


func _setup_xr() -> void:
	origin = XROrigin3D.new()
	add_child(origin)
	camera = XRCamera3D.new()
	origin.add_child(camera)
	left = XRController3D.new()
	left.tracker = "left_hand"
	origin.add_child(left)
	right = XRController3D.new()
	right.tracker = "right_hand"
	origin.add_child(right)
	right.button_pressed.connect(_on_button)

	var xr := XRServer.find_interface("OpenXR")
	if xr and xr.is_initialized():
		xr_active = true
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("OpenXR active")
	else:
		print("OpenXR not available; flat fallback camera")
		camera.position = Vector3.ZERO

	ray_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.004
	cyl.bottom_radius = 0.004
	cyl.height = 1.0
	ray_mesh.mesh = cyl
	ray_mesh.material_override = _mat(Color(1, 1, 0.3), true)
	right.add_child(ray_mesh)

	hud = Label3D.new()
	hud.pixel_size = 0.0007
	hud.font_size = 48
	hud.no_depth_test = true
	hud.rotation_degrees = Vector3(-45, 0, 0)
	hud.position = Vector3(0, 0.05, -0.05)
	left.add_child(hud)


func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _build_world() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.75, 0.95)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	add_child(sun)

	for z in logic.size:
		for x in logic.size:
			var t := Vector2i(x, z)
			var h := logic.height(t)
			var m := MeshInstance3D.new()
			var box := BoxMesh.new()
			var col_h := float(h) + 1.0  # column reaches below the floor
			box.size = Vector3(GameLogic.TILE, col_h, GameLogic.TILE)
			m.mesh = box
			m.position = Vector3((x + 0.5) * GameLogic.TILE, h - col_h / 2.0, (z + 0.5) * GameLogic.TILE)
			var checker := (x + z) % 2 == 0
			m.material_override = _mat(Color(0.25, 0.55, 0.3) if checker else Color(0.2, 0.45, 0.25))
			add_child(m)

	# The Sentinel: a tall rotating figure on the peak.
	sentinel = Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 2.2
	body.mesh = cap
	body.position.y = 1.1
	body.material_override = _mat(Color(0.8, 0.15, 0.15))
	sentinel.add_child(body)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.2, 0.2, 0.6)
	nose.mesh = nm
	nose.position = Vector3(0, 1.8, -0.5)
	nose.material_override = _mat(Color(1, 0.9, 0.2))
	sentinel.add_child(nose)
	sentinel.position = logic.top_position(logic.sentinels[0].tile)
	add_child(sentinel)

	cursor = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.8
	cm.bottom_radius = 0.8
	cm.height = 0.04
	cursor.mesh = cm
	cursor.material_override = _mat(Color(1, 1, 0.2), true)
	cursor.visible = false
	add_child(cursor)


func _place_player() -> void:
	origin.position = logic.top_position(logic.player_tile)


func _refresh() -> void:
	for k in markers.keys():
		if not (logic.synthoids.has(k) or logic.trees.has(k)):
			markers[k].queue_free()
			markers.erase(k)
	for t in logic.synthoids.keys():
		if not markers.has(t):
			markers[t] = _make_marker(t, Color(0.2, 0.4, 1.0), 1.6)
	for t in logic.trees.keys():
		if not markers.has(t):
			markers[t] = _make_marker(t, Color(0.1, 0.8, 0.2), 1.2)
	hud.text = "Energy %d\n%s" % [logic.energy, "YOU WIN" if logic.state == "won" else "Trig:create A:go B:absorb"]


func _make_marker(t: Vector2i, c: Color, h: float) -> Node3D:
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = h
	m.mesh = cap
	m.material_override = _mat(c)
	m.position = logic.top_position(t) + Vector3(0, h / 2.0, 0)
	add_child(m)
	return m


func _aimed_tile() -> Vector2i:
	## First tile the right-hand ray enters (marching along the ray).
	var from := right.global_position
	var dir := -right.global_transform.basis.z
	for i in range(1, 400):
		var p := from + dir * (i * 0.1)
		var t := Vector2i(int(floor(p.x / GameLogic.TILE)), int(floor(p.z / GameLogic.TILE)))
		if not logic.in_bounds(t):
			continue
		if p.y <= float(logic.height(t)):
			return t
	return Vector2i(-1, -1)


func _process(delta: float) -> void:
	sentinel.rotate_y(delta * 0.5)
	var t := _aimed_tile()
	if logic.in_bounds(t):
		cursor.visible = true
		cursor.position = logic.top_position(t) + Vector3(0, 0.03, 0)
		cursor.material_override.albedo_color = Color(1, 1, 0.2) if logic.can_see(t) else Color(1, 0.2, 0.2)
	else:
		cursor.visible = false
	ray_mesh.position = Vector3(0, 0, -0.5)
	ray_mesh.rotation_degrees = Vector3(90, 0, 0)
	(ray_mesh.mesh as CylinderMesh).height = 1.0


func _on_button(name: String) -> void:
	var t := _aimed_tile()
	if not logic.in_bounds(t):
		return
	match name:
		"trigger_click":
			logic.create(t)
		"ax_button":
			if logic.move(t) == "":
				_place_player()
		"by_button":
			logic.absorb(t)
	_refresh()
