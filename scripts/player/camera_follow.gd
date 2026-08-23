extends SpringArm3D

@export var target: Node3D
@export var player: Player
@export var height_offset: float = 1.5
@export var follow_speed: float = 8.0
@export var rotation_speed: float = 6.0

func _ready() -> void:
	spring_length = 10.0 # Estaba en 4.0, sube a 7.0 u 8.0 para alejarla

func _process(delta: float) -> void:
	if not target or not player:
		return

	var desired_pos := target.global_position + Vector3(0, height_offset, 0)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	rotation.y = lerp_angle(rotation.y, player.rotation.y, rotation_speed * delta)

func set_target(new_target: Node3D) -> void:
	target = new_target
	if new_target is CharacterBody3D:
		add_excluded_object(new_target.get_rid())
