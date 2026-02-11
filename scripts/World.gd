extends Node3D

@onready var caravan: CaravanController = $Caravan
@onready var chunk_manager: ChunkManager = $ChunkManager

func _ready() -> void:
	chunk_manager.caravan_path = caravan.get_path()
	chunk_manager.active_radius = GameState.active_chunk_radius
	chunk_manager.chunk_size = GameState.chunk_size
	chunk_manager.tile_size = GameState.tile_size
	chunk_manager.max_height = GameState.max_height

	var save_data := GameState.load_game()
	if not save_data.is_empty():
		caravan.global_transform = GameState.build_transform_from_save(save_data)

	chunk_manager.refresh_chunks(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		GameState.save_game(caravan.global_transform)
	elif event.is_action_pressed("load_game"):
		var save_data := GameState.load_game()
		if not save_data.is_empty():
			caravan.global_transform = GameState.build_transform_from_save(save_data)
			chunk_manager.refresh_chunks(true)
