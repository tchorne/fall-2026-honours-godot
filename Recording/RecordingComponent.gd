class_name RecordingComponent
extends Node

@export var recording_name := ""
@export var write := false
@export var playback := false

@onready var target : Node3D = get_parent()

func set_pos_rot(position: Vector3, rotation: Quaternion):
    target.global_position = position
    target.global_rotation = rotation.get_euler()

func get_pos_rot() -> Array:
    return [target.global_position, Quaternion.from_euler(target.global_rotation)]