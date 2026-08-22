class_name SplitReflection
extends ReflectionBehavior

const SPLIT_ANGLE_DEG := 15.0

func reflect_multi(incoming_dir: Vector3, normal: Vector3) -> Array[Vector3]:
	var base := incoming_dir.bounce(normal)
	var axis := normal.cross(incoming_dir).normalized()
	if axis.length() < 0.01:
		axis = normal.cross(Vector3.UP).normalized()
	if axis.length() < 0.01:                                
		axis = normal.cross(Vector3.RIGHT).normalized()     
	var a := base.rotated(axis, deg_to_rad(SPLIT_ANGLE_DEG))
	var b := base.rotated(axis, deg_to_rad(-SPLIT_ANGLE_DEG))
	return [a, b]
