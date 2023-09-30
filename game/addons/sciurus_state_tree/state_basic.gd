@tool
@icon("icon-sciurus-small.png")
extends Node
class_name StateBasic

signal state_init
signal state_activated
signal state_process(delta)
signal state_physics_process(delta)
signal state_deactivated

@export_enum("Inherit", "Pausable", "When Paused", "Always", "Disable") var active_mode: int = 0 :
	set(value):
		active_mode = value
		if _active:
			self.process_mode = value
			
var _active = true :
	set(value):
		_active = value
		if value:
			self.process_mode = self.active_mode
			if Engine.is_editor_hint():
				return 
			emit_signal("state_activated")
		else:
			self.process_mode = Node.PROCESS_MODE_DISABLED
			if Engine.is_editor_hint():
				return 
			emit_signal("state_deactivated")
			
@export var active = true :
	set(value):
		if value:
			self._state_activate_reorder()
		else:
			self._state_activate_reorder(false)
	get:
		return self._active

@export var events: Array[StateEvent] = []


func _get_events(event: String) -> Array[StateEvent]:
	var tmp: Array[StateEvent] = []
	for event_state in events:
		if event_state.event_name == event:
			event_state.target_node = get_node(event_state.target)
			tmp.append(event_state)
	return tmp

func _state_init():
	if Engine.is_editor_hint():
		return 
	emit_signal("state_init")
	
func _state_activate():
	self._active = true

func _state_deactivate():
	self._active = false

func _state_reorder(pos: int, add = true, up_l = -1):
	pass
	
func _state_activate_reorder(add = true, up_l = -1):
	if up_l != 0 and _active != add:
		if add:
			self._state_activate()
		else:
			self._state_deactivate()
		var tmp_p = get_parent()
		if tmp_p is StateBasic:
			tmp_p._state_reorder(get_index(), add, up_l - 1)

func _process(delta):
	if Engine.is_editor_hint():
		return 
	emit_signal("state_process", delta)
	
func _physics_process(delta):
	if Engine.is_editor_hint():
		return 
	emit_signal("state_physics_process", delta)

#func _toggle_processing(active:bool):
#	set_process(active)
#	set_physics_process(active)
#	set_process_input(active)
#	set_process_unhandled_input(active)
#	set_process_unhandled_key_input(active)
