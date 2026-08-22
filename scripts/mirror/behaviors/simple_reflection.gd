# scripts/mirror/behaviors/simple_reflection.gd
class_name SimpleReflection
extends ReflectionBehavior

func reflect(incoming_dir: Vector3, normal: Vector3) -> Vector3:
	return incoming_dir.bounce(normal) # reflexión especular estándar
