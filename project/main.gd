@tool
extends Control


enum {
	LOAD,
	START,
	DL,
	CFG
}

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


static var c_root = OS.get_executable_path().get_base_dir()
const c_tools = "/tools/"
const c_proj = "/project/"
const c_proj_file = "/project/project.godot"
const c_sc = "/tools/_sc_"
const c_blender = "/tools/blender/"
const c_config = "/config.ini"
const c_got_web = "https://github.com/godotengine/godot-builds/releases/download/" #1.0-stable/Godot_v1.0_stable_win64.exe.zip"
const c_blend_web = "https://download.blender.org/release/"

var fs_root: DirAccess = DirAccess.open(c_root)
var fs_godot = ""
var fs_godot_cfg = ""
var fs_blender = ""

var cfg_main: ConfigFile = ConfigFile.new()

var downloading = false


func _init():
	if not Engine.is_editor_hint():
		var err = 0
		
		if fs_root.dir_exists("tools"):
			pass
		else:
			fs_root.make_dir("tools")
		
		if not fs_root.dir_exists("project"):
			fs_root.make_dir("project")
			FileAccess.open(c_root+c_proj_file, FileAccess.WRITE).close()
		
		if not fs_root.dir_exists("export"):
			fs_root.make_dir("export")
		
		if FileAccess.file_exists(c_root+c_config):
			err = cfg_main.load(c_root+c_config)
			#if err == ERR_FILE_CANT_OPEN:
				#fs_root.remove(c_root+c_config)
				#cfg_main.save(c_root+c_config)
		else:
			cfg_main.save(c_root+c_config)
		
		if cfg_main.get_value("godot", "portable"):
			FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
		else:
			fs_root.remove(c_root+c_sc)

func _ready():
	if not Engine.is_editor_hint():
		await ready
		start_check()

func _process(_delta):
	if downloading:
		if %downloader.status != 0:
			$tab/Download/Box/ProgressBar.value = %downloader.procent
			$tab/Download/Box/item/status.text = %downloader.status_text
			$tab/Download/Box/item/name.text = %downloader.current_name
		else:
			downloading = false
			start_check()

func start_check():
	var tmp_b_ver = cfg_main.get_value("blender", "ver", "")
	if not tmp_b_ver == "":
		fs_blender = "blender-"+tmp_b_ver+"-windows-x64/blender.exe"
		if FileAccess.file_exists(c_root+c_tools+fs_blender):
			%"blender-start".visible = true
			%"blender-download".visible = false
		else:
			%"blender-start".visible = false
			%"blender-download".visible = true
	else:
		fs_blender = ""
		%"blender-start".visible = false
		%"blender-download".visible = false
	
	var tmp_g_ver: String = cfg_main.get_value("godot", "ver", "")
	if not tmp_g_ver == "":
		%err.visible = false
		fs_godot = "Godot_v"+tmp_g_ver+"-stable_win64.exe"
		fs_godot_cfg = "editor_data/editor_settings-"+tmp_g_ver.left(3)+".tres"
		if FileAccess.file_exists(c_root+c_tools+fs_godot):
			%download.visible = false
			%proj.visible = true
			if cfg_main.get_value("godot", "autostart", false):
				self.start_editor()
				return
		else:
			%download.visible = true
			%proj.visible = false
	else:
		fs_godot = ""
		fs_godot_cfg = ""
		%download.visible = false
		%proj.visible = false
		%err.visible = true
		%err_ver.visible = true
	tab = START

func start_editor():
	if cfg_main.get_value("blender", "integrate"):
		if cfg_main.get_value("godot", "portable"):
			if fs_blender == "":
				EditorSettingsFile.change(
					c_root+c_tools+fs_godot_cfg, 
					{
						"filesystem/import/blender/blender_path": "\"\"", 
						"filesystem/external_programs/3d_model_editor": "\"\""
					}
				)
			else:
				EditorSettingsFile.change(
					c_root+c_tools+fs_godot_cfg, 
					{
						"filesystem/import/blender/blender_path": "\""+c_root+c_tools+fs_blender+"\"", 
						"filesystem/external_programs/3d_model_editor": "\""+c_root+c_tools+fs_blender+"\""
					}
				)
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\" -e"])
	get_tree().quit()

func start_project():
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\""])
	get_tree().quit()

func start_blender() -> void:
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \"" +c_root+c_tools+fs_blender+ "\""])
	get_tree().quit()

func dl_start_godot():
	downloading = true
	var tmp_ver = cfg_main.get_value("godot", "ver", "")
	if not tmp_ver == "":
		var tmp_file = "Godot_v"+tmp_ver+"-stable_win64.exe.zip"
		var tmp_source = c_got_web+tmp_ver+"-stable/"+tmp_file
		var tmp_to = c_root + c_tools + tmp_file
		%downloader.start_download("Godot", tmp_source, tmp_to)
	
	tab = DL

func dl_start_blender():
	downloading = true
	var tmp_ver = cfg_main.get_value("blender", "ver", "")
	if not tmp_ver == "":
		var tmp_file = "blender-"+tmp_ver+"-windows-x64.zip"
		var tmp_source = c_blend_web+"Blender"+tmp_ver.left(3)+"/"+tmp_file
		var tmp_to = c_root + c_tools + tmp_file
		%downloader.start_download("Blender", tmp_source, tmp_to)
	
	tab = DL

func cfg_open():
	%"g-ver-setting".text = cfg_main.get_value("godot", "ver", "")
	%"g-autostart-setting".button_pressed = cfg_main.get_value("godot", "autostart", false)
	%"g-portable-setting".button_pressed = cfg_main.get_value("godot", "portable", false)
	%"b-ver-setting".text = cfg_main.get_value("blender", "ver", "")
	%"b-integrate-setting".button_pressed = cfg_main.get_value("blender", "integrate", false)
	
	tab = CFG

func cfg_save():
	cfg_main.set_value("godot", "ver", %"g-ver-setting".text)
	cfg_main.set_value("godot", "autostart", %"g-autostart-setting".button_pressed)
	cfg_main.set_value("godot", "portable", %"g-portable-setting".button_pressed)
	cfg_main.set_value("blender", "ver", %"b-ver-setting".text)
	cfg_main.set_value("blender", "integrate", %"b-integrate-setting".button_pressed)
	
	if %"g-portable-setting".button_pressed:
		FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
	else:
		fs_root.remove(c_root+c_sc)
	
	cfg_main.save(c_root+c_config)
	
	start_check()

func cfg_cancel():
	start_check()
