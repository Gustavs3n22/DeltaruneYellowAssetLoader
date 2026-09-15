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

					var wav_file := FileAccess.open(file, FileAccess.READ)
					if wav_file == null:
						print("Failed to open wav: ", file)
						continue

					var bytes := wav_file.get_buffer(wav_file.get_length())
					wav_file.close()

					if bytes.size() < 44:
						print("Invalid wav (too small): ", file)
						continue

					var riff := bytes.slice(0, 4).get_string_from_ascii()
					var wave := bytes.slice(8, 12).get_string_from_ascii()
					if riff != "RIFF" or wave != "WAVE":
						print("Not a valid wav file: ", file)
						continue

					var num_channels := bytes.decode_u16(22)
					var sample_rate := bytes.decode_u32(24)
					var bits_per_sample := bytes.decode_u16(34)

					var data_pos := -1
					for i in range(12, bytes.size() - 8):
						if bytes.decode_u8(i) == 100 and bytes.decode_u8(i + 1) == 97 and bytes.decode_u8(i + 2) == 116 and bytes.decode_u8(i + 3) == 97:
							data_pos = i
							break

					if data_pos == -1:
						print("No data chunk found in wav: ", file)
						continue

					var data_size := bytes.decode_u32(data_pos + 4)
					var pcm_start := data_pos + 8
					if pcm_start + data_size > bytes.size():
						print("Invalid wav data size: ", file)
						continue

					var pcm := bytes.slice(pcm_start, pcm_start + data_size)

					var sound := AudioStreamWAV.new()
					sound.data = pcm
					sound.format = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 else AudioStreamWAV.FORMAT_8_BITS
					sound.mix_rate = sample_rate
					sound.stereo = num_channels == 2

					replace_resource_at("res://Audio/" + dst_file, sound)
					print("Successfully replaced sound: ", "res://Audio/" + dst_file)
				else:
					print("WARNING: file ", file, "is not ogg, mp3 or wav. Unsupported format is skipped")
	else:
		print()
		print("Audio directory not found, skipping scan.")
