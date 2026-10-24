extends Node3D
## The start scene: story, rules and a walkthrough on a panel in front of the
## player, operated with the right-hand ray and trigger. Start loads level 1.

const PAGES := [
	{"title": "The Story", "body": "The Quiet Valley once hummed with light. The Sentinels grew fearful and hoarded it, and the valley dimmed.\n\nYou are a Spark, the last small light that slipped past them. Grow bodies, slip from one into another, climb above each Sentinel and gather its light gently.\n\nThe hill glows again."},
	{"title": "The Rules", "body": "You are a Spark with energy.\n\n- A body (synthoid) costs 3 energy.\n- Absorb a tree: +1. A body: +3. A Sentinel: +4.\n- You can only act on tiles you can see.\n- A Sentinel that sees you slowly drains your energy. Hide behind hills!\n- Absorb every Sentinel to clear a hill. If your energy hits 0, try again."},
	{"title": "How to Play", "body": "1. Point your right controller. Yellow means you can see the tile.\n2. Pull the TRIGGER to make a blue body (costs 3).\n3. Press A to move into that body.\n4. Press B to absorb trees for energy.\n5. Climb higher, then press B on each Sentinel to absorb it."},
	{"title": "Ready?", "body": "Point at Start and pull the trigger.\n\nLeft stick turns you. Left Y pauses. Left X gives a hint."},
]
const HOW_TO_PAGE := 2
const PANEL_SIZE := Vector2(2.0, 1.3)

var rig: Rig
var panel: Menu3D
var page := 0

var _title: Label3D
var _body: Label3D
var _counter: Label3D
var _diagram: Node3D


func _ready() -> void:
	Scenery.add_sky(self)
	add_child(Scenery.mesh_node("Hill", _hill_mesh(), Color(0.25, 0.55, 0.3), Vector3(0, -5.0, 0)))
	rig = Rig.new()
	add_child(rig)
	rig.button.connect(_on_button)
	_build_panel()
	_show_page()


func _hill_mesh() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 12.0
	s.height = 10.0  # a low dome: only its top 0.0..5.0 m shows above the floor line
	return s


func _build_panel() -> void:
	panel = Menu3D.new(PANEL_SIZE)
	panel.name = "LobbyPanel"
	panel.position = Vector3(0, GameLogic.EYE, -2.0)
	add_child(panel)
	_title = panel.add_label("LobbyTitle", Vector2(0, 0.52), 80)
	_body = panel.add_label("LobbyPage", Vector2(-0.95, 0.42), 40, 780)  # left edge, top
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_counter = panel.add_label("LobbyCounter", Vector2(0, -0.37), 36)
	panel.add_button("BackButton", "back", "Back", Vector2(-0.7, -0.52), Vector2(0.4, 0.16))
	panel.add_button("NextButton", "next", "Next", Vector2(-0.2, -0.52), Vector2(0.4, 0.16))
	panel.add_button("StartButton", "start", "Start", Vector2(0.6, -0.52), Vector2(0.6, 0.2))
	panel.chosen.connect(_on_chosen)
	_diagram = _build_diagram()
	panel.add_child(_diagram)


func _build_diagram() -> Node3D:
	## A small right-controller sketch with the three buttons the game uses.
	var d := Node3D.new()
	d.name = "ControllerDiagram"
	d.position = Vector3(0.72, 0.05, 0.02)
	var body := BoxMesh.new()
	body.size = Vector3(0.22, 0.5, 0.04)
	d.add_child(Scenery.mesh_node("Body", body, Color(0.25, 0.25, 0.3), Vector3.ZERO))
	var spots := {"Trigger": [Vector3(-0.15, -0.12, 0.0), Color(0.9, 0.9, 0.3)],
			"A": [Vector3(0.0, 0.14, 0.04), Color(0.3, 0.8, 0.4)],
			"B": [Vector3(0.0, 0.04, 0.04), Color(0.9, 0.5, 0.3)]}
	for k in spots:
		var s := SphereMesh.new()
		s.radius = 0.035
		s.height = 0.07
		d.add_child(Scenery.mesh_node("Button" + k, s, spots[k][1], spots[k][0]))
		var l := Label3D.new()
		l.text = k
		l.font_size = 40
		l.pixel_size = Menu3D.PIXEL
		l.no_depth_test = true
		l.render_priority = 2
		l.position = spots[k][0] + Vector3(0.14 if k != "Trigger" else -0.14, 0, 0.03)
		d.add_child(l)
	return d


func next() -> void:
	page = mini(page + 1, PAGES.size() - 1)
	_show_page()


func back() -> void:
	page = maxi(page - 1, 0)
	_show_page()


func press_start() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.start_level = 1
	get_parent().add_child(game)
	queue_free()


func _show_page() -> void:
	_title.text = PAGES[page].title
	_body.text = PAGES[page].body
	_counter.text = "Page %d of %d" % [page + 1, PAGES.size()]
	panel.button_node("back").visible = page > 0
	panel.button_node("next").visible = page < PAGES.size() - 1
	panel.button_node("start").visible = true
	_diagram.visible = page == HOW_TO_PAGE


func _on_chosen(id: String) -> void:
	match id:
		"back":
			back()
		"next":
			next()
		"start":
			press_start()


func _on_button(button: String) -> void:
	if button == "trigger_click":
		panel.activate(panel.pick(rig.ray_origin(), rig.ray_direction()))


func _process(_delta: float) -> void:
	var id := panel.pick(rig.ray_origin(), rig.ray_direction())
	panel.highlight(id)
	rig.set_ray_length(2.0 if id != "" else 3.0)
