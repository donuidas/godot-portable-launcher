extends HTTPRequest
class_name Downloader


enum dl_status {
	NONE,
	DOWNLOAD,
	UNPACK
}

static var c_root = OS.get_executable_path().get_base_dir()

var fs_root: DirAccess = DirAccess.open(c_root)

var downloading = false
var dl_ziping = false

var _zip_thread = Thread.new()
var _zip_reader = ZIPReader.new()
var _zip_files: Array = []
var _zip_files_size = 0

var _status: dl_status = dl_status.NONE
var status: dl_status:
	get:
		return _status
var procent: int = 0
var current_name: StringName = &""
var status_text: String = ""


func _process(_delta):
	if downloading:
		if _status == dl_status.DOWNLOAD:
			var tmp_total_size = get_body_size()
			var tmp_size = get_downloaded_bytes()
			procent = 0
			if tmp_size != 0:
				@warning_ignore("integer_division")
				procent = 100 * tmp_size / tmp_total_size
			status_text = str(snappedf(tmp_size/1048576.0, 0.001)) \
									 +"MB von "+ str(snappedf(tmp_total_size/1048576.0, 0.001)) +"MB"
		elif _zip_thread.is_alive():
			procent = 0
			if _zip_files_size != 0:
				@warning_ignore("integer_division")
				procent = 100 * _zip_files.size() / _zip_files_size
			status_text = "noch "+ str(_zip_files.size()) +" von "+ str(_zip_files_size)
		else:
			_zip_thread.wait_to_finish()
			dl_zip_next()

func start_download(label:String, source:String, to:String):
	dl_next(label, source, to)

func dl_next(label:String, source:String, to:String):
	dl_ziping = false
	downloading = true
	_status = dl_status.DOWNLOAD
	download_file = to
	request(source)
	current_name = label

func dl_zip():
	_status = dl_status.UNPACK
	var err = _zip_reader.open(download_file)
	if err != OK:
		return null
	else:
		_zip_files = _zip_reader.get_files()
		_zip_files_size = _zip_files.size()
		dl_zip_next()

func dl_zip_next():
	if _zip_files.is_empty():
		dl_ziping = false
		_zip_reader.close()
		fs_root.remove(download_file)
		_zip_files_size = 0
		downloading = false
		_status = dl_status.NONE
	else:
		dl_ziping = true
		_zip_thread.start(Callable(self, "dl_zip_thread").bind(_zip_files.pop_back()))

func dl_zip_thread(file_name: String):
	if file_name.right(1) != "/":
		var tmp_dir = file_name.get_base_dir().split("/")
		var tmp_comp_dir = c_root+"/tools/"
		for dir in tmp_dir:
			tmp_comp_dir += dir+"/"
			if not fs_root.dir_exists(tmp_comp_dir):
				fs_root.make_dir(tmp_comp_dir)
		FileAccess.open(c_root+"/tools/"+file_name, FileAccess.WRITE).store_buffer(_zip_reader.read_file(file_name))
