extends RefCounted

const War := preload("res://sim/war.gd")
const Stockpile := preload("res://sim/stockpile.gd")
const TICK := 0.25


func _stats() -> Dictionary:
	return (load("res://data/sim.json") as JSON).data


func _westfront(war_seed: int) -> War:
	return War.new((load("res://data/region_westfront.json") as JSON).data, _stats(), war_seed)


func _two_towns(squads: Array, length := 800.0, west_ammo := 100.0) -> Dictionary:
	return {
		"name": "Test", "size_m": 1000.0,
		"factions": {"legion": {}, "crown": {}},
		"places": [
			{"id": "west", "name": "West", "kind": "town", "pos": [0, 0], "owner": "legion", "stock": {"ammo": west_ammo}},
			{"id": "east", "name": "East", "kind": "town", "pos": [length, 0], "owner": "crown", "stock": {"ammo": 100}},
		],
		"roads": [["west", "east"]],
		"squads": squads,
	}


func _total_soldiers(war: War) -> int:
	var total := 0
	for squad in war.squads:
		total += squad.soldiers
	return total


func _assert_invariants(war: War, last_positions: Dictionary, step: float) -> void:
	for place in war.region.places.values():
		for resource in Stockpile.RESOURCES:
			assert(place.stock.amount(resource) >= 0.0, "%s %s went negative" % [place.id, resource])
	for squad in war.squads:
		assert(squad.soldiers > 0 and squad.soldiers <= 8, "squad has %d soldiers" % squad.soldiers)
		assert(squad.ammo >= 0.0 and squad.ammo <= squad.ammo_capacity + 0.0001, "ammo %f" % squad.ammo)
		var now: Vector2 = squad.position(war.region)
		if last_positions.has(squad):
			var moved: float = now.distance_to(last_positions[squad])
			assert(moved <= step + 0.01, "squad jumped %.1f m in a tick" % moved)
		last_positions[squad] = now


# The milestone's test: two squads meet, fight, one wins, and stock stays sane.
func test_two_squads_fight_and_one_wins_and_stock_never_goes_negative() -> void:
	var fought := false
	for war_seed in 8:
		var war := War.new(_two_towns([
			{"faction": "legion", "at": "west", "count": 1},
			{"faction": "crown", "at": "east", "count": 1},
		]), _stats(), war_seed)
		var last := {}
		var step: float = war.stats.squad_speed_mps * TICK
		for i in 4000:
			war.tick(TICK)
			_assert_invariants(war, last, step)
			fought = fought or not war.battles.is_empty()
			if war.squads.size() < 2:
				break
		assert(war.squads.size() == 1, "seed %d: no winner, %d squads left" % [war_seed, war.squads.size()])
		var winner = war.squads[0]
		assert(winner.soldiers > 0 and winner.soldiers <= 8, "winner has %d" % winner.soldiers)
	assert(fought, "they never met")


func test_squads_stop_to_fight_and_only_then() -> void:
	var war := War.new(_two_towns([
		{"faction": "legion", "at": "west", "count": 1},
		{"faction": "crown", "at": "east", "count": 1},
	]), _stats(), 1)
	var range_m: float = war.stats.engage_range_m
	var checked := false
	for i in 4000:
		war.tick(TICK)
		if war.squads.size() < 2:
			break
		var a: Vector2 = war.squads[0].position(war.region)
		var b: Vector2 = war.squads[1].position(war.region)
		if war.squads[0].engaged:
			var before := a
			var battles_before := war.battles.size()
			assert(battles_before == 1, "one fight")
			war.tick(TICK)
			if war.squads.size() == 2 and war.squads[0].engaged:
				assert(war.squads[0].position(war.region) == before, "walked mid-fight")
				checked = true
		else:
			assert(a.distance_to(b) > range_m - 2.0 * war.stats.squad_speed_mps * TICK, "not fighting at %.0f m" % a.distance_to(b))
	assert(checked, "the fight never happened")


