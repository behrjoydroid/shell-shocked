# A bullet in flight. Each step sweeps a ray, so a fast bullet can't skip past
# anything thin. It starts at the shooter's center rather than the muzzle, so a
# muzzle poking through a wall can't fire from the far side.
extends Node2D

const COLOR := Color(1.0, 0.9, 0.6)
const TRACER_LENGTH := 16.0
const ALL_LAYERS := 0xFFFFFFFF

var _damage: float
var _speed: float
var _range_left: float
var _exclude: Array[RID]


func launch(shooter: CollisionObject2D, damage: float, speed: float, max_range: float) -> void:
	global_position = shooter.global_position
	rotation = shooter.global_rotation
	_damage = damage
	_speed = speed
	_range_left = max_range
	_exclude = [shooter.get_rid()]


func _physics_process(delta: float) -> void:
	var step := minf(_speed * delta, _range_left)
	var next := global_position + Vector2.from_angle(rotation) * step
	var query := PhysicsRayQueryParameters2D.create(global_position, next, ALL_LAYERS, _exclude)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		if hit.collider.has_method("take_hit"):
			hit.collider.take_hit(_damage)
		queue_free()
		return
	global_position = next
	_range_left -= step
	if _range_left <= 0.0:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-TRACER_LENGTH, 0.0), Vector2.ZERO, COLOR, 2.0)
