@tool
class_name CapsulePart extends Resource

enum Gender { MALE, FEMALE, NEUTRAL }
enum SkinType { LIGHT, MEDIUM, DARK }

@export var mesh: PackedScene  # The actual mesh scene
@export var gender: Gender = Gender.NEUTRAL  # Determines who can use this part
@export var skin_type: SkinType = SkinType.MEDIUM  # Determines skin compatibility
@export var is_skippable: bool = false  # If true, the part might be skipped randomly
@export var weight: float = 1.0  # Probability weight for random selection (higher = more common)
@export var override_material: Material  # If set, overrides the default material
@export var color_variants: Array[Color]  # Possible color variations
@export var scale_variants: Array[Vector3]  # Possible size variations
@export var tags: Array[String]  # Extra metadata (e.g., "fancy", "military", "casual")

# Optional function to randomize properties when spawning
func get_randomized_properties() -> Dictionary:
	var properties = {}
	
	if not color_variants.is_empty():
		properties["color"] = color_variants.pick_random()
	
	if not scale_variants.is_empty():
		properties["scale"] = scale_variants.pick_random()
	
	return properties
