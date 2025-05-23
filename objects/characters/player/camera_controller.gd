extends Node3D

signal set_cam_rotation(_cam_rotation: float)

@onready var yaw_node = $CameraYaw
@onready var pitch_node = $CameraYaw/CameraPitch
@onready var camera_node = $CameraYaw/CameraPitch/SpringArm3D/Camera3D

var yaw : float = 0
var pitch : float = 0

var yaw_sensitivity : float = 0.07
var pitch_sensitivity : float = 0.07

var yaw_acceleration : float = 15
var pitch_acceleration : float = 15

var pitch_max : float = 12
var target_pitch_max : float = 12
var pitch_min : float = -55

var tween

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += -event.relative.y * pitch_sensitivity
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		

func _physics_process(delta: float) -> void:
	pitch = clampf(pitch, pitch_min, pitch_max)
	pitch_max = lerp(pitch_max, target_pitch_max, 6.0 * delta)
	
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(pitch_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	
	set_cam_rotation.emit(yaw_node.rotation.y)

func _update_movement_state(_movement_state: MovementState):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(camera_node, "fov", _movement_state.camera_fov, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	target_pitch_max = _movement_state.max_camera_pitch
