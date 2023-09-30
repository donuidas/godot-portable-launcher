@tool
extends Resource
class_name StateEvent


@export var event_name: String = ""
@export_node_path("StateBasic") var target: NodePath
@export var target_node: Node
@export var layer_up: int = -1
