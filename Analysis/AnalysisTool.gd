@tool
extends Node

@export_file("*.tres", "*.res") var demo_path : String
## number of frames used to estimate velocity of each sample
@export var velocity_delta := 1

@export_tool_button("Generate Analysis") var analysis_button = generate_analysis

var demo: DemoRecording

func generate_analysis():
	demo = load(demo_path)
	var total_frames := len(demo.recorded_objects[0].positions)
	
	var slashing := false
	
	for frame in range(total_frames):
		var labels = demo.get_labels_between(demo.get_time(frame-1), demo.get_time(frame))
		for label in labels:
			if label.label == "slash_started": slashing = true
			elif label.label == "slash_ended": slashing = false
		
		var frame_data := AnalysisFrame.new()
		frame_data.is_slashing = slashing


		if frame > velocity_delta:
			var hand = demo.get_sample_index("hand_r", frame)
			var previous_hand = demo.get_sample_index("hand_r", frame-velocity_delta)
			var tip = demo.get_sample_index("sword_tip", frame)
			var previous_tip = demo.get_sample_index("sword_tip", frame-velocity_delta)
			frame_data.hilt_velocity = get_velocity(previous_hand, hand, velocity_delta)
			frame_data.tip_velocity = get_velocity(previous_tip, tip, velocity_delta)


func get_velocity(previous_sample, sample, frames: int) -> Vector3:
	return (sample[0] - previous_sample[0]) / float(frames) / float(demo.sample_rate)
