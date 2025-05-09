extends Node

@export var anim_tree : AnimationTree
@export var anim_player : AnimationPlayer
@export var character : CharacterBody3D
@export var lookat_camera_modifier : LookAtModifier3D
@export var character_mesh : Node3D

@export var look_at_target : Node3D
@export var camera_follower : Node3D

var tween : Tween

var anim_fps : int = 30
var step_time : float = 1.0 / 14.0
var timer = 0.0

var on_ground_blend : float = 1 # 1 if grounded, 0 if falling
var on_ground_blend_target : float = 1

var lookat_cutoff: float = 0.8 # if greater, deactivate look at

func _ready() -> void:
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _physics_process(delta: float) -> void:
	
	# frame rate effect
	timer += delta
	while timer >= step_time:
		anim_tree.advance(step_time)
		timer -= step_time
	
	on_ground_blend_target = 1 if character.is_on_floor() else 0
	on_ground_blend = lerp(on_ground_blend, on_ground_blend_target, 10 * delta)
	anim_tree["parameters/Katana/on_ground_blend/blend_amount"] = on_ground_blend
	
	if look_at_target != null:
		lookat_camera_modifier.active = true
		
		var lookat_target_node_pos = look_at_target.global_position
		var lookat_dir = (lookat_target_node_pos - character_mesh.global_position)
		lookat_dir.y = 0
		lookat_dir = lookat_dir.normalized()
		
		if lookat_dir.length() > 0:
			var look_at_transform = character_mesh.global_transform.looking_at(lookat_target_node_pos, Vector3.UP)
			var look_at_rotation = look_at_transform.basis.get_euler()
			
			var forward_vector = -character_mesh.global_transform.basis.z.normalized()
			var dot_product = forward_vector.dot(lookat_dir)
			
			print(dot_product)
			
			if dot_product > 0.4 and dot_product < 1.0:
				lookat_camera_modifier.target_node = camera_follower.get_path()
			else:
				lookat_camera_modifier.target_node = look_at_target.get_path()
		else:
			# camera straight above or below
			lookat_camera_modifier.active = false
	else:
		lookat_camera_modifier.active = false



func _on_set_movement_state(_movement_state: MovementState) -> void:
		#anim_fps = _movement_state.frames_per_second
		#step_time = 1.0 / float(anim_fps)
		if _movement_state.movement_speed > 0 and on_ground_blend_target == 1:
			anim_tree["parameters/Katana/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	
		if _movement_state.max_camera_pitch < 20.0:
			lookat_camera_modifier.use_secondary_rotation = false
		else:
			lookat_camera_modifier.use_secondary_rotation = true
		
		if tween:
			tween.kill()
			
		tween = create_tween()
		tween.tween_property(anim_tree, "parameters/Katana/ground_movement/blend_position", _movement_state.id, 0.4)
		tween.parallel().tween_property(anim_tree, "parameters/Katana/movement_anim_speed/scale", _movement_state.animation_speed, 0.7)

func _on_jump(_jump_state: JumpState):
	anim_tree["parameters/Katana/ground_jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_land():
	anim_tree["parameters/Katana/ground_land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_sprint_end():
	anim_tree["parameters/Katana/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
