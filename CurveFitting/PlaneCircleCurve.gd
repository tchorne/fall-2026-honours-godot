class_name PlaneCircleCurve
extends SlashCurve
## Fits a curve to the points, projects the points to the plane, then fits a circle

const PlaneCircleFitting = preload("uid://dctck4alm7ybx")
const SWORD_LENGTH = 1.5

## 4 control points
var arc_length := 0.0
var normal := Vector3.ZERO
var center := Vector3.ZERO
var plane_circle_fitting : PlaneCircleFitting



static func create(data: SlashCurveData) -> PlaneCircleCurve:
	var curve := PlaneCircleCurve.new()
	
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
	
	# Take the 3rd frame for velocity because I don't remember if the first one has a velocity !!
	curve.plane_circle_fitting = PlaneCircleFitting.FitPlaneAndCircle(tip_points, hilt_points, data.frames[0].analysis_frame.tip_velocity)
	curve.normal = curve.plane_circle_fitting.Normal
	curve.center = curve.plane_circle_fitting.Origin
	
	return curve

func get_tip_path_length() -> float:
	return plane_circle_fitting.GetTipLength(-1)

func sample_point(t: float) -> SampleData:
	var out := SampleData.new()
	out.tip_position = plane_circle_fitting.GetCirclePoint(t, plane_circle_fitting.Radius)
	out.hilt_position = plane_circle_fitting.GetCirclePoint(t, plane_circle_fitting.Radius - SWORD_LENGTH)
	
	return out
