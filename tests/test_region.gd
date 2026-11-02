extends RefCounted

const Region := preload("res://sim/region.gd")
const Stockpile := preload("res://sim/stockpile.gd")
const WESTFRONT := "res://data/region_westfront.json"


func _westfront() -> Region:
	return Region.new((load(WESTFRONT) as JSON).data)


func _of_kind(region: Region, kind: String) -> Array:
	return region.places.values().filter(func(place): return place.kind == kind)


func test_westfront_has_the_five_towns_from_the_design() -> void:
	var region := _westfront()
	var names: Array = _of_kind(region, "town").map(func(town): return town.display_name)
	names.sort()
	assert(names == ["Halle", "Ironford", "Kingsreach", "Marrow", "Westgate"], str(names))


func test_starting_owners() -> void:
	var region := _westfront()
	assert(region.places.westgate.owner == "legion")
	assert(region.places.kingsreach.owner == "crown")
	assert(region.places.ironford.owner == "", "the center starts contested")


func test_each_side_has_a_quarry_and_two_scrap_fields() -> void:
	var region := _westfront()
	var middle := region.size_m / 2.0
	for west: bool in [true, false]:
		var near := func(place): return (place.position.x < middle) == west
		assert(_of_kind(region, "quarry").filter(near).size() == 1, "one quarry each side")
		assert(_of_kind(region, "scrap").filter(near).size() == 2, "two scrap fields each side")


func test_depots_and_towns_hold_stock_and_can_be_captured() -> void:
	var region := _westfront()
	assert(not _of_kind(region, "depot").is_empty(), "there are field depots")
	for place in region.places.values():
		if place.kind == "town" or place.kind == "depot":
			assert(place.is_capturable(), place.id)
			assert(place.stock.amount("ammo") > 0.0, place.id + " has ammo to draw")
		else:
			assert(not place.is_capturable(), place.id)


func test_every_place_is_reachable_from_every_other() -> void:
	var region := _westfront()
	for a: String in region.places:
		for b: String in region.places:
			assert(region.distance(a, b) < INF, "%s can't reach %s" % [a, b])


func test_each_capital_has_two_separate_routes_to_the_center() -> void:
	var data: Dictionary = (load(WESTFRONT) as JSON).data
	for capital: String in ["westgate", "kingsreach"]:
		var first := _westfront().path(capital, "ironford")
		assert(first.size() == 2, "one stop on the way, got %s" % str(first))
		# Close the town it passed through. There must still be a way.
		var without := data.duplicate(true)
		without.roads = without.roads.filter(func(road): return first[0] not in road)
		assert(Region.new(without).distance(capital, "ironford") < INF, "%s only has one route" % capital)


func test_the_map_is_fair() -> void:
	# Turned half a circle around the center, the map lands exactly on itself.
	var region := _westfront()
	var size := region.size_m
	for place in region.places.values():
		var mirrored: Vector2 = Vector2(size, size) - place.position
		var twins: Array = region.places.values().filter(func(other): return other.position == mirrored)
		assert(twins.size() == 1, place.id + " has no opposite number")
		var twin = twins[0]
		assert(twin.kind == place.kind, place.id)
		assert(twin.fortification == place.fortification, place.id)
		for resource in Stockpile.RESOURCES:
			assert(twin.stock.amount(resource) == place.stock.amount(resource), "%s %s" % [place.id, resource])
		for neighbour: String in region.neighbours(place.id):
			var there: Vector2 = Vector2(size, size) - region.places[neighbour].position
			var matched: Array = region.neighbours(twin.id).filter(func(id): return region.places[id].position == there)
			assert(matched.size() == 1, "%s and %s have different roads" % [place.id, twin.id])


func _line() -> Region:
	return Region.new({
		"name": "Test", "size_m": 1000.0, "factions": {},
		"places": [
			{"id": "a", "name": "A", "kind": "town", "pos": [0, 0]},
			{"id": "b", "name": "B", "kind": "town", "pos": [300, 0]},
			{"id": "c", "name": "C", "kind": "town", "pos": [300, 400]},
			{"id": "island", "name": "Island", "kind": "town", "pos": [900, 900]},
		],
		"roads": [["a", "b"], ["b", "c"], ["a", "c"]],
	})


func test_road_length_and_travel_time_come_from_positions() -> void:
	var region := _line()
	assert(is_equal_approx(region.road_length("b", "c"), 400.0))
	assert(is_equal_approx(region.road_length("c", "b"), 400.0), "roads run both ways")
	assert(is_equal_approx(region.travel_time("b", "c", 2.0), 200.0))


func test_path_takes_the_shortest_way_and_leaves_out_the_start() -> void:
	var region := _line()
	assert(region.path("a", "c") == PackedStringArray(["c"]), "direct is 500, via b is 700")
	assert(region.path("b", "a") == PackedStringArray(["a"]))
	assert(is_equal_approx(region.distance("a", "c"), 500.0))


func test_path_goes_through_stops_when_that_is_the_way() -> void:
	var region := _westfront()
	var route := region.path("west_quarry", "ironford")
	assert(route[0] == "westgate", str(route))
	assert(route[route.size() - 1] == "ironford", str(route))


func test_path_is_empty_when_already_there_or_cut_off() -> void:
	var region := _line()
	assert(region.path("a", "a").is_empty())
	assert(region.path("a", "island").is_empty())
	assert(region.distance("a", "island") == INF)


func test_path_ties_go_the_same_way_whatever_the_data_order() -> void:
	var places := [
		{"id": "start", "name": "S", "kind": "town", "pos": [0, 0]},
		{"id": "north", "name": "N", "kind": "town", "pos": [100, 100]},
		{"id": "south", "name": "S", "kind": "town", "pos": [100, -100]},
		{"id": "end", "name": "E", "kind": "town", "pos": [200, 0]},
	]
	var roads := [["start", "north"], ["north", "end"], ["start", "south"], ["south", "end"]]
	var forward := Region.new({"name": "T", "size_m": 1.0, "factions": {}, "places": places, "roads": roads})
	places.reverse()
	roads.reverse()
	var backward := Region.new({"name": "T", "size_m": 1.0, "factions": {}, "places": places, "roads": roads})
	assert(forward.path("start", "end") == backward.path("start", "end"))
