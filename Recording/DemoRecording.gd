class_name DemoRecording
extends Resource

@export var sample_rate := 60
@export var recorded_objects: Array[RecordedObject] = []
@export var recorded_labels: Array[RecordedLabel]

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


func get_sample(obj: String, timestep: float):
	var index := int(floor(sample_rate * timestep))
	var find_result = recorded_objects.find_custom(func(x): return x.my_name == obj)
	if (find_result == -1):
		return null
	var robj := recorded_objects[find_result]
	index = min(index, len(robj.positions))
	return [robj.positions[index], robj.rotations[index]]
