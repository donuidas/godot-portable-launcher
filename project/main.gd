@tool
extends Control


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


static var c_root = OS.get_executable_path().get_base_dir()
const c_tools = "/tools/"
const c_proj = "/project/"
const c_proj_file = "/project/project.godot"
const c_sc = "/tools/_sc_"
const c_got_ver = "/tools/godot.ver"
const c_blend_ver = "/tools/blender.ver"
const c_got_web = "https://downloads.tuxfamily.org/godotengine/"

var fs_root: DirAccess = DirAccess.open(c_root)
var fs_godot = ""

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
		if fs_root.dir_exists("tools"):
			if not FileAccess.file_exists(c_root+c_sc):
				FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
			if not FileAccess.file_exists(c_root+c_got_ver):
				FileAccess.open(c_root+c_got_ver, FileAccess.WRITE).close()
			if not FileAccess.file_exists(c_root+c_blend_ver):
				FileAccess.open(c_root+c_blend_ver, FileAccess.WRITE).close()
		else:
			fs_root.make_dir("tools")
			FileAccess.open(c_root+c_sc, FileAccess.WRITE).close()
			FileAccess.open(c_root+c_got_ver, FileAccess.WRITE).close()
			FileAccess.open(c_root+c_blend_ver, FileAccess.WRITE).close()
		
		if not fs_root.dir_exists("project"):
			fs_root.make_dir("project")
			FileAccess.open(c_root+c_proj_file, FileAccess.WRITE).close()
		
		if not fs_root.dir_exists("export"):
			fs_root.make_dir("export")

func _ready():
	start_check()

func _process(delta):
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
				tmp_procent = 100 * zip_files.size() / zip_files_size
			$tab/Download/Box/ProgressBar.value = tmp_procent
			$tab/Download/Box/item/status.text = "noch "+ str(zip_files.size()) +" von "+ str(zip_files_size)
		else:
			zip_thread.wait_to_finish()
			dl_zip_next()

func start_check():
	tab = 0
	var tmp_ver = FileAccess.open(c_root+c_got_ver, FileAccess.READ).get_as_text()
	if not tmp_ver == "":
		fs_godot = "Godot_v"+tmp_ver+"-stable_win64.exe"
		if FileAccess.file_exists(c_root+c_tools+fs_godot):
			start_tab = 0
		else:
			start_tab = 1
	else:
		start_tab = 2

func start_editor():
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\" -e"])

func start_project():
	OS.create_process("CMD.exe", ["/C", "CD " + c_root+c_proj + 
		" && START \"\" \""+c_root+c_tools+fs_godot+"\""])

func dl_start():
	dl_godot = true
	dl_next()
	tab = 1

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
		var tmp_ver = FileAccess.open(c_root+c_got_ver, FileAccess.READ).get_as_text()
		if not tmp_ver == "":
			dl_current = "Godot_v"+tmp_ver+"-stable_win64.exe.zip"
			%HTTPRequest.download_file = c_root + c_tools + dl_current
			%HTTPRequest.request(c_got_web+tmp_ver+"/"+dl_current)
		dl_godot = false
	else:
		downloading = false
		start_check()

func cfg_got_ver(text: String):
	FileAccess.open(c_root+c_got_ver, FileAccess.WRITE).store_string(text)
