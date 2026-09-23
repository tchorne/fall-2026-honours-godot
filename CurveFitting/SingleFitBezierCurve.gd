class_name SingleFitBezierCurve
extends SlashCurve
## Finds a single cubic bezier curve that best fits a set of points.
## https://www.jimherold.com/computer-science/best-fit-bezier-curve

## 4 control points
var control_points: PackedVector3Array
var control_points_hilt: PackedVector3Array

static func create(data: SlashCurveData) -> SingleFitBezierCurve:
	var curve := SingleFitBezierCurve.new()
	
	var total_time := data.frames[-1].time - data.start_time
	
	# Get a bezier for the tip points
	var tip_points: PackedVector3Array = []
	var hilt_points: PackedVector3Array = []
	var time_values: PackedFloat64Array = []
	tip_points.resize(data.frames.size())
	hilt_points.resize(data.frames.size())
	time_values.resize(data.frames.size())
	
	var i := 0
	for frame in data.frames:
		tip_points[i] = frame.tip_position
		hilt_points[i] = frame.hand_position
		time_values[i] = (frame.time - data.start_time) / total_time
		i += 1
	
	curve.control_points = BezierLeastSquaresFit3D.fit_cubic_bezier(tip_points, time_values)
	curve.control_points_hilt = BezierLeastSquaresFit3D.fit_cubic_bezier(hilt_points, time_values)
	
	return curve

func sample_point(t: float) -> SampleData:
	var out := SampleData.new()
	
	out.tip_position = BezierLeastSquaresFit3D.evaluate(control_points, t)
	out.hilt_position = BezierLeastSquaresFit3D.evaluate(control_points_hilt, t)
	
	return out
