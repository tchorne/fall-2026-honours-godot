extends MultiMeshInstance3D

func redraw(points: PackedVector3Array):
	multimesh = MultiMesh.new()
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.05
	multimesh.mesh = cube_mesh
	
	multimesh.instance_count = points.size()
	
	for i in range(points.size()):
		var p = points[i]
		var basis_transform = Transform3D(Basis(), p)
		multimesh.set_instance_transform(i, basis_transform)
