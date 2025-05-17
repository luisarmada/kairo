extends Node3D

@export var ParticleEffect : PackedScene
@export var SpawnSpread : float = 2.0

func _input(_event):
	return
	if (Input.is_action_just_pressed("left_mouse_button")):
		var newParticle = ParticleEffect.instantiate() as Node3D
		add_child(newParticle)
		
		var rng : RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		
		newParticle.global_position = Vector3(rng.randf_range(-SpawnSpread, SpawnSpread), 0, rng.randf_range(-SpawnSpread, SpawnSpread))
