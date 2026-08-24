@tool
extends Control


enum {
	LOAD,
	START,
	DL,
	CFG,
	GIT
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

var missing_main = false
var missing_export = false

var cfg_main: ConfigFile = ConfigFile.new()

var downloading = false


func _init():
	if not Engine.is_editor_hint():
		var err = 0
		if FileAccess.file_exists(c_root+c_config):
			err = cfg_main.load(c_root+c_config)
			#if err == ERR_FILE_CANT_OPEN:
				#fs_root.remove(c_root+c_config)
				#cfg_main.save(c_root+c_config)
		
		gen_check()
		
		if fs_root.dir_exists("tools"):
			if cfg_main.get_value("godot", "portable", false):
				FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
			else:
				fs_root.remove(c_root+c_sc)

func _ready():
	if not Engine.is_editor_hint():
		await ready
		get_window().title = OS.get_executable_path().get_file().left(-4)
		start_check()
		for arg in OS.get_cmdline_args():
			if arg == "--edit" and %proj.visible == true:
				self.start_editor()
			elif arg == "--cfg":
				self.cfg_open()
			return
		if cfg_main.get_value("godot", "autostart", false):
			self.start_editor()

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
	if missing_main:
		%err_files.visible = true
	else:
		%err_files.visible = false
	if missing_main or missing_export:
		%"files-gen".visible = true
	else:
		%"files-gen".visible = false
	
	var tmp_b_ver = cfg_main.get_value("blender", "ver", "")
	if not (tmp_b_ver == "" or missing_main):
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
	if not (tmp_g_ver == "" or missing_main):
		%err_ver.visible = false
		fs_godot = "Godot_v"+tmp_g_ver+"-stable_win64.exe"
		fs_godot_cfg = "editor_data/editor_settings-"+tmp_g_ver.left(3)+".tres"
		if FileAccess.file_exists(c_root+c_tools+fs_godot):
			%download.visible = false
			%proj.visible = true
		else:
			%download.visible = true
			%proj.visible = false
	else:
		fs_godot = ""
		fs_godot_cfg = ""
		%download.visible = false
		%proj.visible = false
		if tmp_g_ver == "":
			%err_ver.visible = true
		else:
			%err_ver.visible = false
	
	if cfg_main.get_value("git", "active", false):
		%"git-tools".visible = true
	else:
		%"git-tools".visible = false
	
	tab = START

func start_editor():
	if cfg_main.get_value("godot", "portable"):
		if cfg_main.get_value("blender", "integrate") and fs_blender != "":
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

func dl_cancel():
	pass

func gen_check():
	missing_main = false
	if not (fs_root.dir_exists("tools") and fs_root.dir_exists("project")):
		missing_main = true
	if not FileAccess.file_exists(c_root+c_proj_file):
		missing_main = true
	
	missing_export = false
	if cfg_main.get_value("fs", "export", false):
		if not fs_root.dir_exists("export"):
			missing_export = true

func gen_missing_fils():
	if missing_main:
		if fs_root.dir_exists("tools"):
			pass
		else:
			fs_root.make_dir("tools")
		
		if not fs_root.dir_exists("project"):
			fs_root.make_dir("project")
			FileAccess.open(c_root+c_proj_file, FileAccess.WRITE).close()
		
		if cfg_main.get_value("godot", "portable", false):
			FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
		else:
			fs_root.remove(c_root+c_sc)
		
		missing_main = false
	
	if cfg_main.get_value("fs", "export", false):
		if missing_export:
			if not fs_root.dir_exists("export"):
				fs_root.make_dir("export")
				
			missing_export = false
	
	start_check()

func cfg_open():
	%"fs-export-setting".button_pressed = cfg_main.get_value("fs", "export", false)
	
	%"g-ver-setting".text = cfg_main.get_value("godot", "ver", "")
	%"g-autostart-setting".button_pressed = cfg_main.get_value("godot", "autostart", false)
	%"g-portable-setting".button_pressed = cfg_main.get_value("godot", "portable", true)
	
	%"b-ver-setting".text = cfg_main.get_value("blender", "ver", "")
	%"b-integrate-setting".button_pressed = cfg_main.get_value("blender", "integrate", false)
	
	%"git-active-setting".button_pressed = cfg_main.get_value("git", "active", false)
	
	tab = CFG

func cfg_save():
	cfg_main.set_value("fs", "export", %"fs-export-setting".button_pressed)
	
	cfg_main.set_value("godot", "ver", %"g-ver-setting".text)
	cfg_main.set_value("godot", "autostart", %"g-autostart-setting".button_pressed)
	cfg_main.set_value("godot", "portable", %"g-portable-setting".button_pressed)
	
	cfg_main.set_value("blender", "ver", %"b-ver-setting".text)
	
	cfg_main.set_value("git", "active", %"git-active-setting".button_pressed)
	
	if cfg_main.get_value("blender", "integrate", false) and not %"b-integrate-setting".button_pressed:
		EditorSettingsFile.change(
			c_root+c_tools+fs_godot_cfg, 
			{
				"filesystem/import/blender/blender_path": "\"\"", 
				"filesystem/external_programs/3d_model_editor": "\"\""
			}
		)
	cfg_main.set_value("blender", "integrate", %"b-integrate-setting".button_pressed)
	
	if fs_root.dir_exists("tools"):
		if %"g-portable-setting".button_pressed:
			FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
		else:
			fs_root.remove(c_root+c_sc)
	
	cfg_main.save(c_root+c_config)
	
	gen_check()
	start_check()

func cfg_cancel():
	start_check()

func git_open():
	tab = GIT

func git_close():
	start_check()

func git_make_gitignore():
	var file := FileAccess.open(c_root+"/.gitignore", FileAccess.WRITE)
	var text: String = """# Godot 4+
.godot/

# Godot 3-
.import/

# Godot
export.cfg
# export_presets.cfg

# Godot-Mono
.mono/
data_*/
mono_crash.*.json

# Windows
desktop.ini

# godot-portable-launcher
tools/Godot*.exe
tools/Godot*.cmd
export/
tools/blender*/
*.blend1
tools/editor_data/"""
	file.store_string(text)
	file.close()
