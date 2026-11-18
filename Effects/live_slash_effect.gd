extends Node3D

const SlashCurveMeshBuilder = preload("uid://3uh5ps6862q4")
const SLASH_MAIN_MAT = preload("uid://b5wjdckcrvcfl")



@onready var slash_curve_mesh_builder: SlashCurveMeshBuilder = $SlashCurveMeshBuilder
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var live_slash_parameter_controller: LiveSlashParameterController = $LiveSlashParameterController

var my_mat : ShaderMaterial
var data: SlashCurveData

var curve_type: int = 0
var elapsed_time := 0.0

func set_data(data_: SlashCurveData):
	my_mat = SLASH_MAIN_MAT.duplicate()
	# Comment this out to show debug texture
	mesh_instance_3d.material_override = my_mat
	live_slash_parameter_controller.my_material = my_mat
	data = data_

func save():
	ResourceSaver.save(mesh_instance_3d.mesh, "Recording/Recordings/saved_mesh.tres")

func _process(delta: float) -> void:
	elapsed_time += delta
	if data and data.frames.size() > 8:
		mesh_instance_3d.visible = true
		
		var my_curve: SlashCurve = build_curve(data, curve_type)
		var my_distorter: ShapeDistorter = WavyShapeDistorter.new(0.1,5,5)
		
		var end_uv := my_curve.get_tip_path_length() / SlashCurveData.MAX_LENGTH
		
		var distort = func(uv, normal, tangent): return my_distorter.displace(uv, elapsed_time, normal, tangent, end_uv)
		
		mesh_instance_3d.mesh = slash_curve_mesh_builder.generate_extruded_eye(my_curve, end_uv, distort)
		
		var progress = end_uv
		#LoggerGlobal.trace("Tip path is %f units long" % [fitting_curve.get_tip_path_length()])
		live_slash_parameter_controller.update_material(progress, data.complete, delta)
	else:
		mesh_instance_3d.visible = false

func build_curve(d, type) -> SlashCurve:
	if (type == 0):
		return SingleFitBezierCurve.create(d)
	elif (type == 1):
		return PlaneCircleCurve.create(d)
	else:
		return LineSegmentCurve.create(data)
	

func _on_live_slash_parameter_controller_fully_faded_out() -> void:
	queue_free()
