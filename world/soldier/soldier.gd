# Placeholder player: a circle with a facing line. Moves and aims independently.
# Tuning lives in data/soldier.json.
extends CharacterBody2D

const STATS_PATH := "res://data/soldier.json"
const RADIUS := 12.0
const COLOR := Color(0.85, 0.55, 0.25)
const FACING_COLOR := Color(0.95, 0.9, 0.75)
const HURT_COLOR := Color(0.9, 0.2, 0.15)
const HURT_FLASH_TIME := 0.12

var stamina: float
var stamina_max: float
# Set when stamina runs out, and blocks sprinting until it recovers. Without this,
# holding sprint at empty would flicker between sprinting and walking every frame.
var exhausted := false
var health: float
var health_max: float
var bandages: int
var bandaging := false
var alive := true
var respawn_left := 0.0

@onready var weapon: Node = $Weapon
@onready var _collision: CollisionShape2D = $Collision

var _bandages_carried: int
var _bandage_time: float
var _bandage_heal: float
var _bandage_left := 0.0
var _respawn_delay: float
var _hurt_flash_left := 0.0
var _walk_speed: float
var _sprint_speed: float
var _acceleration: float
var _stamina_drain: float
var _stamina_regen: float
var _stamina_regen_delay: float
var _stamina_recover_at: float
var _regen_wait := 0.0
var _aiming_with_stick := false


func _ready() -> void:
	var stats: Dictionary = (load(STATS_PATH) as JSON).data
	_walk_speed = stats.walk_speed
	_sprint_speed = stats.sprint_speed
	_acceleration = stats.acceleration
	stamina_max = stats.stamina_max
	_stamina_drain = stats.stamina_drain_per_sec
	_stamina_regen = stats.stamina_regen_per_sec
	_stamina_regen_delay = stats.stamina_regen_delay
	_stamina_recover_at = stats.stamina_recover_at
	stamina = stamina_max
	health_max = stats.health_max
	health = health_max
	_bandages_carried = int(stats.bandages)
	bandages = _bandages_carried
	_bandage_time = stats.bandage_time
	_bandage_heal = stats.bandage_heal
	_respawn_delay = stats.respawn_delay


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_aiming_with_stick = false


func _process(delta: float) -> void:
	if _hurt_flash_left > 0.0:
		_hurt_flash_left -= delta
		if _hurt_flash_left <= 0.0:
			queue_redraw()


func _physics_process(delta: float) -> void:
	if not alive:
		respawn_left -= delta
		if respawn_left <= 0.0:
			_respawn()
		return
	_update_aim()
	var firing := Input.is_action_just_pressed("fire")
	var reloading := Input.is_action_just_pressed("reload")
	if firing:
		weapon.fire()
	if reloading:
		weapon.reload()
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_bandage(delta, firing or reloading or move != Vector2.ZERO)
	var sprinting := Input.is_action_pressed("sprint") and move != Vector2.ZERO and not exhausted
	var target := move * (_sprint_speed if sprinting else _walk_speed)
	velocity = velocity.move_toward(target, _acceleration * delta)
	move_and_slide()
	# No camera yet, so stay on screen.
	var margin := Vector2.ONE * RADIUS
	position = position.clamp(margin, get_viewport_rect().size - margin)
	_update_stamina(delta, sprinting)


# The right stick takes over aiming while it's held and keeps its last direction
# when released. Moving the mouse hands aiming back to the mouse.
func _update_aim() -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick != Vector2.ZERO:
		_aiming_with_stick = true
		rotation = stick.angle()
	elif not _aiming_with_stick:
		look_at(get_global_mouse_position())


func _update_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		stamina = maxf(stamina - _stamina_drain * delta, 0.0)
		_regen_wait = _stamina_regen_delay
		if stamina == 0.0:
			exhausted = true
		return
	_regen_wait = maxf(_regen_wait - delta, 0.0)
	if _regen_wait == 0.0:
		stamina = minf(stamina + _stamina_regen * delta, stamina_max)
		if stamina >= _stamina_recover_at:
			exhausted = false


# Bandaging takes both hands and standing still: moving, firing or reloading cancels
# it, and the bandage is only used up when it finishes. Taking a hit doesn't cancel it.
func _update_bandage(delta: float, busy: bool) -> void:
	if busy:
		bandaging = false
		return
	if Input.is_action_just_pressed("bandage") and not bandaging and bandages > 0 \
			and health < health_max and not weapon.reloading:
		bandaging = true
		_bandage_left = _bandage_time
	if bandaging:
		_bandage_left -= delta
		if _bandage_left <= 0.0:
			bandaging = false
			bandages -= 1
			health = minf(health + _bandage_heal, health_max)


func take_hit(damage: float) -> void:
	if not alive:
		return
	health = maxf(health - damage, 0.0)
	_hurt_flash_left = HURT_FLASH_TIME
	queue_redraw()
	if health == 0.0:
		_die()


func _die() -> void:
	alive = false
	bandaging = false
	respawn_left = _respawn_delay
	velocity = Vector2.ZERO
	visible = false
	_collision.set_deferred("disabled", true)


func _respawn() -> void:
	alive = true
	visible = true
	_collision.set_deferred("disabled", false)
	global_position = get_tree().get_first_node_in_group("spawn_points").global_position
	health = health_max
	stamina = stamina_max
	exhausted = false
	_regen_wait = 0.0
	bandages = _bandages_carried
	weapon.refill()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, HURT_COLOR if _hurt_flash_left > 0.0 else COLOR)
	draw_line(Vector2.ZERO, Vector2(RADIUS + 8.0, 0.0), FACING_COLOR, 3.0)
