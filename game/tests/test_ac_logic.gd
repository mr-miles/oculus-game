extends SceneTree
## Logic acceptance tests (SPEC section 12, AC-1..AC-11, AC-16..AC-20).
## Run: godot --headless --path game --script res://tests/test_ac_logic.gd

var failures := 0


func check(name: String, cond: bool) -> void:
	print(("PASS " if cond else "FAIL ") + name)
	if not cond:
		failures += 1


func _init() -> void:
	for m in get_method_list():
		if str(m.name).begins_with("ac_"):
			call(m.name)
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


## An empty flat 12x12 level with the player on (1,1).
func flat() -> GameLogic:
	var g := GameLogic.new(12)
	g.player_tile = Vector2i(1, 1)
	return g


## A Sentinel at `tile` facing `facing` degrees.
func sentinel(g: GameLogic, tile: Vector2i, facing: float, dir := 1) -> Dictionary:
	var s := {"tile": tile, "facing": facing, "dir": dir, "turned": 0.0, "clock": 0, "sees": false}
	g.sentinels.append(s)
	g.awake = true
	return s


## Sentinel at (8,1) looking along -x at the player on (1,1).
func watched_scene() -> GameLogic:
	var g := flat()
	sentinel(g, Vector2i(8, 1), 270.0)
	g.update_watch()
	return g


func snapshot(g: GameLogic) -> String:
	return str([g.energy, g.synthoids.keys(), g.trees.keys(), g.player_tile, g.sentinels.size(), g.state])


func ac_1_new_game() -> void:
	var g := Levels.build(1)
	check("ac_1_new_game energy 10", g.energy == 10)
	check("ac_1_new_game one sentinel", g.sentinels.size() == 1)
	check("ac_1_new_game 31x31", g.size == 31 and g.heights.size() == 31 and g.heights[0].size() == 31)
	var h := g.height(g.player_tile)
	check("ac_1_new_game player start altitude", h <= mini(6, Levels.lowest_sentinel_altitude(g)))
	check("ac_1_new_game player tile empty", g.object_at(g.player_tile) == "")


func ac_2_create_costs_three() -> void:
	var g := flat()
	var t := Vector2i(6, 1)
	check("ac_2_create_costs_three succeeds", g.create(t) == "")
	check("ac_2_create_costs_three energy 7", g.energy == 7)
	check("ac_2_create_costs_three synthoid placed", g.synthoids.has(t))


