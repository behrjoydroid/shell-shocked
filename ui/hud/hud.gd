# Placeholder HUD: health and stamina bars, ammo and bandage counts, death message.
extends CanvasLayer

const STAMINA_COLOR := Color(0.75, 0.7, 0.4)
const EXHAUSTED_COLOR := Color(0.7, 0.25, 0.2)

@export var soldier: CharacterBody2D

@onready var _back: ColorRect = $StaminaBack
@onready var _fill: ColorRect = $StaminaBack/StaminaFill
@onready var _ammo: Label = $AmmoLabel
@onready var _health_back: ColorRect = $HealthBack
@onready var _health_fill: ColorRect = $HealthBack/HealthFill
@onready var _bandages: Label = $BandageLabel
@onready var _status: Label = $StatusLabel
@onready var _stance: Label = $StanceLabel


func _ready() -> void:
	# A broken data/soldier.json leaves these at 0. Dividing by them here would log
	# an error every frame and bury the one that names the bad file.
	set_process(soldier.stamina_max > 0.0 and soldier.health_max > 0.0)


func _process(_delta: float) -> void:
	_fill.size.x = _back.size.x * soldier.stamina / soldier.stamina_max
	_fill.color = EXHAUSTED_COLOR if soldier.exhausted else STAMINA_COLOR
	_health_fill.size.x = _health_back.size.x * soldier.health / soldier.health_max
	_bandages.text = "Bandaging" if soldier.bandaging else "Bandages %d" % soldier.bandages
	_stance.text = "Crouched" if soldier.crouching else ""
	_status.text = "" if soldier.alive else "You died. Respawning in %d" % ceili(soldier.respawn_left)
	var weapon: Node = soldier.weapon
	if weapon.reloading:
		_ammo.text = "Reloading"
	elif weapon.ammo == 0:
		_ammo.text = "Empty, press R"
	else:
		_ammo.text = "%d / %d" % [weapon.ammo, weapon.magazine_size]
