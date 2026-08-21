# scripts/player/player.gd
class_name Player
extends CharacterBody3D

enum State { FREE_FLY, POSSESSING }

@export var player_id: int = 1
@export var fly_speed: float = 6.0
@export var rotate_speed: float = 2.0

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
	velocity = input_provider.get_move_vector() * fly_speed
	move_and_slide()
	if input_provider.is_possess_just_pressed() and nearby_fragment:
		_try_possess(nearby_fragment)

func _process_possessing(delta: float) -> void:
	if input_provider.is_possess_just_pressed():
		_release_possession()
		return
	var axis_input := input_provider.get_axis_input()
	match player_id:
		1: possessed_fragment.rotate_x(axis_input * rotate_speed * delta)
		2: possessed_fragment.rotate_z(axis_input * rotate_speed * delta)

func _try_possess(fragment: Node3D) -> void:
	var fragment_id := str(fragment.get_path())
	if PossessionManager.try_possess(fragment_id, player_id):
		possessed_fragment = fragment
		state = State.POSSESSING
		visible = false
		set_physics_process(true)

func _release_possession() -> void:
	if possessed_fragment == null:
		return
	PossessionManager.release(str(possessed_fragment.get_path()))
	possessed_fragment = null
	state = State.FREE_FLY
	visible = true

func _on_possession_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("possessable"):
		nearby_fragment = area.get_parent()

func _on_possession_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("possessable") and area.get_parent() == nearby_fragment:
		nearby_fragment = null
