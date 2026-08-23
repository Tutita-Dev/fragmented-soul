# scripts/player/player.gd
class_name Player
extends CharacterBody3D

enum State { FREE_FLY, POSSESSING }

@export_group("Player Configuration")
@export var player_id: int = 1
@export var turn_speed: float = 2.5   # rad/s
@export var fly_speed: float = 6.0
@export var rotate_speed: float = 2.0
@export var translate_speed: float = 3.0

@export_group("Visual Settings")
@export var color_player_1: Color = Color(0.0, 0.89, 1.0, 1.0) # Azul / Cian
@export var color_player_2: Color = Color(1.0, 0.2, 0.651, 1.0) # Rojo / Magenta

# Referencias a los nodos visuales
@onready var soul_core: MeshInstance3D = $Soul_Orb_Asset/Soul_Core
@onready var soul_halo: MeshInstance3D = $Soul_Orb_Asset/Soul_Halo
@onready var particles: GPUParticles3D = $Soul_Orb_Asset/GPUParticles3D

var state: State = State.FREE_FLY
var possessed_fragment: Node3D = null
var nearby_fragment: Node3D = null

@onready var input_provider: InputProvider = $PossessionArea/InputProvider

func _ready() -> void:
	if input_provider:
		if input_provider.has_method("set_player_id"):
			input_provider.set_player_id(player_id)
		else:
			input_provider.player_id = player_id
			
	_setup_player_visuals()

# --- LÓGICA DE VISUALES Y COLORES ---
func _setup_player_visuals() -> void:
	var target_color := color_player_1 if player_id == 1 else color_player_2
	
	# 1. Configurar Núcleo (Soul_Core)
	if soul_core:
		var core_mat: StandardMaterial3D = _get_unique_material(soul_core)
		core_mat.albedo_color = Color.WHITE
		core_mat.emission_enabled = true
		core_mat.emission = target_color
		core_mat.emission_energy_multiplier = 18.0

	# 2. Configurar Halo (Soul_Halo)
	if soul_halo:
		var halo_mat: StandardMaterial3D = _get_unique_material(soul_halo)
		halo_mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.3)
		halo_mat.emission_enabled = true
		halo_mat.emission = target_color
		halo_mat.emission_energy_multiplier = 7.0

	# 3. Configurar Partículas (GPUParticles3D)
	if particles:
		particles.emitting = true

func _get_unique_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var mat = mesh.get_surface_override_material(0)
	if not mat and mesh.mesh:
		mat = mesh.mesh.surface_get_material(0)
	
	if mat:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
	else:
		mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
		
	return mat as StandardMaterial3D

# --- PROCESO PRINCIPAL DE FÍSICA Y ESTADOS ---
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

# --- POSESIÓN Y LIBERACIÓN ---
func _try_possess(fragment: Node3D) -> void:
	var fragment_id := str(fragment.get_path())
	possessed_fragment = fragment
	state = State.POSSESSING
	
	if PossessionManager.try_possess(fragment_id, player_id):
		if soul_core: 
			soul_core.visible = false
		if particles: 
			particles.emitting = false
		
		if soul_halo:
			soul_halo.reparent(possessed_fragment)
			soul_halo.position = Vector3.ZERO
			
			# Adapta la escala del Halo según el tamaño real de la malla/fragmento
			_fit_halo_to_fragment(possessed_fragment)
			
			var halo_mat = soul_halo.get_surface_override_material(0)
			if halo_mat is StandardMaterial3D:
				halo_mat.emission_energy_multiplier = 4.0
				var target_color := color_player_1 if player_id == 1 else color_player_2
				halo_mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.15)
	else:
		possessed_fragment = null
		state = State.FREE_FLY

func _release_possession() -> void:
	if possessed_fragment == null:
		return
		
	if soul_halo:
		soul_halo.reparent($Soul_Orb_Asset)
		soul_halo.position = Vector3.ZERO
		soul_halo.scale = Vector3.ONE  # Restablece la escala original del Halo
		
		var halo_mat = soul_halo.get_surface_override_material(0)
		if halo_mat is StandardMaterial3D:
			var target_color := color_player_1 if player_id == 1 else color_player_2
			halo_mat.emission_energy_multiplier = 7.0
			halo_mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.3)
		
	if soul_core: 
		soul_core.visible = true
	if particles: 
		particles.emitting = true
	
	var fragment_id := str(possessed_fragment.get_path())
	global_position = possessed_fragment.global_position
	possessed_fragment = null
	state = State.FREE_FLY
	PossessionManager.release(fragment_id)

		# --- CÁLCULO DE TAMAÑO PARA EL HALO ---
func _fit_halo_to_fragment(target_fragment: Node3D) -> void:
	var mesh_inst: MeshInstance3D = target_fragment.get_node_or_null("MeshInstance3D")
	
	if not mesh_inst:
		for child in target_fragment.get_children():
			if child is MeshInstance3D and child.visible:
				mesh_inst = child
				break

	# 1. Calculamos la dimensión mínima basada en el Soul_Core
	var core_min_size: float = 1.0
	if soul_core and soul_core.mesh:
		var core_aabb: AABB = soul_core.mesh.get_aabb()
		var core_scale: Vector3 = soul_core.global_transform.basis.get_scale()
		core_min_size = (core_aabb.size * core_scale).length()

	if mesh_inst and mesh_inst.mesh:
		var aabb: AABB = mesh_inst.mesh.get_aabb()
		var scale_vector: Vector3 = mesh_inst.global_transform.basis.get_scale()
		var max_dimension: float = (aabb.size * scale_vector).length()
		
		# 2. Si la dimensión del fragmento es menor a la del núcleo, no se achica
		var calculated_scale: float = max_dimension * 0.4
		var final_scale: float = maxf(core_min_size, calculated_scale)
		
		var desired_scale := Vector3.ONE * final_scale
		soul_halo.scale = desired_scale
	else:
		var fallback_scale: float = maxf(core_min_size, target_fragment.scale.length() * 1.5)
		soul_halo.scale = Vector3.ONE * fallback_scale


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
