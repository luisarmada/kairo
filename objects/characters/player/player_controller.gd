extends CharacterBody3D

signal set_movement_direction(_movement_dir: Vector3)
signal set_movement_state(_movement_state: MovementState)
signal jump(jump_state: JumpState)
signal sprint_end()

@export var movement_states : Dictionary
@export var jump_state : Resource

var current_movement_state: MovementState = null

var move_time : float = 0.0
var movement_direction : Vector3
var desires_sprint : bool = false

func _ready() -> void:
	_set_movement_state(movement_states["idle"])

func _physics_process(delta: float) -> void:
	movement_direction.z = Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
	movement_direction.x = Input.get_action_raw_strength("move_left") - Input.get_action_raw_strength("move_right")
	
	if is_movement_ongoing():
		set_movement_direction.emit(movement_direction)
		move_time += delta
		_set_movement_state(movement_states["sprint" if desires_sprint else "walk"])
	else:
		if get_last_motion().length_squared() > 0.1 and get_last_motion().y > 0 and move_time > 0.8:
			sprint_end.emit()
		_set_movement_state(movement_states["idle"])
		move_time = 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump.emit(jump_state)
	
	if event.is_action_pressed("movespeed_toggle"):
		desires_sprint = !desires_sprint

func is_movement_ongoing() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0

func _set_movement_state(new_state: MovementState) -> void:
	if current_movement_state != new_state:
		current_movement_state = new_state
		set_movement_state.emit(new_state)
