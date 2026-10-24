extends ViewTest
## AC-23: four pages (Story, Rules, How to play, Ready); next/back move; text non-empty.

func _init() -> void:
	var l := await new_lobby()
	var page: Label3D = l.find_child("LobbyPage", true, false)
	var title: Label3D = l.find_child("LobbyTitle", true, false)
	var want := ["story", "rules", "how to play", "ready"]
	for i in 4:
		check("ac_23 page %d title and text" % (i + 1), title.text.to_lower().contains(want[i]) and page.text != "")
		l.next()
	check("ac_23 next stops on the last page", title.text.to_lower().contains("ready"))
	for i in 3:
		l.back()
	check("ac_23 back returns to the Story", title.text.to_lower().contains("story"))
	l.back()
	check("ac_23 back stops on the first page", title.text.to_lower().contains("story"))
	finish()
