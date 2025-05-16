extends Resource
class_name MovementState

enum State {IDLE, GROUND_MOVE}

@export var state : State

@export_group("Control")
@export var movement_speed : float
@export var acceleration : float = 6
@export var camera_fov : float = 75
@export var max_camera_pitch : int = 45 # for lookup

@export_group("Animation")
@export var animation_name : String
@export var animation_id : int
@export var animation_speed :  float = 1.0

# delete
@export var id: int
