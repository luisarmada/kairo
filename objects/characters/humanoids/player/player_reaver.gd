@tool
extends "res://objects/characters/humanoids/reavers/base_reaver.gd"

var cam_rotation: float

var can_wallrun: bool = true
var is_wall_running: bool = false
var last_wall_run_dir: Vector3
var wall_run_right: bool

@onready var left_wallrun_ray: RayCast3D = %LeftWallrunRay
@onready var right_wallrun_ray: RayCast3D = %RightWallrunRay
@onready var downwards_ray: RayCast3D = %DownwardsRay

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	super()
	$CameraRoot/CameraYaw/CameraPitch/SpringArm3D.add_excluded_object(self)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	input_direction.z = Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
	input_direction.x = Input.get_action_raw_strength("move_left") - Input.get_action_raw_strength("move_right")
	
	if wallrun_check():
		var wall_normal = Vector3.ZERO
		if left_wallrun_ray.is_colliding():
			wall_normal = left_wallrun_ray.get_collision_normal()
			wall_run_right = false
		elif right_wallrun_ray.is_colliding():
			wall_normal = right_wallrun_ray.get_collision_normal()
			wall_run_right = true
			
		velocity.y = -3.0
		is_wall_running = true
		
		#var wall_normal = get_slide_collision(0).get_normal(0)
		var wall_run_direction = wall_normal.cross(Vector3.UP).normalized()
		
		var forward_vector = mesh_reference.transform.basis.z.normalized()
		
		var dot = forward_vector.dot(wall_run_direction)
		if dot < 0:
			wall_run_direction = -wall_run_direction
		
		#print("Wall normal: ", wall_normal, " Wall run direction: ", wall_run_direction, " Is wall right: ", wall_run_right)
		input_direction = wall_run_direction.normalized()
		anim_tree["parameters/katana_tree/in_air/in_air_state/transition_request"] = "wall_run_right" if wall_run_right else "wall_run_left"
	else:
		is_wall_running = false
		anim_tree["parameters/katana_tree/in_air/in_air_state/transition_request"] = "fall"
	
	
	handle_movement(delta, is_wall_running)

func wallrun_check() -> bool:
	return (can_wallrun and not is_on_floor() and 
	input_direction.z > 0 and not downwards_ray.is_colliding() 
	and movement_speed >= 20 and (left_wallrun_ray.is_colliding() or right_wallrun_ray.is_colliding()))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if is_wall_running:
			can_wallrun = false
			velocity.y = 130.0
			await get_tree().create_timer(0.24).timeout
			can_wallrun = true
		else:
			jump()
	
	if event.is_action_pressed("sprint"):
		wants_sprint = true
	elif event.is_action_released("sprint"):
		wants_sprint = false

func _update_cam_rotation(_cam_rotation: float) -> void:
	move_dir_rotator = _cam_rotation
