extends Control
class_name DebugHUD

@export var chunk_manager_path: NodePath
@export var caravan_path: NodePath

@onready var seed_label: Label = $MarginContainer/VBoxContainer/SeedLabel
@onready var chunk_label: Label = $MarginContainer/VBoxContainer/ChunkLabel
@onready var inv_label: Label = $MarginContainer/VBoxContainer/InventoryLabel
@onready var fps_label: Label = $MarginContainer/VBoxContainer/FPSLabel

var chunk_manager: ChunkManager = null
var caravan: Node3D = null

func _ready() -> void:
	var chunk_node: Node = get_node_or_null(chunk_manager_path)
	if chunk_node is ChunkManager:
		chunk_manager = chunk_node
	var caravan_node: Node = get_node_or_null(caravan_path)
	if caravan_node is Node3D:
		caravan = caravan_node

	GameState.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed(GameState.inventory)


func _process(_delta: float) -> void:
	seed_label.text = "Seed: %d" % GameState.world_seed
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if chunk_manager != null and caravan != null:
		var chunk: Vector2i = chunk_manager.world_to_chunk(caravan.global_position)
		chunk_label.text = "Chunk: (%d, %d) | Active: %d" % [chunk.x, chunk.y, chunk_manager.get_active_chunk_count()]


func _on_inventory_changed(inventory: Dictionary) -> void:
	var parts: PackedStringArray = PackedStringArray()
	for key in GameState.RESOURCE_TYPES:
		parts.append("%s: %d" % [key, int(inventory.get(key, 0))])
	inv_label.text = "Inventory | " + ", ".join(parts)
