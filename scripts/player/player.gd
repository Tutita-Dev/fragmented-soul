# scripts/player/player.gd
class_name Player
extends CharacterBody3D

enum State { FREE_FLY, POSSESSING }

@export var player_id: int = 1
@export var turn_speed: float = 2.5  # rad/s

@export var fly_speed: float = 6.0
@export var rotate_speed: float = 2.0
@export var translate_speed: float = 3.0


var state: State = State.FREE_FLY
var possessed_fragment: Node3D = null
var nearby_fragment: Node3D = null

@onready var input_provider: InputProvider = $PossessionArea/InputProvider

func _ready() -> void:
	input_provider.player_id = player_id

func _physics_process(delta: float) -> void:
	match state:
		State.FREE_FLY:
			_process_free_fly()
		State.POSSESSING:
			_process_possessing(delta)

func _process_free_fly() -> void:
	var turn_input := input_provider.get_axis_input()
	rotate_y(-turn_input * turn_speed * get_physics_process_delta_time())

	var forward_input := input_provider.get_forward_input()
	var vertical_input := input_provider.get_vertical_input()

	var move_dir := -global_transform.basis.z * forward_input
	move_dir.y = vertical_input

	velocity = move_dir * fly_speed
	move_and_slide()

	if input_provider.is_possess_just_pressed() and nearby_fragment:
		_try_possess(nearby_fragment)

func _process_possessing(delta: float) -> void:
	if input_provider.is_possess_just_pressed():
		_release_possession()
		return

	var rotate_input := input_provider.get_rotate_input()
	match player_id:
		1: possessed_fragment.rotate_x(rotate_input * rotate_speed * delta)
		2: possessed_fragment.rotate_z(rotate_input * rotate_speed * delta)

	if possessed_fragment.can_translate:
		var translate_input := input_provider.get_translate_input()
		var axis_index := 0 if player_id == 1 else 2
		possessed_fragment.translate_on_axis(axis_index, translate_input * translate_speed * delta)


func _try_possess(fragment: Node3D) -> void:
	var fragment_id := str(fragment.get_path())
	possessed_fragment = fragment
	state = State.POSSESSING
	if PossessionManager.try_possess(fragment_id, player_id):
		visible = false
	else:
		possessed_fragment = null
		state = State.FREE_FLY

func _release_possession() -> void:
	if possessed_fragment == null:
		return
	var fragment_id := str(possessed_fragment.get_path())
	global_position = possessed_fragment.global_position
	possessed_fragment = null
	state = State.FREE_FLY
	visible = true
	PossessionManager.release(fragment_id)

func _on_possession_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("possessable"):
		nearby_fragment = area.get_parent()

func _on_possession_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("possessable") and area.get_parent() == nearby_fragment:
		nearby_fragment = null

func get_camera_target() -> Node3D:
	if state == State.POSSESSING and possessed_fragment:
		return possessed_fragment
	return self
