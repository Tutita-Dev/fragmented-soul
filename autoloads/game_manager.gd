extends Node

## Autoload — punto de integración entre Track A y Track B.
## Track B (light_system, fragments, receptors) solo lee/emite señales acá,
## no edita este archivo directamente.

signal level_completed

## true una vez que el nivel actual se considera completo.
## Debounce simple para no reprocesar en cada frame que el rayo sigue
## tocando el/los receptor(es) (light_received se emite cada frame, sin
## edge-trigger propio del lado de B4).
var _level_completed: bool = false

## Cuántos receptores distintos necesitan estar "lit" para completar
## el nivel actual. Default 1 (caso simple). B6 puede ajustar esto por
## nivel si hace falta más de un receptor.
var _required_receptors: int = 1
var _lit_receptors: Dictionary = {} # receptor: true

## Orden de niveles para la transición automática al completar cada uno.
## Asignar en el Inspector del autoload (Project Settings → Autoload → GameManager),
## o dejar el default de acá si los paths coinciden.
@export var level_paths: Array[String] = [
	"res://scenes/levels/level1.tscn",
	"res://scenes/levels/level2.tscn",
	"res://scenes/levels/level3.tscn",
]
var _current_level_index: int = 0


func _ready() -> void:
	# Se llama de nuevo cada vez que se carga un nivel (ver setup_level).
	level_completed.connect(_on_level_completed)


## Llamar esto al terminar de cargar/instanciar un nivel, desde donde
## sea que Track A maneje la carga de niveles (aún no implementado —
## ajustar el lugar del llamado cuando exista ese flujo).
func setup_level(required_receptors: int = 1) -> void:
	_level_completed = false
	_lit_receptors.clear()
	_required_receptors = required_receptors
	_connect_level_receptors()


func _connect_level_receptors() -> void:
	for receptor in get_tree().get_nodes_in_group("light_receptor"):
		if not receptor.light_received.is_connected(_on_receptor_hit):
			receptor.light_received.connect(_on_receptor_hit)


func _on_receptor_hit(receptor: StaticBody3D) -> void:
	if _level_completed:
		return

	_lit_receptors[receptor] = true

	if _lit_receptors.size() >= _required_receptors:
		_level_completed = true
		level_completed.emit()


func _on_level_completed() -> void:
	await get_tree().create_timer(2.0).timeout
	_current_level_index += 1
	if _current_level_index < level_paths.size():
		get_tree().change_scene_to_file(level_paths[_current_level_index])
	else:
		print("Juego completo")  # placeholder, sin pantalla final por scope

func start_level(index: int) -> void:
	_current_level_index = index
	get_tree().change_scene_to_file(level_paths[index])
	
	
