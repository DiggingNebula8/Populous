@tool
class_name PopulousGenerator extends Resource

## Base class for NPC generation logic.
## 
## EXTENSION POINTS:
## - Override `_generate()` for custom spawning logic
## - Override `_get_params()` to expose parameters to UI
## - Override `_set_params()` to handle parameter updates
## - Use `_spawn_npc()` helper to add NPCs to container
## - Use `_clean_container()` helper to remove previous NPCs
## - Use `_setup_npc_owner()` helper for editor integration
## 
## EXAMPLES:
## - See RandomPopulousGenerator for grid-based spawning
## - See CapsulePersonPopulousGenerator for random positioning

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# RESOURCES
#═══════════════════════════════════════════════════════════════════════════════

@export var resource: PackedScene = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousNPC.tscn")
@export var meta_resource: PopulousMeta = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousMeta.tres")

#═══════════════════════════════════════════════════════════════════════════════
# GENERATION
#═══════════════════════════════════════════════════════════════════════════════

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
	
	if resource == null:
		PopulousLogger.error("Cannot generate NPCs - NPC resource (PackedScene) is not set")
		return
		
	if meta_resource == null:
		PopulousLogger.error("Cannot generate NPCs - Meta resource is not set")
		return
		
	# Clean previous NPCs
	_clean_container(populous_container)
		
	# Spawn single NPC using helper
	var spawned_npc = _spawn_npc(populous_container)
	if spawned_npc == null:
		return
	
	PopulousLogger.debug("Successfully spawned NPC")

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

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
## Use PopulousParamValidator for type-safe parameter handling.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Cleans all children from the container.
## Call this before spawning new NPCs.
## 
## @param container: The container node to clean.
## @return: void
func _clean_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

## Sets up NPC ownership for proper editor integration.
## Call this after adding NPC to container.
## 
## @param npc: The NPC node to set ownership for.
## @param container: The container the NPC was added to.
## @return: void
func _setup_npc_owner(npc: Node, container: Node) -> void:
	var tree = container.get_tree()
	if tree != null:
		var scene_root = tree.edited_scene_root
		if scene_root != null:
			npc.owner = scene_root

## Spawns a single NPC with proper setup.
## Handles instantiation, parenting, ownership, and metadata application.
## 
## @param container: The container node to spawn the NPC in.
## @return: The spawned NPC, or null if spawning failed.
func _spawn_npc(container: Node) -> Node:
	if resource == null:
		PopulousLogger.error("Cannot spawn NPC - resource is null")
		return null
	
	var npc = resource.instantiate()
	if npc == null:
		PopulousLogger.error("Failed to instantiate NPC from resource")
		return null
	
	container.add_child(npc)
	_setup_npc_owner(npc, container)
	
	if meta_resource != null:
		meta_resource.set_metadata(npc)
	
	return npc
