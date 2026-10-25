extends ViewTest
## AC-79: a red vignette on the screen edges while a Sentinel sees you.

func _alpha(g: Node, uv: Vector2) -> float:
	## The vignette's alpha at a point of its quad, computed like the shader does.
	var c := uv * 2.0 - Vector2.ONE
	var r := maxf(absf(c.x), absf(c.y)) * 0.6 + c.length() * 0.4
	var e := smoothstep(0.45, 1.05, r)
	var m: ShaderMaterial = g.find_child("WatchVignette", true, false).material_override
	return e * e * 0.6 * float(m.get_shader_parameter("amount"))


func _init() -> void:
	var g := await new_game()
	var cam: Node3D = g.find_child("XRCamera3D", true, false)
	var v: MeshInstance3D = g.find_child("WatchVignette", true, false)
	check("ac_79 vignette exists under the camera and starts hidden", v != null and cam.is_ancestor_of(v) and not v.visible)
	var shader: Shader = (v.material_override as ShaderMaterial).shader
	check("ac_79 it is red and fades from the edges", shader.code.contains("tint") and shader.code.contains("smoothstep"))
	# Make the Sentinel see you.
	g.logic.awake = true
	var s: Dictionary = g.logic.sentinels[0]
	var seen := false
	for t in g.logic.size * g.logic.size:
		var tile := Vector2i(t % g.logic.size, t / g.logic.size)
		if g.logic.is_flat(tile) and not g.logic.occupied(tile) and tile != s.tile:
			g.logic.player_tile = tile
			for f in range(0, 360, 15):
				s.facing = float(f)
				g.logic.update_watch()
				if g.logic.watched:
					seen = true
					break
		if seen:
			break
	check("ac_79 set-up: a Sentinel sees the player", seen)
	g.advance(0.05)
	check("ac_79 vignette appears while watched", v.visible)
	g.advance(0.5)
	var amount := float((v.material_override as ShaderMaterial).get_shader_parameter("amount"))
	check("ac_79 vignette is fully in after a moment (%.2f)" % amount, amount > 0.99)
	check("ac_79 stronger at the edge than at the middle", _alpha(g, Vector2(0.98, 0.5)) > 0.3 and _alpha(g, Vector2(0.5, 0.5)) < 0.01 and _alpha(g, Vector2(0.98, 0.5)) > _alpha(g, Vector2(0.75, 0.5)) and _alpha(g, Vector2(0.75, 0.5)) > _alpha(g, Vector2(0.55, 0.5)))
	g.press("by_left_button")  # pause
	g.advance(1.0)
	check("ac_79 hidden while paused", not v.visible)
	g.press("by_left_button")
	g.logic.watched = false
	g.advance(0.0)
	g.advance(1.0)
	check("ac_79 gone once nobody sees you", not v.visible)
	finish()
