@tool
class_name LightEmitter
extends Node3D

## Gizmo visual de dirección del rayo, solo en editor.
## Dibuja el eje -Z local (el mismo que usa light_system.gd:
## -emitter.global_transform.basis.z), para poder alinear el emisor
## a ojo al armar niveles sin tener que darle a Play.
##
## Nota: se dibuja vía RenderingServer directo, SIN crear un
## MeshInstance3D hijo. Si fuera un MeshInstance3D, el editor le dibuja
## automáticamente el cuadro de selección/AABB cuando LightEmitter está
## seleccionado (eso es lo que se veía de más). Yendo por RenderingServer
## no hay ningún nodo VisualInstance3D en el árbol, así que no hay AABB
## que el editor pueda dibujar: solo se ve la flecha.

@export var gizmo_length: float = 3.0
@export var gizmo_color: Color = Color(1.0, 0.85, 0.2, 0.9)

var _mesh: ImmediateMesh
var _material: StandardMaterial3D
var _instance_rid: RID


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	_mesh = ImmediateMesh.new()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.no_depth_test = true  # se ve a través de otra geometría

	_instance_rid = RenderingServer.instance_create()
	RenderingServer.instance_set_base(_instance_rid, _mesh.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(
		_instance_rid, RenderingServer.SHADOW_CASTING_SETTING_OFF
	)
	_sync_scenario()
	_draw_gizmo()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or _mesh == null:
		return
	_sync_scenario()
	RenderingServer.instance_set_transform(_instance_rid, global_transform)
	_draw_gizmo()


func _exit_tree() -> void:
	if _instance_rid.is_valid():
		RenderingServer.free_rid(_instance_rid)


func _sync_scenario() -> void:
	var world := get_world_3d()
	if world != null:
		RenderingServer.instance_set_scenario(_instance_rid, world.scenario)


func _draw_gizmo() -> void:
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)

	var tip := Vector3(0, 0, -gizmo_length)  # mismo eje que -basis.z en light_system.gd

	# Línea principal
	_line(Vector3.ZERO, tip)

	# Punta de flecha (4 barbas)
	var back := tip + Vector3(0, 0, gizmo_length * 0.15)
	var spread := gizmo_length * 0.06
	_line(tip, back + Vector3(spread, 0, 0))
	_line(tip, back + Vector3(-spread, 0, 0))
	_line(tip, back + Vector3(0, spread, 0))
	_line(tip, back + Vector3(0, -spread, 0))

	_mesh.surface_end()


func _line(a: Vector3, b: Vector3) -> void:
	_mesh.surface_set_color(gizmo_color)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(gizmo_color)
	_mesh.surface_add_vertex(b)
