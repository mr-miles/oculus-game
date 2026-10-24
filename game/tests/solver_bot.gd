class_name SolverBot
extends RefCounted
## Greedy logic-only player used by the AC-19 test: absorb what it can see
## (Sentinels first), otherwise hop to the best visible tile.

const SECONDS_PER_ACTION := 1.0


static func solve(g: GameLogic, max_steps := 200) -> bool:
	for _i in max_steps:
		if g.state != "playing":
			break
		if not _step(g):
			break
		g.advance(SECONDS_PER_ACTION)
	return g.state == "won"


static func _step(g: GameLogic) -> bool:
	for kind in ["sentinel", "tree"]:
		for z in g.size:
			for x in g.size:
				var t := Vector2i(x, z)
				if g.object_at(t) == kind and g.can_see(t):
					return g.absorb(t) == ""
	if g.energy < GameLogic.SYNTHOID_COST:
		return false
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for z in g.size:
		for x in g.size:
			var t := Vector2i(x, z)
			if g.occupied(t) or not g.can_see(t):
				continue
			var score := 2.0 * g.height(t) - 0.3 * _nearest(g, t)
			if g.watched_from(t):
				score -= 5.0
			if score > best_score:
				best_score = score
				best = t
	if best.x < 0:
		return false
	return g.create(best) == "" and g.move(best) == ""


static func _nearest(g: GameLogic, t: Vector2i) -> float:
	var d := INF
	for s in g.sentinels:
		d = minf(d, Vector2(t - s.tile).length())
	return d
