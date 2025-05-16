@tool
extends "res://objects/characters/humanoids/base_humanoid.gd"

@export_category("Mesh")
@export_group("Bodyparts")
@export var female_mesh_root: Node3D
@export var master_pose_skeleton: Skeleton3D
@export var bodysuit_colours: Array[Texture2D]

@export_group("")
@export_range(0, 18) var bodysuit_material: int :
	set(val):
		bodysuit_material = val
		if Engine.is_editor_hint():
			redraw_mesh()

@export var head_type: int = 0 :
	set(val):
		head_type = val
		if Engine.is_editor_hint():
			redraw_mesh()

func redraw_mesh(destroy_unused: bool = false):
	var new_bodysuit_mat = StandardMaterial3D.new()
	new_bodysuit_mat.albedo_texture = bodysuit_colours[bodysuit_material]
	
	if female_mesh_root == null:
		return
	
	for bodypart in female_mesh_root.get_children(false):
		var mesh: MeshInstance3D = bodypart.get_child(0).get_child(0)
		mesh.skeleton = mesh.get_path_to(master_pose_skeleton)
		
		if bodypart.name.begins_with("Head"):
			bodypart.visible = bodypart.name.ends_with(str(head_type))
		
		mesh.material_override = new_bodysuit_mat

@export_group("IK")
var ik_blend: Tween
@export var arm_ik_references: Array[LookAtModifier3D] # Modifier -> weight
@export var arm_ik_weights: Array[float]

func _ready() -> void:
	redraw_mesh()
	
	# Everything past this is game only
	if Engine.is_editor_hint():
		return
		
	set_state_set("katana")
	
	set_movement_state("idle")
	await get_tree().create_timer(2).timeout
	set_movement_state("walk")
	await get_tree().create_timer(2).timeout
	set_movement_state("run")
	await get_tree().create_timer(2).timeout
	set_movement_state("sprint")

func set_movement_state(state_name: String) -> void:
	super(state_name)
	
	if ik_blend:
		ik_blend.kill()
	
	if state_set == "katana":
		ik_blend = get_tree().create_tween().set_parallel()
		if state_name == "idle" or state_name == "walk":
			for i in arm_ik_references.size():
				ik_blend.tween_property(arm_ik_references[i], "influence", arm_ik_weights[i], 0.2)
		elif state_name == "run":
			for i in arm_ik_references.size():
				# only activate for right arm
				ik_blend.tween_property(arm_ik_references[i], "influence", arm_ik_weights[i] if i <= 1 else 0.0, 0.2)
		else:
			for i in arm_ik_references.size():
				ik_blend.tween_property(arm_ik_references[i], "influence", 0.0, 0.2)
		