func test_westfront_invariants_over_1000_ticks_and_on_to_the_end() -> void:
	for war_seed in 1:
		var war := _westfront(war_seed)
		var last := {}
		var step: float = war.stats.squad_speed_mps * TICK
		var soldiers := _total_soldiers(war)
		var ticks := 0
		while not war.over and ticks < 60000:
			war.tick(TICK)
			ticks += 1
			_assert_invariants(war, last, step)
			var now := _total_soldiers(war)
			assert(now <= soldiers, "soldiers appeared from nowhere")
			soldiers = now
		assert(ticks >= 1000, "war over suspiciously fast, in %d ticks" % ticks)
		assert(war.over, "seed %d: war never ended in %d ticks" % [war_seed, ticks])
		if war.winner != "":
			for place in war.region.places.values():
				if place.kind == "town":
					assert(place.owner == war.winner, "%s isn't the winner's" % place.id)


func _state_of(war: War) -> Array:
	var state: Array = [war.winner, war.time_s]
	for squad in war.squads:
		state.append([squad.id, squad.soldiers, squad.ammo, squad.at, squad.next, squad.metres_along])
	for place in war.region.places.values():
		state.append([place.id, place.owner, place.stock.amount("ammo")])
	return state


func test_same_seed_same_war() -> void:
	var a := _westfront(99)
	var b := _westfront(99)
	var c := _westfront(100)
	for i in 5000:
		a.tick(TICK)
		b.tick(TICK)
		c.tick(TICK)
	assert(_state_of(a) == _state_of(b), "same seed should replay exactly")
	assert(_state_of(a) != _state_of(c), "a different seed should go differently")


func test_a_lone_squad_takes_an_empty_town_in_60_seconds() -> void:
	var war := War.new(_two_towns([{"faction": "legion", "at": "east", "count": 1}]), _stats(), 1)
	var east: RefCounted = war.region.places.east
	var ticks := 0
	while east.owner != "legion" and ticks < 1000:
		war.tick(TICK)
		ticks += 1
	var want: float = war.stats.capture_time_s / TICK
	assert(absf(ticks - want) <= 1.0, "took %d ticks, wanted about %.0f" % [ticks, want])
	assert(war.over and war.winner == "legion", "that was the last town")


func test_capture_needs_an_unbroken_hold() -> void:
	var war := War.new(_two_towns([{"faction": "legion", "at": "east", "count": 1}], 8000.0), _stats(), 1)
	var east: RefCounted = war.region.places.east
	var squad = war.squads[0]
	for i in 200:
		war.tick(TICK)
	assert(east.capture_faction == "legion", "should be taking it")
	assert(east.owner == "crown", "not yet")
	# March off before the 60 s are up and the clock resets.
	squad.set_route(PackedStringArray(["west"]))
	war.tick(TICK)
	assert(east.capture_faction == "", "left, so no longer taking it")
	war.squads.clear()
	var again := war.add_squad("legion", "east")
	war.tick(TICK)
	assert(again != null and east.capture_faction == "legion")
	assert(east.capture_left > war.stats.capture_time_s - 1.0, "started over, %f left" % east.capture_left)


func test_a_contested_town_cant_be_taken() -> void:
	var stats := _stats().duplicate()
	stats.kill_rate_per_shooter_per_sec = 0.0
	var war := War.new(_two_towns([
		{"faction": "legion", "at": "east", "count": 1},
		{"faction": "crown", "at": "east", "count": 1},
	]), stats, 1)
	var east: RefCounted = war.region.places.east
	for i in 2000:
		war.tick(TICK)
		assert(east.capture_faction == "", "both sides are there")
	assert(east.owner == "crown")


