extends HTTPRequest
class_name Downloader


enum dl_status {
	NONE,
	DOWNLOAD,
	UNPACK
}

var _zip_thread = Thread.new()
var _zip_reader = ZIPReader.new()
var _zip_files: PackedStringArray = []
var _zip_files_size = 0

var _status: dl_status = dl_status.NONE
var status: dl_status:
	get:
		return _status
var procent: int = 0
var current_name: StringName = &""
var status_text: String = ""


func _process(_delta):
	if _status == dl_status.DOWNLOAD:
		var tmp_total_size = get_body_size()
		var tmp_size = get_downloaded_bytes()
		procent = 0
		if tmp_size != 0:
			@warning_ignore("integer_division")
			procent = 100 * tmp_size / tmp_total_size
		status_text = str(snappedf(tmp_size/1048576.0, 0.001)) \
								 +"MB von "+ str(snappedf(tmp_total_size/1048576.0, 0.001)) +"MB"
	elif _status == dl_status.UNPACK:
		procent = 0
		if _zip_files_size != 0:
			@warning_ignore("integer_division")
			procent = 100 * _zip_files.size() / _zip_files_size
		status_text = "noch "+ str(_zip_files.size()) +" von "+ str(_zip_files_size)
	elif _status == dl_status.NONE:
		if _zip_thread.is_started():
			if not _zip_thread.is_alive():
				_zip_thread.wait_to_finish()

func start_download(label:String, source:String, to:String):
	_status = dl_status.DOWNLOAD
	download_file = to
	request(source)
	current_name = label
	await request_completed
	_zip()

func _zip():
	_status = dl_status.UNPACK
	var err = _zip_reader.open(download_file)
	if err != OK:
		return null
	else:
		_zip_files = _zip_reader.get_files()
		_zip_files_size = _zip_files.size()
		_zip_thread.start(Callable(self, "_zip_thread_func"))

func _zip_thread_func():
	var base_dir = download_file.get_base_dir()+"/"
	for file in range(_zip_files.size()-1, -1, -1):
		if _zip_files[file].right(1) == "/":
			if not DirAccess.dir_exists_absolute(base_dir+_zip_files[file]):
				DirAccess.make_dir_recursive_absolute(base_dir+_zip_files[file])
			_zip_files.remove_at(file)
	for file in range(_zip_files.size()-1, -1, -1):
		FileAccess.open(base_dir+_zip_files[file], FileAccess.WRITE).store_buffer(_zip_reader.read_file(_zip_files[file]))
		_zip_files.resize(_zip_files.size()-1)
	_zip_files = []
	_zip_reader.close()
	DirAccess.remove_absolute(download_file)
	_zip_files_size = 0
	_status = dl_status.NONE