func ac_3_create_fails() -> void:
	var g := flat()
	g.energy = 2
	var before := snapshot(g)
	check("ac_3_create_fails low energy", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	g = flat()
	g.heights[1][3] = 20
	before = snapshot(g)
	check("ac_3_create_fails hidden tile", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	g = flat()
	g.trees[Vector2i(6, 1)] = true
	before = snapshot(g)
	check("ac_3_create_fails occupied tile", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	before = snapshot(g)
	check("ac_3_create_fails own tile", g.create(g.player_tile) != "" and snapshot(g) == before)
	g = flat()
	for i in 63:
		g.trees[Vector2i(i % 12, 4 + i / 12)] = true
	check("ac_3_create_fails 64 objects counted", g.object_count() == 64)
	before = snapshot(g)
	check("ac_3_create_fails 64 objects", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)


func ac_4_absorb_energy() -> void:
	var g := flat()
	sentinel(g, Vector2i(9, 9), 0.0)
	sentinel(g, Vector2i(9, 5), 0.0)
	g.trees[Vector2i(4, 1)] = true
	g.synthoids[Vector2i(5, 1)] = true
	check("ac_4_absorb_energy tree +1", g.absorb(Vector2i(4, 1)) == "" and g.energy == 11 and not g.trees.has(Vector2i(4, 1)))
	check("ac_4_absorb_energy synthoid +3", g.absorb(Vector2i(5, 1)) == "" and g.energy == 14 and g.synthoids.is_empty())
	g.heights[5][9] = 0
	check("ac_4_absorb_energy sentinel +4", g.absorb(Vector2i(9, 5)) == "" and g.energy == 18 and g.sentinels.size() == 1)
	g.energy = 61
	g.synthoids[Vector2i(5, 1)] = true
	g.absorb(Vector2i(5, 1))
	check("ac_4_absorb_energy capped at 63", g.energy == 63)


func ac_5_absorb_fails() -> void:
	var g := flat()
	g.trees[Vector2i(6, 1)] = true
	g.heights[1][3] = 20
	var before := snapshot(g)
	check("ac_5_absorb_fails hidden", g.absorb(Vector2i(6, 1)) != "" and snapshot(g) == before)
	check("ac_5_absorb_fails empty tile", g.absorb(Vector2i(1, 6)) != "" and snapshot(g) == before)
	check("ac_5_absorb_fails own tile", g.absorb(g.player_tile) != "" and snapshot(g) == before)


func ac_6_line_of_sight() -> void:
	var g := flat()
	var far := Vector2i(6, 1)
	check("ac_6_line_of_sight open", g.can_see(far))
	g.heights[1][3] = 20
	check("ac_6_line_of_sight column blocks", not g.can_see(far))
	g = flat()
	g.trees[Vector2i(3, 1)] = true
	check("ac_6_line_of_sight tree blocks", not g.can_see(far))
	g = flat()
	g.synthoids[Vector2i(3, 1)] = true
	check("ac_6_line_of_sight synthoid does not block", g.can_see(far))


func ac_7_transfer() -> void:
	var g := flat()
	var t := Vector2i(5, 1)
	g.synthoids[t] = true
	check("ac_7_transfer moves", g.move(t) == "" and g.player_tile == t)
	check("ac_7_transfer consumes synthoid", not g.synthoids.has(t))
	check("ac_7_transfer energy unchanged", g.energy == 10)
	g.synthoids[Vector2i(1, 1)] = true
	g.heights[1][3] = 20
	var before := snapshot(g)
	check("ac_7_transfer hidden fails", g.move(Vector2i(1, 1)) != "" and snapshot(g) == before)
	check("ac_7_transfer nonexistent fails", g.move(Vector2i(8, 8)) != "" and snapshot(g) == before)


func ac_8_sentinel_turns() -> void:
	var g := flat()
	g.heights[1][4] = 40  # wall: the Sentinel never sees the player
	var s := sentinel(g, Vector2i(8, 1), 90.0)
	var start: float = s.facing
	g.advance(11.9)
	check("ac_8_sentinel_turns no turn at 11.9 s", s.facing == start)
	g.advance(0.1)
	check("ac_8_sentinel_turns one step at 12.0 s", is_equal_approx(s.turned, 28.125) and is_equal_approx(s.facing, start + 28.125))
	for i in 11:
		g.advance(11.94)
	check("ac_8_sentinel_turns 12 steps = 337.5", is_equal_approx(s.turned, 337.5))
	check("ac_8_sentinel_turns still unwatched", g.state == "playing" and g.energy == 10)


func ac_9_watched() -> void:
	var g := watched_scene()
	check("ac_9_watched in cone with sight", g.watched)
	g.sentinels[0].facing = 300.0
	g.advance(0.01)
	check("ac_9_watched outside cone", not g.watched)
	g.sentinels[0].facing = 270.0
	g.heights[1][4] = 20
	g.advance(0.01)
	check("ac_9_watched blocked by terrain", not g.watched)


func ac_10_drain_timing() -> void:
	var g := watched_scene()
	g.advance(7.13)
	check("ac_10_drain_timing none before 7.14", g.energy == 10)
	g.advance(0.01)
	check("ac_10_drain_timing first at 7.14", g.energy == 9)
	g.advance(1.73)
	check("ac_10_drain_timing none before +1.74", g.energy == 9)
	g.advance(0.01)
	check("ac_10_drain_timing second at +1.74", g.energy == 8)
	g.sentinels[0].facing = 90.0
	g.advance(0.01)
	check("ac_10_drain_timing timer resets", not g.watched and g.watch_ticks == 0)
	g.sentinels[0].facing = 270.0
	g.advance(7.13)
	check("ac_10_drain_timing waits again", g.energy == 8)
	g.advance(0.01)
	check("ac_10_drain_timing drains after full delay", g.energy == 7)


func ac_11_win_lose() -> void:
	var g := watched_scene()
	g.energy = 1
	g.advance(7.14)
	check("ac_11_win_lose energy 0 is not a loss", g.energy == 0 and g.state == "playing")
	g.advance(1.73)
	check("ac_11_win_lose not lost before next drain", g.state == "playing")
	g.advance(0.01)
	check("ac_11_win_lose lost on drain at energy 0", g.state == "lost")
	g = flat()
	sentinel(g, Vector2i(8, 1), 0.0)
	sentinel(g, Vector2i(8, 5), 0.0)
	g.absorb(Vector2i(8, 1))
	check("ac_11_win_lose not won early", g.state == "playing" and g.sentinels_left() == 1)
	g.absorb(Vector2i(8, 5))
	check("ac_11_win_lose won at counter 0", g.state == "won" and g.sentinels_left() == 0)


func signature(g: GameLogic) -> String:
	var tiles := []
	for s in g.sentinels:
		tiles.append([s.tile, s.facing, s.dir])
	var tree_tiles := g.trees.keys()
	tree_tiles.sort()
	return str([g.size, g.heights, tree_tiles, tiles, g.player_tile, g.energy])


func ac_16_levels_match_table() -> void:
	var sentinels := [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]
	var trees := [10, 12, 14, 16, 18, 20, 22, 24, 26, 28]
	var ok := true
	var same := true
	var in_range := true
	for n in range(1, 11):
		var g := Levels.build(n)
		ok = ok and g.size == 31 and g.sentinels.size() == sentinels[n - 1] and g.trees.size() == trees[n - 1] and g.energy == 10 and g.level == n
		same = same and signature(g) == signature(Levels.build(n))
		for row in g.heights:
			for h in row:
				in_range = in_range and h >= 1 and h <= 11
	check("ac_16_levels_match_table sentinels, trees, energy, grid", ok)
	check("ac_16_levels_match_table altitudes 1..11", in_range)
	check("ac_16_levels_match_table deterministic", same)


func block_of(t: Vector2i) -> Vector2i:
	return Vector2i(t.x / 4, t.y / 4)


func ac_17_level_constraints() -> void:
	var ok := true
	for n in range(1, 11):
		var g := Levels.build(n)
		var why := ""
		# Sentinels: each stands on the highest tile of the highest block not excluded.
		var excluded := {}
		for s in g.sentinels:
			var t: Vector2i = s.tile
			var best := 0
			for z in g.size:
				for x in g.size:
					if not excluded.has(block_of(Vector2i(x, z))):
						best = maxi(best, g.heights[z][x])
			if excluded.has(block_of(t)) or g.height(t) != best:
				why = "sentinel placement"
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					excluded[block_of(t) + Vector2i(dx, dz)] = true
		var low := Levels.lowest_sentinel_altitude(g)
		for t in g.trees:
			if g.sentinel_at(t) >= 0 or t == g.player_tile or g.height(t) >= low:
				why = "tree placement"
		if g.trees.size() > 48 - 3 * g.sentinels.size() or g.trees.size() < 10 or g.trees.size() > 32:
			why = "tree count"
		if g.height(g.player_tile) > mini(6, low) or g.occupied(g.player_tile) and g.object_at(g.player_tile) != "":
			why = "start tile"
		for z in g.size:
			for x in g.size:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
					var u := Vector2i(x, z) + d
					if g.in_bounds(u) and absi(g.heights[z][x] - g.height(u)) > 4:
						why = "step > 4"
		if why != "":
			print("level %d violates: %s" % [n, why])
			ok = false
	check("ac_17_level_constraints all levels", ok)


func ac_18_sentinels_idle_until_first_action() -> void:
	var g := Levels.build(1)
	var facing: float = g.sentinels[0].facing
	var energy := g.energy
	g.advance(60.0)
	check("ac_18_sentinels_idle no turn and no drain", g.sentinels[0].facing == facing and g.energy == energy and not g.watched)
	var free := Vector2i(-1, -1)
	for z in g.size:
		for x in g.size:
			if free.x < 0 and g.can_see(Vector2i(x, z)) and not g.occupied(Vector2i(x, z)):
				free = Vector2i(x, z)
	check("ac_18_sentinels_idle first action succeeds", g.create(free) == "" and g.awake)
	g.advance(12.0)
	check("ac_18_sentinels_idle then they turn or watch", g.sentinels[0].turned != 0.0 or g.watched)


func ac_19_solver_bot_clears_all() -> void:
	var cleared := 0
	for n in range(1, 11):
		var g := Levels.build(n)
		if SolverBot.solve(g, 200):
			cleared += 1
		else:
			print("bot failed level %d: %s energy %d" % [n, g.state, g.energy])
	check("ac_19_solver_bot_clears_all 10 of 10", cleared == 10)


func ac_20_energy_carry_and_retry() -> void:
	check("ac_20_energy_carry_and_retry carried", Levels.build(2, 40).energy == 40)
	check("ac_20_energy_carry_and_retry capped", Levels.build(2, 90).energy == 63)
	check("ac_20_energy_carry_and_retry minimum", Levels.build(2, 3).energy == 10)
	check("ac_20_energy_carry_and_retry level 1 fixed", Levels.build(1, 50).energy == 10)
	var g := Levels.build(1)
	g.energy = 30
	var nxt := Levels.next(g)
	check("ac_20_energy_carry_and_retry next carries", nxt.level == 2 and nxt.energy == 30)
	var l := Levels.build(3, 25)
	l.energy = 0
	l.state = "lost"
	var again := Levels.retry(l)
	check("ac_20_energy_carry_and_retry retry original", again.level == 3 and again.energy == 25 and again.state == "playing")
	check("ac_20_energy_carry_and_retry none after 10", Levels.next(Levels.build(10)) == null)
