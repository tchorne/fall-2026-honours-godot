class_name SlashCurveEvaluator
extends Node

@export var temporal_subdivisions: int = 4



func n_points_between(low: float, high: float, n: int) -> Array[float]:
	var points := []
	for i in range(n):
		var t := float(i) / float(n - 1)
		var point := low + t * (high - low)
		points.append(point)
	return points

func evaluate_curve(generation_function: Callable, slash_curve_data: SlashCurveData) -> CurveEvaluation:
	var generated_curves: Array[SlashCurve] = []
	var evaluation := CurveEvaluation.new()

	for i in range(temporal_subdivisions):
		var t := float(i) / float(temporal_subdivisions - 1)
		
		# Take the first t% of the slash_curve_data and generate a curve from it
		var partial_data := slash_curve_data.Clone(int(t * slash_curve_data.frames.size()))
		var generated_curve : SlashCurve = generation_function.call(partial_data)
		generated_curves.append(generated_curve)

	evaluation.stability = compute_stability(generated_curves)
	return evaluation

func compute_stability(curves: Array[SlashCurve]) -> float:
	var summed_distance := 0.0

	for i in range(curves.size() - 1):
		var curve_a := curves[i]
		var curve_b := curves[i + 1]
		
		for t in n_points_between(0.0, float(i) / float(curves.size() - 1), 10):
			var point_a := curve_a.sample_point(t)
			var point_b := curve_b.sample_point(t)
			
			# Compute the distance between the tip positions of the two curves at the same t
			var distance := point_a.tip_position.distance_to(point_b.tip_position)
			summed_distance += distance
			distance = point_a.hilt_position.distance_to(point_b.hilt_position)
			summed_distance += distance

	return summed_distance / (curves.size() - 1) if curves.size() > 1 else 0.0

## Generated from a SlashCurve (or a series of SlashCurves) and the SlashCurveData that generated them
## Metrics:
## Smoothness - if the player has shaky hands during a swing, it should not produce a curve with wavy or jagged edges.
## (Haven't figured out how to calculate smoothness yet)
## Fitting - this one’s self explanatory, the curve as a whole shouldn’t stray too far from the points used to make it.
## Stability - For any P(s) on a curve at time t0, P(s) at time t1 should be positionally close to it.
## Computation speed - How many ms to compute? 
class CurveEvaluation:
	var smoothness: float
	var fitting: float
	var stability: float
	var computation_time: float
