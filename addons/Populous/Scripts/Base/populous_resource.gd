@tool
class_name  PopulousResource extends Resource

@export var generator: PopulousGenerator

func run_populous(populous_container: Node):
	generator._generate(populous_container)
