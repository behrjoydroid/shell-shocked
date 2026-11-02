# Placeholder player: a circle that walks. M1 grows this into the real soldier.
extends CharacterBody2D

const RADIUS := 12.0
const COLOR := Color(0.85, 0.55, 0.25)

@export var speed := 200.0


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
	# No camera yet, so stay on screen.
	var margin := Vector2.ONE * RADIUS
	position = position.clamp(margin, get_viewport_rect().size - margin)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
