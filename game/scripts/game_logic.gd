class_name GameLogic
extends RefCounted
## Pure game rules for the Sentinel-style prototype. No nodes, so it can be
## tested headless. Tiles are Vector2i(x, z); heights are whole metres.

const SIZE := 12
const SYNTHOID_COST := 3
const START_ENERGY := 6
const TREE_ENERGY := 1
const EYE := 1.6  # eye height above a tile top, metres
const TILE := 2.0  # tile edge, metres

var heights: Array = []  # heights[z][x]
var synthoids := {}      # Vector2i -> true
var trees := {}          # Vector2i -> true
var player_tile := Vector2i.ZERO
var sentinel_tile := Vector2i.ZERO
var energy := START_ENERGY
var won := false


func _init() -> void:
	# Deterministic rolling terrain: a bowl-shaped ridge with the Sentinel on the peak.
	for z in SIZE:
		var row := []
		for x in SIZE:
			var h := int(round(2.0 * sin(x * 0.55) * cos(z * 0.45) + 2.0))
			row.append(max(h, 0))
		heights.append(row)
	sentinel_tile = Vector2i(SIZE - 3, SIZE - 3)
	heights[sentinel_tile.y][sentinel_tile.x] = 6
	player_tile = Vector2i(1, 1)
	heights[1][1] = 1
	for t in [Vector2i(4, 2), Vector2i(7, 5), Vector2i(3, 8)]:
		trees[t] = true


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < SIZE and t.y < SIZE


func height(t: Vector2i) -> int:
	return heights[t.y][t.x]


func top_position(t: Vector2i) -> Vector3:
	## World position of the centre of a tile's top face.
	return Vector3((t.x + 0.5) * TILE, float(height(t)), (t.y + 0.5) * TILE)


func eye_position() -> Vector3:
	return top_position(player_tile) + Vector3(0, EYE, 0)


func occupied(t: Vector2i) -> bool:
	return synthoids.has(t) or trees.has(t) or t == sentinel_tile or t == player_tile


func can_see(t: Vector2i) -> bool:
	## Sentinel rule: a tile is visible if the line from the eye to its top
	## centre is not blocked by any terrain column along the way.
	if not in_bounds(t):
		return false
	if t == player_tile:
		return false
	var from := eye_position()
	var to := top_position(t)
	var steps := 48
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / steps)
		var c := Vector2i(int(floor(p.x / TILE)), int(floor(p.z / TILE)))
		if c == t or c == player_tile or not in_bounds(c):
			continue
		if p.y < float(height(c)):
			return false
	return true


func place_synthoid(t: Vector2i) -> bool:
	if not can_see(t) or occupied(t) or energy < SYNTHOID_COST:
		return false
	synthoids[t] = true
	energy -= SYNTHOID_COST
	return true


func absorb(t: Vector2i) -> bool:
	if not can_see(t):
		return false
	if trees.has(t):
		trees.erase(t)
		energy += TREE_ENERGY
		return true
	if synthoids.has(t):
		synthoids.erase(t)
		energy += SYNTHOID_COST
		return true
	return false


func transfer(t: Vector2i) -> bool:
	## "Teleport": move into a synthoid you can see.
	if not synthoids.has(t) or not can_see(t):
		return false
	synthoids.erase(t)
	player_tile = t
	if height(player_tile) >= height(sentinel_tile):
		won = true
	return true
