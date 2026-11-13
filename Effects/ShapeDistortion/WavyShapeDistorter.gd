class_name WavyShapeDistorter
extends ShapeDistorter

func displace(uv: Vector2, time: float, normal: Vector3, tangent: Vector3) -> Vector3:
	return sin(uv.x + time) * normal
