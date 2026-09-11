extends Node

@export var sample_rate := 40
@export var recording_components : Array[RecordingComponent]

@export_file_path("*.res", "*.tres") var recording_file_path: String

var current_recording : DemoRecording

var is_recording := false
var time_since_last_sample := 0.0
var elapsed_time := 0.0

func start_recording():
	current_recording = load(recording_file_path)
	is_recording = true
	elapsed_time = 0.0
	LoggerGlobal.info("Started recording")
	current_recording.reset()
	current_recording.sample_rate = sample_rate
	pass

func end_recording():
	is_recording = false
	ResourceSaver.save(current_recording, recording_file_path)
	LoggerGlobal.info("Saved recording to %s" % recording_file_path)

func take_sample():
	for obj in recording_components:
		if not obj.write: continue
		var pos_rot = obj.get_pos_rot()
		current_recording.add_sample(obj.recording_name, pos_rot[0], pos_rot[1])

func _process(delta: float) -> void:
	if not is_recording: return
	time_since_last_sample += delta
	elapsed_time += delta
	while (time_since_last_sample > 1.0/sample_rate):
		time_since_last_sample -= 1.0/sample_rate
		take_sample()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_recording"):
		if (is_recording):
			end_recording()
		else: 
			start_recording()
	if event.is_action_pressed("label_slash"):
		current_recording.add_label("slash_started", elapsed_time)
	if event.is_action_released("label_slash"):
		current_recording.add_label("slash_ended", elapsed_time)
		


func _on_right_hand_button_pressed(action_name: String) -> void:
	#LoggerGlobal.trace("Right hand button pressed: %s" % [action_name])
	if action_name == "ax_button":
		if (is_recording):
			end_recording()
		else: 
			start_recording()
	if action_name == "trigger_click" and current_recording:
		current_recording.add_label("slash_started", elapsed_time)


func _on_right_hand_button_released(action_name: String) -> void:
	if action_name == "trigger_click" and current_recording:
		current_recording.add_label("slash_ended", elapsed_time)
