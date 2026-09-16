class_name VelocityEvaluator
extends Object

# Detects slashes from just velocity
enum SlashInfo {
	STARTED,
	ENDED,
	NONE,
}
var _hand_threshold := 0.0
var _tip_threshold := 0.0
var _vel_dot_forward_max := 10.0

## if the current velocity is less then the starting velocity by this factor, the slash ends
var _hold_velocity_threshold := 0.5

# Runtime detection 
var _in_slash = false
var _current_slash_starting_tip_velocity := Vector3.ZERO
var _current_slash_starting_hand_velocity := Vector3.ZERO

func _init(hand_threshold := 0.0, tip_threshold := 0.0, vel_dot_forward_max := 10.0, hold_velocity_threshold := 0.5):
	self._hand_threshold = hand_threshold
	self._tip_threshold = tip_threshold
	self._vel_dot_forward_max = vel_dot_forward_max
	self._hold_velocity_threshold = hold_velocity_threshold

func _to_string() -> String:
	return "VelocityEvaluator(%0.2f, %0.2f, %0.2f, %0.2f)" % [_hand_threshold, _tip_threshold, _vel_dot_forward_max, _hold_velocity_threshold]

func reset() -> void:
	_in_slash = false
	_current_slash_starting_tip_velocity = Vector3.ZERO
	_current_slash_starting_hand_velocity = Vector3.ZERO

func process_frame(frame: AnalysisFrame) -> SlashInfo:
	var result := SlashInfo.NONE
	if not _in_slash:
		if frame.tip_velocity.length() >= _tip_threshold \
			and frame.hilt_velocity.length() >= _hand_threshold \
			and abs(frame.tip_velocity.normalized().dot(frame.look_direction)) <= _vel_dot_forward_max:
			result = SlashInfo.STARTED
			_in_slash = true
			_current_slash_starting_tip_velocity = frame.tip_velocity
			_current_slash_starting_hand_velocity = frame.hilt_velocity
	elif (frame.tip_velocity.length() < _current_slash_starting_tip_velocity.length() * _hold_velocity_threshold \
		or frame.hilt_velocity.length() < _current_slash_starting_hand_velocity.length() * _hold_velocity_threshold):
		_in_slash = false
		result = SlashInfo.ENDED
	return result

func is_slashing() -> bool:
	return _in_slash

func get_slashes(analysis: DemoRecordingAnalysis) -> Array[SlashInfo]:
	reset()
	var out : Array[SlashInfo] = []
	
	for frame in analysis.frames:
		out.append(process_frame(frame))
	return out

func mutate(child_count: int, step_size: float = 1.0) -> Array[VelocityEvaluator]:
	var out: Array[VelocityEvaluator] = []

	for i in child_count:
		var new_hand_threshold := _hand_threshold + randf_range(-1.0, 1.0) * step_size
		var new_tip_threshold := _tip_threshold + randf_range(-1.0, 1.0) * 3.0 * step_size
		var new_vel_dot_forward_max := _vel_dot_forward_max + randf_range(-1.0, 1.0) * 0.1 * step_size
		var new_hold_velocity_threshold := _hold_velocity_threshold + randf_range(-0.1, 0.1) * 0.1 * step_size

		out.append(VelocityEvaluator.new(new_hand_threshold, new_tip_threshold, new_vel_dot_forward_max, new_hold_velocity_threshold))
	return out
