# scripts/mirror/behaviors/simple_reflection.gd
class_name SimpleReflection
extends ReflectionBehavior

func reflect(incoming_dir: Vector3, normal: Vector3) -> Array:
	var reflected := incoming_dir.bounce(normal)
	return [reflected]
