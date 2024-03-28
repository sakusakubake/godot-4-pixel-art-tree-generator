@tool
extends Node2D

signal reset;

@export var seed: int = 0:
	set(val):
		seed = val
		reset.emit()

@export var branch_depth: int = 16:
	set(val):
		branch_depth = val
		reset.emit()

@export var branch_splits: int = 4:
	set(val):
		branch_splits = val
		reset.emit()

@export var trunk_width: float = 1.0:
	set(val):
		trunk_width = val
		reset.emit()

@export var branch_spread: float = 1.2:
	set(val):
		branch_spread = val
		reset.emit()

@export var segment_length: float = 10.0:
	set(val):
		segment_length = val
		reset.emit()

@export var branch_split_every: int = 4:
	set(val):
		branch_split_every = val
		reset.emit()

@export var leaves_texture: NoiseTexture2D:
	set(val):
		leaves_texture = val
		reset.emit()

@export var leaves_start_ratio: float = 0.5:
	set(val):
		leaves_start_ratio = val
		reset.emit()

@export var leaves_radius: float = 12.0:
	set(val):
		leaves_radius = val
		reset.emit()

@export var fallen_leaves_color: Color = Color.WHITE:
	set(val):
		fallen_leaves_color = val
		reset.emit()
		
@export var angle_variation_factor: float = 0.5:
	set(val):
		angle_variation_factor = val
		reset.emit()

var leaves_material = preload("res://tree/leaves_material.tres")

var rng = RandomNumberGenerator.new()

func _ready():
	reset.connect(generate_tree)
	generate_tree()
	
func generate_tree():
	print("GENERATING")
	for c in get_children():
		c.queue_free()
	rng.seed = seed
	add_branches(branch_depth, branch_splits, trunk_width, branch_spread, segment_length, branch_split_every)

func add_branches(depth: int, split: int, start_width: float, spread: float, length: float, split_every: int, parent: Node2D = self, index: int = 0, parent_angle: float = 0.0):
	var branch_split = 1
	if index != 0 && index % split_every == 0:
		branch_split = split
	if index < depth:
		var origin: Vector2 = Vector2.ZERO
		if parent != self:
			origin = parent.get_point_position(parent.get_point_count() - 1)
		var number_of_branches = rng.randi_range(1, branch_split)
		for i in range(0, number_of_branches):
			var angle_variation = rng.randf_range(-angle_variation_factor * spread, angle_variation_factor * spread)
			var angle = 0.5 * parent_angle + (2.0 * spread / number_of_branches) * (i - ((number_of_branches - 1) / 2.0))
			var branch: Line2D = Line2D.new()
			branch.gradient = Gradient.new()
			branch.texture_mode = Line2D.LINE_TEXTURE_STRETCH
			branch.joint_mode = Line2D.LINE_JOINT_ROUND
			branch.material = material
			branch.texture = CanvasTexture.new()
			branch.texture.normal_texture = GradientTexture2D.new()
			branch.texture.normal_texture.gradient = Gradient.new()
			branch.texture.normal_texture.gradient.offsets = PackedFloat32Array([0, 0.5, 1])
			branch.texture.normal_texture.gradient.colors = PackedColorArray([Color(0.03, 0.5, 0.69), Color(0.5, 0.49, 0.99), Color(0.96, 0.5, 0.7)])
			branch.texture.normal_texture.fill_to = Vector2(0, 1)
			branch.width_curve = Curve.new()
			branch.width_curve.add_point(Vector2(0.0, start_width - (start_width / depth) * (index + 1)))
			branch.width_curve.add_point(Vector2(0.0, start_width - (start_width / depth) * index))
			branch.add_point(origin)
			var branch_rotation = angle + angle_variation
			var end_position = origin + Vector2(0.0, -length).rotated(branch_rotation)
			branch.add_point(end_position)
			parent.add_child(branch)
			branch.joint_mode = Line2D.LINE_JOINT_ROUND
			branch.begin_cap_mode = Line2D.LINE_CAP_ROUND
			branch.end_cap_mode = Line2D.LINE_CAP_ROUND
			add_leaves(branch, end_position, index, depth)
			add_falling_leaves(branch, end_position, index, depth)
			set_editor_owner(branch)
			add_branches(depth, split, start_width, spread, length, split_every, branch, index + 1, branch_rotation)

func add_leaves(branch: Line2D, leaves_position: Vector2, index: int, depth: int):
	if index > leaves_start_ratio * depth:
		var leaves = Sprite2D.new()
		leaves.position = leaves_position
		leaves.material = leaves_material.duplicate()
		leaves.material.set_shader_parameter("height", leaves_position.y)
		leaves.material.set_shader_parameter("leaves_texture", leaves_texture)
		leaves.texture = CanvasTexture.new()
		leaves.texture.diffuse_texture = NoiseTexture2D.new()
		if leaves_texture != null:
			leaves.texture.normal_texture = leaves_texture.duplicate()
			leaves.texture.normal_texture.as_normal_map = true
		leaves.texture.diffuse_texture.width = leaves_radius
		leaves.texture.diffuse_texture.height = leaves_radius * 0.7
		leaves.texture.diffuse_texture.noise = FastNoiseLite.new()
		leaves.texture.diffuse_texture.noise.frequency = 0.2
		leaves.texture.diffuse_texture.noise.seed = rng.randi()
		branch.add_child(leaves)
		set_editor_owner(leaves)

func add_falling_leaves(branch: Line2D, leaves_position: Vector2, index: int, depth: int):
	if index > leaves_start_ratio * depth && rng.randi_range(0, 10) < 1:
		var falling_leaves = GPUParticles2D.new()
		falling_leaves.position = leaves_position
		falling_leaves.amount = 2
		falling_leaves.texture = GradientTexture2D.new()
		falling_leaves.texture.width = 2
		falling_leaves.texture.height = 2
		falling_leaves.texture.gradient = Gradient.new()
		falling_leaves.texture.gradient.offsets = PackedFloat32Array([1])
		falling_leaves.texture.gradient.colors = PackedColorArray([fallen_leaves_color])
		falling_leaves.lifetime = 30.0
		falling_leaves.process_material = ParticleProcessMaterial.new()
		falling_leaves.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		falling_leaves.process_material.emission_sphere_radius = 10.0
		falling_leaves.process_material.direction = Vector3(0.0, 1.0, 0.0)
		falling_leaves.process_material.gravity = Vector3(0.0, 30.0, 0.0)
		falling_leaves.process_material.lifetime_randomness = 1.0
		falling_leaves.process_material.turbulence_enabled = true
		falling_leaves.process_material.turbulence_noise_strength = 9.0
		branch.add_child(falling_leaves)
		set_editor_owner(falling_leaves)

func set_editor_owner(node):
	if get_tree().edited_scene_root && get_tree().edited_scene_root.is_ancestor_of(self):
		node.owner = get_tree().edited_scene_root
