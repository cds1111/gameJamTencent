extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityGoalControl

@export var goal_move_speed: float = 125.0
@export var goal_vertical_speed: float = 125.0
@export var goal_gravity: float = 980.0
@export var goal_max_fall_speed: float = 520.0
@export var goal_collision_size: Vector2 = Vector2(16.0, 16.0)
@export var terrain_collision_mask: int = 1

var _controlled_goal: Node2D
var _goal_velocity: Vector2 = Vector2.ZERO
var _motion_cast: ShapeCast2D


func _init() -> void:
	ability_name = "GoalControl"
	hold_to_maintain = false


func execute(player: CharacterBody2D) -> void:
	_controlled_goal = _find_goal(player)
	if _controlled_goal == null:
		return

	_goal_velocity = Vector2.ZERO
	_set_motion_collision_enabled(_controlled_goal, true)
	if player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
	player.velocity = Vector2.ZERO
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player != null and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	_goal_velocity = Vector2.ZERO
	_set_motion_collision_enabled(_controlled_goal, false)
	_controlled_goal = null
	emit_ability_used()


func physics_process(player: CharacterBody2D, delta: float) -> void:
	if _controlled_goal == null or not is_instance_valid(_controlled_goal):
		_controlled_goal = _find_goal(player)
	if _controlled_goal == null:
		return

	_set_motion_collision_enabled(_controlled_goal, true)

	var direction_x := Input.get_axis("move_left", "move_right")
	_goal_velocity.x = direction_x * goal_move_speed

	if Input.is_action_pressed("jump"):
		_goal_velocity.y = -goal_vertical_speed
	else:
		_goal_velocity.y = minf(_goal_velocity.y + goal_gravity * delta, goal_max_fall_speed)

	_move_goal_with_collision(Vector2(_goal_velocity.x * delta, 0.0))
	var vertical_motion := Vector2(0.0, _goal_velocity.y * delta)
	var vertical_fraction := _move_goal_with_collision(vertical_motion)
	if vertical_fraction < 1.0:
		_goal_velocity.y = 0.0


func _move_goal_with_collision(motion: Vector2) -> float:
	if _controlled_goal == null or motion.is_zero_approx():
		return 1.0

	var cast := _ensure_motion_cast(_controlled_goal)
	if cast == null:
		_controlled_goal.global_position += motion
		return 1.0

	cast.target_position = motion
	cast.force_shapecast_update()
	if not cast.is_colliding():
		_controlled_goal.global_position += motion
		return 1.0

	var safe_fraction := cast.get_closest_collision_safe_fraction()
	var applied_fraction := clampf(safe_fraction - 0.01, 0.0, 1.0)
	_controlled_goal.global_position += motion * applied_fraction
	return safe_fraction


func _set_motion_collision_enabled(goal: Node2D, enabled: bool) -> void:
	var cast := _ensure_motion_cast(goal)
	if cast != null:
		cast.enabled = enabled


func _ensure_motion_cast(goal: Node2D) -> ShapeCast2D:
	if goal == null:
		return null
	if is_instance_valid(_motion_cast):
		return _motion_cast

	_motion_cast = goal.get_node_or_null("GoalControlMotionCast") as ShapeCast2D
	if _motion_cast == null:
		_motion_cast = ShapeCast2D.new()
		_motion_cast.name = "GoalControlMotionCast"
		goal.add_child(_motion_cast)

	var shape := _motion_cast.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		_motion_cast.shape = shape

	shape.size = goal_collision_size
	_motion_cast.position = Vector2.ZERO
	_motion_cast.target_position = Vector2.ZERO
	_motion_cast.collision_mask = terrain_collision_mask
	_motion_cast.collide_with_areas = false
	_motion_cast.collide_with_bodies = true
	return _motion_cast


func _find_goal(player: CharacterBody2D) -> Node2D:
	if player == null or player.get_tree() == null:
		return null

	var current_scene := player.get_tree().current_scene
	if current_scene == null:
		return null

	var goal := current_scene.get_node_or_null("Entities/Goal") as Node2D
	if goal != null:
		return goal

	return _find_node_named_goal(current_scene)


func _find_node_named_goal(root: Node) -> Node2D:
	if root == null:
		return null
	if root.name == "Goal" and root is Node2D:
		return root as Node2D

	for child in root.get_children():
		var found := _find_node_named_goal(child)
		if found != null:
			return found

	return null
