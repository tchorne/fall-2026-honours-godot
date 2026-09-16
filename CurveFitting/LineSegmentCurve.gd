class_name LineSegmentCurve
extends SlashCurve

var hand_points: PackedVector3Array = []
var tip_points: PackedVector3Array = []

static func create(data: SlashCurveData) -> LineSegmentCurve:
	var curve := LineSegmentCurve.new()
	
	for frame in data.frames:
		curve.hand_points.append(frame.hand_position)
		curve.tip_points.append(frame.tip_position)
	
	return curve

func sample_point(t: float) -> SampleData:
	var out := SampleData.new()
	
	if hand_points.size() == 0:
		return out
	if hand_points.size() == 1:
		out.hilt_position = hand_points[0]
		out.tip_position = tip_points[0]
		return out
		
	var num_points := hand_points.size()
	
	var low_point := floori(t * num_points)
	var high_point := low_point + 1
	high_point = min(high_point, hand_points.size()-1)
	low_point = max(0, low_point)
	
	
	var lerp_t := inverse_lerp(low_point, high_point, t * num_points)
	
	out.hilt_position = lerp(hand_points[low_point], hand_points[high_point], lerp_t)
	out.tip_position = lerp(tip_points[low_point], tip_points[high_point], lerp_t)
	return out
