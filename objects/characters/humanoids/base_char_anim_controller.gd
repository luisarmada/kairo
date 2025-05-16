extends AnimationTree

# Core variables
var state_set: String = ""

# Tweens
var move_blend_tween: Tween

# Animation frame rate
var step_time : float = 1.0 / 14.0
var timer = 0.0

func _ready() -> void:
	callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _process(delta: float) -> void:
	# frame rate effect
	timer += delta
	while timer >= step_time:
		advance(step_time)
		timer -= step_time

func _update_movement_state(state: MovementState):
	if move_blend_tween:
		move_blend_tween.kill()
	
	move_blend_tween = create_tween().set_parallel()
	
	move_blend_tween.tween_property(self, "parameters/" + state_set + "_tree/movement/blend_position", float(state.animation_id), 0.4)
	move_blend_tween.tween_property(self, "parameters/timescale/scale", state.animation_speed, 0.7)
	
func _update_state_set(new_set: String):
	state_set = new_set
