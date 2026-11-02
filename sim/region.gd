# The map: places joined by roads, loaded from data/region_*.json. A road's length
# comes from where its ends are, and its travel time from the speed of who's on it.
extends RefCounted

const Town := preload("res://sim/town.gd")

var display_name: String
var size_m: float
var factions: Dictionary
# Place id -> place, in the order the data lists them.
var places := {}

# Place id -> {neighbouring place id -> road length in metres}.
var _roads := {}


func _init(data: Dictionary) -> void:
	display_name = data.name
	size_m = data.size_m
	factions = data.factions
	for entry: Dictionary in data.places:
		var place := Town.new(entry)
		places[place.id] = place
		_roads[place.id] = {}
		if place.owner != "" and not factions.has(place.owner):
			push_error("Place '%s' has unknown owner '%s'" % [place.id, place.owner])
			place.owner = ""
	for road: Array in data.roads:
		_add_road(road[0], road[1])


func _add_road(a: String, b: String) -> void:
	if not places.has(a) or not places.has(b):
		push_error("Road %s - %s names a place that doesn't exist" % [a, b])
		return
	var length: float = places[a].position.distance_to(places[b].position)
	_roads[a][b] = length
	_roads[b][a] = length


func neighbours(id: String) -> Array:
	return _roads[id].keys()


func road_length(a: String, b: String) -> float:
	return _roads[a][b]


func travel_time(a: String, b: String, speed_mps: float) -> float:
	return road_length(a, b) / speed_mps


# The shortest route between two places, as the places to pass through in order.
# It leaves out `from`, and is empty if already there or there's no way through.
func path(from: String, to: String) -> PackedStringArray:
	var previous: Dictionary = _search(from).previous
	var route := PackedStringArray()
	if not previous.has(to):
		return route
	var step := to
	while step != from:
		route.append(step)
		step = previous[step]
	route.reverse()
	return route


# Road distance between two places, INF if there's no way through.
func distance(from: String, to: String) -> float:
	return _search(from).costs.get(to, INF)


# Dijkstra. Ties go to the lowest place id, so a route never depends on load order.
func _search(from: String) -> Dictionary:
	var costs := {from: 0.0}
	var previous := {}
	var done := {}
	while true:
		var current := ""
		for id: String in costs:
			if done.has(id):
				continue
			if current == "" or costs[id] < costs[current] or (costs[id] == costs[current] and id < current):
				current = id
		if current == "":
			break
		done[current] = true
		for next: String in _roads[current]:
			var cost: float = costs[current] + _roads[current][next]
			var better: bool = not costs.has(next) or cost < costs[next]
			var tied_lower: bool = costs.has(next) and cost == costs[next] and current < previous.get(next, "")
			if better or tied_lower:
				costs[next] = cost
				previous[next] = current
	return {"costs": costs, "previous": previous}
