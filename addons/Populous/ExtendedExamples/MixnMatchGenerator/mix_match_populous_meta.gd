@tool
class_name MixMatchPopulousMeta extends PopulousMeta

var modular_pieces: CapsuleCityParts = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Resources/CapsuleCityParts.tres")
var material: ORMMaterial3D = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Assets/AssetHunts-CapsuleCityPeople/CapsuleCity.tres")
func set_metadata(npc: Node) -> void:
	npc.name = "PopulousNPC"
	npc.set_meta("PopulousMeta",true)
	apply_modular_pieces(npc)

func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
	

func apply_modular_pieces(npc: Node) -> void:
	if modular_pieces == null:
		print_debug("[ERROR] No modular pieces assigned to CapsuleCityPerson!")
		return
	
	# Ensure mesh_container exists inside npc
	var mesh_container = npc.find_child("mesh_container", true, false)
	if mesh_container == null:
		mesh_container = Node3D.new()
		mesh_container.name = "mesh_container"
		npc.add_child(mesh_container)
		mesh_container.owner = npc.get_tree().edited_scene_root

	# Iterate over actual properties
	for part_name in ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]:
		var piece_array: Array[PackedScene] = modular_pieces.get(part_name)

		if piece_array and not piece_array.is_empty():
			print("Spawning: ", part_name)  # Debugging
			var instance: Node3D = piece_array.pick_random().instantiate()
			instance.name = part_name  # Name it properly
			mesh_container.add_child(instance)  # Attach it to the NPC
			instance.owner = mesh_container.get_tree().edited_scene_root

			# Apply material recursively
			_apply_material(instance)


func _apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			node.set_surface_override_material(i, material)  # Apply material
	for child in node.get_children():
		_apply_material(child)  # Recursively apply to children
