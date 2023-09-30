@tool
@icon("icon-sciurus-small.png")
extends StateBasic
class_name StateArrAll


@export var def: int = 0
#var _last: int
#var _activated: int


func _get_events(event: String) -> Array[StateEvent]:
	var tmp1: Array[StateEvent] = super(event)
	var tmp2: Array[StateEvent] = []
	for child in get_children():
		if child is StateBasic:
			tmp2.append_array(child._get_events(event))
	tmp1.append_array(tmp2)
	return tmp1

func _state_init():
	for child in get_children():
		if child is StateBasic:
			child._state_init()
			child._state_activate()
	
	super()

func _state_reorder(pos: int, add = true, up_l = -1):
	for child in get_children():
		if child is StateBasic:
			if add:
				child._state_activate()
			else:
				child._state_activate()
		
	_state_activate_reorder(add, up_l)
