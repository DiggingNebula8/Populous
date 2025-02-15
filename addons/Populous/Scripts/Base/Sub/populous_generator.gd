@tool
class_name PopulousGenerator extends Resource

@export var resource: PackedScene
@export var meta_resource: PopulousMeta

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
		
	
