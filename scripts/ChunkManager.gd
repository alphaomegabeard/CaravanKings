extends Node3D
class_name ChunkManager

@export var terrain_chunk_scene: PackedScene
@export var caravan_path: NodePath
@export var active_radius: int = 2
@export var chunk_size: int = 32
@export var tile_size: float = 2.0
@export var max_height: int = 5

var caravan: Node3D
var active_chunks: Dictionary = {}
var chunk_pool: Array[TerrainChunk] = []
var current_center_chunk := Vector2i(999999, 999999)
var update_accumulator := 0.0

func _ready() -> void:
	caravan = get_node_or_null(caravan_path)
	if caravan == null:
		push_error("ChunkManager: caravan_path is not assigned.")
		return
	refresh_chunks(true)


func _process(delta: float) -> void:
	if caravan == null:
		return

	update_accumulator += delta
	if update_accumulator < 0.2:
		return
	update_accumulator = 0.0

	var caravan_chunk := world_to_chunk(caravan.global_position)
	if caravan_chunk != current_center_chunk:
		refresh_chunks()


func world_to_chunk(world_pos: Vector3) -> Vector2i:
	var world_span := chunk_size * tile_size
	return Vector2i(
		int(floor(world_pos.x / world_span)),
		int(floor(world_pos.z / world_span))
	)


func chunk_to_world_origin(coord: Vector2i) -> Vector3:
	var world_span := chunk_size * tile_size
	return Vector3(coord.x * world_span, 0.0, coord.y * world_span)


func refresh_chunks(force: bool = false) -> void:
	if caravan == null:
		return

	var center := world_to_chunk(caravan.global_position)
	if not force and center == current_center_chunk:
		return
	current_center_chunk = center

	var wanted := {}
	for cx in range(center.x - active_radius, center.x + active_radius + 1):
		for cz in range(center.y - active_radius, center.y + active_radius + 1):
			wanted[Vector2i(cx, cz)] = true

	var to_remove: Array = []
	for coord in active_chunks.keys():
		if not wanted.has(coord):
			to_remove.append(coord)

	for coord in to_remove:
		var chunk: TerrainChunk = active_chunks[coord]
		active_chunks.erase(coord)
		chunk.visible = false
		chunk.set_process(false)
		chunk_pool.push_back(chunk)

	for coord in wanted.keys():
		if active_chunks.has(coord):
			continue
		var chunk_instance := _acquire_chunk()
		chunk_instance.setup_chunk(coord, GameState.world_seed, chunk_size, tile_size, max_height)
		chunk_instance.global_position = chunk_to_world_origin(coord)
		chunk_instance.visible = true
		chunk_instance.set_process(true)
		active_chunks[coord] = chunk_instance


func _acquire_chunk() -> TerrainChunk:
	if chunk_pool.size() > 0:
		return chunk_pool.pop_back()

	if terrain_chunk_scene == null:
		push_error("ChunkManager terrain_chunk_scene is missing")
		return TerrainChunk.new()

	var chunk_instance: TerrainChunk = terrain_chunk_scene.instantiate()
	add_child(chunk_instance)
	return chunk_instance


func get_active_chunk_count() -> int:
	return active_chunks.size()
