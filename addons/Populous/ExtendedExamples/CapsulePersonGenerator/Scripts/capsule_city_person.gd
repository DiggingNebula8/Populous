@tool
class_name CapsuleCityPerson
extends CharacterBody3D

var modular_pieces: CapsuleCityParts = preload("res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Resources/CapsulePersonParts.tres")

var meta_label: Label3D

func _ready() -> void:
	meta_label = %MetaLabel
	if self.has_meta("FirstName") and self.has_meta("LastName"):
		meta_label.text = self.get_meta("FirstName") + " " + self.get_meta("LastName")
		
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if self.has_meta("FirstName") and self.has_meta("LastName"):
			meta_label.text = self.get_meta("FirstName") + " " + self.get_meta("LastName")
