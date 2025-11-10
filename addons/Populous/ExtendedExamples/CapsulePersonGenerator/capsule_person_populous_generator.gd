@tool
class_name CapsulePersonPopulousGenerator extends PopulousGenerator

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

func _generate(populous_container: Node) -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate NPCs - container is null")
		return
	
	var npc_resource: PackedScene = resource
	
	if npc_resource == null:
		PopulousLogger.error("Cannot generate NPCs - NPC resource (PackedScene) is not set")
		return
		
	var npc_meta_resource = meta_resource
	
	if npc_meta_resource == null:
		PopulousLogger.error("Cannot generate NPCs - Meta resource is not set")
		return
		
	for child in populous_container.get_children():
		child.queue_free() #clean previous
		
	var spawned_npc: Node = npc_resource.instantiate()
	if spawned_npc == null:
		PopulousLogger.error("Failed to instantiate NPC from resource")
		return
	
	populous_container.add_child(spawned_npc)
	var tree = populous_container.get_tree()
	if tree != null:
		var scene_root = tree.edited_scene_root
		if scene_root != null:
			spawned_npc.owner = scene_root
	npc_meta_resource.set_metadata(spawned_npc)
	
	PopulousLogger.debug("Successfully spawned NPC")

## Returns empty dictionary (no generator-specific parameters).
## 
## This generator doesn't expose any parameters - all customization is handled by the meta resource.
## 
## @return: Empty dictionary.
func _get_params() -> Dictionary:
	return {}  # No generator-specific parameters

## No-op parameter setter (no generator-specific parameters).
## 
## This generator doesn't have parameters to set - all customization is handled by the meta resource.
## 
## @param params: Dictionary containing parameter key-value pairs (unused).
## @return: void
func _set_params(params: Dictionary) -> void:
	pass  # No generator-specific parameters