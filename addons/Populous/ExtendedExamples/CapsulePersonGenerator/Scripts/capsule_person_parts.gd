@tool
class_name CapsulePersonParts extends Resource

# Define different part categories as arrays of Part resources
@export_group("Hair")
@export var hair: Array[CapsulePart]

@export_group("Head")
@export var head: Array[CapsulePart]

@export_group("Head Prop")
@export var head_prop: Array[CapsulePart]

@export_group("Eyes")
@export var eyes: Array[CapsulePart]

@export_group("Mouth")
@export var mouth: Array[CapsulePart]

@export_group("Torso")
@export var torso: Array[CapsulePart]

@export_group("Arms")
@export var arms: Array[CapsulePart]

@export_group("Arm Sleeve")
@export var arm_sleeve: Array[CapsulePart]

@export_group("Body Prop")
@export var body_prop: Array[CapsulePart]

@export_group("Legs")
@export var legs: Array[CapsulePart]
