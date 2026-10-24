extends ViewTest
## AC-65: a real controller ray aims at sloped tiles (grey disc, "Needs flat ground"); flat tiles are yellow or red.

func _disc(g: Node) -> Color:
	return ((g.find_child("Cursor", true, false) as MeshInstance3D).material_override as StandardMaterial3D).albedo_color


func _init() -> void:
	var g := await new_game()
	var sloped := find_tile(g, func(t: Vector2i) -> bool: return not g.logic.is_flat(t) and g.logic.in_bounds(t))
	check("ac_65 level has a sloped tile", sloped.x >= 0)
	check("ac_65 the ray makes the sloped tile the aimed tile", ray_down_at(g, sloped) == sloped)
	await process_frame
	var grey := _disc(g)
	check("ac_65 disc is grey", absf(grey.r - grey.g) < 0.05 and absf(grey.g - grey.b) < 0.05)
	var energy: int = g.logic.energy
	var trees: int = g.logic.trees.size()
	var tile: Vector2i = g.logic.player_tile
	for button in ["trigger_click", "ax_button", "by_button"]:
		(g.find_child("HudMessage", true, false) as Label3D).text = ""
		g.press(button)
		check("ac_65 %s says Needs flat ground" % button, (g.find_child("HudMessage", true, false) as Label3D).text.contains("Needs flat ground"))
	check("ac_65 nothing changed", g.logic.energy == energy and g.logic.trees.size() == trees
			and g.logic.player_tile == tile and g.logic.synthoids.is_empty())
	var seen := find_tile(g, func(t: Vector2i) -> bool: return g.logic.is_flat(t) and g.logic.can_see(t) and not g.logic.occupied(t))
	check("ac_65 ray at a visible flat tile selects it", ray_down_at(g, seen) == seen)
	await process_frame
	check("ac_65 disc is yellow", _disc(g).r > 0.9 and _disc(g).g > 0.9 and _disc(g).b < 0.5)
	var hidden := find_tile(g, func(t: Vector2i) -> bool: return g.logic.is_flat(t) and not g.logic.can_see(t) and not g.logic.occupied(t))
	check("ac_65 ray at a hidden flat tile selects it", ray_down_at(g, hidden) == hidden)
	await process_frame
	check("ac_65 disc is red", _disc(g).r > 0.9 and _disc(g).g < 0.4)
	finish()
