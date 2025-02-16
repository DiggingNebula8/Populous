@tool
class_name PopulousGenerator extends Resource

@export var resource: PackedScene = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousNPC.tscn")
@export var meta_resource: PopulousMeta = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousMeta.tres")

func _generate(populous_container: Node) -> void:
	if populous_container == null:
		print_debug("Could not find populous container")
		return
		
	var npc_resource: PackedScene = resource
	
	if npc_resource == null:
		print_debug("Missing NPC Resource")
		return
		
	var npc_meta_resource = meta_resource
	
	if npc_meta_resource == null:
		print_debug("Missing NPC Meta Resource")
		return
	else:
		pass
		
	for child in populous_container.get_children():
		child.queue_free() #clean previous
		
	var spawned_npc: Node = npc_resource.instantiate()
	populous_container.add_child(spawned_npc)
	spawned_npc.owner = populous_container.get_tree().edited_scene_root
	npc_meta_resource.set_metadata(spawned_npc)
	
	print_debug("Spawned NPC")

func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
