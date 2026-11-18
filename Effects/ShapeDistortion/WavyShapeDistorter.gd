class_name WavyShapeDistorter
extends ShapeDistorter

var amplitude
var space_frequency
var time_frequency

func _init(amplitude_: float, space_frequency_: float, time_frequency_: float) -> void:
	amplitude = amplitude_
	space_frequency = space_frequency_
	time_frequency = time_frequency_
	

func displace(uv: Vector2, time: float, normal: Vector3, tangent: Vector3, sword_x: float) -> Vector3:
	
	var distortion = smoothstep(0, 1, inverse_lerp(sword_x, 0, uv.x))
	
	
	return sin(uv.x * space_frequency + time * time_frequency) * amplitude * distortion * normal
