extends Object
class_name EditorSettingsFile


static func change(path: String, updates: Dictionary) -> void: 
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
			elif trimmed.begins_with("[resource]"):
				resource_section_found = true
				# Rest behalten, da danach Key-Value-Zeilen kommen
		lines.remove_at(0)
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
	var tmp_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(tmp_dir):
		DirAccess.make_dir_absolute(tmp_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(new_text)
	file.close()
