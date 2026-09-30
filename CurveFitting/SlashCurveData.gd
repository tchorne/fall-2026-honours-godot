class_name SlashCurveData
extends Object
## This class stores AnalysisFrames and position data recorded over the course of a swing.
## Instances can be either complete or incomplete
## We can fit curves to complete or incomplete slashes and evaluate them against complete ones

const MAX_LENGTH = 15.0

var frames: Array[Frame]
var start_time: float
var complete := false

func add_frame(frame: Frame):
	frames.append(frame)

func Clone(up_to_frame: int) -> SlashCurveData:
	var new_frame := SlashCurveData.new()
	new_frame.start_time = start_time
	new_frame.complete = up_to_frame >= frames.size()
	for i in range(up_to_frame):
		new_frame.add_frame(frames[i])
	return new_frame

class Frame:
	var analysis_frame: AnalysisFrame
	var tip_position: Vector3
	var hand_position: Vector3
	var time: float

	
