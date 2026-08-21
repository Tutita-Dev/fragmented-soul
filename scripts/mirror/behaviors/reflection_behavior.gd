# scripts/mirror/behaviors/reflection_behavior.gd
class_name ReflectionBehavior
extends Resource

## Recibe la dirección entrante y la normal de colisión real.
## Devuelve un Array[Vector3] de direcciones salientes 
## (1 elemento en Simple/VariableAngle, 2 en Split).
func reflect(incoming_dir: Vector3, normal: Vector3) -> Array:
	push_error("reflect() no implementado en clase base")
	return []
