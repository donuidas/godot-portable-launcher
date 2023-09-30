@tool
@icon("icon-sciurus-small.png")
extends StateBasic
class_name StateArrOne


@export var def: int = 0


func _get_events(event: String) -> Array[StateEvent]:
	var tmp1: Array[StateEvent] = super(event)
	var tmp2: Array[StateEvent] = []
	for child in get_children():
		if child is StateBasic:
			if child._active:
				tmp2.append_array(child._get_events(event))
	tmp1.append_array(tmp2)
	return tmp1

func _state_init():
	var num: int = 0
	for child in get_children():
		if child is StateBasic:
			child._state_init()
			if num == self.def:
				child._state_activate()
			else:
				child._state_deactivate()
		num += 1
	
	super()

func _state_reorder(pos: int, add = true, up_l = -1):	
	var num: int = 0
	for child in get_children():
		if child is StateBasic:
			if add:
				if num != pos:
					child._state_deactivate()
			else:
				if num == self.def:
					child._state_activate()
				else:
					child._state_deactivate()
		num += 1
		
	_state_activate_reorder(add, up_l)
