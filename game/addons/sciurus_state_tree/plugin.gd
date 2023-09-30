@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("Multi Sensor", "Area3D", preload("multi_sensor.gd"), preload("icon-sciurus-small.png"))
	#add_custom_type("Sensor", "Area3D", preload("sensor.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateTree", "Node", preload("state_tree.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateBasic", "Node", preload("state_basic.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateTrigger", "Node", preload("state_trigger.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateArrAll", "Node", preload("state_arr_all.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateArrOne", "Node", preload("state_arr_one.gd"), preload("icon-sciurus-small.png"))
	add_custom_type("StateVisible", "Node", preload("state_visible.gd"), preload("icon-sciurus-small.png"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	#remove_custom_type("Multi Sensor")
	#remove_custom_type("Sensor")
	remove_custom_type("StateTree")
	remove_custom_type("StateBasic")
	remove_custom_type("StateTrigger")
	remove_custom_type("StateArrAll")
	remove_custom_type("StateArrOne")
	remove_custom_type("StateVisible")
