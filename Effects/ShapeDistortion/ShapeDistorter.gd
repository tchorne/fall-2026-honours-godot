@abstract
class_name ShapeDistorter 
extends RefCounted

@abstract
## Gives a displacement to a particular vertex
func displace(uv: Vector2, time: float, normal: Vector3, tangent: Vector3, sword_x: float) -> Vector3
