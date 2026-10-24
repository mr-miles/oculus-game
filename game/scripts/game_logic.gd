class_name GameLogic
extends RefCounted
## Pure game rules for one level of the Sentinel-style game. No nodes, so it
## runs headless. Tiles are Vector2i(x, z); heights are whole metres.
## Levels.build(n) fills in a playable level; GameLogic.new(size) is an empty
## flat grid (used by tests and by Levels).

const SYNTHOID_COST := 3
const BOULDER_COST := 2
const BOULDER_ENERGY := 2
const BOULDER_HEIGHT := 0.5          # metres per boulder
const MAX_BOULDERS_PER_TILE := 6
const TREE_ENERGY := 1
const SYNTHOID_ENERGY := 3
const SENTINEL_ENERGY := 4
const START_ENERGY := 10
const MAX_ENERGY := 63
const MAX_OBJECTS := 64             # trees, boulders, synthoids, Sentinels and the player's body together
const SENTINEL_TURN_STEP := 28.125  # degrees per turn
const SENTINEL_TURN_TIME := 11.94   # seconds between turns
const SENTINEL_FOV := 56.25         # degrees, total
const DRAIN_DELAY := 7.14           # seconds of continuous watching before the first drain
const DRAIN_INTERVAL := 1.74        # seconds between drains after that
const DRAIN_AMOUNT := 1
const EYE := 1.6           # player eye above a tile top, metres
const SENTINEL_EYE := 2.2  # sentinel eye above its tile top, metres
const TREE_HEIGHT := 3.0   # trees block sight up to this far above their tile
const TILE := 2.0          # tile edge, metres

const MSG_NO_TARGET := "Aim at a blue synthoid you can see"
const MSG_HIDDEN := "You can't see that tile"
const MSG_OCCUPIED := "Something is already there"
const MSG_OWN_TILE := "You are standing there"
const MSG_NO_ENERGY := "Not enough energy: a body costs 3"
const MSG_NO_ENERGY_BOULDER := "Not enough energy: a boulder costs 2"
const MSG_BAD_KIND := "You can only make synthoids and boulders"
const MSG_NOT_FLAT := "Needs flat ground"
const MSG_STACK_FULL := "That stack of boulders is full"
const MSG_NOTHING := "Nothing to absorb there"
const MSG_FULL := "The valley is full of objects"
const MSG_OVER := "This hill is finished"
const MSG_OFF_GRID := "Aim at a tile"

# Simulation runs in whole ticks so timings are exact (every constant above is
# a multiple of 0.01 s).
const _TICK := 0.01
const _TURN_TICKS := 1194
const _DELAY_TICKS := 714
const _INTERVAL_TICKS := 174

var level := 1
var size := 12
var heights: Array = []  # heights[z][x]: tile altitude (rounded mean of its corners)
var corners: Array = []  # corners[z][x], (size + 1) squares of altitudes: the ground truth
var synthoids := {}      # Vector2i -> true
var trees := {}          # Vector2i -> true
var boulders := {}       # Vector2i -> count (1..MAX_BOULDERS_PER_TILE) under any top object
var flat: Array = []     # flat[z][x]: true if the tile's four corners are equal (derived)
## One Dictionary per Sentinel: tile (Vector2i), facing (degrees in [0, 360);
## direction on the ground is Vector2(sin, cos) in (x, z)), dir (+1 or -1, the
## fixed turn direction), turned (cumulative signed degrees turned), clock
## (ticks since its last turn), sees (bool, currently watching the player).
var sentinels: Array = []
var player_tile := Vector2i.ZERO
var energy := START_ENERGY
var start_energy := START_ENERGY  # energy the level began with (used for retry)
var state := "playing"            # "playing", "won" or "lost"
var watched := false
var awake := false                # Sentinels stay idle until the first action
var watch_ticks := 0              # consecutive ticks watched

var _pending := 0.0


