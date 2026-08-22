# scripts/mirror/behaviors/reflection_behavior.gd
class_name ReflectionBehavior
extends Resource

## Recibe la dirección entrante y la normal de colisión real.
## Devuelve un Array[Vector3] de direcciones salientes 
## (1 elemento en Simple/VariableAngle, 2 en Split).
func reflect(incoming_dir: Vector3, normal: Vector3) -> Vector3:
	return incoming_dir.bounce(normal) # fallback, las subclases sobreescriben
	
