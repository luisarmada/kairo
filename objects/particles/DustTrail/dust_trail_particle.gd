extends GPUParticles3D

func _process(delta):
	var cam_pos = get_viewport().get_camera_3d().global_transform.origin
	print(cam_pos)
	material_override.set("camera_position", cam_pos)
