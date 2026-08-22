class_name VariableAngleReflection
extends ReflectionBehavior

@export var angle_offset_deg: float = 0.0 # seteable por fragmento en el inspector

func reflect(incoming_dir: Vector3, normal: Vector3) -> Vector3:
	var base := incoming_dir.bounce(normal)
	return base.rotated(normal, deg_to_rad(angle_offset_deg))
