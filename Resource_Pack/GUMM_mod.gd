extends RefCounted

var resource_storage: Array[Resource]
var base_path: String

func initialize(mod_path: String, scene_tree: SceneTree) -> void:
	base_path = mod_path
	_initialize(scene_tree)

func _initialize(scene_tree: SceneTree) -> void:
	pass

func replace_resource_at(target_path: String, resource: Resource) -> void:
	resource.take_over_path(target_path)
	resource_storage.append(resource)

func get_full_path(path: String) -> String:
	return base_path.path_join(path.trim_prefix("mod://"))