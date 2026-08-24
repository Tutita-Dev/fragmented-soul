# scripts/mirror/fragment.gd
@tool
class_name Fragment
extends Node3D

@export_group("Visual Mesh")
## Arrastra los archivos de malla (.mesh / .tres) a esta lista
@export var mesh_variants: Array[Mesh] = []
## Selecciona la variante a usar (0 a 9)
@export var selected_variant: int = 0:
	set(value):
		selected_variant = clamp(value, 0, max(0, mesh_variants.size() - 1))
		_update_mesh()

@export_group("Fragment Configuration")
@export var can_translate: bool = false:
	set(value):
		can_translate = value
		_update_range_gizmo()
@export var translate_range: float = 2.0:
	set(value):
		translate_range = value
		_update_range_gizmo()
@export var behavior: ReflectionBehavior

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D # ajustá la ruta si está en un hijo distinto (ej. $StaticBody3D/CollisionShape3D)

var origin_position: Vector3
var _range_gizmo: MeshInstance3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		origin_position = position

	_update_mesh()
	_update_range_gizmo()

# --- Lógica de actualización de malla ---
func _update_mesh() -> void:
	if not is_inside_tree():
		return

	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not collision_shape:
		collision_shape = get_node_or_null("Area3D/CollisionShape3D")

	if mesh_instance and mesh_variants.size() > selected_variant:
		var current_mesh: Mesh = mesh_variants[selected_variant]
		mesh_instance.mesh = current_mesh
		_update_collision(current_mesh)

func _update_collision(source_mesh: Mesh) -> void:
	if not collision_shape or not source_mesh:
		return

	var shape: Shape3D = source_mesh.create_convex_shape()
	collision_shape.shape = shape
	
# --- Gizmo de rango (solo editor, B5 paso 4) ---
func _update_range_gizmo() -> void:
	if not Engine.is_editor_hint():
		return
	if not can_translate:
		if _range_gizmo:
			_range_gizmo.visible = false
		return
	if not _range_gizmo:
		_range_gizmo = MeshInstance3D.new()
		_range_gizmo.mesh = ImmediateMesh.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 0.0, 0.6)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_range_gizmo.material_override = mat
		add_child(_range_gizmo)
		if Engine.is_editor_hint():
			_range_gizmo.owner = null # no se guarda en la escena
	_range_gizmo.visible = true
	var mesh: ImmediateMesh = _range_gizmo.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Eje X (P1)
	mesh.surface_add_vertex(Vector3(-translate_range, 0, 0))
	mesh.surface_add_vertex(Vector3(translate_range, 0, 0))
	# Eje Z (P2)
	mesh.surface_add_vertex(Vector3(0, 0, -translate_range))
	mesh.surface_add_vertex(Vector3(0, 0, translate_range))
	mesh.surface_end()
