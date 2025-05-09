extends CharacterBody3D

signal set_movement_direction(_movement_dir: Vector3)
signal set_movement_state(_movement_state: MovementState)
signal jump(jump_state: JumpState)
signal sprint_end()

@export var movement_states : Dictionary
@export var jump_state : Resource

var move_time : float = 0.0
var movement_direction : Vector3
var desires_sprint : bool = false

func _ready() -> void:
	set_movement_state.emit(movement_states["idle"])

func _physics_process(delta: float) -> void:
	if is_movement_ongoing():
		set_movement_direction.emit(movement_direction)
		move_time += delta

func _input(event: InputEvent) -> void:
	if event.is_action("movement"):
		movement_direction.x = Input.get_action_raw_strength("move_left") - Input.get_action_raw_strength("move_right")
		movement_direction.z = Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
		
		if event.is_action_pressed("jump"):
			jump.emit(jump_state)
		
		if event.is_action_pressed("movespeed_toggle"):
			desires_sprint = !desires_sprint
		
		if is_movement_ongoing():
			set_movement_state.emit(movement_states["sprint" if desires_sprint else "walk"])
		else:
			if get_last_motion().length_squared() > 0.1 and get_last_motion().y > 0 and move_time > 0.8:
				sprint_end.emit()
			set_movement_state.emit(movement_states["idle"])
			move_time = 0.0
			
		

func is_movement_ongoing() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
