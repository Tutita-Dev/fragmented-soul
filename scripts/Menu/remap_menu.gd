extends Control

@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var p1_column: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/P1Column
@onready var p2_column: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/P2Column

var player1_input: InputProvider
var player2_input: InputProvider

const LOGICAL_ACTIONS := ["forward", "back", "left", "right", "up", "down", "possess"]

const ACTION_LABELS := {
	"forward": "Adelante",
	"back": "Atrás",
	"left": "Izquierda",
	"right": "Derecha",
	"up": "Arriba",
	"down": "Abajo",
	"possess": "Poseer",
}

var _waiting_action: String = ""
var _waiting_provider: InputProvider = null
var _buttons: Dictionary = {}  # "1_forward" -> Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Esperamos un frame de procesamiento para garantizar que los jugadores hayan cargado
	await get_tree().process_frame
	
	_find_input_providers()
	_build_column(p1_column, player1_input, 1)
	_build_column(p2_column, player2_input, 2)
	$PanelContainer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _find_input_providers() -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if "input_provider" in p and p.input_provider:
			var provider: InputProvider = p.input_provider
			if provider.player_id == 1:
				player1_input = provider
			elif provider.player_id == 2:
				player2_input = provider

func _clean_key_text(raw: String) -> String:
	return raw.split(" - ")[0]

func _build_column(column: VBoxContainer, provider: InputProvider, pid: int) -> void:
	# Si no se encontró el InputProvider para este jugador, mostramos un aviso y evitamos el crash
	if not provider:
		var err_label := Label.new()
		err_label.text = "P%d No detectado" % pid
		column.add_child(err_label)
		return

	for logical_action in LOGICAL_ACTIONS:
		var btn := Button.new()
		var key_text := _clean_key_text(provider.get_current_event_text(logical_action))
		btn.text = "%s: %s" % [ACTION_LABELS[logical_action], key_text]
		btn.pressed.connect(_on_button_pressed.bind(logical_action, provider, btn))
		column.add_child(btn)
		_buttons["%d_%s" % [pid, logical_action]] = btn

func _on_button_pressed(logical_action: String, provider: InputProvider, btn: Button) -> void:
	_waiting_action = logical_action
	_waiting_provider = provider
	btn.text = "Presioná una tecla..."
	status_label.text = "Esperando input para P%d — %s" % [provider.player_id, ACTION_LABELS[logical_action]]

func _input(event: InputEvent) -> void:
	if _waiting_action == "" or not _waiting_provider:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		var conflict := _find_conflicting_action(event, _waiting_provider, _waiting_action)
		if conflict != "":
			status_label.text = "Esa tecla ya está en uso por: %s. Probá otra." % conflict
			get_viewport().set_input_as_handled()
			return

		_waiting_provider.rebind_action(_waiting_action, event)
		var key := "%d_%s" % [_waiting_provider.player_id, _waiting_action]
		var key_text := _clean_key_text(event.as_text())
		_buttons[key].text = "%s: %s" % [ACTION_LABELS[_waiting_action], key_text]
		status_label.text = ""
		_waiting_action = ""
		_waiting_provider = null
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _waiting_action == "":
		visible = not visible
		get_viewport().set_input_as_handled()

func _find_conflicting_action(event: InputEvent, exclude_provider: InputProvider, exclude_logical: String) -> String:
	var new_key_text := _clean_key_text(event.as_text())
	var providers: Array[InputProvider] = []
	if player1_input: providers.append(player1_input)
	if player2_input: providers.append(player2_input)
	
	for provider in providers:
		for logical_action in LOGICAL_ACTIONS:
			if provider == exclude_provider and logical_action == exclude_logical:
				continue
			var action_name: String = provider.get_action_name(logical_action)
			for existing_event in InputMap.action_get_events(action_name):
				var existing_key_text := _clean_key_text(existing_event.as_text())
				if existing_key_text == new_key_text:
					return "P%d - %s" % [provider.player_id, ACTION_LABELS[logical_action]]
	return ""
