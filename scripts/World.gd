extends Node3D

@onready var caravan: CharacterBody3D = $Caravan
@onready var chunk_manager: ChunkManager = $ChunkManager

func _ready() -> void:
	if caravan == null:
		push_error("World: Caravan node is missing")
		return
	if chunk_manager == null:
		push_error("World: ChunkManager node is missing")
		return

	chunk_manager.caravan_path = caravan.get_path()
	chunk_manager.active_radius = GameState.active_chunk_radius
	chunk_manager.chunk_size = GameState.chunk_size
	chunk_manager.tile_size = GameState.tile_size
	chunk_manager.max_height = GameState.max_height

	var save_data: Dictionary = GameState.load_game()
	if not save_data.is_empty():
		caravan.global_transform = GameState.build_transform_from_save(save_data)

	chunk_manager.refresh_chunks(true)


func _unhandled_input(event: InputEvent) -> void:
	if caravan == null or chunk_manager == null:
		return

	if event.is_action_pressed("save_game"):
		GameState.save_game(caravan.global_transform)
	elif event.is_action_pressed("load_game"):
		var save_data: Dictionary = GameState.load_game()
		if not save_data.is_empty():
			caravan.global_transform = GameState.build_transform_from_save(save_data)
			chunk_manager.refresh_chunks(true)
