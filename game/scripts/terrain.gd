class_name Terrain
extends Node3D
## The landscape as a few merged meshes (one per block of tiles), not one node
## per tile: a 31x31 level would otherwise cost 961 draw calls on the Quest.

const BLOCKS := 4  # blocks per side, so at most 16 mesh instances
const LIGHT := Color(0.25, 0.55, 0.3)
const DARK := Color(0.2, 0.45, 0.25)
const WALL := Color(0.16, 0.34, 0.2)

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
			var any := false
			for z in range(bz * per_block, mini((bz + 1) * per_block, logic.size)):
				for x in range(bx * per_block, mini((bx + 1) * per_block, logic.size)):
					_add_tile(st, logic, Vector2i(x, z))
					any = true
			if not any:
				continue
			var m := MeshInstance3D.new()
			m.name = "Block_%d_%d" % [bx, bz]
			m.mesh = st.commit()
			m.material_override = _material
			add_child(m)


func _add_tile(st: SurfaceTool, logic: GameLogic, t: Vector2i) -> void:
	var s := GameLogic.TILE
	var h := float(logic.height(t))
	var x0 := t.x * s
	var z0 := t.y * s
	var top := LIGHT if (t.x + t.y) % 2 == 0 else DARK
	_quad(st, Vector3(x0, h, z0), Vector3(x0 + s, h, z0), Vector3(x0 + s, h, z0 + s), Vector3(x0, h, z0 + s), Vector3.UP, top)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = t + d
		var low := float(logic.height(n)) if logic.in_bounds(n) else 0.0
		if low >= h:
			continue
		var n3 := Vector3(d.x, 0, d.y)
		var along := Vector3(d.y, 0, d.x).abs() * s  # edge direction
		var edge := Vector3(x0, 0, z0) + Vector3(s if d.x > 0 else 0, 0, s if d.y > 0 else 0)
		_quad(st, edge + Vector3(0, low, 0), edge + along + Vector3(0, low, 0),
				edge + along + Vector3(0, h, 0), edge + Vector3(0, h, 0), n3, WALL)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	st.set_color(color)
	st.set_normal(normal)
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)
