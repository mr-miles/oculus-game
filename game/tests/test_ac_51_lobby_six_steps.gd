extends ViewTest
## AC-51: How to play has 6 numbered steps; step 4 names the grip and boulders.

func _init() -> void:
	var l := await new_lobby()
	l.next()
	l.next()
	var steps := []
	for line in (l.find_child("LobbyPage", true, false) as Label3D).text.split("\n", false):
		if line.length() > 2 and line[0] in "0123456789" and line[1] == ".":
			steps.append(line.to_lower())
	check("ac_51 six numbered steps", steps.size() == 6)
	check("ac_51 step 4 contains grip and boulder", steps.size() > 3 and steps[3].contains("grip") and steps[3].contains("boulder"))
	finish()
