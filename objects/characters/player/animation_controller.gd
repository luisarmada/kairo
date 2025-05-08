extends Node

@export var anim_tree : AnimationTree
@export var anim_player : AnimationPlayer
@export var character : CharacterBody3D

var tween : Tween

var anim_fps : int = 30
var step_time : float = 1.0 / 14.0
var timer = 0.0

var on_ground_blend : float = 1 # 1 if grounded, 0 if falling
var on_ground_blend_target : float = 1

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


func _on_set_movement_state(_movement_state: MovementState) -> void:
		#anim_fps = _movement_state.frames_per_second
		#step_time = 1.0 / float(anim_fps)
		
		if tween:
			tween.kill()
			
		tween = create_tween()
		tween.tween_property(anim_tree, "parameters/Katana/ground_movement/blend_position", _movement_state.id, 0.4)
		tween.parallel().tween_property(anim_tree, "parameters/Katana/movement_anim_speed/scale", _movement_state.animation_speed, 0.7)

func _on_jump(jump_state: JumpState):
	pass
	anim_tree["parameters/Katana/ground_jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_land():
	anim_tree["parameters/Katana/ground_land/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_sprint_end():
	anim_tree["parameters/Katana/sprint_end/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
