extends Node

@export var recording_components : Array[RecordingComponent]
@export var current_recording : DemoRecording

@onready var timeline: HSlider = %Timeline
@onready var trail_renderer: MultiMeshInstance3D = %TrailRenderer

var is_playing := false
var is_slicing := false
var time_since_last_sample := 0.0
var elapsed_time := 0.0
var paused := false
var scrubbing := false
var prev_time := 0.0

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
	LoggerGlobal.add_stat("Current Frame", func(): return current_recording.get_index(elapsed_time))
	LoggerGlobal.add_stat("Is Slashing", func(): return is_slicing)

func _process(delta: float) -> void:
	if not is_playing: return
	if not paused and not scrubbing:
		elapsed_time += delta
		timeline.set_value_no_signal(elapsed_time)
	
	var current_frame = current_recording.get_index(elapsed_time)
	
	for obj in recording_components:
		if not obj.playback: continue
		var sample = current_recording.get_sample(obj.recording_name, elapsed_time)
		if sample:
			var pos : Vector3 = sample[0]
			var rot_vec : Vector4 = sample[1]
			var rot := Quaternion(rot_vec.x, rot_vec.y, rot_vec.z, rot_vec.w)
			obj.set_pos_rot(pos, rot)
	
	if is_instance_valid(trail_renderer):
		trail_renderer.redraw(current_recording.get_many_samples("sword_tip", current_frame-60, current_frame)[0])
		
	if (prev_time != elapsed_time):
		var reversing = prev_time > elapsed_time
		var labels = current_recording.get_labels_between(prev_time, elapsed_time)
		for label in labels:
			_on_label_passed(label, reversing)

		
	prev_time = elapsed_time


func _on_label_passed(label: RecordedLabel, reversing := false):
	LoggerGlobal.info("Passed Label: %s" % [label.label])
	if label.label == "slash_started":
		is_slicing = not reversing
	elif label.label == "slash_ended":
		is_slicing = reversing

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
