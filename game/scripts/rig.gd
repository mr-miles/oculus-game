class_name Rig
extends Node3D
## The XR rig shared by the lobby and the game: origin, head camera, two
## controllers, a yellow pointer ray on the right hand. Turns controller
## signals into three plain signals so scenes never touch XR nodes for input.

signal button(name: String)       ## right-hand button pressed (trigger_click, grip_click, ax_button)
signal left_button(name: String)  ## left-hand button pressed, as trigger_left_click / by_left_button / ax_left_button
signal snap(direction: int)       ## left stick pushed: +1 right, -1 left

const SNAP_DEGREES := 30.0
const STICK_ON := 0.7
const STICK_OFF := 0.3
const RAY_COLOR := Color(1, 1, 0.3)
const LEFT_RAY_COLOR := Color(1, 0.5, 0.15)  # the absorb ray (left hand)

var origin: XROrigin3D
var camera: XRCamera3D
var left: XRController3D
var right: XRController3D
var xr_active := false
var _ray: MeshInstance3D
var _left_ray: MeshInstance3D
var _stick_latched := false


func _init() -> void:
	origin = XROrigin3D.new()
	origin.name = "XROrigin3D"
	add_child(origin)
	camera = XRCamera3D.new()
	camera.name = "XRCamera3D"
	origin.add_child(camera)
	left = _controller("LeftController", "left_hand")
	right = _controller("RightController", "right_hand")
	right.button_pressed.connect(func(n: String) -> void: button.emit(n))
	left.button_pressed.connect(_on_left_button)
	left.input_vector2_changed.connect(_on_left_vector)
	_ray = _make_ray(right, RAY_COLOR)
	_left_ray = _make_ray(left, LEFT_RAY_COLOR)
	set_ray_length(3.0)
	set_ray_length(3.0, "left")


func _make_ray(hand: Node3D, colour: Color) -> MeshInstance3D:
	var ray := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.004
	cyl.bottom_radius = 0.004
	cyl.height = 1.0
	ray.mesh = cyl
	ray.material_override = unshaded(colour)
	hand.add_child(ray)
	return ray


func _ready() -> void:
	var xr := XRServer.find_interface("OpenXR")
	if xr and xr.is_initialized():
		xr_active = true
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		# Flat fallback (tests, desktop): a fixed standing eye height.
		camera.position = Vector3(0, GameLogic.EYE, 0)
		right.position = Vector3(0.25, GameLogic.EYE - 0.4, -0.3)
		left.position = Vector3(-0.25, GameLogic.EYE - 0.4, -0.3)
		camera.make_current()


static func unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _controller(node_name: String, tracker: String) -> XRController3D:
	var c := XRController3D.new()
	c.name = node_name
	c.tracker = tracker
	origin.add_child(c)
	return c


func ray_origin(hand := "right") -> Vector3:
	return (left if hand == "left" else right).global_position


func ray_direction(hand := "right") -> Vector3:
	return -(left if hand == "left" else right).global_transform.basis.z


func set_ray_length(metres: float, hand := "right") -> void:
	var ray := _left_ray if hand == "left" else _ray
	(ray.mesh as CylinderMesh).height = metres
	ray.position = Vector3(0, 0, -metres / 2.0)
	ray.rotation_degrees = Vector3(90, 0, 0)


func place_at(pos: Vector3) -> void:
	## Put the player (not the tracking-space centre) over a world point,
	## keeping the room-scale offset of the head.
	var head := camera.position
	origin.global_position = pos - origin.global_transform.basis * Vector3(head.x, 0, head.z)


func snap_turn(direction: int) -> void:
	## Rotate the origin around the head, so the player turns on the spot.
	var pivot := camera.global_position
	var t := origin.global_transform
	t.origin -= pivot
	t = Transform3D(Basis(Vector3.UP, deg_to_rad(-SNAP_DEGREES * direction)), Vector3.ZERO) * t
	t.origin += pivot
	origin.global_transform = t


func haptic(seconds: float) -> void:
	if xr_active:
		right.trigger_haptic_pulse("haptic", 0.0, 1.0, seconds, 0.0)


func _on_left_button(n: String) -> void:
	# The left trigger absorbs: it arrives as "trigger_left_click" so it cannot be mistaken for the right one.
	left_button.emit(n.replace("_button", "_left_button").replace("trigger_click", "trigger_left_click"))


func _on_left_vector(n: String, v: Vector2) -> void:
	if n != "primary":
		return
	if not _stick_latched and absf(v.x) > STICK_ON:
		_stick_latched = true
		snap.emit(1 if v.x > 0 else -1)
	elif absf(v.x) < STICK_OFF:
		_stick_latched = false
