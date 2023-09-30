@tool
extends Node
class_name SystemSettings


var _root: Window

@export var start_mode = true

@export_category("Root Viewport")
@export var variable_resolution = false :
	set(value):
		if _root:
			if value:
				_root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
			elif pixel_perfect_resolution:
				_root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			else:
				_root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		variable_resolution = value
	get:
		if _root:
			if _root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED:
				return true
			else:
				return false
		else:
			return variable_resolution

@export var pixel_perfect_resolution = false :
	set(value):
		if _root and not variable_resolution:
			if value:
				_root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			else:
				_root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		pixel_perfect_resolution = value
	get:
		if _root and not variable_resolution:
			if _root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
				return true
			elif _root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
				return false
		else:
			return pixel_perfect_resolution

@export var expanded_resolution = false :
	set(value):
		if _root:
			if value:
				_root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
			else:
				_root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		expanded_resolution = value
	get:
		if _root:
			if _root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND:
				return true
			else:
				return false
		else:
			return expanded_resolution
			
#@export var aspect_ratio_on = false
#@export var aspect_ratio = Vector2(16 ,9)
@export var resolution = Vector2(800 ,400) :
	set(value):
		if _root:
			_root.content_scale_size = value
		resolution = value
	get:
		if _root:
			return _root.content_scale_size
		else:
			return resolution

@export var fullscreen = false :
	set(value):
		if _root:
			if value:
				if exclusiv_fullscreen:
					_root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
				else:
					_root.mode = Window.MODE_FULLSCREEN
			else:
				_root.mode = Window.MODE_WINDOWED
		fullscreen = value
	get:
		if _root:
			if _root.mode == Window.MODE_FULLSCREEN or _root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
				return true
			else:
				return false
		else:
			return fullscreen

@export var exclusiv_fullscreen = false :
	set(value):
		if _root:
			if fullscreen:
				if value:
					_root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
				else:
					_root.mode = Window.MODE_FULLSCREEN
		exclusiv_fullscreen = value
	get:
		return exclusiv_fullscreen

@export var disable_pre_3d = false :
	set(value):
		if _root:
			_root.disable_3d = value
		disable_pre_3d = value
	get:
		if _root:
			return _root.disable_3d
		else:
			return disable_pre_3d


func _enter_tree():
	var tmp_root = get_tree().root
	
	tmp_root.disable_3d = disable_pre_3d
	
	if variable_resolution:
		tmp_root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	elif pixel_perfect_resolution:
		tmp_root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	else:
		tmp_root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	
	_root = get_tree().root

func _ready():
	pass

func _exit_tree():
	_root = null
