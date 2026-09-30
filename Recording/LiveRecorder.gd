class_name LiveRecorder
extends Node

# This class is almost all AI written. It's a slight variant of how the recording system works.
"""
Now that I have an evaluator, I want to be able to query that evaluator for "Am I slashing right now" at runtime. 
I think the best way to do this would be with a "LiveRecorder" or something that stores a rolling buffer of past tracked positions. 
Then every frame we do an analysis of the past few frames to get the AnalysisFrame for the current frame, which we pass directly into @sym:VelocityEvaluator
"""

signal slash_started
signal slash_ended

@export var hand: RecordingComponent
@export var tip: RecordingComponent
@export var head: RecordingComponent
var evaluator := VelocityEvaluator.new(5.9, 15.36, 10.04, 0.52)
@export var buffer_size := 120
@export var velocity_delta := 6

var _hand_positions: Array[Vector3] = []
var _tip_positions: Array[Vector3] = []
var _head_rotations: Array[Quaternion] = []
var _sample_times: Array[float] = []
var _elapsed_time := 0.0
var _last_result := VelocityEvaluator.SlashInfo.NONE

var current_slash_data: SlashCurveData
var previous_slash_data: SlashCurveData

func _process(delta: float) -> void:
	_elapsed_time += delta * TimeManager.game_speed
	_add_sample()
	if _sample_times.size() <= velocity_delta:
		return

	var previous_index := _sample_times.size() - 1 - velocity_delta
	var current_index := _sample_times.size() - 1
	var sample_delta := (_sample_times[current_index] - _sample_times[previous_index]) / TimeManager.game_speed
	if sample_delta <= 0.0:
		return

	var frame := AnalysisFrame.new()
	frame.hilt_velocity = (_hand_positions[current_index] - _hand_positions[previous_index]) / sample_delta
	frame.tip_velocity = (_tip_positions[current_index] - _tip_positions[previous_index]) / sample_delta
	frame.look_direction = _head_rotations[current_index] * Vector3.FORWARD
	_last_result = evaluator.process_frame(frame)
	if _last_result == VelocityEvaluator.SlashInfo.STARTED:
		current_slash_data = SlashCurveData.new()
		current_slash_data.start_time = Time.get_ticks_msec()
		slash_started.emit()
		
	elif _last_result == VelocityEvaluator.SlashInfo.ENDED:
		previous_slash_data = current_slash_data
		previous_slash_data.complete = true
		current_slash_data = null
		slash_ended.emit()
	
	if is_slashing():
		var data_frame := SlashCurveData.Frame.new()
		data_frame.analysis_frame = frame
		data_frame.hand_position = hand.get_pos_rot()[0]
		data_frame.tip_position = tip.get_pos_rot()[0]
		data_frame.time = Time.get_ticks_msec()
		current_slash_data.add_frame(data_frame)

func _add_sample() -> void:
	_hand_positions.append(hand.get_pos_rot()[0])
	_tip_positions.append(tip.get_pos_rot()[0])
	_head_rotations.append(head.get_pos_rot()[1])
	_sample_times.append(_elapsed_time)

	while _sample_times.size() > buffer_size:
		_hand_positions.pop_front()
		_tip_positions.pop_front()
		_head_rotations.pop_front()
		_sample_times.pop_front()

func is_slashing() -> bool:
	return evaluator.is_slashing()

func get_last_result() -> VelocityEvaluator.SlashInfo:
	return _last_result

func set_evaluator(new_evaluator: VelocityEvaluator) -> void:
	evaluator = new_evaluator
