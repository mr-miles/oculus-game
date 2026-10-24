class_name Hud
extends Node3D
## Head-locked heads-up display. Add as a child of the XR camera. Shows energy
## (number and bar), level, sentinels left, a watched warning and one message.
## Label3D anchors left-aligned text at its left edge and right-aligned at its right edge.

const PIXEL := 0.0012
const BAR_WIDTH := 0.5
const WATCH_RED := Color(1, 0.2, 0.2)

var energy_label: Label3D
var level_label: Label3D
var sentinels_label: Label3D
var message_label: Label3D
var watched_label: Label3D
var _bar_fill: MeshInstance3D
var _border: Node3D


func _init() -> void:
	name = "Hud"
	position = Vector3(0, -0.3, -1.2)
	level_label = _label("HudLevel", Vector2(-0.55, 0.12), HORIZONTAL_ALIGNMENT_LEFT)
	sentinels_label = _label("HudSentinels", Vector2(0.55, 0.12), HORIZONTAL_ALIGNMENT_RIGHT)
	energy_label = _label("HudEnergy", Vector2(-0.55, 0.02), HORIZONTAL_ALIGNMENT_LEFT)
	message_label = _label("HudMessage", Vector2(0, -0.1), HORIZONTAL_ALIGNMENT_CENTER)
	watched_label = _label("HudWatched", Vector2(0, -0.2), HORIZONTAL_ALIGNMENT_CENTER)
	watched_label.modulate = WATCH_RED
	watched_label.visible = false
	_build_bar(Vector2(0.12, 0.02))
	_build_border(Vector2(1.2, 0.6))


func _label(node_name: String, at: Vector2, align: HorizontalAlignment) -> Label3D:
	var l := Label3D.new()
	l.name = node_name
	l.pixel_size = PIXEL
	l.font_size = 44
	l.outline_size = 12
	l.horizontal_alignment = align
	l.no_depth_test = true
	l.render_priority = 10
	l.position = Vector3(at.x, at.y, 0)
	add_child(l)
	return l


func _quad(node_name: String, size: Vector2, at: Vector2, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	var q := QuadMesh.new()
	q.size = size
	m.mesh = q
	var mat := Rig.unshaded(color)
	mat.no_depth_test = true
	mat.render_priority = 9
	m.material_override = mat
	m.position = Vector3(at.x, at.y, 0)
	add_child(m)
	return m


func _build_bar(at: Vector2) -> void:
	_quad("HudBarBack", Vector2(BAR_WIDTH, 0.035), at, Color(0.15, 0.15, 0.2, 0.9))
	_bar_fill = _quad("HudBarFill", Vector2(BAR_WIDTH, 0.03), at, Color(0.3, 0.9, 0.4))


func _build_border(size: Vector2) -> void:
	_border = Node3D.new()
	_border.name = "HudBorder"
	var t := 0.015
	for e in [[Vector2(size.x, t), Vector2(0, size.y / 2)], [Vector2(size.x, t), Vector2(0, -size.y / 2)],
			[Vector2(t, size.y), Vector2(size.x / 2, 0)], [Vector2(t, size.y), Vector2(-size.x / 2, 0)]]:
		var q := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = e[0]
		q.mesh = mesh
		var mat := Rig.unshaded(WATCH_RED)
		mat.no_depth_test = true
		mat.render_priority = 9
		q.material_override = mat
		q.position = Vector3(e[1].x, e[1].y, 0)
		_border.add_child(q)
	_border.position = Vector3(0, 0.05, 0)
	_border.visible = false
	add_child(_border)


func show_state(logic: GameLogic, sentinels_total: int, message: String) -> void:
	energy_label.text = "Energy %d" % logic.energy
	level_label.text = "Level %d of %d" % [logic.level, Levels.COUNT]
	sentinels_label.text = "Sentinels: %d of %d left" % [logic.sentinels_left(), sentinels_total]
	message_label.text = message
	var frac := clampf(float(logic.energy) / GameLogic.MAX_ENERGY, 0.0, 1.0)
	_bar_fill.scale.x = maxf(frac, 0.001)
	_bar_fill.position.x = 0.12 - BAR_WIDTH * (1.0 - frac) / 2.0
	var watched := logic.watched and logic.state == "playing"
	watched_label.visible = watched
	_border.visible = watched
	if watched:
		watched_label.text = "A Sentinel sees you! Energy drops in %.1f s" % maxf(logic.drain_countdown(), 0.0)
