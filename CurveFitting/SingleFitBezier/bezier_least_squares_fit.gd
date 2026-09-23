## bezier_least_squares_fit.gd
##
## Closed-form "best fit" cubic Bezier curve fitting via ordinary least
## squares -- a GDScript port of the algorithm described by Jim Herold:
##   https://www.jimherold.com/computer-science/best-fit-bezier-curve
## (the basis for his Java "BezierFit" tool on SourceForge:
##   https://sourceforge.net/p/lsbezier/code/HEAD/tree/LeastSquaresBezier/src/BezierFit.java)
##
## Given an ordered polyline of 2D points (e.g. digitized pen-stroke
## samples), this finds the single cubic Bezier (4 control points) whose
## curve minimizes the summed squared distance to those points --
## directly and deterministically, with one 4x4 matrix inversion. No
## gradient descent, simulated annealing, or iterative re-parameterization.
##
## --- The math, briefly ---------------------------------------------
## A cubic Bezier can be written B(t) = T(t) * M * P, where:
##   T(t) = [t^3  t^2  t  1]          (a row vector)
##   M    = the constant 4x4 Bezier "characteristic" matrix
##   P    = [P0; P1; P2; P3]          (the control points, as a column)
##
## Each input point is assigned a parameter t_i in [0, 1] via
## chord-length parameterization. Stacking T(t_i) * M for every sample
## point gives an n x 4 matrix A. Minimizing ||X - A*Px||^2 (and the
## same for Y) is ordinary linear least squares, solved by the normal
## equations:
##       (A^T A) * Px = A^T * X          (A^T A) * Py = A^T * Y
##
## A^T A is always exactly 4x4 -- precisely the size Godot's `Projection`
## builtin natively works with -- so `Projection.inverse()` does the
## heavy lifting instead of a hand-rolled Gaussian-elimination routine.
## GDScript has no general matrix library, so every other matrix op
## below (construction, matrix*vector) is written out explicitly in
## terms of Projection's four Vector4 columns.
## ---------------------------------------------------------------------
class_name BezierLeastSquaresFit
extends RefCounted


# The constant cubic-Bezier basis matrix M, stored as a Projection.
# Column k holds the coefficients of (t^3, t^2, t, 1) that make up the
# k-th Bernstein polynomial:
#   B0(t) = (1-t)^3   = -t^3 + 3t^2 - 3t + 1
#   B1(t) = 3t(1-t)^2 =  3t^3 - 6t^2 + 3t
#   B2(t) = 3t^2(1-t) = -3t^3 + 3t^2
#   B3(t) = t^3       =  t^3
# so that for T = (t^3, t^2, t, 1):  _mat_vec(basis_matrix, T) == (B0,B1,B2,B3).
static func _basis_matrix() -> Projection:
	return Projection(
		Vector4(-1.0, 3.0, -3.0, 1.0), # column 0 -> contributes to B0
		Vector4(3.0, -6.0, 3.0, 0.0),  # column 1 -> contributes to B1
		Vector4(-3.0, 3.0, 0.0, 0.0),  # column 2 -> contributes to B2
		Vector4(1.0, 0.0, 0.0, 0.0)    # column 3 -> contributes to B3
	)


# Standard 4x4-matrix * 4x1-vector product, written out as a sum of
# scaled columns: M * v == v.x*col0 + v.y*col1 + v.z*col2 + v.w*col3.
# Done explicitly (rather than via the built-in `*` operator) so the
# row/column convention used throughout this file is unambiguous.
static func _mat_vec(m: Projection, v: Vector4) -> Vector4:
	return m.x * v.x + m.y * v.y + m.z * v.z + m.w * v.w


# T(t) * M -- the four Bernstein weights (B0(t), B1(t), B2(t), B3(t)).
static func _bernstein_weights(t: float, basis_m: Projection) -> Vector4:
	var t_vec := Vector4(t * t * t, t * t, t, 1.0)
	return _mat_vec(basis_m, t_vec)


## Chord-length ("path length") parameterization: d_1 = 0,
## d_i = d_(i-1) + |point_i - point_(i-1)|, t_i = d_i / d_n.
## This is what lines each input point up with a t-value along the
## eventual Bezier curve.
static func chord_length_parameters(points: PackedVector2Array) -> PackedFloat64Array:
	var n := points.size()
	var t_values := PackedFloat64Array()
	t_values.resize(n)
	if n <= 1:
		return t_values

	var cumulative := PackedFloat64Array()
	cumulative.resize(n)
	cumulative[0] = 0.0
	for i in range(1, n):
		cumulative[i] = cumulative[i - 1] + points[i].distance_to(points[i - 1])

	var total_length := cumulative[n - 1]
	if total_length <= 1e-6:
		# All points coincide -- fall back to uniform spacing so we don't
		# divide by zero.
		for i in range(n):
			t_values[i] = float(i) / float(n - 1)
	else:
		for i in range(n):
			t_values[i] = cumulative[i] / total_length
	return t_values


