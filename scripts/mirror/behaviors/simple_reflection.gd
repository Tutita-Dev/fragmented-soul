# simple_reflection.gd
extends ReflectionBehavior
class_name SimpleReflection

func reflect_multi(dir: Vector3, normal: Vector3) -> Array[Vector3]:
	var reflected: Vector3 = dir.bounce(normal)
	return [reflected]
