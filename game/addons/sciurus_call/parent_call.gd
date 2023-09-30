@tool
extends Node
#class_name ParentCall


@export_category("ParentCall")
@export var everlast_child = false
@export var run_in_editor = false


@export_group("Calls(>)")

@export var enter_tree = false
@export var enter_tree_func = "_after_child_enter_tree"

@export var process = false
@export var process_func = "_after_child_process"

@export var physics_process = false
@export var physics_process_func = "_after_child_physics_process"


@export_group("Calls(<)")

@export var is_ready = false
@export var ready_func = "_befor_child_ready"

@export var exit_tree = false
@export var exit_tree_func = "_befor_child_exit_tree"


func _call_parent(toCall):
	if toCall != "":
		var prt = self.get_parent()
		if prt.has_method(toCall):
			prt.call(toCall)


func _call_parent_witharg(toCall, arg):
	if toCall != "":
		var prt = self.get_parent()
		if prt.has_method(toCall):
			prt.call(toCall, arg)


func _enter_tree():
	if not Engine.is_editor_hint or run_in_editor:
		if enter_tree:
			self._call_parent(enter_tree_func)


# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint or run_in_editor:
		if is_ready:
			self._call_parent(ready_func)


func _process(delta):
	if everlast_child:
		var prt = self.get_parent()
		if prt.get_child_count()-1 != self.get_index():
#			self.raise()
			prt.move_child(self, prt.get_child_count()-1)
	if not Engine.is_editor_hint or run_in_editor:
		if process:
			self._call_parent_witharg(process_func, delta)


func _physics_process(delta):
	if not Engine.is_editor_hint or run_in_editor:
		if physics_process:
			self._call_parent_witharg(physics_process_func, delta)


func _exit_tree():
	if not Engine.is_editor_hint or run_in_editor:
		if exit_tree:
			self._call_parent(exit_tree_func)
