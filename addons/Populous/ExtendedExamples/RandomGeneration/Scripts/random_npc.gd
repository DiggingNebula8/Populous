@tool
extends CharacterBody3D

var npc: MeshInstance3D
var mat: StandardMaterial3D
var meta_label: Label3D

func _ready() -> void:
	npc = %MeshInstance3D
	mat = npc.get_surface_override_material(0)
	meta_label = %MetaLabel
	if self.has_meta("FirstName") and self.has_meta("LastName"):
		meta_label.text = self.get_meta("FirstName") + " " + self.get_meta("LastName")
	if self.has_meta("Albedo"):	
		mat.albedo_color = self.get_meta("Albedo")
		
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if self.has_meta("FirstName") and self.has_meta("LastName"):
			meta_label.text = self.get_meta("FirstName") + " " + self.get_meta("LastName")
		if self.has_meta("Albedo"):	
			mat.albedo_color = self.get_meta("Albedo")
