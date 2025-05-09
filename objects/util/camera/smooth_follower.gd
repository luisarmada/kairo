extends CSGSphere3D

@export var smoothing : float = 7

func _physics_process(delta: float) -> void:
	$Follower.global_position = lerp($Follower.global_position, global_position, smoothing * delta)
