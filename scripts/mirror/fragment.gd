# scripts/mirror/fragment.gd
class_name Fragment
extends Node3D

@export var can_translate: bool = false
@export var translate_range: float = 2.0

var origin_position: Vector3

func _ready() -> void:
	origin_position = position

func translate_on_axis(axis_index: int, delta_amount: float) -> void:
	var new_val := position[axis_index] + delta_amount
	var min_val := origin_position[axis_index] - translate_range
	var max_val := origin_position[axis_index] + translate_range
	position[axis_index] = clamp(new_val, min_val, max_val)
