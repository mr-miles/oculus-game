class_name Levels
extends RefCounted
## The ten deterministic levels. Levels.build(n) is a pure function of n (and
## the carried energy). Terrain follows the original's generator: a 40-bit LFSR
## fills a 32x32 grid of corner altitudes that is smoothed, scaled, repaired and
## stretched to 1..11 (see Levels.stages); tiles come from the corners.

const COUNT := 10
const SIZE := 31
const MIN_ALT := 1
const MAX_ALT := 11
const CORNERS := 32  # corner grid edge (tiles + 1)
const MAX_STEP := 3  # largest altitude difference between neighbouring corners
const BLOCK := 4     # Sentinel placement block edge, tiles
const START_MAX_ALT := 6
const MAX_ATTEMPTS := 100000  # random draws before placement gives up

const SENTINELS := [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]
## Landscape number per level (index 0 = level 1). The spec default is n - 1;
## entries may differ where that landscape fails a shape check (SPEC 4.1).
const LANDSCAPE := [1, 0, 15, 10, 4, 5, 21, 17, 19, 9]
const _LFSR_MASK := 0xFFFFFFFFFF  # 40 bits


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
	_terrain(g, n)
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


static func stages(n: int) -> Dictionary:
	## Every stage of the terrain generator for level n (SPEC 4.1): "outputs"
	## (the 1024 LFSR bytes used), "multiplier", then corner grids "raw",
	## "smoothed" (after pass 2), "scaled", "repaired" (after pass 2) and "final"
	## (stretched and limited). Grids are [z][x], 32 x 32.
	var landscape: int = LANDSCAPE[n - 1]
	var state := _bcd(landscape) | (1 << 16)
	var out := _Lfsr.new(state)
	for _i in 81:
		out.next_byte()
	var mult_byte := out.next_byte()
	var multiplier := 14 + (mult_byte & 7) + ((mult_byte >> 3) & 15)
	if landscape == 0:
		multiplier = 24
	var outputs: Array = []
	for _i in CORNERS * CORNERS:
		outputs.append(out.next_byte())
	var raw := _grid_from(outputs)
	var smoothed := _smooth_grid(_smooth_grid(raw))
	var scaled := _scale(smoothed, multiplier)
	var repaired := _repair(_repair(scaled))
	return {
		"outputs": outputs, "multiplier": multiplier, "raw": raw, "smoothed": smoothed,
		"scaled": scaled, "repaired": repaired, "final": _stretch_limit(repaired),
	}


class _Lfsr:
	var bits: int

	func _init(seed_bits: int) -> void:
		bits = seed_bits

	func next_byte() -> int:
		## Eight shifts: feedback = bit 19 XOR bit 32, shifted into bit 0.
		for _i in 8:
			var fb := ((bits >> 19) ^ (bits >> 32)) & 1
			bits = ((bits << 1) | fb) & Levels._LFSR_MASK
		return bits & 0xFF


static func _bcd(v: int) -> int:
	var r := 0
	for shift in 4:
		r |= (v / int(pow(10, shift)) % 10) << (4 * shift)
	return r


static func _grid_from(values: Array) -> Array:
	var grid: Array = []
	for z in CORNERS:
		grid.append(values.slice(z * CORNERS, (z + 1) * CORNERS))
	return grid


static func _smooth_grid(src: Array) -> Array:
	## Each corner becomes the average of itself and the next three along its
	## row (wrapping), then the same along its column.
	var rows: Array = []
	for z in CORNERS:
		var row: Array = []
		for x in CORNERS:
			var sum := 0
			for k in 4:
				sum += src[z][(x + k) % CORNERS]
			row.append(sum / 4)
		rows.append(row)
	var out: Array = []
	for z in CORNERS:
		var row: Array = []
		for x in CORNERS:
			var sum := 0
			for k in 4:
				sum += rows[(z + k) % CORNERS][x]
			row.append(sum / 4)
		out.append(row)
	return out


static func _scale(src: Array, multiplier: int) -> Array:
	var out: Array = []
	for z in CORNERS:
		var row: Array = []
		for x in CORNERS:
			var v := int(floor(multiplier * (src[z][x] - 128) / 256.0)) + 6
			row.append(mini(maxi(v, 0) + 1, MAX_ALT))
		out.append(row)
	return out


static func _neighbours(z: int, x: int) -> Array:
	var out: Array = []
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var u: Vector2i = Vector2i(x, z) + d
		if u.x >= 0 and u.y >= 0 and u.x < CORNERS and u.y < CORNERS:
			out.append(u)
	return out


static func _repair(src: Array) -> Array:
	## A corner at least 2 above all its neighbours drops to the highest
	## neighbour; one at least 2 below all of them rises to the lowest.
	var out: Array = src.duplicate(true)
	for z in CORNERS:
		for x in CORNERS:
			var hi := -1
			var lo := 99
			var above := true
			var below := true
			for u in _neighbours(z, x):
				var v: int = src[u.y][u.x]
				hi = maxi(hi, v)
				lo = mini(lo, v)
				above = above and src[z][x] >= v + 2
				below = below and src[z][x] <= v - 2
			if above:
				out[z][x] = hi
			elif below:
				out[z][x] = lo
	return out


static func _stretch_limit(src: Array) -> Array:
	var lo := 99
	var hi := -1
	for row in src:
		for v in row:
			lo = mini(lo, v)
			hi = maxi(hi, v)
	var out: Array = []
	for z in CORNERS:
		var row: Array = []
		for x in CORNERS:
			row.append(MIN_ALT + (src[z][x] - lo) * (MAX_ALT - MIN_ALT) / maxi(hi - lo, 1))
		out.append(row)
	var changed := true
	while changed:
		changed = false
		for z in CORNERS:
			for x in CORNERS:
				for dz in range(-1, 2):
					for dx in range(-1, 2):
						var u := Vector2i(x + dx, z + dz)
						if u.x < 0 or u.y < 0 or u.x >= CORNERS or u.y >= CORNERS:
							continue
						if out[z][x] > out[u.y][u.x] + MAX_STEP:
							out[z][x] = out[u.y][u.x] + MAX_STEP
							changed = true
	return out


static func _terrain(g: GameLogic, n: int) -> void:
	## Tiles come from the final corner grid (the ground truth).
	g.load_corners(stages(n).final)


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
				if excluded.has(Vector2i(x / BLOCK, z / BLOCK)) or not g.flat[z][x]:
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
	## Distinct flat empty tiles strictly below the lowest Sentinel.
	var limit := lowest_sentinel_altitude(g)
	var attempts := 0
	while g.trees.size() < count and attempts < MAX_ATTEMPTS:
		attempts += 1
		var t := Vector2i(rng.randi() % g.size, rng.randi() % g.size)
		if g.flat[t.y][t.x] and g.height(t) < limit and not g.occupied(t):
			g.trees[t] = true
	assert(g.trees.size() == count, "could not place all trees")


static func _place_start(g: GameLogic, rng: RandomNumberGenerator) -> void:
	## A flat empty tile at altitude <= min(6, lowest Sentinel altitude).
	var limit := mini(START_MAX_ALT, lowest_sentinel_altitude(g))
	for _i in MAX_ATTEMPTS:
		var t := Vector2i(rng.randi() % g.size, rng.randi() % g.size)
		if g.flat[t.y][t.x] and g.height(t) <= limit and not g.occupied(t):
			g.player_tile = t
			return
	assert(false, "no start tile")
