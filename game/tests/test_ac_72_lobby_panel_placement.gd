extends ViewTest
## AC-72: the lobby panel is in front of the camera's facing direction at load, 2..3.5 m away,
## fixed in the world, and robust to the headset's starting yaw.

func _flat_forward(cam: Node3D) -> Vector3:
	var f := -cam.global_transform.basis.z
	return Vector3(f.x, 0, f.z).normalized()


func _angle_to_panel(l: Node, cam: Node3D) -> float:
	var to_panel: Vector3 = l.panel.global_position - cam.global_position
	to_panel.y = 0
	return rad_to_deg(_flat_forward(cam).angle_to(to_panel.normalized()))


func _init() -> void:
	var l := await new_lobby()
	var cam: Node3D = l.find_child("XRCamera3D", true, false)
	var origin: Node3D = l.find_child("XROrigin3D", true, false)
	check("ac_72 panel is placed at load", l.placed and l.panel.visible)
	check("ac_72 panel within 5 degrees of the camera forward", _angle_to_panel(l, cam) <= 5.0)
	var d: Vector3 = l.panel.global_position - cam.global_position
	d.y = 0
	check("ac_72 panel distance 2..3.5 m (%.2f)" % d.length(), d.length() >= 2.0 and d.length() <= 3.5)
	check("ac_72 panel is at eye height", absf(l.panel.global_position.y - cam.global_position.y) <= 0.05)
	var to_cam: Vector3 = cam.global_position - l.panel.global_position
	check("ac_72 panel front faces the player", l.panel.global_transform.basis.z.dot(to_cam.normalized()) > 0.95)
	# Fixed in the world: turning the head or the whole rig does not move it.
	var before: Transform3D = l.panel.global_transform
	origin.rotation.y += deg_to_rad(40)
	await process_frame
	check("ac_72 panel does not follow the camera yaw", l.panel.global_transform.is_equal_approx(before))
	# Robust to the starting yaw: any rig yaw, placed again from the camera's own direction.
	for yaw in [90.0, 180.0, -137.0]:
		origin.rotation.y = deg_to_rad(yaw)
		l.place_panel()
		check("ac_72 yaw %d: panel in front of the camera" % yaw, _angle_to_panel(l, cam) <= 5.0)
	finish()
