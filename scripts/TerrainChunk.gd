extends StaticBody3D
class_name TerrainChunk

enum Biome {
	PLAINS,
	DESERT,
	FOREST,
	ROCKY,
}

const ResourcePickupScene := preload("res://scenes/resource_pickup.tscn")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var chunk_coord := Vector2i.ZERO
var chunk_size: int = 32
var tile_size: float = 2.0
var max_height: int = 5
var seed: int = 1337

var height_noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()
var pickup_rng := RandomNumberGenerator.new()
var pickup_pool: Array[ResourcePickup] = []
var active_pickups: Array[ResourcePickup] = []

func _ready() -> void:
	height_noise.frequency = 0.015
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_noise.frequency = 0.008
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


func setup_chunk(new_coord: Vector2i, world_seed: int, new_chunk_size: int, new_tile_size: float, new_max_height: int) -> void:
	chunk_coord = new_coord
	seed = world_seed
	chunk_size = new_chunk_size
	tile_size = new_tile_size
	max_height = new_max_height

	height_noise.seed = seed
	biome_noise.seed = seed * 17 + 23

	_build_mesh()
	_spawn_pickups()


func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)

	for x in range(chunk_size):
		for z in range(chunk_size):
			var h := _tile_height(x, z)
			var biome := _biome_for_tile(x, z)
			var color := _color_for_biome(biome)
			_add_top_face(st, x, z, h, color)

			var neighbor_hx := _tile_height(x + 1, z)
			if neighbor_hx < h:
				_add_side_face_x(st, x + 1, z, neighbor_hx, h, color)

			var neighbor_hz := _tile_height(x, z + 1)
			if neighbor_hz < h:
				_add_side_face_z(st, x, z + 1, neighbor_hz, h, color)

	var mesh := st.commit()
	mesh_instance.mesh = mesh

	if mesh == null:
		return

	var shape := mesh.create_trimesh_shape()
	collision_shape.shape = shape


func _add_top_face(st: SurfaceTool, x: int, z: int, h: int, color: Color) -> void:
	var y := h * tile_size
	var p0 := Vector3(x * tile_size, y, z * tile_size)
	var p1 := Vector3((x + 1) * tile_size, y, z * tile_size)
	var p2 := Vector3((x + 1) * tile_size, y, (z + 1) * tile_size)
	var p3 := Vector3(x * tile_size, y, (z + 1) * tile_size)
	_add_quad(st, p0, p1, p2, p3, Vector3.UP, color)


func _add_side_face_x(st: SurfaceTool, x_edge: int, z: int, from_h: int, to_h: int, color: Color) -> void:
	for h in range(from_h, to_h):
		var y0 := h * tile_size
		var y1 := (h + 1) * tile_size
		var p0 := Vector3(x_edge * tile_size, y0, z * tile_size)
		var p1 := Vector3(x_edge * tile_size, y0, (z + 1) * tile_size)
		var p2 := Vector3(x_edge * tile_size, y1, (z + 1) * tile_size)
		var p3 := Vector3(x_edge * tile_size, y1, z * tile_size)
		_add_quad(st, p0, p1, p2, p3, Vector3.RIGHT, color.darkened(0.18))


func _add_side_face_z(st: SurfaceTool, x: int, z_edge: int, from_h: int, to_h: int, color: Color) -> void:
	for h in range(from_h, to_h):
		var y0 := h * tile_size
		var y1 := (h + 1) * tile_size
		var p0 := Vector3(x * tile_size, y0, z_edge * tile_size)
		var p1 := Vector3((x + 1) * tile_size, y0, z_edge * tile_size)
		var p2 := Vector3((x + 1) * tile_size, y1, z_edge * tile_size)
		var p3 := Vector3(x * tile_size, y1, z_edge * tile_size)
		_add_quad(st, p0, p1, p2, p3, Vector3.BACK, color.darkened(0.28))


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(a)
	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(b)
	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(c)

	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(a)
	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(c)
	st.set_normal(normal)
	st.set_color(color)
	st.add_vertex(d)


func _tile_height(local_x: int, local_z: int) -> int:
	var wx := local_x + chunk_coord.x * chunk_size
	var wz := local_z + chunk_coord.y * chunk_size
	var n := height_noise.get_noise_2d(float(wx), float(wz))
	var normalized := (n + 1.0) * 0.5
	return int(round(normalized * max_height))


func _biome_for_tile(local_x: int, local_z: int) -> Biome:
	var wx := local_x + chunk_coord.x * chunk_size
	var wz := local_z + chunk_coord.y * chunk_size
	var n := biome_noise.get_noise_2d(float(wx), float(wz))
	if n < -0.3:
		return Biome.DESERT
	if n < 0.1:
		return Biome.PLAINS
	if n < 0.5:
		return Biome.FOREST
	return Biome.ROCKY


func _color_for_biome(biome: Biome) -> Color:
	match biome:
		Biome.DESERT:
			return Color(0.88, 0.78, 0.49)
		Biome.FOREST:
			return Color(0.42, 0.72, 0.36)
		Biome.ROCKY:
			return Color(0.55, 0.56, 0.62)
		_:
			return Color(0.58, 0.8, 0.48)


func _spawn_pickups() -> void:
	for pickup in active_pickups:
		pickup.visible = false
		pickup.monitoring = false
		pickup_pool.push_back(pickup)
	active_pickups.clear()

	var key_seed := int(seed * 92821 + chunk_coord.x * 68917 + chunk_coord.y * 51787)
	pickup_rng.seed = key_seed

	var pickup_count := pickup_rng.randi_range(2, 5)
	for i in range(pickup_count):
		var pickup := _acquire_pickup()
		var tx := pickup_rng.randi_range(1, chunk_size - 2)
		var tz := pickup_rng.randi_range(1, chunk_size - 2)
		var height := _tile_height(tx, tz)
		pickup.global_position = global_position + Vector3(tx * tile_size, height * tile_size + 0.75, tz * tile_size)
		pickup.resource_type = GameState.RESOURCE_TYPES[pickup_rng.randi_range(0, GameState.RESOURCE_TYPES.size() - 1)]
		pickup.activate()
		active_pickups.push_back(pickup)


func _acquire_pickup() -> ResourcePickup:
	if pickup_pool.size() > 0:
		return pickup_pool.pop_back()

	var pickup: ResourcePickup = ResourcePickupScene.instantiate()
	add_child(pickup)
	return pickup
