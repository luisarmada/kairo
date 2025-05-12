extends CSGSphere3D

@export var smoothing : float = 0.5
@export var target_node : Node3D = null

func _physics_process(delta: float) -> void:
	if target_node != null:
		global_position = lerp(global_position, target_node.global_position, smoothing * delta)
		
func update_target_node(target: Node3D, smooth: float) -> void:
	target_node = target
	smoothing = smooth
