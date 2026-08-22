extends StaticBody3D

## Se emite cada vez que el rayo impacta este receptor.
## game_manager.gd (Track A) se conecta a esta señal por nodo,
## no hay bus global — así soporta 1 o N receptores según defina B6.
signal light_received(receptor: StaticBody3D)

@export var receptor_id: String = ""

func _ready() -> void:
	add_to_group("light_receptor")
	collision_layer = 2
	collision_mask = 0 # no necesita detectar nada, solo ser detectado por el raycast
	
func on_light_hit() -> void:
	light_received.emit(self)
	_placeholder_feedback()

func _placeholder_feedback() -> void:
	var mesh := $MeshInstance3D as MeshInstance3D
	if mesh and mesh.get_surface_override_material(0):
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		mat.emission_energy_multiplier = 3.0
