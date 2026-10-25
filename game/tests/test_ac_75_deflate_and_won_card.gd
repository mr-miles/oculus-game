extends ViewTest
## AC-75: an absorbed Sentinel visibly deflates (squashes and shrinks away) instead of vanishing,
## and clearing a level shows a big "Hill cleared!" card in the middle of the view.

func _deflating(g: Node) -> Node3D:
	for n in g.find_children("Deflating_Sentinel_*", "Node3D", true, false):
		return n
	return null


func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var card: Label3D = g.find_child("WonCard", true, false)
	check("ac_75 no won card before the win", card != null and not card.visible)
	absorb_one_sentinel(g)
	g.advance(0.0)
	var n := _deflating(g)
	check("ac_75 the absorbed Sentinel is still there, deflating", n != null)
	if n != null:
		var early: float = n.scale.y
		g.advance(0.3)
		var mid: float = n.scale.y
		check("ac_75 it gets flatter (%.2f -> %.2f)" % [early, mid], mid < early and mid < 0.9)
		g.advance(1.0)
		check("ac_75 it is gone afterwards", not is_instance_valid(n) or n.is_queued_for_deletion())
	check("ac_75 won card visible", card.visible)
	check("ac_75 won card text is Hill cleared!", card.text == "Hill cleared!")
	var p := cam.global_transform.affine_inverse() * card.global_position
	check("ac_75 won card is in the middle of the view (%.2f, %.2f)" % [p.x, p.y], absf(p.x) < 0.3 and absf(p.y) < 0.6 and p.z < -1.0)
	check("ac_75 won card text is large (>= 2x HUD text)", card.font_size * card.pixel_size * 3.0 >= 44 * 0.0012 * 2.7 * 2.0 * 0.9)
	finish()
