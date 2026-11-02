# A range target. For now it only shows that a bullet landed: it flashes and counts.
extends StaticBody2D

const RADIUS := 14.0
const COLOR := Color(0.45, 0.52, 0.62)
const FLASH_COLOR := Color(1.0, 0.95, 0.8)
const FLASH_TIME := 0.1

var hits := 0

var _flash_left := 0.0


func take_hit(_damage: float) -> void:
	hits += 1
	_flash_left = FLASH_TIME
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, FLASH_COLOR if _flash_left > 0.0 else COLOR)
