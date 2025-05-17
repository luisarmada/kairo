@tool
extends "res://objects/characters/humanoids/reavers/base_reaver.gd"

var cam_rotation: float
var input_direction: Vector3
var wants_sprint: bool

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	super(delta)
	
	input_direction.z = Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
	input_direction.x = Input.get_action_raw_strength("move_left") - Input.get_action_raw_strength("move_right")
	
	if is_movement_input():
		movement_direction = input_direction.rotated(Vector3.UP, cam_rotation)
		if wants_sprint:
			set_movement_state("sprint")
		else:
			set_movement_state("walk")
	else:
		set_movement_state("idle")
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	
	if event.is_action_pressed("sprint"):
		wants_sprint = true
	elif event.is_action_released("sprint"):
		wants_sprint = false

func _update_cam_rotation(_cam_rotation: float) -> void:
	cam_rotation = _cam_rotation

func is_movement_input() -> bool:
	return abs(input_direction.x) > 0 or abs(input_direction.z) > 0
