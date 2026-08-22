# scripts/mirror/behaviors/reflection_behavior.gd
class_name ReflectionBehavior
extends Resource

## Recibe la dirección entrante y la normal de colisión real.
## Devuelve un Array[Vector3] de direcciones salientes 
## (1 elemento en Simple/VariableAngle, 2 en Split).
func reflect_multi(_dir: Vector3, _normal: Vector3) -> Array[Vector3]:
	push_error("reflect_multi no implementado en behavior base")
	return []