func test_a_squad_passing_through_doesnt_capture() -> void:
	var data := _two_towns([{"faction": "legion", "at": "west", "count": 1}], 400.0)
	data.places.append({"id": "far", "name": "Far", "kind": "town", "pos": [800, 0], "owner": "crown"})
	data.roads.append(["east", "far"])
	var war := War.new(data, _stats(), 1)
	var squad = war.squads[0]
	squad.set_route(PackedStringArray(["east", "far"]))
	war._orders_left = 1000000.0
	for i in 1650:
		war.tick(TICK)
		if squad.is_moving():
			assert(war.region.places.east.capture_faction == "", "walking through shouldn't count")
	assert(squad.at == "far" and not squad.is_moving(), "at %s" % squad.at)
	assert(war.region.places.east.owner == "crown", "still theirs")


func test_resupply_moves_units_and_doesnt_make_them() -> void:
	var war := War.new(_two_towns([{"faction": "legion", "at": "west", "count": 1}], 800.0, 30.0), _stats(), 1)
	war._orders_left = 1000000.0
	var squad = war.squads[0]
	var stock: RefCounted = war.region.places.west.stock
	squad.ammo = 5.0
	var total: float = squad.ammo + stock.amount("ammo")
	for i in 20:
		war.tick(TICK)
		assert(is_equal_approx(squad.ammo + stock.amount("ammo"), total), "units appeared or vanished")
	assert(squad.ammo > 5.0, "it should have drawn some")
	assert(squad.ammo <= squad.ammo_capacity)
	for i in 400:
		war.tick(TICK)
	assert(is_equal_approx(squad.ammo, 35.0), "got everything the depot had, %f" % squad.ammo)
	assert(stock.amount("ammo") == 0.0, "depot is empty")
	for i in 40:
		war.tick(TICK)
		assert(stock.amount("ammo") == 0.0, "stays at zero, not below")


func test_squads_only_draw_from_their_own_side() -> void:
	var stats := _stats()
	var war := War.new(_two_towns([{"faction": "legion", "at": "east", "count": 1}]), stats, 1)
	var squad = war.squads[0]
	squad.ammo = 5.0
	var stock: RefCounted = war.region.places.east.stock
	var before: float = stock.amount("ammo")
	for i in 100:
		war.tick(TICK)
		assert(stock.amount("ammo") == before, "drew from an enemy depot")
	assert(squad.ammo == 5.0)


func test_fights_on_owned_ground_get_the_fortification() -> void:
	var war := _westfront(1)
	var westgate: RefCounted = war.region.places.westgate
	assert(war._fortification_for("legion", westgate.position) == westgate.fortification)
	assert(war._fortification_for("crown", westgate.position) == 0.0, "not their ground")
	assert(war._fortification_for("legion", westgate.position + Vector2(500, 0)) == 0.0, "too far out")


func test_stand_in_orders_send_idle_squads_to_the_nearest_unowned_place() -> void:
	var war := _westfront(1)
	war.tick(TICK)
	for squad in war.squads:
		assert(squad.is_moving(), "squad at %s has no orders" % squad.at)
	for squad in war.squads_of("legion"):
		assert(squad.next in ["halle", "cray_depot", "ironford"], "legion squad heading to %s" % squad.next)
	for squad in war.squads_of("crown"):
		assert(squad.next in ["marrow", "ashby_depot", "ironford"], "crown squad heading to %s" % squad.next)


func test_a_squad_holds_a_place_until_it_is_taken() -> void:
	var war := War.new(_two_towns([{"faction": "legion", "at": "east", "count": 1}]), _stats(), 1)
	war.tick(TICK)
	assert(not war.squads[0].is_moving(), "it should stay and take the place")


func test_neither_side_wins_more_than_chance() -> void:
	var wins := {"legion": 0, "crown": 0, "": 0}
	# Longer ticks keep this quick. It's a guard against one side always winning.
	for war_seed in 16:
		var war := _westfront(1000 + war_seed)
		var ticks := 0
		while not war.over and ticks < 15000:
			war.tick(1.0)
			ticks += 1
		assert(war.over, "seed %d never ended" % war_seed)
		wins[war.winner] += 1
	assert(wins.legion >= 3 and wins.crown >= 3, "lopsided: %s" % str(wins))
