extends SceneTree
## Run: godot --headless --path game --script res://tests/test_logic.gd

var failures := 0

func check(name: String, cond: bool) -> void:
	print(("PASS " if cond else "FAIL ") + name)
	if not cond:
		failures += 1

func _init() -> void:
	var g := GameLogic.new()
	check("start energy", g.energy == GameLogic.START_ENERGY)
	check("cannot see own tile", not g.can_see(g.player_tile))
	check("out of bounds invisible", not g.can_see(Vector2i(-1, 0)))
	# Find any visible, free tile.
	var target := Vector2i(-1, -1)
	for z in GameLogic.SIZE:
		for x in GameLogic.SIZE:
			var t := Vector2i(x, z)
			if g.can_see(t) and not g.occupied(t):
				target = t
	check("some free tile is visible", target.x >= 0)
	check("place synthoid", g.place_synthoid(target))
	check("energy spent", g.energy == GameLogic.START_ENERGY - GameLogic.SYNTHOID_COST)
	check("cannot place twice on tile", not g.place_synthoid(target))
	check("transfer moves player", g.transfer(target) and g.player_tile == target)
	# Walls: build a tall column and verify it blocks sight.
	var h := GameLogic.new()
	h.heights[1][3] = 20
	check("tall column blocks line of sight", not h.can_see(Vector2i(6, 1)))
	# Absorb a tree if visible, else make one visible.
	var a := GameLogic.new()
	a.trees = {Vector2i(2, 1): true}
	a.heights[1][2] = 1
	var before := a.energy
	check("absorb tree", a.absorb(Vector2i(2, 1)) and a.energy == before + GameLogic.TREE_ENERGY)
	# Energy gate.
	var e := GameLogic.new()
	e.energy = 2
	check("insufficient energy blocks place", not e.place_synthoid(Vector2i(2, 1)))
	# Win condition.
	var w := GameLogic.new()
	w.synthoids[Vector2i(2, 1)] = true
	w.heights[1][2] = 9
	check("transfer to peak wins", w.transfer(Vector2i(2, 1)) and w.won)
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
