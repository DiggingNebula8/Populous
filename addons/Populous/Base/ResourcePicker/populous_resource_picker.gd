@tool
class_name PopulousResourcePicker extends EditorResourcePicker

## Custom EditorResourcePicker preconfigured for PopulousResource selection.
## 
## This picker is used in the Populous Tool UI to allow users to select
## a PopulousResource (which contains a generator and configuration).

func _ready() -> void:
	base_type = "PopulousResource"
