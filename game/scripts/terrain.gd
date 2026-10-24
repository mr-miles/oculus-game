class_name Terrain
extends Node3D
## The landscape as one merged heightfield, cut into at most BLOCKS x BLOCKS
## mesh instances (a 31x31 level as separate nodes would cost 961 draw calls on
## the Quest). Built from the corner grid: each tile is two triangles split
## along the a-d diagonal (a = front-left corner, d = back-right), so a ridge or
## valley folds exactly where GameLogic.surface_height() says it does. A
## vertical skirt down to y = 0 closes the border.

const BLOCKS := 4
const LIGHT := Color(0.25, 0.55, 0.3)
const DARK := Color(0.2, 0.45, 0.25)
const SLOPED := Color(0.36, 0.34, 0.17)  # darker brown-green: no objects can stand here

var _material := StandardMaterial3D.new()


func _init() -> void:
	name = "Terrain"
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func build(logic: GameLogic) -> void:
	var per_block := ceili(float(logic.size) / BLOCKS)
	for bz in BLOCKS:
		for bx in BLOCKS:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var tiles := 0
			for z in range(bz * per_block, mini((bz + 1) * per_block, logic.size)):
				for x in range(bx * per_block, mini((bx + 1) * per_block, logic.size)):
					_add_tile(st, logic, Vector2i(x, z))
					tiles += 1
			if tiles == 0:
				continue
			st.generate_normals()
			var m := MeshInstance3D.new()
			m.name = "Block_%d_%d" % [bx, bz]
			m.mesh = st.commit()
			m.material_override = _material
			add_child(m)


func _corner(logic: GameLogic, cx: int, cz: int) -> Vector3:
	return Vector3(cx * GameLogic.TILE, logic.corner(cx, cz), cz * GameLogic.TILE)


func _add_tile(st: SurfaceTool, logic: GameLogic, t: Vector2i) -> void:
	var a := _corner(logic, t.x, t.y)
	var b := _corner(logic, t.x + 1, t.y)
	var c := _corner(logic, t.x, t.y + 1)
	var d := _corner(logic, t.x + 1, t.y + 1)
	var color := SLOPED
	if logic.is_flat(t):
		color = LIGHT if (t.x + t.y) % 2 == 0 else DARK
	_triangle(st, a, b, d, color)
	_triangle(st, a, d, c, color)
	# Skirt on the grid border.
	if t.y == 0:
		_wall(st, a, b, color)
	if t.y == logic.size - 1:
		_wall(st, c, d, color)
	if t.x == 0:
		_wall(st, a, c, color)
	if t.x == logic.size - 1:
		_wall(st, b, d, color)


func _wall(st: SurfaceTool, top_1: Vector3, top_2: Vector3, color: Color) -> void:
	var low_1 := Vector3(top_1.x, 0.0, top_1.z)
	var low_2 := Vector3(top_2.x, 0.0, top_2.z)
	_triangle(st, top_1, top_2, low_2, color)
	_triangle(st, top_1, low_2, low_1, color)


func _triangle(st: SurfaceTool, p: Vector3, q: Vector3, r: Vector3, color: Color) -> void:
	st.set_color(color)
	for v in [p, q, r]:
		st.add_vertex(v)
