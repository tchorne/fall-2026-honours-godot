extends Node3D

@export var ray_length: float = 1000.0
@onready var camera: Camera3D = $"../Camera3D"
@onready var right_hand: Marker3D = $"../RightHand"

func get_mouse_world_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0b10
	var result = space_state.intersect_ray(query)
	
	if result.has("position"):
		return result["position"]
	return Vector3.ZERO

func _process(delta: float) -> void:
	right_hand.position = get_mouse_world_position()
