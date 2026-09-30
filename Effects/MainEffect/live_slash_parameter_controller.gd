class_name LiveSlashParameterController
extends Node

signal fully_faded_out

@export var erosion_curve : Curve
@export var linger_time := 0.7

var my_material: ShaderMaterial


var t := 0.0

func update_material(sword_uv: float, complete: bool, delta: float):
	if (complete): t += delta
	
	var erosion = erosion_curve.sample(t / linger_time)
	my_material.set_shader_parameter("SwordUV", sword_uv)
	my_material.set_shader_parameter("ErodeTime", erosion)
	
	if (t / linger_time > 1):
		fully_faded_out.emit()
