@tool
class_name PopulousResource extends Resource

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

## Main resource class for Populous addon.
## Contains a generator that defines how NPCs are created and spawned.
## Use this resource in the Populous Tool to generate NPCs in your scene.

@export var generator: PopulousGenerator = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousGenerator.tres")

## Generates NPCs in the specified container using the configured generator.
## 
## @param populous_container: The Node3D container where NPCs will be spawned.
## Must be a PopulousContainer node (has the populous_container meta).
##
## @return: void
func run_populous(populous_container: Node) -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate NPCs - container is null")
		return
	
	if generator == null:
		PopulousLogger.error("Cannot generate NPCs - generator resource is not set")
		return
	
	generator._generate(populous_container)

func get_params() -> Dictionary:
	if generator == null:
		PopulousLogger.warning("Generator is null, returning empty params")
		return {}
	return generator._get_params()
	
func set_params(params: Dictionary) -> void:
	if generator == null:
		PopulousLogger.error("Cannot set params - generator resource is not set")
		return
	
	if params == null:
		PopulousLogger.error("Cannot set params - params dictionary is null")
		return
	
	generator._set_params(params)
