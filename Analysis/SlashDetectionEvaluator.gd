class_name SlashDetectionEvaluator
extends Node

const AnalysisTool = preload("uid://jetxc6eghcm1")

@onready var analysis_tool: AnalysisTool = $"../Analysis"

const threshold = 0.2

func _ready() -> void:
	LoggerGlobal.info("Evaluator: Perfect score is %0.5f" % [get_perfect_score()])

# Evaluation algorithm:
# When the detector thinks there will be a slash, gain 1 point if we're within 0.5 seconds of a slash starting.
# When the detector thinks a slash has ended, gain 0.5 points if we're within 0.5 seconds of a slash ending.
# If either event occurs outside of the 0.5 second window, lose 1 point.
# Up to 0.025 bonus points for slash or end slash based on how close the timing is

func evaluate(detector: Object) -> float:
	assert(detector.has_method("get_slashes"))
	
	var analysis := analysis_tool.generate_analysis()
	var recording := analysis_tool.demo
	
	var score := 0.0
	
	var detection_results = detector.get_slashes(analysis)

	var target_slash_start_frame := -1
	var target_slash_end_frame := -1
	target_slash_start_frame = get_next_slash_starting_frame(analysis, 0)
	target_slash_end_frame = get_next_slash_ending_frame(analysis, 0)

	for frame_index in analysis.frames.size():
		var _frame = analysis.frames[frame_index]
		var detection_result = detection_results[frame_index]

		var current_time := recording.get_time(frame_index)
		var target_slash_start_time := recording.get_time(target_slash_start_frame)
		var target_slash_end_time := recording.get_time(target_slash_end_frame)

		if detection_result == VelocityEvaluator.SlashInfo.STARTED:
			var closeness_to_start_time = abs(target_slash_start_time - current_time)
			if target_slash_start_frame != -1 and closeness_to_start_time <= threshold:
				score += 1.0 + inverse_lerp(threshold, 0, closeness_to_start_time) * 0.025
				target_slash_start_frame = get_next_slash_starting_frame(analysis, target_slash_start_frame + 1)
			else:
				score -= 1.0
		elif detection_result == VelocityEvaluator.SlashInfo.ENDED:
			var closeness_to_end_time = abs(target_slash_end_time - current_time)
			if target_slash_end_frame != -1 and closeness_to_end_time <= threshold:
				score += 0.5
				score += inverse_lerp(0.5, 0, closeness_to_end_time) * 0.025
				target_slash_end_frame = get_next_slash_ending_frame(analysis, target_slash_end_frame + 1)
			else:
				score -= 1.0

	return score

func get_perfect_score() -> float:
	var analysis := analysis_tool.generate_analysis()
	var total := 0.0
	for frame in analysis.frames:
		if frame.is_slash_starting:
			total += 1 + 0.025
		elif frame.is_slash_ending:
			total += 0.5 + 0.025
	return total

func get_next_slash_starting_frame(analysis: DemoRecordingAnalysis, start_frame: int) -> int:
	for frame_index in range(start_frame, len(analysis.frames)):
		if analysis.frames[frame_index].is_slash_starting:
			return frame_index
	return -1

func get_next_slash_ending_frame(analysis: DemoRecordingAnalysis, start_frame: int) -> int:
	for frame_index in range(start_frame, len(analysis.frames)):
		if analysis.frames[frame_index].is_slash_ending:
			return frame_index
	return -1
