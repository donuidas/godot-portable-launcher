@tool
@icon("icon-sciurus-small.png")
extends StateBasic
class_name StateVisible


@export_category("StateVisible")

@export var links: Array[LinkVisible] = [] :
	set(value):
		links = value
		var count = 0
		for tmp in links:
			if not tmp is LinkVisible:
				links[count] = LinkVisible.new()
			count +=1



func _state_activate():
	super()
	for link in links:
		var node = get_node(link.node)
		if node is Node3D or node is CanvasItem:
			node.visible = link.visible

func _state_deactivate():
	super()
	for link in links:
		if link.oposite_when_deactivate:
			var node = get_node(link.node)
			if node is Node3D or node is CanvasItem:
				node.visible = not link.visible
