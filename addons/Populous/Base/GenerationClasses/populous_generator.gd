@tool
class_name PopulousGenerator extends Resource

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

@export var resource: PackedScene = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousNPC.tscn")
@export var meta_resource: PopulousMeta = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousMeta.tres")

## Base class for NPC generation logic.
## 
## Extend this class to create custom generators that define how NPCs are spawned.
## Override `_generate()` to implement custom spawning logic, and `_get_params()` / `_set_params()`
## to expose parameters for UI editing.

## Generates NPCs in the specified container.
## 
## Base implementation spawns a single NPC from the resource and applies metadata.
## Override this method in child classes to implement custom generation logic.
## 
## @param populous_container: The Node3D container where NPCs will be spawned.
## Must be a PopulousContainer node (has the populous_container meta).
## @return: void
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
		
	# Clean previous NPCs
	for child in populous_container.get_children():
		child.queue_free()
		
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

## Returns a dictionary of parameters that can be edited in the UI.
## 
## Override this method in child classes to expose generator parameters.
## Parameters will be automatically bound to UI controls in the Populous Tool.
## 
## @return: Dictionary with parameter names as keys and default values as values.
func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

## Sets parameters from a dictionary (typically from UI changes).
## 
## Override this method in child classes to handle parameter updates.
## Parameters are updated in real-time as users modify UI controls.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
