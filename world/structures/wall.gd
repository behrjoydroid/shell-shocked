# Solid cover: stops soldiers and bullets. Each wall sets its own size in the scene.
extends StaticBody2D

const COLOR := Color(0.36, 0.31, 0.24)

@export var size := Vector2(20, 120)


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	$Collision.shape = shape


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), COLOR)
