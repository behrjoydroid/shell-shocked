extends RefCounted

const Region := preload("res://sim/region.gd")
const Squad := preload("res://sim/squad.gd")


func _region() -> Region:
	return Region.new({
		"name": "Test", "size_m": 1000.0, "factions": {},
		"places": [
			{"id": "a", "name": "A", "kind": "town", "pos": [0, 0]},
			{"id": "b", "name": "B", "kind": "town", "pos": [100, 0]},
			{"id": "c", "name": "C", "kind": "town", "pos": [100, 100]},
		],
		"roads": [["a", "b"], ["b", "c"]],
	})


func _squad() -> Squad:
	return Squad.new(1, "legion", "a", 8, 40.0)


func test_a_new_squad_is_stopped_at_its_place() -> void:
	var region := _region()
	var squad := _squad()
	assert(not squad.is_moving())
	assert(squad.position(region) == Vector2(0, 0))
	assert(squad.soldiers == 8)
	assert(squad.supply() == 1.0)


func test_with_no_route_walking_goes_nowhere() -> void:
	var region := _region()
	var squad := _squad()
	squad.walk(50.0, region)
	assert(squad.position(region) == Vector2(0, 0))


func test_walks_partway_along_a_road() -> void:
	var region := _region()
	var squad := _squad()
	squad.set_route(PackedStringArray(["b"]))
	squad.walk(25.0, region)
	assert(squad.is_moving())
	assert(squad.position(region).is_equal_approx(Vector2(25, 0)))
	assert(squad.at == "a" and squad.next == "b")


func test_stops_exactly_at_the_end_of_its_route() -> void:
	var region := _region()
	var squad := _squad()
	squad.set_route(PackedStringArray(["b"]))
	squad.walk(1000.0, region)
	assert(not squad.is_moving())
	assert(squad.at == "b")
	assert(squad.position(region) == Vector2(100, 0))


func test_a_long_step_carries_on_round_the_corner() -> void:
	var region := _region()
	var squad := _squad()
	squad.set_route(PackedStringArray(["b", "c"]))
	squad.walk(130.0, region)
	assert(squad.at == "b" and squad.next == "c")
	assert(squad.position(region).is_equal_approx(Vector2(100, 30)))


func test_landing_exactly_on_a_stop_doesnt_count_as_stopping() -> void:
	var region := _region()
	var squad := _squad()
	squad.set_route(PackedStringArray(["b", "c"]))
	squad.walk(100.0, region)
	assert(squad.at == "b" and squad.next == "c", "should already be on the next road")
	assert(not squad.is_at_place())


func test_a_new_route_mid_road_finishes_the_road_first() -> void:
	var region := _region()
	var squad := _squad()
	squad.set_route(PackedStringArray(["b"]))
	squad.walk(50.0, region)
	squad.set_route(PackedStringArray(["c"]))
	assert(squad.next == "b", "still heading for b")
	squad.walk(60.0, region)
	assert(squad.at == "b" and squad.next == "c")
	assert(squad.position(region).is_equal_approx(Vector2(100, 10)))


func test_squads_never_teleport_over_1000_ticks() -> void:
	var region := Region.new((load("res://data/region_westfront.json") as JSON).data)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ids: Array = region.places.keys()
	var squad := Squad.new(1, "legion", "westgate", 8, 40.0)
	var step := 2.0 * 0.25
	var last := squad.position(region)
	for i in 1000:
		if not squad.is_moving():
			var target: String = ids[rng.randi() % ids.size()]
			squad.set_route(region.path(squad.at, target))
		squad.walk(step * rng.randf_range(0.0, 200.0), region)
		var now := squad.position(region)
		assert(now.distance_to(last) <= step * 200.0 + 0.01, "jumped from %s to %s" % [last, now])
		assert(squad.metres_along >= 0.0)
		if squad.next != "":
			assert(squad.metres_along < region.road_length(squad.at, squad.next), "walked past the end of a road")
			assert(squad.next in region.neighbours(squad.at), "on a road that doesn't exist")
		last = now
