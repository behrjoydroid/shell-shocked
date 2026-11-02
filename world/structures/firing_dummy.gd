# A range dummy that shoots back with a real gun, so there's something to dodge,
# take cover from and bandage after.
extends "res://world/structures/dummy.gd"

const FACING_COLOR := Color(0.2, 0.25, 0.32)

@export var target: Node2D
@export var fire_interval := 2.0

var _shot_wait := 0.0

@onready var _weapon: Node = $Weapon


func _physics_process(delta: float) -> void:
	if not target.alive:
		return
	rotation = (target.global_position - global_position).angle()
	_shot_wait -= delta
	if _weapon.ammo == 0:
		_weapon.reload()
	elif _shot_wait <= 0.0:
		_shot_wait = fire_interval
		_weapon.fire()


func _draw() -> void:
	super()
	draw_line(Vector2.ZERO, Vector2(RADIUS + 8.0, 0.0), FACING_COLOR, 4.0)
