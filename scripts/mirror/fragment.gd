# scripts/mirror/fragment.gd
@tool
class_name Fragment
extends Node3D

@export var can_translate: bool = false:
	set(value):
		can_translate = value
		_update_range_gizmo()

@export var translate_range: float = 2.0:
	set(value):
		translate_range = value
		_update_range_gizmo()

@export var behavior: ReflectionBehavior

var origin_position: Vector3
var _range_gizmo: MeshInstance3D

func _ready() -> void:
	origin_position = position
	_update_range_gizmo()

func translate_on_axis(axis_index: int, delta_amount: float) -> void:
	var new_val := position[axis_index] + delta_amount
	var min_val := origin_position[axis_index] - translate_range
	var max_val := origin_position[axis_index] + translate_range
	position[axis_index] = clamp(new_val, min_val, max_val)

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
