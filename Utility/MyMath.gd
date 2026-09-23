class_name MyMath
extends Node

static func n_points_between(low: float, high: float, n: int) -> Array[float]:
	var points := []
	for i in range(n):
		var t := float(i) / float(n - 1)
		var point := lerpf(low, high, t)
		points.append(point)
	return points

static func mat_transpose(mat: Projection) -> Projection:
	var new_mat := Projection()
	for i in range(4):
		for j in range(4):
			new_mat[i][j] = mat[j][i]
	return new_mat
