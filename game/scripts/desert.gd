class_name Desert
extends MeshInstance3D
## The sand that surrounds the level: gentle dunes from the foot of the hill out to the
## horizon haze. One mesh (about 20k triangles at 8 m cells) with a hole where the hill stands, flat at
## the hill's edge (y = 0, where the terrain skirt ends) and rising into dunes further out.

const CELL := 8.0        # metres per grid cell
const HALF := 400.0      # the desert reaches this far from the hill's centre
const DUNE_AFTER := 4.0  # dunes start rising this far from the hill's edge, full height at +24 m
const SAND_LIGHT := Color(0.64, 0.50, 0.28)
const SAND_DARK := Color(0.52, 0.40, 0.22)


func _init() -> void:
	name = "Desert"


static func height_at(x: float, z: float, edge_distance: float) -> float:
	## Dune height (metres, >= 0) at a point `edge_distance` metres outside the hill's edge.
	var ramp := smoothstep(DUNE_AFTER, DUNE_AFTER + 20.0, edge_distance)
	var ridge := 0.5 + 0.5 * sin(x * 0.045 + 2.0 * sin(z * 0.021)) * cos(z * 0.038 + 1.5 * sin(x * 0.017))
	var far := 1.0 + 1.5 * smoothstep(60.0, 200.0, edge_distance)  # dunes grow towards the horizon
	return ramp * ridge * 2.2 * far


func build(extent: float) -> void:
	## `extent`: the hill's side length in metres (it spans 0..extent in x and z).
	var centre := extent / 2.0
	var n := int(HALF * 2.0 / CELL)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in n:
		for ix in n:
			var x0 := centre - HALF + ix * CELL
			var z0 := centre - HALF + iz * CELL
			if x0 >= -0.01 and z0 >= -0.01 and x0 + CELL <= extent + 0.01 and z0 + CELL <= extent + 0.01:
				continue  # under the hill
			var p := [Vector2(x0, z0), Vector2(x0 + CELL, z0), Vector2(x0, z0 + CELL), Vector2(x0 + CELL, z0 + CELL)]
			var v: Array[Vector3] = []
			for q in p:
				var dx := maxf(maxf(-q.x, q.x - extent), 0.0)
				var dz := maxf(maxf(-q.y, q.y - extent), 0.0)
				var d := sqrt(dx * dx + dz * dz)
				v.append(Vector3(q.x, height_at(q.x, q.y, d) - 0.05, q.y))
			var shade := hash(Vector2i(ix / 3, iz / 3)) % 100 / 100.0
			st.set_color(SAND_LIGHT.lerp(SAND_DARK, shade * 0.6))
			for i in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(v[i])
	st.generate_normals()
	mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = m
