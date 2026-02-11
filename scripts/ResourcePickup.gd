extends Area3D
class_name ResourcePickup

@export var resource_type: String = "Scrap"

@onready var label: Label3D = $Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	activate()


func activate() -> void:
	visible = true
	monitoring = true
	if label != null:
		label.text = resource_type


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("caravan"):
		return
	GameState.add_resource(resource_type, 1)
	visible = false
	monitoring = false
