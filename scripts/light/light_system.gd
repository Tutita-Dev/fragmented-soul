class_name LightSystem
extends Node3D

const FRAGMENT_MASK := 2  # bit de Layer 2 (fragmentos + receptor)
const ENVIRONMENT_MASK := 4  # bit de Layer 3 (piso, paredes, geometría de nivel)
const MAX_BOUNCES := 8
const MAX_RAY_DISTANCE := 100.0  # alcance real del raycast, no tocar por escala de nivel

@export var emitter: Node3D  # asignar en el inspector, el nodo del light_emitter


@export var miss_beam_length: float = 100

var beam_pool: Array[MeshInstance3D] = []
var beam_light_pool: Array[OmniLight3D] = []

# Pool bidimensional: cada segmento del rayo tendrá su propia sub-lista de luces alineadas
#var beam_light_pool: Array[Array] = []

var _needs_retrace := true



const BEAM_LIGHT_SPACING := 2.0     # distancia deseada entre luces (ajustar a gusto)
const BEAM_LIGHT_MAX_PER_SEGMENT := 6  # tope de seguridad, performance



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
	query.collision_mask = FRAGMENT_MASK | ENVIRONMENT_MASK
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

#func _render_beams(segments: Array[Dictionary]) -> void:
	#while beam_pool.size() < segments.size():
		#var mesh := MeshInstance3D.new()
		#var cyl := CylinderMesh.new()
		#cyl.top_radius = 0.05
		#cyl.bottom_radius = 0.05
		#cyl.height = 2.0
		#
		## Material emisivo del cilindro
		#var mat := StandardMaterial3D.new()
		#mat.albedo_color = Color("fff5d6")
		#mat.emission_enabled = true
		#mat.emission = Color("fff5d6")
		#mat.emission_energy_multiplier = 4.0
		#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		#cyl.material = mat
		#
		#mesh.mesh = cyl
		#add_child(mesh)
		#beam_pool.append(mesh)
#
	## 1. Primero, ocultamos TODAS las luces del pool globalmente para evitar que arrastren estados viejos
	#for segment_lights in beam_light_pool:
		#for light in segment_lights:
			#(light as OmniLight3D).visible = false
#
	## 2. Renderizamos cada segmento activo y sus respectivas luces
	#for i in segments.size():
		#var seg = segments[i]
		#var beam = beam_pool[i]
		#beam.visible = true
		#
		#var dist = seg["from"].distance_to(seg["to"])
		#var light_count = clampi(int(ceil(dist / BEAM_LIGHT_SPACING)), 1, BEAM_LIGHT_MAX_PER_SEGMENT)
		#var segment_lights = _get_or_create_beam_lights_for_segment(i, light_count)
#
		#_position_beam_between(beam, segment_lights, seg["from"], seg["to"], dist, light_count)
#
	## 3. Ocultar mallas de segmentos sobrantes
	#for i in range(segments.size(), beam_pool.size()):
		#beam_pool[i].visible = false
		#


func _render_beams(segments: Array[Dictionary]) -> void:
	while beam_pool.size() < segments.size():
		var mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05  # grosor placeholder; reemplazar en B8 con arte/shader real
		cyl.bottom_radius = 0.05
		cyl.height = 2.0
		
		# --- NUEVO: Material Emisivo ---
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE # El color base (ej: cian como en tu imagen)
		mat.emission_enabled = true
		mat.emission = Color.WHITE # El color de la luz que emite
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

#func _get_or_create_beam_lights_for_segment(segment_index: int, required_count: int) -> Array:
	#if segment_index >= beam_light_pool.size():
		#beam_light_pool.append([])
	#
	#var segment_lights: Array = beam_light_pool[segment_index]
	#
	#while segment_lights.size() < required_count:
		#var light := OmniLight3D.new()
		#light.omni_range = 4.0      # Rango individual más acotado para no pasarnos de brillo
		#light.light_energy = 2.5      # Energía equilibrada
		#light.omni_attenuation = 1.5
		#light.light_color = Color("fff5d6") # Tu color de "luz pura"
		#add_child(light)
		#segment_lights.append(light)
		#
	#return segment_lights

func _get_or_create_beam_light(index: int) -> OmniLight3D:
	if index >= beam_light_pool.size():
		var light := OmniLight3D.new()
		# 1. Aumentamos el radio para que la luz alcance el piso y el entorno
		light.omni_range = 10
		
		# 2. Subimos la energía para que el brillo se note más
		light.light_energy = 5
		
		# 3. Suavizamos la caída de la luz (atenuación)
		light.omni_attenuation = 2
		
		# 4. Le asignamos el color de tu "luz pura"
		light.light_color = Color("fff5d6")
		
		# IMPORTANTE: Forzamos que la luz afecte a todas las capas visuales (Layer 1 a 32)
		light.light_cull_mask = 0xFFFFFFFF
		
		add_child(light)
		beam_light_pool.append(light)
	return beam_light_pool[index]
	

#func _position_beam_between(beam: MeshInstance3D, lights: Array, from: Vector3, to: Vector3, dist: float, light_count: int) -> void:
	#if dist < 0.001:
		#beam.visible = false
		#for l in lights:
			#(l as OmniLight3D).visible = false
		#return
		#
	#var mid := (from + to) / 2.0
	#var dir := (to - from) / dist  
#
	#var up_ref := Vector3.UP
	#if absf(dir.dot(Vector3.UP)) > 0.99:
		#up_ref = Vector3.RIGHT
		#
	## Posicionar la malla (Fix B5 intacto)
	#beam.scale = Vector3.ONE
	#beam.global_position = mid
	#beam.look_at(to, up_ref)
	#beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	#beam.scale.y = dist / 2.0
	#
	## Mostrar y distribuir SOLO las light_count necesarias
	#for j in range(lights.size()):
		#var light: OmniLight3D = lights[j]
		#if j >= light_count:
			#light.visible = false   # <- esto es lo que faltaba: apaga las sobrantes del array viejo
			#continue
		#light.visible = true
		#if light_count == 1:
			#light.global_position = mid
		#else:
			#var t = float(j) / float(light_count - 1)
			#light.global_position = from.lerp(to, t)

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
	light.omni_range = 100
	
	
	
