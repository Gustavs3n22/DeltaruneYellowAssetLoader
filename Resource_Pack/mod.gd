extends "GUMM_mod.gd"

func scan_directory(path: String, file_list: Array) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		print("Failed to open directory: ", path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path + "/" + file_name

		if dir.current_is_dir():
			scan_directory(full_path, file_list)
		else:
			file_list.append(full_path)

		file_name = dir.get_next()

func read_mod_cfg(cfg_path: String) -> String:
	var file = FileAccess.open(cfg_path, FileAccess.ModeFlags.READ)
	if file == null:
		print("Failed to open mod.cfg: ", cfg_path)
		return ""
	
	var language = "na"
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("language="):
			language = line.split("=")[1].trim_prefix("\"").trim_suffix("\"")
			break
	
	return language

func remove_all_folders(path: String) -> bool:
	var dir = DirAccess.open(path)
	if dir == null:
		return false
	
	dir.list_dir_begin()
	var item_name = dir.get_next()
	
	while item_name != "":
		if item_name != "." and item_name != "..":
			var full_path = path.path_join(item_name)
			
			if dir.current_is_dir():
				remove_all_folders(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		
		item_name = dir.get_next()
	
	DirAccess.remove_absolute(path)
	return true


func _initialize(scene_tree: SceneTree) -> void:
	print("Resource Pack Initializing...")


	# SPRITES
	var global_sprites_path = ProjectSettings.globalize_path("res://Resource_Pack/Sprites")
	var all_pngs : Array = []

	scan_directory(global_sprites_path, all_pngs)

	for file in all_pngs:
		print("Found file: ", file)
		var image = Image.new()
		var error = image.load(file)

		if error == OK:
			var sprite = ImageTexture.create_from_image(image)
			var found_slash: int = file.find("/")
			var new_path: String = file.substr(found_slash)

			replace_resource_at("res:/"+new_path, sprite)
			print("Successfully replaced sprite: ", "res:/"+new_path)
		else:
			print("Error loading sprite: ", error)


	# TEXT
	var text_source = ProjectSettings.globalize_path("res://Resource_Pack/Text")
	var all_txts : Array = []

	scan_directory(text_source, all_txts)
	var language = read_mod_cfg("res://Resource_Pack/mod.cfg")
	var text_target = "user://Text/Text_" + language
	print()
	print("Reading language from mod.cfg: ", language)
	print()

	if language == "na":
		pass
	elif language == "remove":
		remove_all_folders("user://Text/")
		print("WARNING: language setting set to 'remove', ALL language packs in deltarune yellow's appdata folder were removed!")
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(text_target))

		for file in all_txts:
			print("Found text file: ", file)
			var text_file_name = file.get_file()
			var data = FileAccess.get_file_as_bytes(file)

			if data.is_empty():
				print("Failed to read text file: ", file)

			var found_slash_one: int = file.find("/")
			var dst_file_one: String = file.substr(found_slash_one + 1)
			var found_slash_two: int = dst_file_one.find("/")
			var dst_file: String = dst_file_one.substr(found_slash_two + 1)
			var fin_path = text_target + "/" + dst_file

			var fin_dir = fin_path.get_base_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fin_dir))

			var out = FileAccess.open(fin_path, FileAccess.ModeFlags.WRITE)
			if out:
				out.store_buffer(data)
				out.close()
				print("Created text file: ", fin_path)
			else:
				print("Failed to write text file: ", fin_path)


	# AUDIO
	var all_sounds : Array = []
	var global_sounds_path = ProjectSettings.globalize_path("res://Resource_Pack/Audio")
	if DirAccess.dir_exists_absolute(global_sounds_path):
		scan_directory(global_sounds_path, all_sounds)

		if all_sounds.is_empty():
			print()
			print("No audio files found. Skipping")
		else:
			for file in all_sounds:
				var dst_file: String = file.trim_prefix("Resource_Pack/Audio/")
				var ext: String = file.get_extension().to_lower()

				if ext == "ogg":
					print("Found ogg file: ", file)
					var modded_audio = AudioStreamOggVorbis.load_from_file(file)
					replace_resource_at("res://Audio/" + dst_file, modded_audio)
					print("Successfully replaced sound: ", "res://Audio/" + dst_file)
				elif ext == "mp3":
					print("Found mp3 file: ", file)
					var modded_audio = AudioStreamMP3.load_from_file(file)
					replace_resource_at("res://Audio/" + dst_file, modded_audio)
					print("Successfully replaced sound: ", "res://Audio/" + dst_file)
				elif ext == "wav":
					print("Found wav file: ", file)
					var modded_audio = AudioStreamWAV.new()
					modded_audio.data = FileAccess.get_file_as_bytes(file)
					replace_resource_at("res://Audio/" + dst_file, modded_audio)
					print("Successfully replaced sound: ", "res://Audio/" + dst_file)
				else:
					print("WARNING: file ", file, "is not ogg, mp3 or wav. Unsupported format is skipped")

	else:
		print()
		print("Audio directory not found, skipping scan.")
