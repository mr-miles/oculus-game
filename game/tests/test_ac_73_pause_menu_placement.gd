extends ViewTest
## AC-73: the pause menu opens in front of where the player is looking, 1..2.5 m away at
## eye height facing them, fixed in the world (it does not follow the head), at any rig yaw.

func _check_placed(g: Node, cam: Node3D, menu: Node3D, label: String) -> void:
	var f := -cam.global_transform.basis.z
	var flat := Vector3(f.x, 0, f.z).normalized()
	var d: Vector3 = menu.global_position - cam.global_position
	var dy := d.y
	d.y = 0
	check("ac_73 %s: menu within 5 degrees of the camera forward" % label, rad_to_deg(flat.angle_to(d.normalized())) <= 5.0)
	check("ac_73 %s: distance 1..2.5 m (%.2f)" % [label, d.length()], d.length() >= 1.0 and d.length() <= 2.5)
	check("ac_73 %s: at eye height" % label, absf(dy) <= 0.05)
	var to_cam: Vector3 = (cam.global_position - menu.global_position).normalized()
	check("ac_73 %s: front faces the player" % label, menu.global_transform.basis.z.dot(to_cam) > 0.95)


func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var menu: Node3D = g.find_child("PauseMenu", true, false)
	for yaw in [0.0, 90.0, 180.0, -137.0]:
		origin.rotation.y = deg_to_rad(yaw)
		g.press("by_left_button")
		check("ac_73 yaw %d: menu shown" % yaw, menu.is_visible_in_tree())
		_check_placed(g, cam, menu, "yaw %d" % yaw)
		if yaw == 90.0:
			var before: Transform3D = menu.global_transform
			origin.rotation.y += deg_to_rad(40)
			await process_frame
			check("ac_73 menu does not follow the head", menu.global_transform.is_equal_approx(before))
		g.press("by_left_button")
	finish()
