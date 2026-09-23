class_name MyMath
extends Node

static func n_points_between(low: float, high: float, n: int) -> Array[float]:
	var points := []
	for i in range(n):
		var t := float(i) / float(n - 1)
		var point := lerpf(low, high, t)
		points.append(point)
	return points
