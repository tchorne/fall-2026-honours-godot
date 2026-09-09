extends Node

@export var recording_components : Array[RecordingComponent]
@export var current_recording : DemoRecording

@onready var timeline: HSlider = %Timeline

var is_playing := false
var is_slicing := false
var time_since_last_sample := 0.0
var elapsed_time := 0.0
var paused := false
var scrubbing := false

func start_playing():
	is_playing = true
	elapsed_time = 0.0
	LoggerGlobal.info("Playing back recording %s" % [current_recording])
	timeline.min_value = 0.0
	timeline.max_value = len(current_recording.recorded_objects[0].positions) / float(current_recording.sample_rate)
	pass

func end_playing():
	is_playing = false
	LoggerGlobal.info("Stopped playing back recording")
	pass

func _ready():
	start_playing()

func _process(delta: float) -> void:
	if not is_playing: return
	if not paused and not scrubbing:
		elapsed_time += delta
		timeline.set_value_no_signal(elapsed_time)
		
	for obj in recording_components:
		if not obj.playback: continue
		var sample = current_recording.get_sample(obj.recording_name, elapsed_time)
		if sample:
			var pos : Vector3 = sample[0]
			var rot_vec : Vector4 = sample[1]
			var rot := Quaternion(rot_vec.x, rot_vec.y, rot_vec.z, rot_vec.w)
			obj.set_pos_rot(pos, rot)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_recording"):
		if (is_playing):
			end_playing()
		else: 
			start_playing()
	if event.is_action_pressed("pause_recording"):
		paused = not paused
		if paused:
			LoggerGlobal.info("Paused playback")
		else:
			LoggerGlobal.info("Resumed playback")
	if event.is_action_pressed("replay_recording"):
		elapsed_time = 0.0
		if not is_playing:
			start_playing()

func _on_timeline_drag_started() -> void:
	scrubbing = true


func _on_timeline_drag_ended(_value_changed: bool) -> void:
	scrubbing = false


func _on_timeline_value_changed(value: float) -> void:
	elapsed_time = value