func _init(grid_size := 12) -> void:
	size = grid_size
	for z in size:
		var row := []
		row.resize(size)
		row.fill(0)
		heights.append(row)
		var f := []
		f.resize(size)
		f.fill(true)
		flat.append(f)
	for z in size + 1:
		var crow := []
		crow.resize(size + 1)
		crow.fill(0)
		corners.append(crow)


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size and t.y < size


func height(t: Vector2i) -> int:
	return heights[t.y][t.x]


func is_flat(t: Vector2i) -> bool:
	return flat[t.y][t.x]


func corner(cx: int, cz: int) -> int:
	## Altitude of corner (cx, cz), both in 0..size.
	return corners[cz][cx]


func set_corner(cx: int, cz: int, altitude: int) -> void:
	## Change one corner and refresh the (up to four) tiles that share it.
	corners[cz][cx] = altitude
	for t in [Vector2i(cx - 1, cz - 1), Vector2i(cx, cz - 1), Vector2i(cx - 1, cz), Vector2i(cx, cz)]:
		if in_bounds(t):
			_retile(t)


func set_tile(t: Vector2i, altitude: int) -> void:
	## Make tile t a flat column at `altitude` (its four corners).
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		set_corner(t.x + d.x, t.y + d.y, altitude)


func load_corners(grid: Array) -> void:
	## Replace the whole corner grid (size + 1 rows of size + 1 altitudes).
	for z in size + 1:
		for x in size + 1:
			corners[z][x] = grid[z][x]
	for z in size:
		for x in size:
			_retile(Vector2i(x, z))


func _retile(t: Vector2i) -> void:
	var a: int = corners[t.y][t.x]
	var b: int = corners[t.y][t.x + 1]
	var c: int = corners[t.y + 1][t.x]
	var d: int = corners[t.y + 1][t.x + 1]
	heights[t.y][t.x] = (a + b + c + d + 2) / 4
	flat[t.y][t.x] = a == b and a == c and a == d


func tile_shape(t: Vector2i) -> String:
	## "flat" (a = b = c = d), "slope" (a + d = b + c), "ridge" (a + d > b + c)
	## or "valley" (a + d < b + c); a, b, c, d = corners (x, z), (x+1, z),
	## (x, z+1), (x+1, z+1).
	var a: int = corners[t.y][t.x]
	var b: int = corners[t.y][t.x + 1]
	var c: int = corners[t.y + 1][t.x]
	var d: int = corners[t.y + 1][t.x + 1]
	if a == b and a == c and a == d:
		return "flat"
	if a + d == b + c:
		return "slope"
	return "ridge" if a + d > b + c else "valley"


func boulder_count(t: Vector2i) -> int:
	return boulders.get(t, 0)


func stack_height(t: Vector2i) -> float:
	## Tile altitude plus half a metre per boulder on it.
	return float(height(t)) + BOULDER_HEIGHT * boulder_count(t)


func surface_height(x_m: float, z_m: float) -> float:
	## Height of the ground at a world point (metres): the corner grid
	## interpolated over two triangles split on the a-d diagonal, plus the
	## boulders on a flat tile. Outside the grid: 0.
	var t := Vector2i(int(floor(x_m / TILE)), int(floor(z_m / TILE)))
	if not in_bounds(t):
		return 0.0
	var u := x_m / TILE - t.x
	var v := z_m / TILE - t.y
	var a: float = corners[t.y][t.x]
	var b: float = corners[t.y][t.x + 1]
	var c: float = corners[t.y + 1][t.x]
	var d: float = corners[t.y + 1][t.x + 1]
	var h: float
	if u >= v:
		h = a + u * (b - a) + v * (d - b)
	else:
		h = a + v * (c - a) + u * (d - c)
	if flat[t.y][t.x]:
		h += BOULDER_HEIGHT * boulder_count(t)
	return h


func top_position(t: Vector2i) -> Vector3:
	## World position of the centre of a tile's surface (boulders included on a flat tile).
	var x := (t.x + 0.5) * TILE
	var z := (t.y + 0.5) * TILE
	return Vector3(x, surface_height(x, z), z)


