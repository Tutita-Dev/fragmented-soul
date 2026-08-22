# scripts/player/input_provider.gd
class_name InputProvider
extends Node

var player_id: int = 1

func get_move_vector() -> Vector3:
	var prefix := "p%d_" % player_id
	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")
	dir.y = Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")
	dir.z = Input.get_action_strength(prefix + "back") - Input.get_action_strength(prefix + "forward")
	return dir if dir.length() <= 1.0 else dir.normalized()

func get_axis_input() -> float:
	var prefix := "p%d_" % player_id
	return Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")

func is_possess_just_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_possess" % player_id)

func get_rotate_input() -> float:
	var prefix := "p%d_" % player_id
	return Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")

func get_translate_input() -> float:
	var prefix := "p%d_" % player_id
	if player_id == 1:
		return Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")
	else:
		return Input.get_action_strength(prefix + "forward") - Input.get_action_strength(prefix + "back")

func get_forward_input() -> float:
	var prefix := "p%d_" % player_id
	return Input.get_action_strength(prefix + "forward") - Input.get_action_strength(prefix + "back")

func get_vertical_input() -> float:
	var prefix := "p%d_" % player_id
	return Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")
