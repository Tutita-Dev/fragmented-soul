# autoloads/possession_manager.gd
extends Node

var current_possessor: Dictionary = {} # fragment_id -> player_id
signal fragment_possessed(fragment_id, player_id)
signal fragment_released(fragment_id)
