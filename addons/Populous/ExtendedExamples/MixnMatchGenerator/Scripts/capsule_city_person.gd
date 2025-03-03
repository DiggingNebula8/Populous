@tool
class_name CapsuleCityPerson
extends CharacterBody3D

@export var modular_pieces: CapsuleCityParts

func apply_modular_pieces() -> void:
	if modular_pieces == null:
		print_debug("No modular pieces assigned!")
		return

	for part in modular_pieces.get_property_list():
		if part.name in ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]:
			var piece_array: Array[PackedScene] = modular_pieces.get(part.name)
			if not piece_array.is_empty():
				var instance = piece_array.pick_random().instantiate()
				if has_node(part.name):  
					get_node(part.name).add_child(instance)

func randomize_appearance():
	apply_modular_pieces()
