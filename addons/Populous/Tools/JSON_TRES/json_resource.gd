@tool
class_name JSONResource extends Resource

## A simple resource for storing JSON data as a Godot Dictionary.
## 
## This resource is used by the JSON_TRES tool to convert JSON files
## to .tres resources that can be referenced throughout the project.
## 
## Usage:
##   var json_res: JSONResource = preload("res://path/to/file.tres")
##   var names = json_res.data.FirstNames  # Access nested data
## 
## The data dictionary preserves the full JSON structure with
## Godot-compatible types (Dictionary, Array, String, int, float, bool).

## The parsed JSON data stored as a Godot Dictionary.
## Nested objects become nested Dictionaries, arrays become Arrays.
@export var data: Dictionary
