extends CharacterBody3D

signal set_movement_direction(_movement_dir: Vector3)
signal set_movement_state(_movement_state: MovementState)

@export var movement_states : Dictionary

var movement_direction : Vector3

func _ready() -> void:
	set_movement_state.emit(movement_states["idle"])

func _physics_process(delta: float) -> void:
	if is_movement_ongoing():
		set_movement_direction.emit(movement_direction)

func _input(event: InputEvent) -> void:
	if event.is_action("movement"):
		movement_direction.x = Input.get_action_raw_strength("move_left") - Input.get_action_raw_strength("move_right")
		movement_direction.z = Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
		
		if is_movement_ongoing():
			if Input.is_action_pressed("sprint"):
				set_movement_state.emit(movement_states["sprint"])
			else:
				set_movement_state.emit(movement_states["run"])
		else:
			set_movement_state.emit(movement_states["idle"])
		

func is_movement_ongoing() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
