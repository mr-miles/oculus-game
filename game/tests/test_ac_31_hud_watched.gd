extends ViewTest
## AC-31: HudWatched shows a countdown only while the player is watched.

func _init() -> void:
	var g := await new_game()
	var w: Label3D = g.find_child("HudWatched", true, false)
	g.logic.watched = false
	g.refresh()
	check("ac_31 hidden when not watched", not w.is_visible_in_tree())
	g.logic.watched = true
	g.logic.watch_ticks = 314  # 4.0 s left before the first drain
	g.refresh()
	check("ac_31 visible when watched", w.is_visible_in_tree())
	check("ac_31 shows the countdown", w.text.contains("4"))
	g.logic.watched = false
	g.refresh()
	check("ac_31 hidden again", not w.is_visible_in_tree())
	finish()
