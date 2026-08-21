# autoloads/possession_manager.gd
extends Node

var current_possessor: Dictionary = {} # fragment_id (String) -> player_id (int)

signal fragment_possessed(fragment_id: String, player_id: int)
signal fragment_released(fragment_id: String)

@export var allow_multi_possession: bool = false

func try_possess(fragment_id: String, player_id: int) -> bool:
	if current_possessor.has(fragment_id) and not allow_multi_possession:
		return false
	current_possessor[fragment_id] = player_id
	fragment_possessed.emit(fragment_id, player_id)
	return true

func release(fragment_id: String) -> void:
	if current_possessor.has(fragment_id):
		current_possessor.erase(fragment_id)
		fragment_released.emit(fragment_id)
