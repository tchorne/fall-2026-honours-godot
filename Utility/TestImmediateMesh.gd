extends MeshInstance3D


func _ready():
	var m := mesh as ImmediateMesh
	
	m.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	m.surface_add_vertex(Vector3(0,0,0))
	m.surface_add_vertex(Vector3(0,1,0))
	m.surface_add_vertex(Vector3(1,0,0))
	m.surface_add_vertex(Vector3(1,1,0))
	m.surface_end()
	