func eye_position() -> Vector3:
	return top_position(player_tile) + Vector3(0, EYE, 0)


func sentinel_at(t: Vector2i) -> int:
	## Index into `sentinels` of the Sentinel on tile t, or -1.
	for i in sentinels.size():
		if sentinels[i].tile == t:
			return i
	return -1


func sentinels_left() -> int:
	return sentinels.size()


func object_at(t: Vector2i) -> String:
	## The top object on tile t: "sentinel", "tree", "synthoid", "boulder" or "".
	if sentinel_at(t) >= 0:
		return "sentinel"
	if trees.has(t):
		return "tree"
	if synthoids.has(t):
		return "synthoid"
	if boulders.has(t):
		return "boulder"
	return ""


func object_count() -> int:
	var n := trees.size() + synthoids.size() + sentinels.size() + 1
	for t in boulders:
		n += boulders[t]
	return n


func occupied(t: Vector2i) -> bool:
	## Boulders alone do not make a tile occupied; a top object or the player does.
	var top := object_at(t)
	return (top != "" and top != "boulder") or t == player_tile


func can_see(t: Vector2i) -> bool:
	## A tile is visible if nothing blocks the line from the player's eye to its
	## top centre. Terrain columns, boulders and trees block; synthoids do not.
	if not in_bounds(t) or t == player_tile or not is_flat(t):
		return false
	return _clear(eye_position(), top_position(t), player_tile, t)


func _clear(from: Vector3, to: Vector3, skip_a: Vector2i, skip_b: Vector2i) -> bool:
	## True if the segment from->to passes above the ground surface, boulders
	## and trees, except over the two skipped end tiles. Sampled every 0.25 m
	## horizontally.
	var reach := Vector2(to.x - from.x, to.z - from.z).length()
	var steps := maxi(48, int(ceil(reach / 0.25)))
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / steps)
		var c := Vector2i(int(floor(p.x / TILE)), int(floor(p.z / TILE)))
		if c == skip_a or c == skip_b or not in_bounds(c):
			continue
		var top := surface_height(p.x, p.z)
		if trees.has(c):
			top += TREE_HEIGHT
		if p.y < top:
			return false
	return true


func sentinel_sees(s: Dictionary, eye: Vector3) -> bool:
	var origin := top_position(s.tile)
	var d := Vector2(eye.x - origin.x, eye.z - origin.z)
	if d.length() < 0.001:
		return false
	var angle := rad_to_deg(Vector2(sin(deg_to_rad(s.facing)), cos(deg_to_rad(s.facing))).angle_to(d))
	if absf(angle) > SENTINEL_FOV / 2.0 + 0.0001:
		return false
	return _clear(origin + Vector3(0, SENTINEL_EYE, 0), eye, s.tile, player_tile)


func watched_from(t: Vector2i) -> bool:
	## Would a player standing on tile t be watched right now?
	var eye := top_position(t) + Vector3(0, EYE, 0)
	for s in sentinels:
		if sentinel_sees(s, eye):
			return true
	return false


func drain_countdown() -> float:
	## Seconds until the next drain; only meaningful while watched.
	if not watched:
		return 0.0
	var left := _DELAY_TICKS - watch_ticks
	if watch_ticks >= _DELAY_TICKS:
		left = _INTERVAL_TICKS - (watch_ticks - _DELAY_TICKS) % _INTERVAL_TICKS
	return left * _TICK


