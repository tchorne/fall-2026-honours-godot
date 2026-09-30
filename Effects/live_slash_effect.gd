extends Node3D

const SlashCurveMeshBuilder = preload("uid://3uh5ps6862q4")
const SLASH_MAIN_MAT = preload("uid://b5wjdckcrvcfl")



@onready var slash_curve_mesh_builder: SlashCurveMeshBuilder = $SlashCurveMeshBuilder
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var live_slash_parameter_controller: LiveSlashParameterController = $LiveSlashParameterController

var my_mat : ShaderMaterial
var data: SlashCurveData

func set_data(data_: SlashCurveData):
	my_mat = SLASH_MAIN_MAT.duplicate()
	# Comment this out to show debug texture
	#mesh_instance_3d.material_override = my_mat
	live_slash_parameter_controller.my_material = my_mat
	data = data_

func _process(delta: float) -> void:
	if data and data.frames.size() > 4:
		mesh_instance_3d.visible = true
		var fitting_curve := SingleFitBezierCurve.create(data)
		var end_uv := fitting_curve.get_tip_path_length() / SlashCurveData.MAX_LENGTH
		mesh_instance_3d.mesh = slash_curve_mesh_builder.generate_extruded_eye(fitting_curve, end_uv)
		
		var progress = end_uv
		#LoggerGlobal.trace("Tip path is %f units long" % [fitting_curve.get_tip_path_length()])
		live_slash_parameter_controller.update_material(progress, data.complete, delta)
	else:
		mesh_instance_3d.visible = false
		
func _on_live_slash_parameter_controller_fully_faded_out() -> void:
	queue_free()
