# Placeholder HUD: just a stamina bar for now.
extends CanvasLayer

const STAMINA_COLOR := Color(0.75, 0.7, 0.4)
const EXHAUSTED_COLOR := Color(0.7, 0.25, 0.2)

@export var soldier: CharacterBody2D

@onready var _back: ColorRect = $StaminaBack
@onready var _fill: ColorRect = $StaminaBack/StaminaFill


func _ready() -> void:
	# A broken data/soldier.json leaves stamina_max at 0. Dividing by it here would
	# log an error every frame and bury the one that names the bad file.
	set_process(soldier.stamina_max > 0.0)


func _process(_delta: float) -> void:
	_fill.size.x = _back.size.x * soldier.stamina / soldier.stamina_max
	_fill.color = EXHAUSTED_COLOR if soldier.exhausted else STAMINA_COLOR