func create(t: Vector2i, kind := "synthoid") -> String:
	## Make a "synthoid" or a "boulder" on t. Returns "" or the reason it failed.
	var why := _blocked(t)
	if why != "":
		return why
	if kind != "synthoid" and kind != "boulder":
		return MSG_BAD_KIND
	var own := t == player_tile
	if own and kind == "synthoid":
		return MSG_OWN_TILE
	var top := object_at(t)
	if top != "" and top != "boulder":
		return MSG_OCCUPIED
	if not own and not can_see(t):
		return MSG_HIDDEN
	if kind == "boulder" and boulder_count(t) >= MAX_BOULDERS_PER_TILE:
		return MSG_STACK_FULL
	if energy < (SYNTHOID_COST if kind == "synthoid" else BOULDER_COST):
		return MSG_NO_ENERGY if kind == "synthoid" else MSG_NO_ENERGY_BOULDER
	if object_count() >= MAX_OBJECTS:
		return MSG_FULL
	if kind == "synthoid":
		synthoids[t] = true
		_set_energy(energy - SYNTHOID_COST)
	else:
		boulders[t] = boulder_count(t) + 1
		_set_energy(energy - BOULDER_COST)
	_wake()
	return ""


func move(t: Vector2i) -> String:
	## Transfer into the visible synthoid on t.
	var why := _blocked(t)
	if why != "":
		return why
	if not synthoids.has(t) or not can_see(t):
		return MSG_NO_TARGET
	synthoids.erase(t)
	player_tile = t
	_wake()
	return ""


func absorb(t: Vector2i) -> String:
	## Absorb the top object (tree, synthoid, Sentinel or boulder) of the visible tile t.
	var why := _blocked(t)
	if why != "":
		return why
	if t == player_tile:
		return MSG_OWN_TILE
	var what := object_at(t)
	if what == "":
		return MSG_NOTHING
	if not can_see(t):
		return MSG_HIDDEN
	match what:
		"tree":
			trees.erase(t)
			_set_energy(energy + TREE_ENERGY)
		"synthoid":
			synthoids.erase(t)
			_set_energy(energy + SYNTHOID_ENERGY)
		"boulder":
			if boulders[t] <= 1:
				boulders.erase(t)
			else:
				boulders[t] -= 1
			_set_energy(energy + BOULDER_ENERGY)
		"sentinel":
			sentinels.remove_at(sentinel_at(t))
			_set_energy(energy + SENTINEL_ENERGY)
	_wake()
	return ""


func advance(seconds: float) -> void:
	## Step the Sentinels, watching and draining by `seconds` of game time.
	if state != "playing" or not awake:
		return
	_pending += seconds
	var n := int(floor(_pending / _TICK + 0.000001))
	_pending -= n * _TICK
	for i in n:
		_tick()
		if state != "playing":
			return


func _tick() -> void:
	for s in sentinels:
		if s.sees:
			continue
		s.clock += 1
		if s.clock >= _TURN_TICKS:
			s.clock = 0
			s.turned += s.dir * SENTINEL_TURN_STEP
			s.facing = fposmod(s.facing + s.dir * SENTINEL_TURN_STEP, 360.0)
	update_watch()
	if watched:
		watch_ticks += 1
		var since := watch_ticks - _DELAY_TICKS
		if since >= 0 and since % _INTERVAL_TICKS == 0:
			if energy <= 0:
				state = "lost"
			else:
				_set_energy(energy - DRAIN_AMOUNT)
	else:
		watch_ticks = 0


func update_watch() -> void:
	var eye := eye_position()
	watched = false
	for s in sentinels:
		s.sees = awake and sentinel_sees(s, eye)
		watched = watched or s.sees


func _wake() -> void:
	## After a successful action: wake the Sentinels, then recompute watching
	## and the win state.
	awake = true
	update_watch()
	if not watched:
		watch_ticks = 0
	_check_state()


func _set_energy(e: int) -> void:
	energy = clampi(e, 0, MAX_ENERGY)
	_check_state()


func _check_state() -> void:
	if state != "playing":
		return
	if sentinels.is_empty():
		state = "won"


func _blocked(t: Vector2i) -> String:
	if state != "playing":
		return MSG_OVER
	if not in_bounds(t):
		return MSG_OFF_GRID
	if not is_flat(t):
		return MSG_NOT_FLAT
	return ""
