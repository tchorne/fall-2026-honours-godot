class_name LiveSlashParameterController
extends Node

signal fully_faded_out

@export var erosion_curve : Curve
## Controls how horizontally stretched the texture is over progress
@export var stretch_curve : Curve
## Adds a little bit to progress based on time since slash start
@export var progess_add_with_time : Curve


@export var linger_time := 0.7

var my_material: ShaderMaterial


var t := 0.0
var t_since_start := 0.0
var stretch := 0.0

func update_material(sword_uv: float, complete: bool, delta: float):
	if (complete): t += delta
	t_since_start += delta
	
	var erosion = erosion_curve.sample(t / linger_time)
	stretch = stretch_curve.sample(sword_uv)
	var summed_sword_uv = sword_uv + progess_add_with_time.sample(t_since_start)
	my_material.set_shader_parameter("SwordUV", summed_sword_uv)
	my_material.set_shader_parameter("EndUV", sword_uv)
	my_material.set_shader_parameter("ErodeTime", erosion)
	my_material.set_shader_parameter("HStretch", stretch)
	
	
	if (t / linger_time > 1):
		fully_faded_out.emit()
