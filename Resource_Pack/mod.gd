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

func read_u16(arr: PackedByteArray, pos: int) -> int:
	return int(arr[pos]) | (int(arr[pos + 1]) << 8)

func read_u32(arr: PackedByteArray, pos: int) -> int:
	return int(arr[pos]) | (int(arr[pos + 1]) << 8) | (int(arr[pos + 2]) << 16) | (int(arr[pos + 3]) << 24)

func read_f32(arr: PackedByteArray, pos: int) -> float:
	var peer := StreamPeerBuffer.new()
	peer.data_array = arr.slice(pos, pos + 4)
	return peer.get_float()



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

					var f := FileAccess.open(file, FileAccess.READ)
					if f == null:
						print("Failed to open wav: ", file)
						continue

					var bytes := f.get_buffer(f.get_length())
					f.close()

					if bytes.size() < 44:
						print("Invalid wav (too small): ", file)
						continue

					if bytes.slice(0, 4).get_string_from_ascii() != "RIFF" or bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
						print("Not a valid wav: ", file)
						continue

					var fmt_found := false
					var data_found := false

					var audio_format := 0
					var num_channels := 0
					var sample_rate := 0
					var bits_per_sample := 0
					var data_pos := 0
					var data_size := 0

					var i := 12
					while i + 8 <= bytes.size():
						var chunk_id := bytes.slice(i, i + 4).get_string_from_ascii()
						var chunk_size: int = read_u32(bytes, i + 4)
						var chunk_data := i + 8

						if chunk_data + chunk_size > bytes.size():
							print("Corrupt wav chunk: ", file)
							break

						if chunk_id == "fmt ":
							fmt_found = true
							audio_format = read_u16(bytes, chunk_data)
							num_channels = read_u16(bytes, chunk_data + 2)
							sample_rate = read_u32(bytes, chunk_data + 4)
							bits_per_sample = read_u16(bytes, chunk_data + 14)

						elif chunk_id == "data":
							data_found = true
							data_pos = chunk_data
							data_size = chunk_size
							break

						i += 8 + chunk_size
						if chunk_size % 2 == 1:
							i += 1

					if not fmt_found or not data_found:
						print("Missing fmt or data chunk: ", file)
						continue

					var pcm := PackedByteArray()

					if audio_format == 1:
						# PCM
						if bits_per_sample == 16:
							pcm = bytes.slice(data_pos, data_pos + data_size)
						elif bits_per_sample == 8:
							# Convert unsigned 8-bit PCM to signed 16-bit PCM
							var sample_count := data_size
							pcm.resize(sample_count * 2)
							var out_i := 0
							for s in range(sample_count):
								var u8 := int(bytes[data_pos + s])
								var sample_i := (u8 - 128) << 8
								pcm[out_i] = sample_i & 0xFF
								pcm[out_i + 1] = (sample_i >> 8) & 0xFF
								out_i += 2
						else:
							print("Unsupported PCM bit depth: ", bits_per_sample, " in ", file)
							continue

					elif audio_format == 3:
						if bits_per_sample != 32:
							print("Unsupported float WAV bit depth: ", bits_per_sample, " in ", file)
							continue

						var sample_count := data_size / 4
						pcm.resize(sample_count * 2)
						var out_i := 0

						for s in range(sample_count):
							var in_i := data_pos + s * 4
							var sample_f := read_f32(bytes, in_i)
							var sample_i := int(clampf(sample_f, -1.0, 1.0) * 32767.0)
							pcm[out_i] = sample_i & 0xFF
							pcm[out_i + 1] = (sample_i >> 8) & 0xFF
							out_i += 2
					else:
						print("Unsupported WAV format: ", audio_format, " in ", file)
						continue

					var sound := AudioStreamWAV.new()
					sound.data = pcm
					sound.mix_rate = sample_rate
					sound.stereo = (num_channels == 2)
					sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
					sound.format = AudioStreamWAV.FORMAT_16_BITS

					replace_resource_at("res://Audio/" + dst_file, sound)
					print("Successfully replaced wav: ", file)

				else:
					print("WARNING: file ", file, "is not ogg, mp3 or wav. Unsupported format is skipped")

	else:
		print()
		print("Audio directory not found, skipping scan.")
