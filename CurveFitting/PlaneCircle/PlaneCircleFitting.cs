using Godot;
using System.Linq;
using MathNet.Numerics.LinearAlgebra;
using MathNet.Numerics;
using MathNet.Numerics.LinearRegression;
/// <summary>
/// Represents the result of fitting a plane and a circle to a set of 3D points.
/// Finds plane with SVD
/// 
/// The normal follows a left hand rule, where if the normal is pointing in the thumb direction, the fingers curl in the direction of the circle. 
/// This is determined by the start_velocity parameter.
/// </summary>
public partial class PlaneCircleFitting : GodotObject
{
	public Vector3 Normal { get; set; }
	public Vector3 Origin { get; set; }
	public float Radius { get; set; }

	private Vector3 uhat { get; set; }
	private Vector3 vhat { get; set; }
	private Vector2 center { get; set; }
	private float start_angle { get; set; }
	private float end_angle { get; set; }

	/// <summary>
	/// 
	/// </summary>
	/// <param name="tip_points"></param>
	/// <param name="hilt_points"></param>
	/// <param name="start_velocity">Direction the sword is moving at the start. Determines the winding direction / normal</param>
	/// <returns></returns>
	public static PlaneCircleFitting FitPlaneAndCircle(Vector3[] tip_points, Vector3[] hilt_points, Vector3 start_velocity)
	{
		var result = new PlaneCircleFitting();

		Vector3[] all_points = [.. tip_points, .. hilt_points];

		var n = all_points.Length;

		// I had to ask AI here to figure out how to get the array of vector3s into a 2D matrix of doubles without a giant for loop
		// "How do I convert a csharp Godot.Vector3[] to a double[,] to create a MathNet.Numerics.LinearAlgebra matrix?"
		// Turns out we use a for loop anyways
		#region AI
		var all_points_as_floats = new float[all_points.Length, 3];
		for (int i = 0; i < all_points.Length; i++)
		{
			all_points_as_floats[i, 0] = all_points[i].X;
			all_points_as_floats[i, 1] = all_points[i].Y;
			all_points_as_floats[i, 2] = all_points[i].Z;
		}
		#endregion // AI

		var matrix = Matrix<float>.Build.DenseOfArray(all_points_as_floats);

		// Get the centroid of the points
		var centroid = matrix.ColumnSums() / matrix.RowCount;

		var rows = Enumerable.Repeat(centroid, all_points.Length);
		var matrix_sub_centroid = matrix - Matrix<float>.Build.DenseOfRowVectors(rows);

		var svd = matrix_sub_centroid.Svd();

		var V = svd.VT.Transpose();

		var fitting_plane = V.Column(V.ColumnCount - 1).Normalize(2);
		var normal = fitting_plane.ToGodot();

		// The normal we want is roughly aligned with (centroid_to_first_tip_point cross start_velocity)
		var centroid_to_first_tip_point = (tip_points[0] - centroid.ToGodot()).Normalized();

		if (normal.Dot(centroid_to_first_tip_point.Cross(start_velocity)) < 0)
		{
			fitting_plane = -fitting_plane;
			normal = -normal;
		}

		result.Normal = normal;

		// Now we fit the circle

		// This whole section was me projecting the points in 3D but this was not necessary because I only need the coordinates in plane space
		// Project all points onto the plane

		// projected_point = point - ((point - centroid) dot normal) times normal

		// matrix_sub_centroid = (projected_point - centroid)
		// distances_to_plane = (matrix_sub_centroid dot normal)

		// var distances_to_plane = matrix_sub_centroid * fitting_plane;
		// distances_times_normal = distances_to_plane * normal
		// var distances_times_normal = Matrix<float>.Build.Dense(n, 3, (row, col) => distances_to_plane[row] * fitting_plane[col]);
		// var projected_points = matrix - distances_times_normal;

		var uhat = Vector3.Right.Cross(result.Normal).Normalized();
		var vhat = result.Normal.Cross(uhat).Normalized(); 
		// v hat (corresponding to y axis) is always to the left of uhat (corresponding to x axis) when looking in the direction of the normal
		// We're rotating clockwise when viewed from the normal, so we're moving *from* v hat *to* u hat, which is *decreasing* angle in the standard unit circle sense.
		// I'm starting to doubt my choice of the left hand rule earlier
		result.uhat = uhat;
		result.vhat = vhat;

		var world_to_plane_matrix = Matrix<float>.Build.DenseOfArray(new float[,] {
			{ uhat.X, vhat.X },
			{ uhat.Y, vhat.Y },
			{ uhat.Z, vhat.Z }
		});

		var projected_points_2d = matrix_sub_centroid * world_to_plane_matrix;

		/* The above matrix is
		x1 y1
		x2 y2
		x3 y3
		...
		xn yn

		We want to satisfy
		(x - x')^2 + (y - y')^2 = r^2

		Let k= rr - x'x' - y'y'

		Now each point gives us an equation
		(2x 2y 1) dot (x' y' k) = xx + yy
		A[x` y` r]^T = b 
		*/

		// Just realized we don't want to fit a circle to all the points, just the tip points.
		// So we shrink n

		n = tip_points.Length;

		var A = Matrix<float>.Build.Dense(n, 3, (row, col) =>
		{

			var x = projected_points_2d[row, 0];
			var y = projected_points_2d[row, 1];

			if (col == 0) return 2 * x;
			if (col == 1) return 2 * y;
			return 1; // col == 2
		});

		var b = Vector<float>.Build.Dense(n, (i) =>
		{
			var x = projected_points_2d[i, 0];
			var y = projected_points_2d[i, 1];

			return x * x + y * y;
		});

		// Similar to np.linalg.lstsq(A, b)
		var solve = MultipleRegression.QR(A, b);
		var x_prime = solve[0];
		var y_prime = solve[1];
		var k = solve[2];
		var r = Mathf.Sqrt(k + x_prime * x_prime + y_prime * y_prime);

		var center = Vector<float>.Build.Dense(new float[] { x_prime, y_prime });
		result.center = new Vector2(x_prime, y_prime);
		result.Origin = centroid.ToGodot() + x_prime * uhat + y_prime * vhat;
		result.Radius = r;

		// Compute the start and end angles of the circle segment that corresponds to the tip points
		var start_point = projected_points_2d.Row(0) - center;
		var end_point = projected_points_2d.Row(n - 1) - center;

		result.start_angle = Mathf.Atan2(start_point[1], start_point[0]);
		result.end_angle = Mathf.Atan2(end_point[1], end_point[0]);

		// Recall that we always want to be moving from vhat to uhat, which is decreasing angle in the standard unit circle sense. 
		// So we make sure end angle is always less than start angle so we get decreasing values when interpolating.
		// Since I wrote the above I fixed a backwards cross product and everything became backwards so this got flipped too
		while (result.end_angle < result.start_angle)
		{
			result.end_angle += Mathf.Tau;
		}

		return result;
	}

	public Vector3 GetCirclePoint(float t, float radius = -1)
	{
		if (radius < 0)
		{
			radius = Radius;
		}
		var angle = Mathf.Lerp(start_angle, end_angle, t);

		return Origin + radius * (Mathf.Cos(angle) * uhat + Mathf.Sin(angle) * vhat);
	}
	
	public float GetTipLength(float radius = -1)
	{
		if (radius < 0)
		{
			radius = Radius;
		}
		var angle_diff = Mathf.Abs(end_angle - start_angle); // Distance in radians
		return radius * angle_diff; // Distance in units
	}
}

public static class PlaneCircleFittingExtensions
{
	public static Vector3 ToGodot(this Vector<float> v)
	{
		return new Vector3(v[0], v[1], v[2]);
	}
	public static Vector<float> ToMathNet(this Vector3 v)
	{
		return Vector<float>.Build.Dense(new float[] { v.X, v.Y, v.Z });
	}
}
