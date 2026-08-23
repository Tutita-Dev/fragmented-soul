class_name LightSystem
extends Node3D

const FRAGMENT_MASK := 2  # bit de Layer 2 (fragmentos + receptor)
const MAX_BOUNCES := 8
const MAX_RAY_DISTANCE := 100.0  # alcance real del raycast, no tocar por escala de nivel

@export var emitter: Node3D  # asignar en el inspector, el nodo del light_emitter


@export var miss_beam_length: float = 100

var beam_pool: Array[MeshInstance3D] = []
var beam_light_pool: Array[OmniLight3D] = []
var _needs_retrace := true

func _ready() -> void:
	PossessionManager.fragment_possessed.connect(_on_possession_changed)
	PossessionManager.fragment_released.connect(_on_possession_changed)
	
func _process(_delta: float) -> void:
	if emitter == null:
		return
	if _needs_retrace or PossessionManager.current_possessor.size() > 0:
		_retrace()

func _on_possession_changed(_a = null, _b = null) -> void:
	_needs_retrace = true

func _retrace() -> void:
	var segments: Array[Dictionary] = []
	_trace_recursive(
		emitter.global_position,
		-emitter.global_transform.basis.z,
		0,
		get_world_3d(),
		segments
	)
	_render_beams(segments)
	_needs_retrace = false

func _trace_recursive(origin: Vector3, direction: Vector3, bounce_count: int, world: World3D, out_segments: Array[Dictionary]) -> void:
	if bounce_count >= MAX_BOUNCES:
		return

	var space_state := world.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + direction.normalized() * MAX_RAY_DISTANCE
	)
	query.collision_mask = FRAGMENT_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := space_state.intersect_ray(query)

	if result.is_empty():
		out_segments.append({"from": origin, "to": origin + direction.normalized() * miss_beam_length})
		return

	out_segments.append({"from": origin, "to": result.position})

	var collider = result.collider

	if collider.is_in_group("light_receptor"):
		if collider.has_method("on_light_hit"):
			collider.on_light_hit()
		return

	if not (collider is StaticBody3D and "behavior" in collider):
		return  # golpeó algo sin behavior, corta acá

	var behavior: ReflectionBehavior = collider.behavior
	if behavior == null:
		return  # fragmento sin behavior asignado

	var new_dirs: Array[Vector3] = behavior.reflect_multi(direction, result.normal)
	for new_dir in new_dirs:
		_trace_recursive(result.position, new_dir, bounce_count + 1, world, out_segments)

func _render_beams(segments: Array[Dictionary]) -> void:
	while beam_pool.size() < segments.size():
		var mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05  # grosor placeholder; reemplazar en B8 con arte/shader real
		cyl.bottom_radius = 0.05
		cyl.height = 2.0
		
		# --- NUEVO: Material Emisivo ---
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.CYAN # El color base (ej: cian como en tu imagen)
		mat.emission_enabled = true
		mat.emission = Color.CYAN # El color de la luz que emite
		mat.emission_energy_multiplier = 4.0 # Qué tan fuerte brilla (ajustá a gusto)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Para que no le afecten las sombras
		
		cyl.material = mat
		# -------------------------------
		
		mesh.mesh = cyl
		add_child(mesh)
		beam_pool.append(mesh)

	for i in segments.size():
		var seg = segments[i]
		var beam = beam_pool[i]
		var light = _get_or_create_beam_light(i) # <-- Traemos la luz del pool
		
		beam.visible = true
		light.visible = true # <-- Encendemos la luz
		
		# Pasamos tanto la malla como la luz a la función de posicionamiento
		_position_beam_between(beam, light, seg["from"], seg["to"])

	# Ocultamos las mallas sobrantes
	for i in range(segments.size(), beam_pool.size()):
		beam_pool[i].visible = false
		
	# <-- NUEVO: Ocultamos las luces sobrantes
	for i in range(segments.size(), beam_light_pool.size()):
		beam_light_pool[i].visible = false

	for i in range(segments.size(), beam_pool.size()):
		beam_pool[i].visible = false
		

func _get_or_create_beam_light(index: int) -> OmniLight3D:
	if index >= beam_light_pool.size():
		var light := OmniLight3D.new()
		light.omni_range = 1.2
		light.omni_attenuation = 4.0
		light.light_energy = 1.5
		add_child(light)
		beam_light_pool.append(light)
	return beam_light_pool[index]
	

# Se agrega el parámetro 'light' a la firma
func _position_beam_between(beam: MeshInstance3D, light: OmniLight3D, from: Vector3, to: Vector3) -> void:
	var mid := (from + to) / 2.0
	var dist := from.distance_to(to)
	if dist < 0.001:
		beam.visible = false
		light.visible = false # <-- Apagamos la luz también por si acaso
		return
	var dir := (to - from) / dist  

	var up_ref := Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.99:
		up_ref = Vector3.RIGHT
		
	# --- INICIO DE LÓGICA DE MALLA (Fix B5 Intacto) ---
	beam.scale = Vector3.ONE

	beam.global_position = mid
	beam.look_at(to, up_ref)
	beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	beam.scale.y = dist / 2.0
	# --- FIN DE LÓGICA DE MALLA ---
	
	# --- INICIO DE LÓGICA DE LUZ (B8.6) ---
	light.global_position = to
	# Opcional si querés que la luz ilumine un poco más a lo largo en tramos largos:
	light.omni_range = 1.5
