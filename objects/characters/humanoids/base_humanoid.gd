extends CharacterBody3D

signal update_movement_state(state: MovementState)
signal update_state_set(new_set: String)

# Base HUMANOID

@export var mesh_reference: Node3D

# Contains: 
# - Movement FUNCTIONALITY (Doesn't actually use them)
@export_category("Movement")
@export_group("States")
@export var state_set: String = ""
@export var movement_states: Dictionary[String, MovementState]
var current_move_state: MovementState
@export var jump_state: JumpState

var target_velocity: Vector3
var input_direction: Vector3
var movement_direction: Vector3
var movement_speed: float
var movement_acceleration: float
var fall_gravity: float = 200
const GRAVITY: float = 200

var move_dir_rotator: float
var wants_sprint: bool

@onready var anim_tree = $AnimationTree
var move_blend_tween: Tween
# Animation frame rate
var step_time : float = 1.0 / 14.0
var timer = 0.0

var move_time: float = 0.0
var in_air_blend_current: float = 0.0
var in_air_blend_target: float = 0.0
var has_landed_flag: bool = true

@onready var particle_run_dust_trail: GPUParticles3D = $Mesh/Particle_RunDustTrail

# - Pathfinding
# - Look At X (Head rotation)

# - Interaction (Dialogue, Damage)

func set_movement_state(state_name: String) -> void:
	var state_key = state_set + "_" + state_name
	var state: MovementState = movement_states[state_key]
	
	current_move_state = state
	update_movement_state.emit(state)
	
	movement_speed = state.movement_speed
	movement_acceleration = state.acceleration
	
	if not anim_tree["parameters/" + state_set + "_tree/movement/blend_position"]:
		return
	
	if move_blend_tween:
		move_blend_tween.kill()
	
	move_blend_tween = create_tween().set_parallel()
	
	move_blend_tween.tween_property(anim_tree, "parameters/" + state_set + "_tree/movement/blend_position", float(state.animation_id), 0.3)
	#move_blend_tween.tween_property(anim_tree, "parameters/katana_tree/timescale/scale", state.animation_speed, 0.7)
	
	
func set_state_set(new_set: String):
	state_set = new_set
	update_state_set.emit(state_set)

func _ready() -> void:
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


func handle_movement(delta: float, wallrun: bool) -> void:
	if Engine.is_editor_hint():
		return
	
	timer += delta
	while timer >= step_time:
		anim_tree.advance(step_time)
		timer -= step_time
	
	if is_input_movement():
		if not wallrun:
			movement_direction = input_direction.rotated(Vector3.UP, move_dir_rotator)
		else:
			movement_direction = input_direction
			
		move_time += delta
		if wants_sprint:
			set_movement_state("sprint")
		else:
			set_movement_state("walk")
	else:
		if move_time > 0.8 and get_last_motion().length_squared() > 0.1 and is_on_floor():
			anim_tree["parameters/katana_tree/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		set_movement_state("idle")
		move_time = 0.0
	
	var move_mult = 1.0 if is_on_floor() else 1.8
	
	target_velocity.x = movement_speed * move_mult * movement_direction.normalized().x
	target_velocity.z = movement_speed * move_mult * movement_direction.normalized().z
	
	if not is_on_floor():
		velocity.y -= fall_gravity * delta
		particle_run_dust_trail.emitting = false
		has_landed_flag = false
	else:
		if not has_landed_flag:
			anim_tree["parameters/katana_tree/jump_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		has_landed_flag = true
		particle_run_dust_trail.emitting = movement_speed > 20
	
	
	in_air_blend_target = 0 if is_on_floor() else 1
	in_air_blend_current = lerp(in_air_blend_current, in_air_blend_target, 10 * delta)
	anim_tree["parameters/katana_tree/in_air_blend/blend_amount"] = in_air_blend_current
	
	if movement_acceleration == -1 or not is_on_floor():
		velocity.x = target_velocity.x
		velocity.z = target_velocity.z
	else:
		velocity.x = lerp(velocity.x, target_velocity.x, movement_acceleration * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, movement_acceleration * delta)
	
	move_and_slide()
	
	var target_rotation = atan2(movement_direction.x, movement_direction.z) - rotation.y
	mesh_reference.rotation.y = lerp_angle(mesh_reference.rotation.y, target_rotation, 8 * delta)
	#mesh_reference.rotation.y = target_rotation
	

func is_input_movement() -> bool:
	return abs(input_direction.x) > 0 or abs(input_direction.z) > 0

func jump():
	if not is_on_floor():
		return
	
	anim_tree["parameters/katana_tree/jump_start/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	await get_tree().create_timer(0.24).timeout
	velocity.y = 130.0
