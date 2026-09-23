extends Node

@export var resolution := 100


func generate_triangle_strip(mesh: ImmediateMesh, curve: SlashCurve) -> void:
	mesh.clear_surfaces()
	var last_sample := curve.sample_point(0)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	mesh.surface_set_uv(Vector2(0,0))
	mesh.surface_add_vertex(last_sample.hilt_position)
	mesh.surface_set_uv(Vector2(0,1))
	mesh.surface_add_vertex(last_sample.tip_position)
	for i in range(1, resolution):
		var t := float(i) / resolution
		var sample := curve.sample_point(t)
		mesh.surface_set_uv(Vector2(t,0))
		mesh.surface_add_vertex(sample.hilt_position)
		mesh.surface_set_uv(Vector2(t,1))
		mesh.surface_add_vertex(sample.tip_position)
	
	mesh.surface_end()
	
	
## Adds triangles (a.a, a.b, b.a) and (a.b, b.b, b.a)
func add_quad(mesh: SurfaceTool, a: Edge, b: Edge, x0: float, x1: float) -> void:
	
	#mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.set_uv(Vector2(x0, a.ta))
	mesh.add_vertex(a.a)
	mesh.set_uv(Vector2(x0, a.tb))
	mesh.add_vertex(a.b)
	mesh.set_uv(Vector2(x1, b.ta))
	mesh.add_vertex(b.a)
	#mesh.surface_end()
	
	#mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.set_uv(Vector2(x0, a.tb))
	mesh.add_vertex(a.b)
	mesh.set_uv(Vector2(x1, b.tb))
	mesh.add_vertex(b.b)
	mesh.set_uv(Vector2(x1, b.ta))
	mesh.add_vertex(b.a)
	#mesh.surface_end()

## 
func generate_extruded_eye(curve: SlashCurve) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous_eye: Array[Edge] = []
	
	
	SurfaceTool.new()
	
	for i in range(1, resolution-1):
		var t := float(i) / resolution
		var next_t := float(i+1) / resolution
		
		var sample := curve.sample_point(t)
		var forward := curve.sample_point(next_t).midpoint() - sample.midpoint()
		if (forward.length_squared() == 0): continue
		forward = forward.normalized()
		var up := forward.cross(sample.hilt_to_tip())
		
		var first_vertex := sample.hilt_position
		var last_vertex := sample.tip_position
		var edges : Array[Edge] = []
		
		
		var first_j := true
		var prev_j := 0.0
		var upper_edge : Edge
		var lower_edge : Edge
		
		for j in MyMath.n_points_between(0, 1, 5).slice(1, 5-1):
			# Used some desmos to get this eye-shaped curve from 0-1
			var height_off_curve : float = (1 - (2*j-1) ** 2) / 13.0
			
			var upper_point = lerp(first_vertex, last_vertex, j) + up * height_off_curve
			var lower_point = lerp(first_vertex, last_vertex, j) - up * height_off_curve
			
			if first_j:
				upper_edge = Edge.new(first_vertex, upper_point, 0, j)
				lower_edge = Edge.new(first_vertex, lower_point, 0, j)
				edges.append(upper_edge)
				edges.append(lower_edge)
				first_j = false
			else:
				upper_edge = Edge.new(upper_edge.b, upper_point, prev_j, j)
				lower_edge = Edge.new(lower_edge.b, lower_point, prev_j, j)
				edges.append(upper_edge)
				edges.append(lower_edge)
			prev_j = j
		
		# connect last 2 to last vertex
		edges.append(Edge.new(upper_edge.b, last_vertex, prev_j, 1))
		edges.append(Edge.new(lower_edge.b, last_vertex, prev_j, 1))
		
		# Connect this eye to the previous, if it exists
		if previous_eye:
			for j in previous_eye.size():
				var edge_a := previous_eye[j]
				var edge_b := edges[j]
				add_quad(st, edge_a, edge_b, t, next_t)
		
		previous_eye = edges
	
	st.index()
	return st.commit()


			
class Edge:
	var a: Vector3
	var b: Vector3
	var ta: float
	var tb: float
	
	func _init(a, b, ta, tb) -> void:
		self.a = a
		self.b = b
		self.ta = ta
		self.tb = tb
