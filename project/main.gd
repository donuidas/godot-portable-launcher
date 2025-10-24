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

var fs_root: DirAccess = DirAccess.open(c_root)
var fs_godot = ""
var fs_godot_cfg = ""
var fs_blender = ""

var cfg_main: ConfigFile = ConfigFile.new()

var downloading = false
var dl_ziping = false
var dl_godot = false
var dl_current = ""

var zip_thread = Thread.new()
var zip_reader = ZIPReader.new()
var zip_files: Array = []
var zip_files_size = 0


func _init():
	if not Engine.is_editor_hint():
		var err = 0
		
		if fs_root.dir_exists("tools"):
			pass
			#if not FileAccess.file_exists(c_root+c_sc):
			#	FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
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
		if not dl_ziping:
			var tmp_total_size = %HTTPRequest.get_body_size()
			var tmp_size = %HTTPRequest.get_downloaded_bytes()
			var tmp_procent = 0
			if tmp_size != 0:
				tmp_procent = 100 * tmp_size / tmp_total_size
			
			$tab/Download/Box/ProgressBar.value = tmp_procent
			$tab/Download/Box/item/status.text = str(snappedf(tmp_size/1048576.0, 0.001)) \
									 +"MB von "+ str(snappedf(tmp_total_size/1048576.0, 0.001)) +"MB"
		elif zip_thread.is_alive():
			var tmp_procent = 0
			if zip_files_size != 0:
				@warning_ignore("integer_division")
				tmp_procent = 100 * zip_files.size() / zip_files_size
			$tab/Download/Box/ProgressBar.value = tmp_procent
			$tab/Download/Box/item/status.text = "noch "+ str(zip_files.size()) +" von "+ str(zip_files_size)
		else:
			zip_thread.wait_to_finish()
			dl_zip_next()

func start_check():
	var tmp_g_ver: String = cfg_main.get_value("godot", "ver", "")
	if not tmp_g_ver == "":
		%err.visible = false
		
		if cfg_main.get_value("blender", "integrate"):
			var tmp_b_ver = cfg_main.get_value("blender", "ver", "")
			if not tmp_b_ver == "":
				fs_blender = "blender-"+tmp_b_ver+"-windows-x64/blender.exe"
				if FileAccess.file_exists(c_root+c_tools+fs_blender):
					%"blender-start".visible = true
				else:
					%"blender-start".visible = false
		else:
				%"blender-start".visible = false
		
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
		%download.visible = false
		%proj.visible = false
		%err.visible = true
		%err_ver.visible = true
		%"blender-start".visible = false
	tab = START

func start_editor():
	if cfg_main.get_value("blender", "integrate"):
		if cfg_main.get_value("godot", "portable"):
			_change_editorsettings_file(
				c_root+c_tools+fs_godot_cfg, 
				{
					"filesystem/import/blender/blender_path": "\""+c_root+c_tools+fs_blender+"\"", 
					"filesystem/external_programs/3d_model_editor": "\""+c_root+c_tools+fs_blender+"\""
				}
			)
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\" -e"])
	get_tree().quit()

func _change_editorsettings_file(path: String, updates: Dictionary) -> void:
	# updates = {"key/path": "value", ...}
	var header := ""
	var format_version := 3
	var resource_section_found := false
	var lines: PackedStringArray = []
	
	# --- Datei lesen oder Grundgerüst anlegen ---
	if FileAccess.file_exists(path):
		var file_text := FileAccess.get_file_as_string(path)
		lines = file_text.split("\n")
		
		# Header und Format erkennen
		for i in range(lines.size()):
			var trimmed := lines[i].strip_edges()
			if trimmed.begins_with("[gd_resource"):
				header = lines[i]
				# Formatnummer extrahieren
				var match2 := RegEx.new()
				match2.compile("format=(\\d+)")
				var m := match2.search(trimmed)
				if m:
					format_version = int(m.get_string(1))
				lines.remove_at(0)
			elif trimmed.begins_with("[resource]"):
				resource_section_found = true
				# Rest behalten, da danach Key-Value-Zeilen kommen
	else:
		# Keine Datei: Grundgerüst erzeugen
		header = "[gd_resource type=\"EditorSettings\" format=3]"
		lines = ["[resource]"]
		resource_section_found = true
	
	# --- Sicherstellen, dass Header vorhanden ist ---
	if header == "":
		header = "[gd_resource type=\"EditorSettings\" format=%d]" % format_version
	
	# --- Key-Zeilen suchen und ersetzen ---
	var found_keys := {}
	for i in range(lines.size()):
		var line := lines[i].strip_edges()
		if line == "" or line.begins_with(";"):
			continue
		for key in updates.keys():
			if line.begins_with(key + " "):
				lines[i] = key + " = " + updates[key]
				found_keys[key] = true
	
	# --- Fehlende Keys am Ende anhängen ---
	if not resource_section_found:
		lines.append("[resource]")
	for key in updates.keys():
		if not found_keys.has(key):
			lines.append(key + " = " + updates[key])
	
	# --- Überflüssige Leerzeilen entfernen ---
	while lines.size() > 0 and lines[-1].strip_edges() == "":
		#lines.pop_back()
		lines.remove_at(lines.size()-1)
	
	# --- Zusammenbauen ---
	var new_text := header + "\n" + String("\n").join(lines) + "\n"
	
	# --- Schreiben ---
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(new_text)
	file.close()

func start_project():
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\""])
	get_tree().quit()

func start_blender() -> void:
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \"" +c_root+c_tools+fs_blender+ "\""])
	get_tree().quit()

func dl_start():
	dl_godot = true
	dl_next()
	tab = DL
	
func dl_zip():
	var err = zip_reader.open(c_root + c_tools + dl_current)
	if err != OK:
		return null
	else:
		zip_files = zip_reader.get_files()
		zip_files_size = zip_files.size()
		dl_zip_next()

func dl_zip_next():
	if zip_files.is_empty():
		dl_ziping = false
		zip_reader.close()
		fs_root.remove("tools/" + dl_current)
		dl_current = ""
		zip_files_size = 0
		dl_next()
	else:
		dl_ziping = true
		zip_thread.start(Callable(self, "dl_zip_thread").bind(zip_files.pop_back()))

func dl_zip_thread(file_name: String):
	FileAccess.open(c_root+c_tools+file_name, FileAccess.WRITE).store_buffer(zip_reader.read_file(file_name))

func dl_next():
	dl_ziping = false
	if dl_godot:
		downloading = true
		var tmp_ver = cfg_main.get_value("godot", "ver", "")
		if not tmp_ver == "":
			dl_current = "Godot_v"+tmp_ver+"-stable_win64.exe.zip"
			%HTTPRequest.download_file = c_root + c_tools + dl_current
			%HTTPRequest.request(c_got_web+tmp_ver+"-stable/"+dl_current)
		dl_godot = false
	else:
		downloading = false
		start_check()

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
