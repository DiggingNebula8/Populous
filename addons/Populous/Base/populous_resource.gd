@tool
class_name  PopulousResource extends Resource

@export var generator: PopulousGenerator = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousGenerator.tres")

func run_populous(populous_container: Node) -> void:
	if populous_container == null:
		push_error("Populous: Cannot generate NPCs - container is null")
		return
	
	if generator == null:
		push_error("Populous: Cannot generate NPCs - generator resource is not set")
		return
	
	generator._generate(populous_container)

func get_params() -> Dictionary:
	if generator == null:
		push_warning("Populous: Generator is null, returning empty params")
		return {}
	return generator._get_params()
	
func set_params(params: Dictionary) -> void:
	if generator == null:
		push_error("Populous: Cannot set params - generator resource is not set")
		return
	
	if params == null:
		push_error("Populous: Cannot set params - params dictionary is null")
		return
	
	generator._set_params(params)
