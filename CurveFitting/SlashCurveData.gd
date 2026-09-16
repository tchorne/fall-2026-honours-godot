class_name SlashCurveData
extends Object
## This class stores AnalysisFrames and position data recorded over the course of a swing.
## Instances can be either complete or incomplete
## We can fit curves to complete or incomplete slashes and evaluate them against complete ones

const MAX_LENGTH = 3.0

var frames: Array[Frame]
var start_time: float
var complete := false

func add_frame(frame: Frame):
	frames.append(frame)

class Frame:
	var analysis_frame: AnalysisFrame
	var tip_position: Vector3
	var hand_position: Vector3
	var time: float
