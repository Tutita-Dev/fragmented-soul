
extends Control

func _on_level_1_pressed() -> void:
	GameManager.start_level(0)

func _on_level_2_pressed() -> void:
	GameManager.start_level(1)

func _on_level_3_pressed() -> void:
	GameManager.start_level(2)
