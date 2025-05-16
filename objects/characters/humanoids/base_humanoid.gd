extends CharacterBody3D

signal update_movement_state(state: MovementState)
signal update_state_set(new_set: String)

# Base HUMANOID
# Contains: 
# - Movement FUNCTIONALITY (Doesn't actually use them)
@export_category("Movement")
@export_group("States")
@export var state_set: String = ""
@export var movement_states: Dictionary[String, MovementState]
@export var jump_state: JumpState

# - Pathfinding
# - Look At X (Head rotation)

# - Interaction (Dialogue, Damage)

func set_movement_state(state_name: String) -> void:
	var state_key = state_set + "_" + state_name
	var new_state: MovementState = movement_states[state_key]
	
	update_movement_state.emit(new_state)
	
func set_state_set(new_set: String):
	state_set = new_set
	update_state_set.emit(state_set)
