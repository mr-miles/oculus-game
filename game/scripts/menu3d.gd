class_name Menu3D
extends Node3D
## A flat world-space panel of text and buttons, operated by the pointer ray.
## Used for the lobby and the pause menu. The panel faces +z in local space.

signal chosen(id: String)

const BG := Color(0.08, 0.1, 0.2, 0.85)
const BUTTON := Color(0.2, 0.45, 0.8)
const BUTTON_HOT := Color(0.95, 0.8, 0.2)
const PIXEL := 0.0016

var size := Vector2(1.6, 1.0)
var _buttons := {}  # id -> {node, rect, face}


func _init(panel_size := Vector2(1.6, 1.0)) -> void:
	size = panel_size
	var bg := MeshInstance3D.new()
	bg.name = "Background"
	var quad := QuadMesh.new()
	quad.size = size
	bg.mesh = quad
	bg.material_override = Rig.unshaded(BG)
	add_child(bg)


func add_label(node_name: String, centre: Vector2, font_size: int, width_px := 0) -> Label3D:
	var l := Label3D.new()
	l.name = node_name
	l.font_size = font_size
	l.pixel_size = PIXEL
	l.no_depth_test = true
	l.render_priority = 2
	l.outline_size = 0
	l.modulate = Color.WHITE
	if width_px > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = width_px
	l.position = Vector3(centre.x, centre.y, 0.01)
	add_child(l)
	return l


func add_button(node_name: String, id: String, text: String, centre: Vector2, button_size: Vector2) -> Node3D:
	var b := Node3D.new()
	b.name = node_name
	b.position = Vector3(centre.x, centre.y, 0.005)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = button_size
	face.mesh = quad
	face.material_override = Rig.unshaded(BUTTON)
	b.add_child(face)
	var l := Label3D.new()
	l.name = "Text"
	l.text = text
	l.font_size = 40
	l.pixel_size = PIXEL
	l.no_depth_test = true
	l.render_priority = 2
	l.position = Vector3(0, 0, 0.005)
	b.add_child(l)
	add_child(b)
	_buttons[id] = {"node": b, "rect": Rect2(centre - button_size / 2.0, button_size), "face": face}
	return b


func button_node(id: String) -> Node3D:
	return _buttons[id].node


func pick(ray_origin: Vector3, ray_direction: Vector3) -> String:
	## The id of the visible button the ray points at, or "".
	var inv := global_transform.affine_inverse()
	var o := inv * ray_origin
	var d := inv.basis * ray_direction
	if absf(d.z) < 0.0001:
		return ""
	var s := -o.z / d.z
	if s <= 0.0:
		return ""
	var p := o + d * s
	for id in _buttons:
		var entry: Dictionary = _buttons[id]
		if entry.node.is_visible_in_tree() and entry.rect.has_point(Vector2(p.x, p.y)):
			return id
	return ""


func highlight(id: String) -> void:
	for k in _buttons:
		var mat := (_buttons[k].face as MeshInstance3D).material_override as StandardMaterial3D
		mat.albedo_color = BUTTON_HOT if k == id else BUTTON


func activate(id: String) -> void:
	if _buttons.has(id) and _buttons[id].node.is_visible_in_tree():
		chosen.emit(id)
