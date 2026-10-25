extends ViewTest
## AC-81: the energy bar fill is drawn on top of its dark back (it was hidden), grows with energy,
## and does not overlap the "Energy nn" text.

func _init() -> void:
	var g := await new_game()
	var back: MeshInstance3D = g.find_child("HudBarBack", true, false)
	var fill: MeshInstance3D = g.find_child("HudBarFill", true, false)
	var bm := back.material_override as BaseMaterial3D
	var fm := fill.material_override as BaseMaterial3D
	check("ac_81 fill is drawn after (on top of) the back", fm.render_priority > bm.render_priority)
	check("ac_81 fill is green and opaque", fm.albedo_color.g > 0.8 and fm.albedo_color.a > 0.99)
	check("ac_81 fill is in front of the back", fill.position.z > back.position.z)
	var energy: Label3D = g.find_child("HudEnergy", true, false)
	g.logic.energy = 10
	g.refresh()
	var full: float = fill.scale.x
	check("ac_81 fill at energy 10 is %.2f of the bar (visible)" % full, full > 0.1)
	g.logic.energy = 20
	g.refresh()
	check("ac_81 fill grows with energy", fill.scale.x > full)
	g.logic.energy = 0
	g.refresh()
	check("ac_81 fill is nearly empty at energy 0", fill.scale.x < 0.01)
	g.logic.energy = 63
	g.refresh()
	var text_end: float = energy.position.x + energy.get_aabb().end.x
	var bar_start: float = back.position.x - (back.mesh as QuadMesh).size.x / 2.0
	check("ac_81 bar starts right of the Energy text (%.2f < %.2f)" % [text_end, bar_start], text_end < bar_start)
	var mode: Label3D = g.find_child("HudMode", true, false)
	var bar_end: float = back.position.x + (back.mesh as QuadMesh).size.x / 2.0
	var mode_start: float = mode.position.x + mode.get_aabb().position.x
	check("ac_81 bar ends left of the create-mode text (%.2f < %.2f)" % [bar_end, mode_start], bar_end < mode_start)
	finish()
