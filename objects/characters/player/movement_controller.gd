extends Node

signal land()

@export var character : CharacterBody3D
@export var mesh_root : Node3D
@export var rotation_speed : float = 8
@export var fall_gravity : float = 55

@export var run_dust_trail : GPUParticles3D

var direction : Vector3
var velocity : Vector3
var acceleration : float
var speed : float
var jump_gravity : float = fall_gravity
var has_landed: bool = true

var cam_rotation: float

func _physics_process(delta: float) -> void:
	velocity.x = speed * direction.normalized().x
	velocity.z = speed * direction.normalized().z
	
	if not character.is_on_floor():
		velocity.y -= (jump_gravity if velocity.y >= 0 else fall_gravity) * delta
		has_landed = false
		run_dust_trail.emitting = false
	else:
		if not has_landed:
			has_landed = true
			land.emit()
		
		run_dust_trail.emitting = speed > 20
	
	if acceleration < 100.0:
		character.velocity = character.velocity.lerp(velocity, acceleration * delta)
	else:
		character.velocity = velocity
	character.move_and_slide()
	
	var target_rotation = atan2(direction.x, direction.z) - character.rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, rotation_speed * delta)

func _on_jump(jump_state: JumpState):
	await get_tree().create_timer(0.24).timeout
	velocity.y = 2 * jump_state.jump_height / jump_state.apex_duration
	jump_gravity = velocity.y / jump_state.apex_duration

func _on_set_movement_state(_movement_state: MovementState):
	speed = _movement_state.movement_speed
	acceleration = _movement_state.acceleration
	
func _on_set_movement_direction(_movement_dir: Vector3):
	direction = _movement_dir.rotated(Vector3.UP, cam_rotation)

func _on_set_cam_rotation(_cam_rotation: float):
	cam_rotation = _cam_rotation
	
