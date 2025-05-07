extends Node

@export var anim_tree : AnimationTree
@export var anim_player : AnimationPlayer
@export var character : CharacterBody3D

var tween : Tween

var anim_fps : int = 30
var step_time : float = 1.0 / float(anim_fps)
var timer = 0.0

func _ready() -> void:
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _process(delta: float) -> void:
	timer += delta
	while timer >= step_time:
		anim_tree.advance(step_time)
		timer -= step_time
	

func _on_set_movement_state(_movement_state: MovementState) -> void:
		anim_fps = _movement_state.frames_per_second
		step_time = 1.0 / float(anim_fps)
		
		if tween:
			tween.kill()
			
		tween = create_tween()
		tween.tween_property(anim_tree, "parameters/movement_blend/blend_position", _movement_state.id, 0.25)
		tween.parallel().tween_property(anim_tree, "parameters/movement_anim_speed/scale", _movement_state.animation_speed, 0.7)
