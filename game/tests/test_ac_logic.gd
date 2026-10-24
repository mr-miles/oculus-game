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


## Like flat(), with a far Sentinel facing away so the level cannot be won by
## accident (a level with no Sentinels is won by its first action).
func guarded() -> GameLogic:
	var g := flat()
	sentinel(g, Vector2i(11, 11), 0.0)
	g.awake = false
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
	g.set_tile(Vector2i(3, 1), 20)
	before = snapshot(g)
	check("ac_3_create_fails hidden tile", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	g = flat()
	g.trees[Vector2i(6, 1)] = true
	before = snapshot(g)
	check("ac_3_create_fails occupied tile", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	before = snapshot(g)
	check("ac_3_create_fails own tile", g.create(g.player_tile) != "" and snapshot(g) == before)
	g = flat()
	g.energy = 1
	before = snapshot(g)
	check("ac_3_create_fails boulder low energy", g.create(Vector2i(6, 1), "boulder") != "" and snapshot(g) == before)
	g = flat()
	g.set_corner(6, 1, 2)
	before = snapshot(g)
	check("ac_3_create_fails not flat", g.create(Vector2i(6, 1)) != "" and snapshot(g) == before)
	g = flat()
	g.trees[Vector2i(6, 1)] = true
	g.synthoids[Vector2i(6, 2)] = true
	sentinel(g, Vector2i(6, 3), 0.0)
	before = snapshot(g)
	var tops_refused := true
	for row in [1, 2, 3]:
		tops_refused = tops_refused and g.create(Vector2i(6, row), "boulder") != "" and g.create(Vector2i(6, row)) != ""
	check("ac_3_create_fails top is tree, synthoid or sentinel", tops_refused and snapshot(g) == before)
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
	check("ac_4_absorb_energy sentinel +4", g.absorb(Vector2i(9, 5)) == "" and g.energy == 18 and g.sentinels.size() == 1)
	g.boulders[Vector2i(4, 2)] = 2
	check("ac_4_absorb_energy boulder +2", g.absorb(Vector2i(4, 2)) == "" and g.energy == 20 and g.boulder_count(Vector2i(4, 2)) == 1)
	g.energy = 61
	g.synthoids[Vector2i(5, 1)] = true
	g.absorb(Vector2i(5, 1))
	check("ac_4_absorb_energy capped at 63", g.energy == 63)


func ac_5_absorb_fails() -> void:
	var g := flat()
	g.trees[Vector2i(6, 1)] = true
	g.set_tile(Vector2i(3, 1), 20)
	var before := snapshot(g)
	check("ac_5_absorb_fails hidden", g.absorb(Vector2i(6, 1)) != "" and snapshot(g) == before)
	check("ac_5_absorb_fails empty tile", g.absorb(Vector2i(1, 6)) != "" and snapshot(g) == before)
	check("ac_5_absorb_fails own tile", g.absorb(g.player_tile) != "" and snapshot(g) == before)


func ac_6_line_of_sight() -> void:
	var g := flat()
	var far := Vector2i(6, 1)
	check("ac_6_line_of_sight open", g.can_see(far))
	g.set_tile(Vector2i(3, 1), 20)
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
	g.set_tile(Vector2i(3, 1), 20)
	var before := snapshot(g)
	check("ac_7_transfer hidden fails", g.move(Vector2i(1, 1)) != "" and snapshot(g) == before)
	check("ac_7_transfer nonexistent fails", g.move(Vector2i(8, 8)) != "" and snapshot(g) == before)


func ac_8_sentinel_turns() -> void:
	var g := flat()
	g.set_tile(Vector2i(4, 1), 40)  # wall: the Sentinel never sees the player
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
	g.set_tile(Vector2i(4, 1), 20)
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
		# Sentinels: each on the highest flat tile of the highest block not excluded.
		var excluded := {}
		for s in g.sentinels:
			var t: Vector2i = s.tile
			var best := 0
			for z in g.size:
				for x in g.size:
					if g.flat[z][x] and not excluded.has(block_of(Vector2i(x, z))):
						best = maxi(best, g.heights[z][x])
			if excluded.has(block_of(t)) or g.height(t) != best or not g.is_flat(t):
				why = "sentinel placement"
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					excluded[block_of(t) + Vector2i(dx, dz)] = true
		var low := Levels.lowest_sentinel_altitude(g)
		for t in g.trees:
			if g.sentinel_at(t) >= 0 or t == g.player_tile or g.height(t) >= low or not g.is_flat(t):
				why = "tree placement"
		if g.trees.size() > 48 - 3 * g.sentinels.size() or g.trees.size() < 10 or g.trees.size() > 32:
			why = "tree count"
		if g.height(g.player_tile) > mini(6, low) or g.object_at(g.player_tile) != "" or not g.is_flat(g.player_tile):
			why = "start tile"
		var corners: Array = Levels.stages(n).final
		for z in 32:
			for x in 32:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
					var u := Vector2i(x, z) + d
					if u.x >= 0 and u.y >= 0 and u.x < 32 and u.y < 32 and absi(corners[z][x] - corners[u.y][u.x]) > 3:
						why = "corner step > 3"
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
			if free.x < 0 and g.is_flat(Vector2i(x, z)) and g.can_see(Vector2i(x, z)) and not g.occupied(Vector2i(x, z)):
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


func ac_44_create_boulder() -> void:
	var g := guarded()
	var t := Vector2i(6, 1)
	check("ac_44_create_boulder succeeds", g.create(t, "boulder") == "")
	check("ac_44_create_boulder energy -2", g.energy == 8)
	check("ac_44_create_boulder one boulder", g.boulder_count(t) == 1 and g.object_at(t) == "boulder")
	check("ac_44_create_boulder surface +0.5 m", is_equal_approx(g.stack_height(t), 0.5) and is_equal_approx(g.top_position(t).y, 0.5))
	check("ac_44_create_boulder tile still free", not g.occupied(t))
	check("ac_44_create_boulder second boulder and synthoid on top", g.create(t, "boulder") == "" and g.create(t) == "" and g.object_at(t) == "synthoid")


func ac_46_trees_not_creatable() -> void:
	var g := guarded()
	g.energy = 30
	var before := snapshot(g)
	var refused := true
	for t in [Vector2i(6, 1), g.player_tile]:
		refused = refused and g.create(t, "tree") != "" and g.create(t, "") != "" and g.create(t, "sentinel") != ""
	check("ac_46_trees_not_creatable refused with reason", refused)
	check("ac_46_trees_not_creatable nothing changed", snapshot(g) == before and g.trees.is_empty() and g.boulders.is_empty())


func ac_47_stacks() -> void:
	var g := guarded()
	g.energy = 40
	var t := Vector2i(6, 1)
	var ok := true
	for i in 6:
		ok = ok and g.create(t, "boulder") == ""
	check("ac_47_stacks six boulders", ok and g.boulder_count(t) == 6)
	var before := snapshot(g)
	check("ac_47_stacks seventh refused", g.create(t, "boulder") != "" and g.boulder_count(t) == 6 and snapshot(g) == before)
	check("ac_47_stacks synthoid on top of boulders", g.create(t) == "" and g.object_at(t) == "synthoid" and g.boulder_count(t) == 6)
	check("ac_47_stacks nothing on a synthoid", g.create(t, "boulder") != "" and g.create(t) != "")


func ac_48_absorb_top_only() -> void:
	var g := guarded()
	g.energy = 20
	var t := Vector2i(6, 1)
	g.create(t, "boulder")
	g.create(t, "boulder")
	g.create(t)
	check("ac_48_absorb_top_only spent 7", g.energy == 20 - 7)
	var gained := []
	for i in 3:
		var e := g.energy
		g.absorb(t)
		gained.append(g.energy - e)
	check("ac_48_absorb_top_only +3 then +2, +2", gained == [3, 2, 2] and g.boulder_count(t) == 0 and g.object_at(t) == "")
	check("ac_48_absorb_top_only conservation", g.energy == 20)
	g.create(g.player_tile, "boulder")
	var before := snapshot(g)
	check("ac_48_absorb_top_only own tile refused", g.absorb(g.player_tile) != "" and g.boulder_count(g.player_tile) == 1 and snapshot(g) == before)


func ac_49_boulders_block_sight() -> void:
	var g := flat()
	var far := Vector2i(6, 1)
	g.boulders[Vector2i(3, 1)] = 6
	check("ac_49_boulders_block_sight stack hides tile", not g.can_see(far))
	g.boulders.erase(Vector2i(3, 1))
	check("ac_49_boulders_block_sight removing shows it", g.can_see(far))


func ac_50_energy_math() -> void:
	var g := guarded()
	g.energy = 2
	var refused := g.create(Vector2i(6, 1)) != "" and g.energy == 2
	check("ac_50_energy_math 2 energy: synthoid refused", refused)
	check("ac_50_energy_math 2 energy: boulder ok, exactly 0 left", g.create(Vector2i(6, 1), "boulder") == "" and g.energy == 0)
	g = guarded()
	g.energy = 1
	check("ac_50_energy_math 1 energy: neither", g.create(Vector2i(6, 1)) != "" and g.create(Vector2i(6, 1), "boulder") != "" and g.energy == 1)
	g = guarded()
	for i in 61:
		g.trees[Vector2i(i % 12, 4 + i / 12)] = true
	check("ac_50_energy_math 63 objects: one more works", g.object_count() == 63 and g.create(Vector2i(6, 1)) == "" and g.object_count() == 64)
	check("ac_50_energy_math 64 objects: refused", g.create(Vector2i(7, 1), "boulder") != "")


func ac_54_generator_stages() -> void:
	var ok := true
	var failed := 0
	for n in range(1, 11):
		var st: Dictionary = Levels.stages(n)
		var outs: Array = st.outputs
		ok = ok and outs.size() == 1024 and outs.min() >= 0 and outs.max() <= 255
		ok = ok and variance(st.smoothed) < variance(st.raw)
		for key in ["scaled", "repaired", "final"]:
			for row in st[key]:
				ok = ok and row.min() >= 1 and row.max() <= 11
		var lo := 99
		var hi := 0
		for row in st.final:
			lo = mini(lo, row.min())
			hi = maxi(hi, row.max())
		ok = ok and lo == 1 and hi == 11
		if not ok:
			print("stages failed on level %d" % n)
			ok = true
			failed += 1
	ok = failed == 0
	check("ac_54_generator_stages all levels", ok)


func variance(grid: Array) -> float:
	var sum := 0.0
	var n := 0
	for row in grid:
		for v in row:
			sum += v
			n += 1
	var mean := sum / n
	var acc := 0.0
	for row in grid:
		for v in row:
			acc += (v - mean) * (v - mean)
	return acc / n


func ac_55_no_pits_or_spikes() -> void:
	var bad := 0
	for n in range(1, 11):
		var g := Levels.build(n)
		for z in g.size:
			for x in g.size:
				var t := Vector2i(x, z)
				var above := true
				var below := true
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if g.in_bounds(t + d):
						above = above and g.height(t) >= g.height(t + d) + 2
						below = below and g.height(t) <= g.height(t + d) - 2
				if (above and g.sentinel_at(t) < 0) or below:
					bad += 1
	check("ac_55_no_pits_or_spikes none in 10 levels", bad == 0)


func ac_56_smooth_not_noise() -> void:
	var steps_ok := true
	var mean_ok := true
	for n in range(1, 11):
		var g := Levels.build(n)
		var corners: Array = Levels.stages(n).final
		for z in 32:
			for x in 32:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
					var u := Vector2i(x, z) + d
					if u.x < 32 and u.y < 32 and absi(corners[z][x] - corners[u.y][u.x]) > 3:
						steps_ok = false
		var sum := 0.0
		var count := 0
		for z in g.size:
			for x in g.size:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
					if g.in_bounds(Vector2i(x, z) + d):
						sum += absf(g.height(Vector2i(x, z)) - g.height(Vector2i(x, z) + d))
						count += 1
		var mean := sum / count
		mean_ok = mean_ok and mean >= 0.3 and mean <= 1.2
	check("ac_56_smooth_not_noise corner steps <= 3", steps_ok)
	check("ac_56_smooth_not_noise mean tile step 0.3..1.2", mean_ok)


func ac_57_flat_share() -> void:
	var ok := true
	for n in range(1, 11):
		var g := Levels.build(n)
		var flats := 0
		for row in g.flat:
			flats += row.count(true)
		var share := float(flats) / (g.size * g.size)
		ok = ok and share >= 0.2 and share <= 0.8
	check("ac_57_flat_share 20%..80% in every level", ok)


func ac_58_sentinels_on_peaks() -> void:
	var ok := true
	for n in range(1, 11):
		var g := Levels.build(n)
		var best := 0
		var block_best := {}
		for z in g.size:
			for x in g.size:
				if g.flat[z][x]:
					best = maxi(best, g.heights[z][x])
					var b := block_of(Vector2i(x, z))
					block_best[b] = maxi(block_best.get(b, 0), g.heights[z][x])
		ok = ok and g.height(g.sentinels[0].tile) == best and best >= 9
		for s in g.sentinels:
			ok = ok and g.height(s.tile) >= 5 and g.height(s.tile) == block_best[block_of(s.tile)] and g.is_flat(s.tile)
	check("ac_58_sentinels_on_peaks all levels", ok)


func ac_59_deterministic() -> void:
	var same := true
	var seen := []
	var distinct := true
	for n in range(1, 11):
		same = same and signature(Levels.build(n)) == signature(Levels.build(n)) and Levels.stages(n).outputs == Levels.stages(n).outputs
		var grid := str(Levels.build(n).heights)
		distinct = distinct and not seen.has(grid)
		seen.append(grid)
	check("ac_59_deterministic two builds identical", same)
	check("ac_59_deterministic levels pairwise different", distinct)


## A single-tile grid with corners a, b, c, d (SPEC 4.2).
func one_tile(a: int, b: int, c: int, d: int) -> GameLogic:
	var g := GameLogic.new(1)
	g.load_corners([[a, b], [c, d]])
	return g


func ac_60_tile_shapes() -> void:
	var t := Vector2i(0, 0)
	check("ac_60_tile_shapes flat", one_tile(3, 3, 3, 3).tile_shape(t) == "flat")
	check("ac_60_tile_shapes slope", one_tile(3, 3, 5, 5).tile_shape(t) == "slope")
	check("ac_60_tile_shapes ridge", one_tile(3, 3, 3, 5).tile_shape(t) == "ridge")
	check("ac_60_tile_shapes valley", one_tile(3, 4, 4, 3).tile_shape(t) == "valley")
	check("ac_60_tile_shapes height flat", one_tile(3, 3, 3, 3).height(t) == 3)
	check("ac_60_tile_shapes height is rounded mean", one_tile(3, 3, 5, 5).height(t) == 4 and one_tile(3, 3, 3, 5).height(t) == 4)


func ac_61_surface_height() -> void:
	var corners_ok := true
	for abcd in [[1, 3, 3, 5], [1, 1, 1, 5], [3, 5, 5, 3]]:
		var g := one_tile(abcd[0], abcd[1], abcd[2], abcd[3])
		corners_ok = corners_ok and is_equal_approx(g.surface_height(0.0, 0.0), abcd[0]) \
				and is_equal_approx(g.surface_height(1.999999, 0.0), abcd[1]) \
				and is_equal_approx(g.surface_height(0.0, 1.999999), abcd[2]) \
				and is_equal_approx(g.surface_height(1.999999, 1.999999), abcd[3])
	check("ac_61_surface_height equals corner altitude at corners", corners_ok)
	check("ac_61_surface_height slope centre 3.0", is_equal_approx(one_tile(1, 3, 3, 5).surface_height(1.0, 1.0), 3.0))
	var ridge := one_tile(1, 1, 1, 5)
	check("ac_61_surface_height ridge centre 3.0 and 2.0", is_equal_approx(ridge.surface_height(1.0, 1.0), 3.0) and is_equal_approx(ridge.surface_height(1.5, 0.5), 2.0))
	var valley := one_tile(3, 5, 5, 3)
	check("ac_61_surface_height valley centre 3.0 and 4.0", is_equal_approx(valley.surface_height(1.0, 1.0), 3.0) and is_equal_approx(valley.surface_height(1.5, 0.5), 4.0))
	var flat_tile := one_tile(4, 4, 4, 4)
	check("ac_61_surface_height flat is its altitude everywhere", is_equal_approx(flat_tile.surface_height(0.3, 1.7), 4.0) and is_equal_approx(flat_tile.surface_height(1.1, 0.2), 4.0))


func ac_62_slopes_in_levels() -> void:
	var every_level := true
	var seen := {}
	for n in range(1, 11):
		var g := Levels.build(n)
		var non_flat := 0
		var has_slope := false
		for z in g.size:
			for x in g.size:
				var shape := g.tile_shape(Vector2i(x, z))
				seen[shape] = true
				if shape != "flat":
					non_flat += 1
				has_slope = has_slope or shape == "slope"
		var share := float(non_flat) / (g.size * g.size)
		every_level = every_level and has_slope and share >= 0.2 and share <= 0.8
	check("ac_62_slopes_in_levels slope tile in every level, non-flat share 20..80%", every_level)
	check("ac_62_slopes_in_levels slope, ridge and valley all occur", seen.has("slope") and seen.has("ridge") and seen.has("valley"))


func ac_63_objects_only_on_flat() -> void:
	var placed_ok := true
	var refused_ok := true
	for n in range(1, 11):
		var g := Levels.build(n)
		for t in g.trees:
			placed_ok = placed_ok and g.is_flat(t)
		for s in g.sentinels:
			placed_ok = placed_ok and g.is_flat(s.tile)
		placed_ok = placed_ok and g.is_flat(g.player_tile)
		g.energy = GameLogic.MAX_ENERGY
		for z in g.size:
			for x in g.size:
				var t := Vector2i(x, z)
				if g.is_flat(t):
					continue
				var before := snapshot(g)
				for kind in ["synthoid", "boulder"]:
					var why := g.create(t, kind)
					refused_ok = refused_ok and why.to_lower().contains("flat") and snapshot(g) == before
		for t in g.synthoids:
			placed_ok = placed_ok and g.is_flat(t)
		for t in g.boulders:
			placed_ok = placed_ok and g.is_flat(t)
	check("ac_63_objects_only_on_flat generated objects on flat tiles", placed_ok)
	check("ac_63_objects_only_on_flat create on a non-flat tile refused with 'flat'", refused_ok)


func ac_64_sight_over_slopes() -> void:
	var results := []
	for apex in [5, 4, 3.5, 1]:
		var g := GameLogic.new(4)
		var grid := []
		for z in 5:
			var row := []
			for x in 5:
				row.append(3)
			grid.append(row)
		for z in 5:
			grid[z][2] = apex
		g.load_corners(grid)
		g.player_tile = Vector2i(0, 1)
		results.append(g.can_see(Vector2i(3, 1)))
	check("ac_64_sight_over_slopes blocked at apex 5 and 4", not results[0] and not results[1])
	check("ac_64_sight_over_slopes visible at apex 3.5 and 1", results[2] and results[3])
