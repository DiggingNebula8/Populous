@tool
class_name CapsulePerson
extends CharacterBody3D

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

var meta_label: Label3D
var mesh_container: Node3D
var bIsInstantiated: bool = false
@export var material: ORMMaterial3D

func _ready() -> void:
	meta_label = %MetaLabel
	mesh_container = %mesh_container
	
	if meta_label == null:
		PopulousLogger.warning("MetaLabel node not found in CapsulePerson scene")
	if mesh_container == null:
		PopulousLogger.warning("mesh_container node not found in CapsulePerson scene")
	
	if meta_label != null and has_meta("FirstName") and has_meta("LastName"):
		meta_label.text = get_meta("FirstName") + " " + get_meta("LastName")
	_instantiate_person()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if meta_label != null and has_meta("FirstName") and has_meta("LastName"):
			meta_label.text = get_meta("FirstName") + " " + get_meta("LastName")
		_instantiate_person()

func _instantiate_person() -> void:
	if mesh_container == null:
		return
	
	if has_meta("Parts"):
		var parts: Array = get_meta("Parts")
		if not bIsInstantiated:
			# Ensure the container is empty before instantiating
			for child in mesh_container.get_children():
				child.queue_free()
			
			var tree = get_tree()
			if tree != null:
				await tree.process_frame  # Ensure cleanup before adding new meshes

			# Instantiate every part and add it to the mesh container
			for part in parts:
				if part is PackedScene:
					var instance: Node3D = part.instantiate()
					if instance != null:
						#_apply_material_to_children(instance)  # Apply material recursively
						mesh_container.add_child(instance)
					else:
						PopulousLogger.error("Failed to instantiate part: " + str(part))
				else:
					PopulousLogger.error("Part is not a PackedScene: " + str(part))

			bIsInstantiated = true

func _apply_material_to_children(node: Node) -> void:
	# Recursively apply material to all MeshInstance3D nodes
	if node is MeshInstance3D:
		node.material_override = material
	for child in node.get_children():
		_apply_material_to_children(child)
