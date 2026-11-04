extends Node3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
const SLASH_MAIN = preload("uid://c8a7xnth6sj3r")
@onready var live_slash_parameter_controller: LiveSlashParameterController = $LiveSlashParameterController
const SLASH_MAIN_MAT = preload("uid://b5wjdckcrvcfl")

func _ready():
	var my_mat : ShaderMaterial = SLASH_MAIN_MAT.duplicate()
	mesh_instance_3d.material_override = my_mat
	live_slash_parameter_controller.my_material = my_mat
	
func _process(delta: float) -> void:
	
	var uv = $Controls/Progress.value
	var time = $Controls/Time.value
	var stretch = $Controls/Stretch.value
	
	live_slash_parameter_controller.t = time
	live_slash_parameter_controller.stretch = stretch
	live_slash_parameter_controller.update_material(uv, false, 0)


func _on_progress_value_changed(value: float) -> void:
	$Controls/Stretch.value = live_slash_parameter_controller.stretch_curve.sample(value)
