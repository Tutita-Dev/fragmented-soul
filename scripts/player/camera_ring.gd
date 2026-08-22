# scripts/player/camera_rig.gd
extends Node

@export var player1: Player
@export var player2: Player

@onready var spring_arm_p1: SpringArm3D = $HBoxContainer/SubViewportContainerP1/SubViewport/SpringArm3D
@onready var spring_arm_p2: SpringArm3D = $HBoxContainer/SubViewportContainerP2/SubViewport/SpringArm3D

func _ready() -> void:
	PossessionManager.fragment_possessed.connect(_on_possession_changed)
	PossessionManager.fragment_released.connect(_on_possession_changed)
	
	spring_arm_p1.player = player1
	spring_arm_p2.player = player2
	_refresh_targets()

func _on_possession_changed(_a = null, _b = null) -> void:
	_refresh_targets()

func _refresh_targets() -> void:
	spring_arm_p1.set_target(player1.get_camera_target())
	spring_arm_p2.set_target(player2.get_camera_target())
