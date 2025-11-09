@tool
class_name PopulousGenerator extends Resource

@export var resource: PackedScene = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousNPC.tscn")
@export var meta_resource: PopulousMeta = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousMeta.tres")

func _generate(populous_container: Node) -> void:
	if populous_container == null:
		push_error("Populous: Cannot generate NPCs - container is null")
		return
	
	var npc_resource: PackedScene = resource
	
	if npc_resource == null:
		push_error("Populous: Cannot generate NPCs - NPC resource (PackedScene) is not set")
		return
		
	var npc_meta_resource = meta_resource
	
	if npc_meta_resource == null:
		push_error("Populous: Cannot generate NPCs - Meta resource is not set")
		return
		
	# Clean previous NPCs
	for child in populous_container.get_children():
		child.queue_free()
		
	var spawned_npc: Node = npc_resource.instantiate()
	if spawned_npc == null:
		push_error("Populous: Failed to instantiate NPC from resource")
		return
	
	populous_container.add_child(spawned_npc)
	
	var tree = populous_container.get_tree()
	if tree != null:
		var scene_root = tree.edited_scene_root
		if scene_root != null:
			spawned_npc.owner = scene_root
	
	npc_meta_resource.set_metadata(spawned_npc)
	
	PopulousLogger.debug("Successfully spawned NPC")

func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
