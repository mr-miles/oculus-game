class_name Levels
extends RefCounted
## The ten deterministic levels. Levels.build(n) is a pure function of n (and
## the carried energy): a fixed seed per level drives layered sine and hash
## terrain on the original's 31x31 world with altitudes 1..11.

const COUNT := 10
const SIZE := 31
const MIN_ALT := 1
const MAX_ALT := 11
const MAX_STEP := 4  # largest altitude difference between neighbours
const BLOCK := 4     # Sentinel placement block edge, tiles
const START_MAX_ALT := 6

const SENTINELS := [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]


static func tree_count(n: int) -> int:
	## 10 + 2 per level, at most 48 - 3 per Sentinel (the original's budget).
	return mini(10 + 2 * (n - 1), 48 - 3 * SENTINELS[n - 1])


static func build(n: int, carried_energy := -1) -> GameLogic:
	## Level n (1..10). Starting energy is 10 on level 1, otherwise the energy
	## carried over, at least 10 and at most GameLogic.MAX_ENERGY.
	assert(n >= 1 and n <= COUNT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * n + 104729
	var g := GameLogic.new(SIZE)
	g.level = n
	_terrain(g, rng, n)
	_place_sentinels(g, rng, SENTINELS[n - 1])
	_place_trees(g, rng, tree_count(n))
	_place_start(g, rng)
	var e := GameLogic.START_ENERGY
	if n > 1:
		e = clampi(maxi(carried_energy, GameLogic.START_ENERGY), GameLogic.START_ENERGY, GameLogic.MAX_ENERGY)
	g.energy = e
	g.start_energy = e
	return g


static func next(g: GameLogic) -> GameLogic:
	## The level after a won one, carrying its energy; null after level 10.
	if g.level >= COUNT:
		return null
	return build(g.level + 1, g.energy)


static func retry(g: GameLogic) -> GameLogic:
	## The same level again with its original starting energy.
	return build(g.level, g.start_energy)


static func lowest_sentinel_altitude(g: GameLogic) -> int:
	var low := MAX_ALT
	for s in g.sentinels:
		low = mini(low, g.height(s.tile))
	return low


static func _terrain(g: GameLogic, rng: RandomNumberGenerator, n: int) -> void:
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var fx := 0.20 + 0.02 * (n % 4)
	var fz := 0.17 + 0.03 * (n % 3)
	for z in g.size:
		for x in g.size:
			var v := 6.0 + 3.6 * sin(x * fx + p1) * cos(z * fz + p2) + 2.0 * sin((x + z) * 0.23 + p3)
			v += rng.randf() * 1.6 - 0.8
			g.heights[z][x] = clampi(int(round(v)), MIN_ALT, MAX_ALT)
	_smooth(g)


static func _smooth(g: GameLogic) -> void:
	## Lower spikes until no tile is more than MAX_STEP above any neighbour
	## (8-neighbourhood).
	var changed := true
	while changed:
		changed = false
		for z in g.size:
			for x in g.size:
				for dz in range(-1, 2):
					for dx in range(-1, 2):
						var t := Vector2i(x + dx, z + dz)
						if g.in_bounds(t) and g.heights[z][x] > g.height(t) + MAX_STEP:
							g.heights[z][x] = g.height(t) + MAX_STEP
							changed = true


static func _place_sentinels(g: GameLogic, rng: RandomNumberGenerator, count: int) -> void:
	## The original's rule: the first Sentinel stands on the highest tile of the
	## highest 4x4 block; each next on the highest tile of the highest block not
	## yet excluded; a used block and its 8 neighbouring blocks are excluded.
	var excluded := {}
	while g.sentinels.size() < count:
		var best := Vector2i(-1, -1)
		var best_score := -1.0
		for z in g.size:
			for x in g.size:
				if excluded.has(Vector2i(x / BLOCK, z / BLOCK)):
					continue
				# Altitude first; the seeded fraction breaks ties.
				var score: float = g.heights[z][x] + rng.randf() * 0.5
				if score > best_score:
					best_score = score
					best = Vector2i(x, z)
		assert(best.x >= 0)
		var home := Vector2i(best.x / BLOCK, best.y / BLOCK)
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				excluded[home + Vector2i(dx, dz)] = true
		g.sentinels.append({
			"tile": best, "facing": float(rng.randi() % 12) * GameLogic.SENTINEL_TURN_STEP,
			"dir": 1 if g.sentinels.size() % 2 == 0 else -1,
			"turned": 0.0, "clock": 0, "sees": false,
		})


static func _place_trees(g: GameLogic, rng: RandomNumberGenerator, count: int) -> void:
	## Distinct empty tiles strictly below the lowest Sentinel.
	var limit := lowest_sentinel_altitude(g)
	while g.trees.size() < count:
		var t := Vector2i(rng.randi() % g.size, rng.randi() % g.size)
		if g.height(t) < limit and not g.occupied(t):
			g.trees[t] = true


static func _place_start(g: GameLogic, rng: RandomNumberGenerator) -> void:
	## An empty tile at altitude <= min(6, lowest Sentinel altitude).
	var limit := mini(START_MAX_ALT, lowest_sentinel_altitude(g))
	while true:
		var t := Vector2i(rng.randi() % g.size, rng.randi() % g.size)
		if g.height(t) <= limit and not g.occupied(t):
			g.player_tile = t
			return
