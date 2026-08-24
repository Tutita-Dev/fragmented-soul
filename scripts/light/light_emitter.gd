@tool
class_name LightEmitter
extends Node3D

## Gizmo visual de dirección del rayo, solo en editor.
## Dibuja el eje -Z local (el mismo que usa light_system.gd:
## -emitter.global_transform.basis.z), para poder alinear el emisor
## a ojo al armar niveles sin tener que darle a Play.

@export var gizmo_length: float = 3.0:
	set(value):
		gizmo_length = value
		_draw_gizmo()
@export var gizmo_color: Color = Color(1.0, 0.85, 0.2, 0.9):
	set(value):
		gizmo_color = value
		_draw_gizmo()

const GIZMO_NAME := "_EditorRayGizmo"

var _gizmo: MeshInstance3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_gizmo()
		_draw_gizmo()
	else:
		# Por si el nodo quedó guardado en la escena de una sesión anterior
		# de edición: en juego no debe existir ni renderizar nada.
		var leftover := find_child(GIZMO_NAME, false, false)
		if leftover:
			leftover.queue_free()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_draw_gizmo()


func _ensure_gizmo() -> void:
	_gizmo = find_child(GIZMO_NAME, false, false)
	if _gizmo != null:
		return

	_gizmo = MeshInstance3D.new()
	_gizmo.name = GIZMO_NAME
	_gizmo.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true  # se ve a través de otra geometría, más fácil de ubicar
	_gizmo.material_override = mat

	add_child(_gizmo)
	# Owner intencionalmente en null: el gizmo vive en memoria mientras
	# editás, pero NO se serializa en el .tscn al guardar la escena.


func _draw_gizmo() -> void:
	if _gizmo == null:
		return

	var im: ImmediateMesh = _gizmo.mesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var tip := Vector3(0, 0, -gizmo_length)  # mismo eje que -basis.z en light_system.gd

	# Línea principal
	_line(im, Vector3.ZERO, tip)

	# Punta de flecha (4 barbas)
	var back := tip + Vector3(0, 0, gizmo_length * 0.15)
	var spread := gizmo_length * 0.06
	_line(im, tip, back + Vector3(spread, 0, 0))
	_line(im, tip, back + Vector3(-spread, 0, 0))
	_line(im, tip, back + Vector3(0, spread, 0))
	_line(im, tip, back + Vector3(0, -spread, 0))

	im.surface_end()


func _line(im: ImmediateMesh, a: Vector3, b: Vector3) -> void:
	im.surface_set_color(gizmo_color)
	im.surface_add_vertex(a)
	im.surface_set_color(gizmo_color)
	im.surface_add_vertex(b)
