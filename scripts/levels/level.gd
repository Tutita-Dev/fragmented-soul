extends Node3D 

@export var required_receptors: int = 1

func _ready() -> void:
	GameManager.setup_level(required_receptors)
