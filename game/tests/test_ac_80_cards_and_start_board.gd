extends ViewTest
## AC-80: win, lose and level-start messages are cards fixed in the world in front of you;
## the level start board shows the level, the Sentinels and a 5 s countdown; no aim circles on slopes.

func _flat_angle(cam: Node3D, card: Node3D) -> float:
	var f := -cam.global_transform.basis.z
	var d := card.global_position - cam.global_position
	return rad_to_deg(Vector3(f.x, 0, f.z).normalized().angle_to(Vector3(d.x, 0, d.z).normalized()))


func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var origin: Node3D = g.find_child("XROrigin3D", true, false)
	var start: Label3D = g.find_child("StartCard", true, false)
	# Level start board.
	g.advance(0.0)
	check("ac_80 start board is shown", start.visible)
	check("ac_80 start board names level, Sentinels and countdown", start.text.contains("Level 1 of 10")
			and start.text.contains("1 Sentinel") and start.text.contains("Starting in 5"))
	check("ac_80 start board is in front of you, not a child of the camera", _flat_angle(cam, start) < 5.0 and not cam.is_ancestor_of(start))
	var before := start.global_transform
	origin.rotation.y += deg_to_rad(50)
	g.advance(2.0)
	check("ac_80 start board stays put when you turn", start.global_transform.is_equal_approx(before))
	check("ac_80 start countdown counts down (%s)" % start.text.replace("\n", " | "), start.text.contains("Starting in 3"))
	g.advance(3.5)
	check("ac_80 start board is gone after 5 s", not start.visible)
	origin.rotation.y = 0.0
	# Win card.
	absorb_one_sentinel(g)
	g.advance(0.0)
	var won: Label3D = g.find_child("WonCard", true, false)
	check("ac_80 win card shown in front and not a child of the camera", won.visible and _flat_angle(cam, won) < 5.0 and not cam.is_ancestor_of(won))
	before = won.global_transform
	origin.rotation.y += deg_to_rad(70)
	g.advance(0.5)
	check("ac_80 win card stays put when you turn", won.global_transform.is_equal_approx(before))
	# Lose card.
	var l := await new_game()
	var lost: Label3D = l.find_child("LostCard", true, false)
	l.logic.energy = 0
	l.logic.awake = true
	l.logic.state = "lost"
	l.advance(0.1)
	var lcam: Node3D = l.find_child("XRCamera3D", true, false)
	check("ac_80 lose card shown with the message", lost.visible and lost.text.contains("ran out of energy"))
	check("ac_80 lose card is in front and fixed in the world", _flat_angle(lcam, lost) < 5.0 and not lcam.is_ancestor_of(lost))
	finish()
