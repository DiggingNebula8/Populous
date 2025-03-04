class_name CapsuleCityPerson
extends CharacterBody3D

var modular_pieces: CapsuleCityParts = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Resources/CapsuleCityParts.tres")

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		#randomize_appearance()
		pass
