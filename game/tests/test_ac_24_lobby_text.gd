extends ViewTest
## AC-24: page contents: Spark/Sentinel, energy numbers, five numbered steps.

func _init() -> void:
	var l := await new_lobby()
	var page: Label3D = l.find_child("LobbyPage", true, false)
	check("ac_24 story names Spark and Sentinel", page.text.contains("Spark") and page.text.contains("Sentinel"))
	check("ac_24 story is 60 words or fewer", page.text.split(" ", false).size() <= 60)
	l.next()
	check("ac_24 rules mention energy, 3 and 4", page.text.contains("energy") and page.text.contains("3") and page.text.contains("4"))
	l.next()
	var steps := 0
	for line in page.text.split("\n", false):
		if line.length() > 2 and line[0] in "12345" and line[1] == ".":
			steps += 1
	check("ac_24 five numbered steps", steps == 5)
	var low := page.text.to_lower()
	check("ac_24 steps name trigger, A and B", low.contains("trigger") and low.contains("press a") and low.contains("press b"))
	check("ac_24 controller diagram on this page", (l.find_child("ControllerDiagram", true, false) as Node3D).visible)
	l.back()
	check("ac_24 diagram hidden on other pages", not (l.find_child("ControllerDiagram", true, false) as Node3D).visible)
	finish()
