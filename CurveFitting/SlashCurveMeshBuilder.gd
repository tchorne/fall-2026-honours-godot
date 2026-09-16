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
