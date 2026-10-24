extends ViewTest
## AC-30: "Sentinels: k of N left" decrements per absorb and reads 0 when won.

func _text(g: Node) -> String:
	return (g.find_child("HudSentinels", true, false) as Label3D).text


func _init() -> void:
	var g := await new_game(3)
	var n: int = g.logic.sentinels_left()
	check("ac_30 initial text", _text(g) == "Sentinels: %d of %d left" % [n, n])
	for k in range(n - 1, -1, -1):
		absorb_one_sentinel(g)
		check("ac_30 after absorb, %d left" % k, _text(g) == "Sentinels: %d of %d left" % [k, n])
	check("ac_30 level won", g.logic.state == "won")
	check("ac_30 reads 0 left when won", _text(g).begins_with("Sentinels: 0 of"))
	finish()
