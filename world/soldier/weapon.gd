# A gun carried by its parent soldier: magazine, fire rate, reload, and launching
# bullets. Stats come from data/weapons.json. Spare ammo is unlimited until M4 adds
# somewhere to get more.
extends Node2D

const WEAPONS_PATH := "res://data/weapons.json"
const BULLET := preload("res://world/bullets/bullet.tscn")
const GUN_SOUNDS := preload("res://world/soldier/gun_sounds.gd")
const SOUND_VOLUME_DB := -6.0
const OVERLAPPING_SOUNDS := 4

@export var weapon_id := "rifle"

var ammo := 0
var magazine_size := 0
var reloading := false

var _shot_interval: float
var _reload_time: float
var _damage: float
var _bullet_speed: float
var _bullet_range: float
var _cooldown := 0.0
var _reload_left := 0.0
var _shot_player: AudioStreamPlayer2D
var _click_player: AudioStreamPlayer2D
var _clack_player: AudioStreamPlayer2D


func _ready() -> void:
	_shot_player = _make_player(GUN_SOUNDS.shot())
	_click_player = _make_player(GUN_SOUNDS.click())
	_clack_player = _make_player(GUN_SOUNDS.clack())
	var stats: Dictionary = (load(WEAPONS_PATH) as JSON).data[weapon_id]
	_shot_interval = stats.shot_interval
	_reload_time = stats.reload_time
	_damage = stats.damage
	_bullet_speed = stats.bullet_speed
	_bullet_range = stats.bullet_range
	magazine_size = int(stats.magazine)
	ammo = magazine_size


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			reloading = false
			ammo = magazine_size
			_clack_player.play()


func fire() -> void:
	if reloading or _cooldown > 0.0:
		return
	if ammo == 0:
		_click_player.play()
		return
	ammo -= 1
	_cooldown = _shot_interval
	_shot_player.play()
	var shooter: CollisionObject2D = get_parent()
	var bullet: Node2D = BULLET.instantiate()
	shooter.get_parent().add_child(bullet)
	bullet.launch(shooter, _damage, _bullet_speed, _bullet_range)


func reload() -> void:
	if reloading or ammo == magazine_size:
		return
	reloading = true
	_reload_left = _reload_time
	_clack_player.play()


func refill() -> void:
	ammo = magazine_size
	reloading = false
	_cooldown = 0.0


func _make_player(stream: AudioStream) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = SOUND_VOLUME_DB
	player.max_polyphony = OVERLAPPING_SOUNDS
	add_child(player)
	return player
