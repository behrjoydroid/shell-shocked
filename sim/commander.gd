# One side's decision maker. For now it's a stand-in so a war can run: idle squads
# hold a place until it's theirs, then march on the nearest place that isn't. M5 turns
# this into the real Gamemaster, with threat and need scoring.
extends RefCounted

var faction: String


func _init(side: String) -> void:
	faction = side


func assign_orders(war: RefCounted) -> void:
	var region: RefCounted = war.region
	for squad in war.squads:
		if squad.faction != faction or squad.is_moving():
			continue
		var here: RefCounted = region.places[squad.at]
		if here.is_capturable() and here.owner != faction:
			continue
		var target := _nearest_unowned(squad.at, region)
		if target != "":
			squad.set_route(region.path(squad.at, target))


func _nearest_unowned(from: String, region: RefCounted) -> String:
	var best := ""
	var best_distance := INF
	for place in region.places.values():
		if not place.is_capturable() or place.owner == faction:
			continue
		var distance: float = region.distance(from, place.id)
		if distance < best_distance or (distance == best_distance and place.id < best):
			best = place.id
			best_distance = distance
	return best
