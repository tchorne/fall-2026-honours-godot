extends Node

const LIVE_SLASH_EFFECT = preload("uid://dypo7ljc2kmog")
@export var recorder: LiveRecorder

var _previous_effect = null

func _ready() -> void:
	recorder.slash_started.connect(_on_recorder_slash_started)
	
func _on_recorder_slash_started():
	var effect = LIVE_SLASH_EFFECT.instantiate()
	_previous_effect = effect
	add_child(effect)
	
	effect.set_data(recorder.current_slash_data)


func _on_save_most_recent_curve_pressed() -> void:
	_previous_effect.save()
