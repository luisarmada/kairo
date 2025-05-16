extends Node

@export var anim_tree : AnimationTree
@export var anim_player : AnimationPlayer
@export var character : CharacterBody3D
@export var character_mesh : Node3D

@export var lookat_camera_modifier : LookAtModifier3D
var look_at_target : Node3D = null
@export var look_at_smooth_follower : Node3D

@export var camera_target_node : Node3D # Towards camera
@export var camera_forward_node : Node3D # Camera facing direction
@export var mesh_forward_node : Node3D # Mesh facing direction

var tween : Tween

var anim_fps : int = 30
var step_time : float = 1.0 / 14.0
var timer = 0.0

var on_ground_blend : float = 1 # 1 if grounded, 0 if falling
var on_ground_blend_target : float = 1

var lookat_cutoff: float = 0.8 # if greater, deactivate look at

var arm_ik_target: float = 0.0
var arm_ik_value: float = 0.0

@export var arm_modifiers: Dictionary

@export var odm_left: Node3D
@export var odm_right: Node3D

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
	
	# Head look at location logic
	if on_ground_blend_target != 0:
		lookat_camera_modifier.active = true
		
		var lookat_target_node_pos = camera_forward_node.global_position
		var lookat_dir = (lookat_target_node_pos - character_mesh.global_position)
		lookat_dir.y = 0
		lookat_dir = lookat_dir.normalized()
		
		if lookat_dir.length() > 0:
			var look_at_transform = character_mesh.global_transform.looking_at(lookat_target_node_pos, Vector3.UP)
			var look_at_rotation = look_at_transform.basis.get_euler()
			
			var forward_vector = -character_mesh.global_transform.basis.z.normalized()
			var dot_product = forward_vector.dot(lookat_dir)
			
			if dot_product > 0.4 and dot_product < 1.0:
				# Look at camera
				update_look_at_target(camera_target_node)
			else:
				# Look in straight direction
				update_look_at_target(camera_forward_node)
		else:
			# camera straight above or below
			update_look_at_target(mesh_forward_node, false)
	else:
		update_look_at_target(mesh_forward_node, false, 6.0)

func update_look_at_target(target: Node3D, allow_vertical: bool = true, smoothing: float = 3.0):
	if look_at_target == target:
		return
		
	look_at_target = target
	lookat_camera_modifier.use_secondary_rotation = allow_vertical
	look_at_smooth_follower.update_target_node(look_at_target, smoothing)

func _on_set_movement_state(_movement_state: MovementState) -> void:
	if _movement_state.movement_speed > 0 and on_ground_blend_target == 1:
		anim_tree["parameters/Katana/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT

	if _movement_state.max_camera_pitch < 20.0:
		lookat_camera_modifier.use_secondary_rotation = false
	else:
		lookat_camera_modifier.use_secondary_rotation = true
	
	if tween:
		tween.kill()
		
	var should_ik_arm: bool = _movement_state.movement_speed < 20
	
	tween = create_tween()
	tween.tween_property(anim_tree, "parameters/Katana/ground_movement/blend_position", _movement_state.id, 0.4)
	tween.parallel().tween_property(anim_tree, "parameters/Katana/movement_anim_speed/scale", _movement_state.animation_speed, 0.7)
	
	tween.parallel().tween_property(odm_left, "rotation_degrees", Vector3(2.0 if should_ik_arm else -30.0, odm_left.rotation_degrees.y, odm_left.rotation_degrees.z), 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(odm_right, "rotation_degrees", Vector3(2.0 if should_ik_arm else 30.0, odm_right.rotation_degrees.y, odm_right.rotation_degrees.z), 0.25).set_ease(Tween.EASE_OUT)
	
	for i in arm_modifiers.keys():
		tween.parallel().tween_property(get_node(i), "influence", arm_modifiers[i] if should_ik_arm else 0, 0.15).set_ease(Tween.EASE_OUT)
	

func _on_jump(_jump_state: JumpState):
	anim_tree["parameters/Katana/ground_jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_land():
	anim_tree["parameters/Katana/ground_land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_sprint_end():
	anim_tree["parameters/Katana/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
