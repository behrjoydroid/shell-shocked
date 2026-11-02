# A range target. It flashes when hit and darkens as it takes damage, falls when it
# runs out of health, and stands back up after a while. Tuning is in data/dummy.json.
extends StaticBody2D

const STATS_PATH := "res://data/dummy.json"
const RADIUS := 14.0
const COLOR := Color(0.45, 0.52, 0.62)
const DAMAGED_COLOR := Color(0.2, 0.14, 0.14)
const FLASH_COLOR := Color(1.0, 0.95, 0.8)
const FLASH_TIME := 0.1
const FALLEN_COLOR := Color(0.28, 0.25, 0.22)
const FALLEN_DRAW_SCALE := 0.6

var health := 0.0
var health_max := 0.0
var standing := true

var _stand_up_time: float
var _stand_up_left := 0.0
var _flash_left := 0.0

@onready var _collision: CollisionShape2D = $Collision


func _ready() -> void:
	var stats: Dictionary = (load(STATS_PATH) as JSON).data
	health_max = stats.health
	health = health_max
	_stand_up_time = stats.stand_up_time


func take_hit(damage: float) -> void:
	if not standing:
		return
	health = maxf(health - damage, 0.0)
	_flash_left = FLASH_TIME
	if health == 0.0:
		standing = false
		_stand_up_left = _stand_up_time
		_collision.set_deferred("disabled", true)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			queue_redraw()
	if not standing:
		_stand_up_left -= delta
		if _stand_up_left <= 0.0:
			standing = true
			health = health_max
			_collision.set_deferred("disabled", false)
			queue_redraw()


func _draw() -> void:
	if not standing:
		draw_circle(Vector2.ZERO, RADIUS * FALLEN_DRAW_SCALE, FALLEN_COLOR)
	elif _flash_left > 0.0:
		draw_circle(Vector2.ZERO, RADIUS, FLASH_COLOR)
	else:
		draw_circle(Vector2.ZERO, RADIUS, COLOR.lerp(DAMAGED_COLOR, 1.0 - health / health_max))
