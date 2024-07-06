@tool
extends Control


#var tst2 = %tab

@export var tab = 0:
	get:
		if is_node_ready():
			return %tab.current_tab
		else:
			return tab
	set(value):
		if is_node_ready():
			tab = value
			%tab.current_tab = value
		else:
			tab = value
			await ready
			%tab.current_tab = value
		
@export var start_tab = 0:
	get:
		if is_node_ready():
			return %start_tab.current_tab
		else:
			return start_tab
	set(value):
		if is_node_ready():
			start_tab = value
			%start_tab.current_tab = value
		else:
			start_tab = value
			await ready
			%start_tab.current_tab = value

@export var tst = false:
	set(value):
		start_check()


var fs_root: DirAccess = DirAccess.open("res://")
var downloading = false
var dl_start = false
var dl_godot = false


func _init():
	if fs_root.dir_exists("tools"):
		if not FileAccess.file_exists("res://tools/_sc_"):
			FileAccess.open("res://tools/_sc_", FileAccess.WRITE).close()
		if not FileAccess.file_exists("res://tools/godot.ver"):
			FileAccess.open("res://tools/godot.ver", FileAccess.WRITE).close()
		if not FileAccess.file_exists("res://tools/blender.ver"):
			FileAccess.open("res://tools/blender.ver", FileAccess.WRITE).close()
	else:
		fs_root.make_dir("tools")
		FileAccess.open("res://tools/_sc_", FileAccess.WRITE).close()
		FileAccess.open("res://tools/godot.ver", FileAccess.WRITE).close()
		FileAccess.open("res://tools/blender.ver", FileAccess.WRITE).close()
#	fs_tools = DirAccess.open("res://tools")

func _ready():
	start_check()

func _process(delta):
	if downloading:
		
		if dl_start:
			if dl_godot:
				var tmp_ver_file = FileAccess.open("res://tools/godot.ver", FileAccess.READ)
				var tmp_ver = tmp_ver_file.get_as_text()
				tmp_ver_file.close()
				if not tmp_ver == "":
					var tmp_exe_str = "Godot_v"+tmp_ver+"-stable_win64.exe"
					%HTTPRequest.download_file = tmp_exe_str+".zip"
					%HTTPRequest.request("https://downloads.tuxfamily.org/godotengine/"+tmp_ver+"/"+tmp_exe_str+".zip")
				dl_godot = false
			dl_start = false
			
		var tmp_total_size = %HTTPRequest.get_body_size()
		var tmp_size = %HTTPRequest.get_downloaded_bytes()
		var tmp_procent = 0
		if tmp_total_size != 0:
			tmp_procent = (100/tmp_total_size)*tmp_size
		print(tmp_size)
		
		$tab/Download/Box/ProgressBar.value = tmp_procent

func start_check():
	tab = 0
	
	var tmp_ver_file = FileAccess.open("res://tools/godot.ver", FileAccess.READ)
	var tmp_ver = tmp_ver_file.get_as_text()
	tmp_ver_file.close()
	
	if not tmp_ver == "":
		var tmp_exe_str = "Godot_v"+tmp_ver+"-stable_win64.exe"
		if FileAccess.file_exists("res://tools/"+tmp_exe_str):
			start_tab = 0
		else:
			start_tab = 1

func download():
	downloading = true
	dl_godot = true
	dl_start = true
	tab = 1
