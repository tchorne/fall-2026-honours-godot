class_name DemoRecording
extends Resource

@export var sample_rate := 60
@export var recorded_objects: Array[RecordedObject] = []
@export var recorded_labels: Array[RecordedLabel]

func reset():
	recorded_labels.clear()
	recorded_objects.clear()

func add_sample(obj: String, pos: Vector3, rot: Quaternion):
	var find_result = recorded_objects.find_custom(func(x): return x.my_name == obj)
	var robj: RecordedObject
	if find_result == -1:
		robj = RecordedObject.new()
		robj.my_name = obj
		recorded_objects.append(robj)
	else:
		robj = recorded_objects[find_result]
	
	robj.positions.append(pos)
	robj.rotations.append(Vector4(rot.x, rot.y, rot.z, rot.w))

func add_label(label: String, time: float):
	LoggerGlobal.info("Label added: %s" % [label])
	var n = RecordedLabel.new()
	n.label = label
	n.time = time
	recorded_labels.append(n)

func get_index(timestep: float):
	return int(floor(sample_rate * timestep))

func get_time(index: int) -> float:
	return float(index) / sample_rate

func get_sample(obj: String, timestep: float):
	var index := int(floor(sample_rate * timestep))
	var robj := get_recorded_object(obj)
	index = min(index, len(robj.positions) - 1)
	return [robj.positions[index], robj.rotations[index]]

func get_sample_index(obj: String, index: int):
	var robj := get_recorded_object(obj)
	index = min(index, len(robj.positions) - 1)
	return [robj.positions[index], robj.rotations[index]]

## Returns a [PackedVector3Array, PackedVector4Array]
func get_many_samples(obj: String, start_index: int, end_index: int):
	var robj := get_recorded_object(obj)
	start_index = clamp(start_index, 0, len(robj.positions) - 1)
	end_index = clamp(end_index, 0, len(robj.positions) - 1)
	return [
		robj.positions.slice(start_index, end_index),
		robj.rotations.slice(start_index, end_index)
	]

func get_recorded_object(s: String) -> RecordedObject:
	var find_result = recorded_objects.find_custom(func(x): return x.my_name == s)
	if (find_result == -1):
		return null
	var robj := recorded_objects[find_result]
	return robj

func get_labels_between(from: float, to: float):
	var reverse := from > to
	if (reverse):
		var temp = from
		from = to
		to = temp

	var filtered = recorded_labels.filter(func(x: RecordedLabel): return x.time < to and x.time > from)

	filtered.sort_custom(func(a,b): return (a.time < b.time) == not reverse)
	return filtered