## Fits a single cubic Bezier curve to `points` by ordinary least
## squares. Returns [P0, P1, P2, P3], or an empty array if there are
## fewer than 2 points.
##
## `t_values`, if given, must be the same length as `points` (handy if
## you want to reuse/share a parameterization). If left empty,
## chord-length parameterization is computed automatically.
static func fit_cubic_bezier(
	points: PackedVector2Array,
	t_values: PackedFloat64Array = PackedFloat64Array()
) -> PackedVector2Array:
	var n := points.size()
	if n < 2:
		push_error("BezierLeastSquaresFit: need at least 2 points to fit a curve.")
		return PackedVector2Array()
	if n < 4:
		push_warning("BezierLeastSquaresFit: fewer than 4 points is under-determined; the fit may be degenerate.")

	if t_values.is_empty():
		t_values = chord_length_parameters(points)
	elif t_values.size() != n:
		push_error("BezierLeastSquaresFit: t_values must be the same size as points.")
		return PackedVector2Array()

	var basis_m := _basis_matrix()

	# Accumulate the normal-equation pieces:
	#   AtA = sum_i  b_i * b_i^T     (4x4 symmetric "Gram" matrix)
	#   AtX = sum_i  b_i * x_i       (4x1)
	#   AtY = sum_i  b_i * y_i       (4x1)
	# where b_i are the Bernstein weights (B0..B3) evaluated at t_i.
	var col0 := Vector4.ZERO
	var col1 := Vector4.ZERO
	var col2 := Vector4.ZERO
	var col3 := Vector4.ZERO
	var at_x := Vector4.ZERO
	var at_y := Vector4.ZERO

	for i in range(n):
		var b := _bernstein_weights(t_values[i], basis_m)
		col0 += b * b.x
		col1 += b * b.y
		col2 += b * b.z
		col3 += b * b.w
		at_x += b * points[i].x
		at_y += b * points[i].y

	var at_a := Projection(col0, col1, col2, col3)

	if is_zero_approx(at_a.determinant()):
		push_warning("BezierLeastSquaresFit: normal matrix is singular (too few/degenerate points); result may be unreliable.")

	var at_a_inv := at_a.inverse()
	var px := _mat_vec(at_a_inv, at_x) # (P0.x, P1.x, P2.x, P3.x)
	var py := _mat_vec(at_a_inv, at_y) # (P0.y, P1.y, P2.y, P3.y)

	var control_points := PackedVector2Array()
	control_points.resize(4)
	control_points[0] = Vector2(px.x, py.x)
	control_points[1] = Vector2(px.y, py.y)
	control_points[2] = Vector2(px.z, py.z)
	control_points[3] = Vector2(px.w, py.w)
	return control_points


## Evaluates a cubic Bezier (given its 4 control points) at t in [0, 1].
## Useful for drawing or sanity-checking a fit result.
static func evaluate(control_points: PackedVector2Array, t: float) -> Vector2:
	var b := _bernstein_weights(t, _basis_matrix())
	return (control_points[0] * b.x + control_points[1] * b.y
		+ control_points[2] * b.z + control_points[3] * b.w)


## Sum of squared residuals E(P), as defined in the article -- handy for
## comparing candidate fits or deciding whether a segment needs to be
## subdivided before fitting again.
static func fit_error(
	points: PackedVector2Array,
	control_points: PackedVector2Array,
	t_values: PackedFloat64Array = PackedFloat64Array()
) -> float:
	if t_values.is_empty():
		t_values = chord_length_parameters(points)
	var error := 0.0
	for i in range(points.size()):
		error += points[i].distance_squared_to(evaluate(control_points, t_values[i]))
	return error


# --- Example usage -----------------------------------------------------
# var stroke := PackedVector2Array([
#     Vector2(0, 0), Vector2(20, 40), Vector2(60, 55),
#     Vector2(100, 40), Vector2(130, 0),
# ])
# var cp := BezierLeastSquaresFit.fit_cubic_bezier(stroke)
# print("P0=%s  P1=%s  P2=%s  P3=%s" % [cp[0], cp[1], cp[2], cp[3]])
# print("error = %f" % BezierLeastSquaresFit.fit_error(stroke, cp))

# I ran out of Claude usage here lol