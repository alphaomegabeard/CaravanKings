extends CharacterBody3D
class_name CaravanController

@export var acceleration: float = 18.0
@export var deceleration: float = 12.0
@export var max_speed: float = 14.0
@export var turn_speed: float = 3.0
@export var gravity: float = 30.0
@export var tap_plane_y: float = 0.0

@onready var camera: Camera3D = $Camera3D

var speed := 0.0
var move_target: Vector3
var has_target := false

func _ready() -> void:
	add_to_group("caravan")
	move_target = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_set_target_from_screen(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_target_from_screen(event.position)
	elif event.is_action_pressed("teleport_debug"):
		global_position += Vector3(80.0, 0.0, 80.0)
		has_target = false


func _physics_process(delta: float) -> void:
	var steering_input := Input.get_axis("ui_left", "ui_right")
	var throttle_input := Input.get_axis("ui_down", "ui_up")

	if has_target:
		var to_target := move_target - global_position
		to_target.y = 0.0
		if to_target.length() < 1.2:
			has_target = false
		else:
			var desired_dir := to_target.normalized()
			var forward := -global_basis.z
			var angle := forward.signed_angle_to(desired_dir, Vector3.UP)
			rotation.y += clamp(angle, -turn_speed * delta, turn_speed * delta)
			throttle_input = 1.0

	if absf(throttle_input) > 0.01:
		speed = move_toward(speed, throttle_input * max_speed, acceleration * delta)
	else:
		speed = move_toward(speed, 0.0, deceleration * delta)

	if absf(steering_input) > 0.01 and not has_target:
		rotation.y -= steering_input * turn_speed * delta

	var forward_velocity := -global_basis.z * speed
	velocity.x = forward_velocity.x
	velocity.z = forward_velocity.z
	velocity.y -= gravity * delta

	move_and_slide()

	if camera:
		camera.look_at(global_position + Vector3(0.0, -1.2, -1.2), Vector3.UP)


func _set_target_from_screen(screen_pos: Vector2) -> void:
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var t := (tap_plane_y - origin.y) / direction.y
	if t <= 0.0:
		return
	move_target = origin + direction * t
	has_target = true
