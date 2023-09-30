@tool
@icon("icon-sciurus-small.png")
extends Node
class_name StateTree

@export var now_init = false
@export var now_send_event = false
@export var event_string = ""

var _states: PackedStringArray = []


func _ready():
	var tmp = get_child(0)
	if tmp is StateBasic:
		tmp._active = true
		tmp._state_init()
	
	if Engine.is_editor_hint():
		return 


func _process(delta):
	if now_init:
		var tmp = get_child(0)
		if tmp is StateBasic:
			tmp._state_activate()
			tmp._state_init()
		now_init = false
	
	if now_send_event:
		send_event(event_string)
		now_send_event = false
	
	if Engine.is_editor_hint():
		return 

func send_event(event: String):
	var events: Array[StateEvent] = []
	var tmp = get_child(0)
	if tmp is StateBasic:
		events = tmp._get_events(event)
	for state_event in events:
#		state_event.target_node.state_activate()
		state_event.target_node._state_activate_reorder(true, state_event.layer_up)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if get_child_count() != 1:
		warnings.append("StateTree must have exactly one child")
#	var child = get_child(0)
#	if not child is StateBasic:
#		warnings.append("StateTree's child must be a StateBasic")
	return warnings
