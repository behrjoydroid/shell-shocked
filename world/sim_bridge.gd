# The one door between the sim and everything with a scene. It runs the war on the
# clock, and scenes read and change the war through here. The sim keeps running
# whether or not anyone is looking at it.
extends Node

const War := preload("res://sim/war.gd")
const SimClock := preload("res://sim/sim_clock.gd")
const REGION_PATH := "res://data/region_westfront.json"
const SIM_PATH := "res://data/sim.json"

var war: War
var clock := SimClock.new()
var war_seed := 0


func _ready() -> void:
	start_war(randi())


func start_war(new_seed: int) -> void:
	# If the data is broken there's no war to run, and its error shouldn't get buried.
	set_process(false)
	war = null
	war_seed = new_seed
	var new_war := War.new((load(REGION_PATH) as JSON).data, (load(SIM_PATH) as JSON).data, new_seed)
	if new_war.region != null:
		war = new_war
		set_process(true)


func _process(delta: float) -> void:
	for i in clock.advance(delta):
		war.tick(SimClock.TICK_SECONDS)
