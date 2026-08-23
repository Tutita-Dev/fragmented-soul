class_name LightSystem
extends Node3D

const FRAGMENT_MASK := 2  # bit de Layer 2 (fragmentos + receptor)
const MAX_BOUNCES := 8
const MAX_RAY_DISTANCE := 100.0  # alcance real del raycast, no tocar por escala de nivel

@export var emitter: Node3D  # asignar en el inspector, el nodo del light_emitter


@export var miss_beam_length: float = 100

var beam_pool: Array[MeshInstance3D] = []
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
		mesh.mesh = cyl
		add_child(mesh)
		beam_pool.append(mesh)

	for i in segments.size():
		var seg = segments[i]
		var beam = beam_pool[i]
		beam.visible = true
		_position_beam_between(beam, seg["from"], seg["to"])

	for i in range(segments.size(), beam_pool.size()):
		beam_pool[i].visible = false

func _position_beam_between(beam: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var mid := (from + to) / 2.0
	var dist := from.distance_to(to)
	if dist < 0.001:
		beam.visible = false
		return
	var dir := (to - from) / dist  

	var up_ref := Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.99:
		up_ref = Vector3.RIGHT
		
	beam.scale = Vector3.ONE

	beam.global_position = mid
	beam.look_at(to, up_ref)
	beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	beam.scale.y = dist / 2.0
