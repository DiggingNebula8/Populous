@tool
class_name Part extends Resource
enum Gender { MALE, FEMALE, NEUTRAL }
@export var mesh: PackedScene
@export var gender: Gender = Gender.NEUTRAL
@export var is_skippable: bool = false
