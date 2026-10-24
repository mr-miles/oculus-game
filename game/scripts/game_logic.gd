class_name GameLogic
extends RefCounted
## Pure game rules for one level of the Sentinel-style game. No nodes, so it
## runs headless. Tiles are Vector2i(x, z); heights are whole metres.
## Levels.build(n) fills in a playable level; GameLogic.new(size) is an empty
## flat grid (used by tests and by Levels).

const SYNTHOID_COST := 3
const TREE_ENERGY := 1
const SYNTHOID_ENERGY := 3
const SENTINEL_ENERGY := 4
const START_ENERGY := 10
const MAX_ENERGY := 63
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
const MSG_NOTHING := "Nothing to absorb there"
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
var heights: Array = []  # heights[z][x]
var synthoids := {}      # Vector2i -> true
var trees := {}          # Vector2i -> true
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
var watch_ticks := 0              # consecutive ticks watched

var _pending := 0.0


func _init(grid_size := 12) -> void:
	size = grid_size
	for z in size:
		var row := []
		row.resize(size)
		row.fill(0)
		heights.append(row)


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size and t.y < size


func height(t: Vector2i) -> int:
	return heights[t.y][t.x]


func top_position(t: Vector2i) -> Vector3:
	## World position of the centre of a tile's top face.
	return Vector3((t.x + 0.5) * TILE, float(height(t)), (t.y + 0.5) * TILE)


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
	## What stands on tile t: "sentinel", "tree", "synthoid" or "".
	if sentinel_at(t) >= 0:
		return "sentinel"
	if trees.has(t):
		return "tree"
	if synthoids.has(t):
		return "synthoid"
	return ""


func occupied(t: Vector2i) -> bool:
	return object_at(t) != "" or t == player_tile


func can_see(t: Vector2i) -> bool:
	## A tile is visible if nothing blocks the line from the player's eye to its
	## top centre. Terrain columns and trees block; synthoids do not.
	if not in_bounds(t) or t == player_tile:
		return false
	return _clear(eye_position(), top_position(t), player_tile, t)


func _clear(from: Vector3, to: Vector3, skip_a: Vector2i, skip_b: Vector2i) -> bool:
	## True if the segment from->to passes above every column and tree except
	## those on the two skipped end tiles.
	var steps := maxi(48, int(ceil(from.distance_to(to) / 0.5)))
	var last := Vector2i(-1, -1)
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / steps)
		var c := Vector2i(int(floor(p.x / TILE)), int(floor(p.z / TILE)))
		if c == last or c == skip_a or c == skip_b or not in_bounds(c):
			continue
		last = c
		var top := float(height(c))
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


func create(t: Vector2i) -> String:
	## Make a synthoid on t. Returns "" or the reason it failed.
	var why := _blocked(t)
	if why != "":
		return why
	if t == player_tile:
		return MSG_OWN_TILE
	if occupied(t):
		return MSG_OCCUPIED
	if not can_see(t):
		return MSG_HIDDEN
	if energy < SYNTHOID_COST:
		return MSG_NO_ENERGY
	synthoids[t] = true
	_set_energy(energy - SYNTHOID_COST)
	_refresh()
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
	_refresh()
	return ""


func absorb(t: Vector2i) -> String:
	## Absorb the visible tree, synthoid or Sentinel on t.
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
		"sentinel":
			sentinels.remove_at(sentinel_at(t))
			_set_energy(energy + SENTINEL_ENERGY)
	_refresh()
	return ""


func advance(seconds: float) -> void:
	## Step the Sentinels, watching and draining by `seconds` of game time.
	if state != "playing":
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
			_set_energy(energy - DRAIN_AMOUNT)
	else:
		watch_ticks = 0


func update_watch() -> void:
	var eye := eye_position()
	watched = false
	for s in sentinels:
		s.sees = sentinel_sees(s, eye)
		watched = watched or s.sees


func _refresh() -> void:
	## After the world changed: recompute watching and the win/lose state.
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
	elif energy <= 0:
		state = "lost"


func _blocked(t: Vector2i) -> String:
	if state != "playing":
		return MSG_OVER
	if not in_bounds(t):
		return MSG_OFF_GRID
	return ""
