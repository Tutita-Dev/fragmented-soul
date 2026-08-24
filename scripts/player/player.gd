# scripts/player/player.gd
@tool
class_name Player
extends CharacterBody3D

enum State { FREE_FLY, POSSESSING }

@export_group("Player Identity")
@export var player_id: int = 1:
	set(value):
		player_id = value
		_update_visuals_safe()

@export_group("Movement")
@export var turn_speed: float = 2.5
@export var fly_speed: float = 6.0
@export var rotate_speed: float = 2.0
@export var translate_speed: float = 3.0

@export_group("Player Visual Overrides")
@export var player_color: Color = Color(0.0, 0.89, 1.0, 1.0):
	set(v): player_color = v; _update_visuals_safe()
@export var core_color: Color = Color.WHITE:
	set(v): core_color = v; _update_visuals_safe()
@export var core_emission_energy: float = 18.0:
	set(v): core_emission_energy = v; _update_visuals_safe()
@export var halo_alpha_free: float = 0.3:
	set(v): halo_alpha_free = v; _update_visuals_safe()
@export var halo_emission_free: float = 7.0:
	set(v): halo_emission_free = v; _update_visuals_safe()

@export_group("Shared Possession Visuals")
@export var halo_alpha_possess: float = 0.15
@export var halo_emission_possess: float = 4.0
@export var light_energy: float = 2.0:
	set(v): light_energy = v; _update_visuals_safe()
@export var light_range: float = 5.0:
	set(v): light_range = v; _update_visuals_safe()

# Referencias a los nodos visuales
@onready var soul_core: MeshInstance3D = $Soul_Orb_Asset.get_node_or_null("Soul_Core")
@onready var soul_halo: MeshInstance3D = $Soul_Orb_Asset.get_node_or_null("Soul_Halo")
@onready var particles: GPUParticles3D = $Soul_Orb_Asset.get_node_or_null("GPUParticles3D")
@onready var orb_light: OmniLight3D = $Soul_Orb_Asset.get_node_or_null("OmniLight3D")

var state: State = State.FREE_FLY
var possessed_fragment: Node3D = null
var nearby_fragment: Node3D = null

@onready var input_provider: InputProvider = get_node_or_null("PossessionArea/InputProvider")

func _ready() -> void:
	# Cargar colores por defecto según ID al instanciar si no fueron modificados
	if player_id == 2 and player_color == Color(0.0, 0.89, 1.0, 1.0):
		player_color = Color(1.0, 0.2, 0.651, 1.0)

	_setup_player_visuals()

	if Engine.is_editor_hint():
		return

	if input_provider:
		if input_provider.has_method("set_player_id"):
			input_provider.set_player_id(player_id)
		else:
			input_provider.player_id = player_id

func _update_visuals_safe() -> void:
	if is_node_ready():
		_setup_player_visuals()
		
		# Si estamos dentro del editor de Godot, forzamos al viewport a redibujar
		if Engine.is_editor_hint():
			notify_property_list_changed()
			
			# Redibujar la escena activa en el editor
			var main_screen = EditorInterface.get_editor_main_screen() if Engine.has_singleton("EditorInterface") else null
			if soul_core:
				soul_core.update_gizmos()
			if soul_halo:
				soul_halo.update_gizmos()

# --- LÓGICA DE VISUALES Y COLORES ---
func _setup_player_visuals() -> void:
	# 1. Configurar Núcleo (Soul_Core)
	if soul_core:
		soul_core.visible = (state == State.FREE_FLY)
		var core_mat: StandardMaterial3D = _get_unique_material(soul_core)
		core_mat.albedo_color = core_color
		core_mat.emission_enabled = true
		core_mat.emission = core_color
		core_mat.emission_energy_multiplier = core_emission_energy

	# 2. Configurar Halo (Soul_Halo)
	if soul_halo:
		soul_halo.visible = true
		var halo_mat: StandardMaterial3D = _get_unique_material(soul_halo)
		halo_mat.albedo_color = Color(player_color.r, player_color.g, player_color.b, halo_alpha_free)
		halo_mat.emission_enabled = true
		halo_mat.emission = player_color
		halo_mat.emission_energy_multiplier = halo_emission_free

	# 3. Configurar Partículas (GPUParticles3D)
	if particles:
		particles.emitting = (state == State.FREE_FLY)

	# 4. Configurar Luz (OmniLight3D)
	if orb_light:
		orb_light.light_color = player_color
		orb_light.light_energy = light_energy
		orb_light.omni_range = light_range

