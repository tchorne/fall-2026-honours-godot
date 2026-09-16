extends Node3D

const SlashCurveMeshBuilder = preload("uid://3uh5ps6862q4")


@export var recorder: LiveRecorder
@onready var slash_curve_mesh_builder: SlashCurveMeshBuilder = $SlashCurveMeshBuilder
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready():
	recorder.slash_started.connect(_on_recorder_slash_started)
	recorder.slash_ended.connect(_on_recorder_slash_ended)

func _process(_delta: float) -> void:
	var data: SlashCurveData = null
	if recorder.current_slash_data != null:
		data = recorder.current_slash_data
	elif recorder.previous_slash_data != null:
		data = recorder.previous_slash_data
	
	if data:
		mesh_instance_3d.visible = true
		slash_curve_mesh_builder.generate_triangle_strip(mesh_instance_3d.mesh as ImmediateMesh, LineSegmentCurve.create(data))
	else:
		mesh_instance_3d.visible = false
		
func _on_recorder_slash_started():
	pass

func _on_recorder_slash_ended():
	pass
