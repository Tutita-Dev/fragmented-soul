# scripts/player/input_provider.gd
class_name InputProvider
extends Node

var player_id: int = 1

var _actions: Dictionary = {}

func _ready() -> void:
	_build_actions()

func _build_actions() -> void:
	var prefix := "p%d_" % player_id
	_actions = {
		"forward": prefix + "forward",
		"back": prefix + "back",
		"left": prefix + "left",
		"right": prefix + "right",
		"up": prefix + "up",
		"down": prefix + "down",
		"possess": prefix + "possess",
	}

func rebind_action(logical_action: String, event: InputEvent) -> bool:
	if not _actions.has(logical_action):
		push_warning("InputProvider: acción lógica desconocida: %s" % logical_action)
		return false
	var action_name: String = _actions[logical_action]
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	return true

func get_current_event_text(logical_action: String) -> String:
	if not _actions.has(logical_action):
		return "—"
	var events := InputMap.action_get_events(_actions[logical_action])
	return events[0].as_text() if events.size() > 0 else "—"

func get_move_vector() -> Vector3:
	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength(_actions.right) - Input.get_action_strength(_actions.left)
	dir.y = Input.get_action_strength(_actions.up) - Input.get_action_strength(_actions.down)
	dir.z = Input.get_action_strength(_actions.back) - Input.get_action_strength(_actions.forward)
	return dir if dir.length() <= 1.0 else dir.normalized()

func get_axis_input() -> float:
	return Input.get_action_strength(_actions.right) - Input.get_action_strength(_actions.left)

func is_possess_just_pressed() -> bool:
	return Input.is_action_just_pressed(_actions.possess)

func get_rotate_input() -> float:
	return Input.get_action_strength(_actions.up) - Input.get_action_strength(_actions.down)

func get_translate_input() -> float:
	if player_id == 1:
		return Input.get_action_strength(_actions.right) - Input.get_action_strength(_actions.left)
	else:
		return Input.get_action_strength(_actions.forward) - Input.get_action_strength(_actions.back)

func get_forward_input() -> float:
	return Input.get_action_strength(_actions.forward) - Input.get_action_strength(_actions.back)

func get_vertical_input() -> float:
	return Input.get_action_strength(_actions.up) - Input.get_action_strength(_actions.down)
	
func set_player_id(id: int) -> void:
	player_id = id
	_build_actions()
	
func get_action_name(logical_action: String) -> String:
	return _actions.get(logical_action, "")
