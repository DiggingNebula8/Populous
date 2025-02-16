@tool
class_name  PopulousResource extends Resource

@export var generator: PopulousGenerator = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousGenerator.tres")

func run_populous(populous_container: Node):
	generator._generate(populous_container)
