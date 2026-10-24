class_name Levels
extends RefCounted
## The ten deterministic levels. Levels.build(n) is a pure function of n (and
## the carried energy): a fixed seed per level drives layered sine and hash
## terrain.

const COUNT := 10
const MIN_SENTINEL_GAP := 4  # tiles, Chebyshev
const MIN_START_GAP := 6     # tiles from the start to every Sentinel
const MAX_HEIGHT := 9
const MAX_ATTEMPTS := 60

# [grid size, sentinels, trees] per level, index 0 = level 1.
const TABLE := [
	[12, 1, 4], [12, 1, 5], [14, 2, 6], [14, 2, 7], [16, 3, 8],
	[16, 3, 9], [18, 4, 10], [18, 4, 11], [20, 5, 12], [20, 6, 14],
]


static func build(n: int, carried_energy := -1) -> GameLogic:
	## Level n (1..10). Starting energy is 10 on level 1, otherwise the energy
	## carried over, at least 10 and at most GameLogic.MAX_ENERGY.
	assert(n >= 1 and n <= COUNT)
	var e := GameLogic.START_ENERGY
	if n > 1:
		e = clampi(maxi(carried_energy, GameLogic.START_ENERGY), GameLogic.START_ENERGY, GameLogic.MAX_ENERGY)
	# Try fixed variants of the seed until no Sentinel is in view of the start,
	# so every level needs at least one climb.
	var g: GameLogic
	for attempt in MAX_ATTEMPTS:
		g = _generate(n, attempt)
		if not _any_visible(g):
			break
	g.energy = e
	g.start_energy = e
	return g


static func _any_visible(g: GameLogic) -> bool:
	for s in g.sentinels:
		if g.can_see(s.tile):
			return true
	return false


static func _generate(n: int, attempt: int) -> GameLogic:
	var row: Array = TABLE[n - 1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * n + 104729 + 15485863 * attempt
	var g := GameLogic.new(row[0])
	g.level = n
	_terrain(g, rng, n)
	g.player_tile = _pick_start(g, rng)
	_place_sentinels(g, rng, row[1])
	_place_trees(g, rng, row[2])
	_face_away(g, rng)
	return g


static func next(g: GameLogic) -> GameLogic:
	## The level after a won one, carrying its energy; null after level 10.
	if g.level >= COUNT:
		return null
	return build(g.level + 1, g.energy)


static func retry(g: GameLogic) -> GameLogic:
	## The same level again with its original starting energy.
	return build(g.level, g.start_energy)


static func _terrain(g: GameLogic, rng: RandomNumberGenerator, n: int) -> void:
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var fx := 0.35 + 0.04 * (n % 4)
	var fz := 0.30 + 0.05 * (n % 3)
	for z in g.size:
		for x in g.size:
			var v := 3.5 + 2.6 * sin(x * fx + p1) * cos(z * fz + p2) + 1.6 * sin((x + z) * 0.37 + p3)
			v += rng.randf() * 1.4 - 0.4
			g.heights[z][x] = clampi(int(round(v)), 0, MAX_HEIGHT)


static func _pick_start(g: GameLogic, rng: RandomNumberGenerator) -> Vector2i:
	## A low tile (height <= 1) near a grid edge.
	var best := Vector2i(-1, -1)
	var best_score := -1.0
	for z in g.size:
		for x in g.size:
			var edge := mini(mini(x, z), mini(g.size - 1 - x, g.size - 1 - z))
			if g.heights[z][x] <= 1 and edge <= 2:
				var score := rng.randf() + (0.5 if g.heights[z][x] == 1 else 0.0)
				if score > best_score:
					best_score = score
					best = Vector2i(x, z)
	if best.x < 0:
		best = Vector2i(1, 1)
	g.heights[best.y][best.x] = mini(g.heights[best.y][best.x], 1)
	return best


static func _cheb(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func _place_sentinels(g: GameLogic, rng: RandomNumberGenerator, count: int) -> void:
	var cand: Array = []
	for z in g.size:
		for x in g.size:
			var t := Vector2i(x, z)
			if _cheb(t, g.player_tile) >= MIN_START_GAP:
				cand.append([g.heights[z][x] + rng.randf() * 0.9, t])
	cand.sort_custom(func(a, b): return a[0] > b[0])
	for c in cand:
		if g.sentinels.size() >= count:
			break
		var t: Vector2i = c[1]
		var far := true
		for s in g.sentinels:
			far = far and _cheb(t, s.tile) >= MIN_SENTINEL_GAP
		if far:
			_make_peak(g, t)
			g.sentinels.append({
				"tile": t, "facing": 0.0, "dir": 1 if g.sentinels.size() % 2 == 0 else -1,
				"turned": 0.0, "clock": 0, "sees": false,
			})
	assert(g.sentinels.size() == count)


static func _make_peak(g: GameLogic, t: Vector2i) -> void:
	## Raise t to be at least 2 m above every tile within 2 tiles (lowering
	## neighbours if t is already at the height cap).
	var around := 0
	for z in range(maxi(t.y - 2, 0), mini(t.y + 3, g.size)):
		for x in range(maxi(t.x - 2, 0), mini(t.x + 3, g.size)):
			if Vector2i(x, z) != t:
				around = maxi(around, g.heights[z][x])
	var h := mini(maxi(g.height(t), around + 2), MAX_HEIGHT)
	g.heights[t.y][t.x] = h
	for z in range(maxi(t.y - 2, 0), mini(t.y + 3, g.size)):
		for x in range(maxi(t.x - 2, 0), mini(t.x + 3, g.size)):
			if Vector2i(x, z) != t:
				g.heights[z][x] = mini(g.heights[z][x], h - 2)


static func _place_trees(g: GameLogic, rng: RandomNumberGenerator, count: int) -> void:
	while g.trees.size() < count:
		var t := Vector2i(rng.randi() % g.size, rng.randi() % g.size)
		if not g.occupied(t):
			g.trees[t] = true


static func _face_away(g: GameLogic, rng: RandomNumberGenerator) -> void:
	## Give each Sentinel a start facing (a multiple of the turn step) that does
	## not watch the player at the start.
	for s in g.sentinels:
		s.facing = float(rng.randi() % 12) * GameLogic.SENTINEL_TURN_STEP
	var guard := 0
	while g.watched_from(g.player_tile) and guard < 12:
		for s in g.sentinels:
			if g.watched_from(g.player_tile) and g.sentinel_sees(s, g.eye_position()):
				s.facing = fposmod(s.facing + GameLogic.SENTINEL_TURN_STEP, 360.0)
		guard += 1