func _get_unique_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var mat = mesh.get_surface_override_material(0)
	
	# Si no existe material único en el surface override, creamos/duplicamos uno exclusivo para esta instancia
	if not mat:
		var active_mat = mesh.get_active_material(0)
		if active_mat:
			mat = active_mat.duplicate()
		else:
			mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
	elif not mat.is_local_to_scene():
		# Forzamos duplicación si el material está compartido entre nodos
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)

	if mat is StandardMaterial3D and mesh == soul_halo:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		
	return mat

# --- PROCESO PRINCIPAL DE FÍSICA Y ESTADOS ---
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	match state:
		State.FREE_FLY:
			_process_free_fly()
		State.POSSESSING:
			_process_possessing(delta)

func _process_free_fly() -> void:
	if not input_provider:
		return

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
	if not input_provider:
		return

	if input_provider.is_possess_just_pressed():
		_release_possession()
		return

	var rotate_input := input_provider.get_rotate_input()
	match player_id:
		1: possessed_fragment.rotate_x(rotate_input * rotate_speed * delta)
		2: possessed_fragment.rotate_y(rotate_input * rotate_speed * delta)

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
			_fit_halo_to_fragment(possessed_fragment)
			
			var halo_mat = soul_halo.get_surface_override_material(0)
			if halo_mat is StandardMaterial3D:
				halo_mat.emission_energy_multiplier = halo_emission_possess
				halo_mat.albedo_color = Color(player_color.r, player_color.g, player_color.b, halo_alpha_possess)
				
		if orb_light:
			orb_light.reparent(possessed_fragment)
			orb_light.position = Vector3.ZERO
	else:
		possessed_fragment = null
		state = State.FREE_FLY

func _release_possession() -> void:
	if possessed_fragment == null:
		return
		
	if soul_halo:
		soul_halo.reparent($Soul_Orb_Asset)
		soul_halo.position = Vector3.ZERO
		soul_halo.scale = Vector3.ONE
		
		var halo_mat = soul_halo.get_surface_override_material(0)
		if halo_mat is StandardMaterial3D:
			halo_mat.emission_energy_multiplier = halo_emission_free
			halo_mat.albedo_color = Color(player_color.r, player_color.g, player_color.b, halo_alpha_free)
	
	if orb_light:
		orb_light.reparent($Soul_Orb_Asset)
		orb_light.position = Vector3.ZERO
		
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

	var core_min_size: float = 1.0
	if soul_core and soul_core.mesh:
		var core_aabb: AABB = soul_core.mesh.get_aabb()
		var core_scale: Vector3 = soul_core.global_transform.basis.get_scale()
		core_min_size = (core_aabb.size * core_scale).length()

	if mesh_inst and mesh_inst.mesh:
		var aabb: AABB = mesh_inst.mesh.get_aabb()
		var scale_vector: Vector3 = mesh_inst.global_transform.basis.get_scale()
		var max_dimension: float = (aabb.size * scale_vector).length()
		
		var calculated_scale: float = max_dimension * 0.4
		var final_scale: float = maxf(core_min_size, calculated_scale)
		soul_halo.scale = Vector3.ONE * final_scale
	else:
		var fallback_scale: float = maxf(core_min_size, target_fragment.scale.length() * 1.5)
		soul_halo.scale = Vector3.ONE * fallback_scale

# --- DETECCIÓN DE ÁREAS ---
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
