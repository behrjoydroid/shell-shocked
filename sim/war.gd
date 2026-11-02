# One whole war: the map, the squads, the commanders, the one random number generator,
# and the order things happen in each tick. Everything in it can run with no scene.
extends RefCounted

const Region := preload("res://sim/region.gd")
const Squad := preload("res://sim/squad.gd")
const Commander := preload("res://sim/commander.gd")
const Resolver := preload("res://sim/resolver.gd")
const REQUIRED_STATS: Array[String] = [
	"squad_size", "squad_speed_mps", "squad_ammo_capacity", "ammo_burn_per_soldier_per_sec",
	"resupply_per_sec", "engage_range_m", "kill_rate_per_shooter_per_sec", "low_supply_firepower",
	"fortification_protection", "fortification_radius_m", "capture_time_s", "commander_interval_s",
]

var region: Region
var stats: Dictionary
var squads: Array[Squad] = []
var commanders: Array[Commander] = []
var time_s := 0.0
var over := false
# The side that took every town. Empty if the war ended with nobody left to fight.
var winner := ""
# This tick's fights, each {"position": Vector2, "squads": Array}.
var battles: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()
var _orders_left := 0.0


func _init(region_data: Dictionary, sim_stats: Dictionary, war_seed: int) -> void:
	_rng.seed = war_seed
	stats = sim_stats
	# Checked up front so a typo gives one clear error, not one on every tick. With
	# no region, whoever made this war knows it can't run.
	var complete := true
	for key in REQUIRED_STATS:
		if not stats.has(key):
			push_error("data/sim.json is missing '%s'" % key)
			complete = false
	if not complete:
		return
	region = Region.new(region_data)
	for faction: String in region.factions:
		commanders.append(Commander.new(faction))
	for group: Dictionary in region_data.squads:
		if not region.places.has(group.at) or not region.factions.has(group.faction):
			push_error("Squads of '%s' start at '%s': one of those doesn't exist" % [group.faction, group.at])
			continue
		for i in int(group.count):
			add_squad(group.faction, group.at)


func add_squad(faction: String, place_id: String) -> Squad:
	var squad := Squad.new(squads.size(), faction, place_id, int(stats.squad_size), stats.squad_ammo_capacity)
	squads.append(squad)
	return squad


func tick(dt: float) -> void:
	if over:
		return
	time_s += dt
	_orders_left -= dt
	if _orders_left <= 0.0:
		_orders_left = stats.commander_interval_s
		for commander in commanders:
			commander.assign_orders(self)
	_fight(dt)
	_march(dt)
	_resupply(dt)
	_capture(dt)
	_check_over()


func squads_of(faction: String) -> Array[Squad]:
	return squads.filter(func(squad: Squad) -> bool: return squad.faction == faction)


func _fight(dt: float) -> void:
	battles.clear()
	for squad in squads:
		squad.engaged = false
	var positions := {}
	for squad in squads:
		positions[squad] = squad.position(region)
	for squad in squads:
		if squad.engaged:
			continue
		var group := _contact_group(squad, positions)
		if group.size() < 2:
			continue
		var centre := Vector2.ZERO
		for member in group:
			member.engaged = true
			centre += positions[member]
		centre /= group.size()
		var side_a: Array = group.filter(func(member: Squad) -> bool: return member.faction == squad.faction)
		var side_b: Array = group.filter(func(member: Squad) -> bool: return member.faction != squad.faction)
		var fort_a := _fortification_for(squad.faction, centre)
		var fort_b := _fortification_for(side_b[0].faction, centre)
		Resolver.fight(side_a, side_b, fort_a, fort_b, dt, stats, _rng)
		battles.append({"position": centre, "squads": group})
	squads = squads.filter(func(squad: Squad) -> bool: return squad.soldiers > 0)


# Every squad joined to this one through enemies within range of each other.
func _contact_group(start: Squad, positions: Dictionary) -> Array:
	var group: Array = [start]
	var index := 0
	while index < group.size():
		var current: Squad = group[index]
		index += 1
		for other in squads:
			if other.faction != current.faction and other not in group \
					and positions[current].distance_to(positions[other]) <= stats.engage_range_m:
				group.append(other)
	return group


func _fortification_for(faction: String, position: Vector2) -> float:
	var best := 0.0
	for place in region.places.values():
		if place.owner == faction and place.position.distance_to(position) <= stats.fortification_radius_m:
			best = maxf(best, place.fortification)
	return best


func _march(dt: float) -> void:
	var metres: float = stats.squad_speed_mps * dt
	for squad in squads:
		if not squad.engaged:
			squad.walk(metres, region)


# A squad stopped at its own side's place tops up from the stock there.
func _resupply(dt: float) -> void:
	var most: float = stats.resupply_per_sec * dt
	for squad in squads:
		if not squad.is_at_place():
			continue
		var place: RefCounted = region.places[squad.at]
		if place.owner == squad.faction:
			squad.ammo += place.stock.take("ammo", minf(most, squad.ammo_capacity - squad.ammo))


# One side alone at a place it doesn't own takes it by holding it, without a break.
func _capture(dt: float) -> void:
	var present := {}
	for squad in squads:
		if squad.is_at_place():
			if not present.has(squad.at):
				present[squad.at] = {}
			present[squad.at][squad.faction] = true
	for place in region.places.values():
		if not place.is_capturable():
			continue
		var sides: Array = present.get(place.id, {}).keys()
		if sides.size() != 1 or sides[0] == place.owner:
			place.capture_faction = ""
			continue
		if place.capture_faction != sides[0]:
			place.capture_faction = sides[0]
			place.capture_left = stats.capture_time_s
		place.capture_left -= dt
		if place.capture_left <= 0.0:
			place.owner = sides[0]
			place.capture_faction = ""


func _check_over() -> void:
	if squads.is_empty():
		over = true
		return
	var owners := {}
	for place in region.places.values():
		if place.kind == "town":
			owners[place.owner] = true
	if owners.size() == 1 and not owners.has(""):
		over = true
		winner = owners.keys()[0]
