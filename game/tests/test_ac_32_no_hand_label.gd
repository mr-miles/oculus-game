extends ViewTest
## AC-32: LeftController carries no Label3D.

func _init() -> void:
	var g := await new_game()
	var left: Node = g.find_child("LeftController", true, false)
	check("ac_32 no Label3D under LeftController", left.find_children("*", "Label3D", true, false).is_empty())
	finish()
