@tool
class_name CapsulePart extends Resource

@export var mesh: PackedScene  # The actual mesh scene
@export var gender: CapsulePersonConstants.Gender = CapsulePersonConstants.Gender.NEUTRAL  # Determines who can use this part
@export var skin_type: CapsulePersonConstants.SkinType = CapsulePersonConstants.SkinType.DEFAULT  # Determines skin compatibility
@export var is_skippable: bool = false  # If true, the part might be skipped randomly
@export var weight: float = 1.0  # Probability weight for random selection (higher = more common)
@export var override_material: Material  # If set, overrides the default material
@export var tags: Array[String]  # Extra metadata (e.g., "fancy", "military", "casual")
