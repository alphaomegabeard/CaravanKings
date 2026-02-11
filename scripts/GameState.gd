extends Node

signal inventory_changed(new_inventory: Dictionary)

const SAVE_PATH := "user://savegame.json"
const RESOURCE_TYPES := ["Scrap", "Fuel", "Food", "Water"]

@export var world_seed: int = 1337
@export var chunk_size: int = 32
@export var tile_size: float = 2.0
@export var max_height: int = 5
@export var active_chunk_radius: int = 2

var inventory: Dictionary = {}

func _ready() -> void:
	reset_inventory()


func reset_inventory() -> void:
	inventory = {}
	for resource_name in RESOURCE_TYPES:
		inventory[resource_name] = 0
	emit_signal("inventory_changed", inventory.duplicate(true))


func add_resource(resource_name: String, amount: int = 1) -> void:
	if not inventory.has(resource_name):
		inventory[resource_name] = 0
	inventory[resource_name] += amount
	emit_signal("inventory_changed", inventory.duplicate(true))


func save_game(caravan_transform: Transform3D) -> bool:
	var payload := {
		"seed": world_seed,
		"inventory": inventory,
		"caravan": {
			"origin": [caravan_transform.origin.x, caravan_transform.origin.y, caravan_transform.origin.z],
			"basis": [
				[caravan_transform.basis.x.x, caravan_transform.basis.x.y, caravan_transform.basis.x.z],
				[caravan_transform.basis.y.x, caravan_transform.basis.y.y, caravan_transform.basis.y.z],
				[caravan_transform.basis.z.x, caravan_transform.basis.z.y, caravan_transform.basis.z.z]
			]
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save game at %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	return true


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open save file at %s" % SAVE_PATH)
		return {}

	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is invalid JSON")
		return {}

	var data: Dictionary = parsed
	if data.has("seed"):
		world_seed = int(data["seed"])
	if data.has("inventory") and typeof(data["inventory"]) == TYPE_DICTIONARY:
		inventory = (data["inventory"] as Dictionary).duplicate(true)
		emit_signal("inventory_changed", inventory.duplicate(true))

	return data


func build_transform_from_save(data: Dictionary) -> Transform3D:
	if not data.has("caravan"):
		return Transform3D.IDENTITY

	var caravan_data: Dictionary = data["caravan"]
	if not caravan_data.has("origin") or not caravan_data.has("basis"):
		return Transform3D.IDENTITY

	var origin_data: Array = caravan_data["origin"]
	var basis_data: Array = caravan_data["basis"]
	if origin_data.size() != 3 or basis_data.size() != 3:
		return Transform3D.IDENTITY

	var basis := Basis(
		Vector3(basis_data[0][0], basis_data[0][1], basis_data[0][2]),
		Vector3(basis_data[1][0], basis_data[1][1], basis_data[1][2]),
		Vector3(basis_data[2][0], basis_data[2][1], basis_data[2][2])
	)
	var origin := Vector3(origin_data[0], origin_data[1], origin_data[2])
	return Transform3D(basis, origin)
