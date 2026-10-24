extends ViewTest
## AC-22: the app starts in the lobby and no level is loaded.

func _init() -> void:
	check("ac_22 main scene is the lobby", ProjectSettings.get_setting("application/run/main_scene") == "res://lobby.tscn")
	var l := await new_lobby()
	await settle()
	check("ac_22 lobby is running", l.name == "Lobby" and l.find_child("LobbyPanel", true, false) != null)
	check("ac_22 no level node exists", root.get_node_or_null("Main") == null)
	finish()
