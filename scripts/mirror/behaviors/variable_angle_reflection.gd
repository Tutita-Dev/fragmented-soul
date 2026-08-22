class_name VariableAngleReflection
extends ReflectionBehavior

@export var angle_offset_deg: float = 0.0 # seteable por fragmento en el inspector

func reflect_multi(dir: Vector3, normal: Vector3) -> Array[Vector3]:
	var reflected: Vector3 = dir.bounce(normal)
	var offset_rad: float = deg_to_rad(angle_offset_deg)
	var final_dir: Vector3 = reflected.rotated(normal.normalized(), offset_rad)
	return [final_dir]
